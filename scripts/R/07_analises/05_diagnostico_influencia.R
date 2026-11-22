# ============================================================================
# 05_diagnostico_influencia.R | 7 ETAPAS | TCC BH (2022–2026)
# Diagnostico leave-one-party-out e leave-one-vereador-out para os 17 temas.
# NUNCA altera planilhas nem sobrescreve saidas 01/02/03/04.
# Usar APENAS dados aprovados em 01, 02 e 03; o script 04 e independente.
#
# Unidade de analise: vereador-ano; denominador: carteira nao-saude.
# Modelo base: participacao ~ ideologia + factor(ano), por escala.
# A retirada de ator reestima toda a regressao na amostra remanescente.
# A variancia CR2 NAO modifica os coeficientes OLS; para amostra dirigida,
# recalculamos tambem CR2 e p com graus de liberdade Satterthwaite.
# ============================================================================
source(file.path(Sys.getenv("TCC_BH_RAIZ", unset=getwd()),
  "scripts", "R", "01_importacao_padronizacao", "_config_funcoes.R"), encoding="UTF-8")

# ---------------------------------------------------------------------------
# ETAPA 1/7 - Verificar fontes, versoes e dependencias
# ---------------------------------------------------------------------------
verificar_pacotes(c("dplyr", "readr", "tibble", "clubSandwich"))
preparar_saida()
validar_manifesto_preparo()
fonte_longa <- file.path(TCC_SAIDAS,"03_painel_longo_17_temas.rds")
fonte_base <- file.path(TCC_SAIDAS,"03_regressoes_tematicas_CR2.csv")
fonte_painel_02 <- file.path(TCC_SAIDAS,"02_painel_com_ideologia.rds")
if (!all(file.exists(c(fonte_longa,fonte_base,fonte_painel_02)))) {
  stop("Arquivos de 02/03 ausentes. Execute novamente 01, 02 e 03 na ordem.",call.=FALSE)
}
if (file.info(fonte_longa)$mtime < file.info(fonte_painel_02)$mtime) {
  stop("O painel tematico de 03 e anterior ao de 02. Reexecute 03.",call.=FALSE)
}
message("[05] ETAPA 1/7 - Fontes e dependencias aprovadas")

# ---------------------------------------------------------------------------
# ETAPA 2/7 - Reproduzir exatamente amostras e coeficientes completos de 03
# ---------------------------------------------------------------------------
matriz <- readRDS(fonte_longa)
base_03 <- readr::read_csv(fonte_base,show_col_types=FALSE)
campos <- c("tema","ano","id_vereador_ano","pessoa_chave","parlamentar_partido",
            "sigla_partido","participacao","zucco_final","bolognesi_media")
if (length(setdiff(campos,names(matriz)))) stop(
  "Faltam campos no painel de 03: ",paste(setdiff(campos,names(matriz)),collapse=", "),
  call.=FALSE)
if (nrow(matriz)!=206L*17L || nrow(base_03)!=34L ||
    dplyr::n_distinct(matriz$tema)!=17L ||
    anyDuplicated(matriz[,c("id_vereador_ano","tema")])>0L) {
  stop("Matriz de 03 ou regressoes nao correspondem a 206 x 17 e 34 modelos.",call.=FALSE)
}
if (any(is.na(matriz$participacao)) ||
    any(matriz$participacao < -1e-8 | matriz$participacao > 1+1e-8)) {
  stop("Participacoes invalidas: reexecute 03.",call.=FALSE)
}
escalas <- c("zucco_final","bolognesi_media")
nomes_escala <- c("Zucco-Power (2021/2017)","Bolognesi (media)")
nomes_escala_por_coluna <- stats::setNames(nomes_escala,escalas)
temas <- unique(matriz$tema)

amostra <- function(tema, escala) {
  x <- matriz[matriz$tema==tema & !is.na(matriz[[escala]]),,drop=FALSE]
  x$ideologia <- x[[escala]]
  x <- x[is.finite(x$ideologia) & is.finite(x$participacao) &
         !is.na(x$pessoa_chave) & !is.na(x$sigla_partido),,drop=FALSE]
  x
}

# Nunca incluir excluidos sem registros; diagnosique "nao estimavel".
fit_ols <- function(x) {
  if (nrow(x)<10L || dplyr::n_distinct(x$pessoa_chave)<8L ||
      dplyr::n_distinct(x$ideologia)<2L) return(list(status="amostra_insuficiente", beta=NA_real_,modelo=NULL))
  mod <- tryCatch(stats::lm(participacao ~ ideologia + factor(ano),data=x),
                  error=function(e) NULL)
  if (is.null(mod) || stats::nobs(mod)!=nrow(x) ||
      !"ideologia" %in% names(stats::coef(mod)) ||
      !is.finite(stats::coef(mod)[["ideologia"]])) {
    return(list(status="nao_estimavel", beta=NA_real_,modelo=NULL))
  }
  list(status="ok",beta=unname(stats::coef(mod)[["ideologia"]]),modelo=mod)
}

configs <- list()
k <- 0L
for (escala in escalas) for (tema in temas) {
  k <- k+1L
  x <- amostra(tema,escala)
  esperado <- if (escala=="zucco_final") 173L else 140L
  if (nrow(x)!=esperado) {
    stop("Amostra inesperada em ",tema,"/",escala,call.=FALSE)
  }
  base <- fit_ols(x)
  if (base$status!="ok") stop("Modelo integral nao estimavel: ",tema,"/",escala,call.=FALSE)
  referencia <- base_03[base_03$tema==tema &
                            base_03$escala==nomes_escala_por_coluna[[escala]],,drop=FALSE]
  if (nrow(referencia)!=1L ||
      abs(base$beta-referencia$beta[[1]])>1e-9 ||
      referencia$n_observacoes[[1]]!=nrow(x) ||
      referencia$n_vereadores[[1]]!=dplyr::n_distinct(x$pessoa_chave)) {
    stop("O modelo de base nao coincide com a saida de 03: ",tema," / ",escala,
         ". Nao prosseguir com comparacoes.",call.=FALSE)
  }
  configs[[k]] <- list(tema=tema,escala=escala,nome=nomes_escala_por_coluna[[escala]],
                       x=x,beta=base$beta, modelo=base$modelo)
}
message("[05] ETAPA 2/7 - 34 modelos originais reproduzidos com precisao numerica")

# ---------------------------------------------------------------------------
# ETAPA 3/7 - Reestimar todas as exclusoes unitarias de partido e vereador
# ---------------------------------------------------------------------------
# Remover TODAS as observacoes do ator no periodo; NAO apenas um ano.
retirar_ator <- function(config,tipo,chave) {
  x <- config$x
  col <- if (tipo=="partido") "sigla_partido" else "pessoa_chave"
  selecionado <- x[[col]]==chave
  n_retiradas <- sum(selecionado)
  x_reduz <- x[!selecionado,,drop=FALSE]
  estimado <- fit_ols(x_reduz)
  den <- abs(config$beta)
  delta <- if(is.finite(estimado$beta)) abs(estimado$beta-config$beta) else NA_real_
  tibble::tibble(
    tema=config$tema, escala=config$nome,
    tipo_ator=tipo, chave_ator=as.character(chave),
    beta_original=config$beta,beta_sem_ator=estimado$beta,
    delta_beta_abs=delta,
    mudanca_relativa_pct=if (den>1e-8 && is.finite(delta)) 100*delta/den else NA_real_,
    n_amostra_original=nrow(x),n_amostra_sem_ator=nrow(x_reduz),
    n_removidas=n_retiradas,
    n_vereadores_originais=dplyr::n_distinct(x$pessoa_chave),
    n_vereadores_sem_ator=dplyr::n_distinct(x_reduz$pessoa_chave),
    n_anos_sem_ator=dplyr::n_distinct(x_reduz$ano),
    alterou_sinal=if (is.finite(estimado$beta))
      (sign(estimado$beta)!=sign(config$beta)) else NA,
    beta_original_pequeno=(den<0.01),
    status=estimado$status
  )
}

# Inclui exclusao de cada sigla usada nos modelos e de cada pessoa longitudinal.
exclusoes <- list(); k <- 0L
for (conf in configs) {
  for (tipo in c("partido","vereador")) {
    coluna <- if (tipo=="partido") "sigla_partido" else "pessoa_chave"
    atores <- sort(unique(as.character(conf$x[[coluna]])))
    if (anyNA(atores) || any(!nzchar(atores))) stop("Chave vazia em ",tipo,call.=FALSE)
    for (ator in atores) {
      k<-k+1L
      exclusoes[[k]] <- retirar_ator(conf,tipo,ator)
    }
  }
}
loo <- dplyr::bind_rows(exclusoes)
if (nrow(loo)!=length(exclusoes) || any(loo$n_removidas<1L)) {
  stop("LOO nao abrangeu todos os atores observados.",call.=FALSE)
}
if (any(!is.finite(loo$beta_sem_ator[loo$status=="ok"]))) {
  stop("LOO retornou coeficiente nao finito com status ok.",call.=FALSE)
}
message("[05] ETAPA 3/7 - ",nrow(loo)," exclusoes partido/vereador reestimadas")

# ---------------------------------------------------------------------------
# ETAPA 4/7 - Classificar sensibilidade sem interpretar causalmente
# ---------------------------------------------------------------------------
# Atores com poucas observacoes podem apresentar grandes variacoes relativas.
# A coluna beta_original_pequeno sinaliza instabilidade dos percentuais.
ranking <- loo |>
  dplyr::filter(status=="ok") |>
  dplyr::group_by(tema,escala,tipo_ator) |>
  dplyr::arrange(dplyr::desc(delta_beta_abs),chave_ator,.by_group=TRUE) |>
  dplyr::mutate(posicao_influencia=dplyr::row_number()) |>
  dplyr::ungroup()
top10 <- ranking |>
  dplyr::filter(posicao_influencia<=10L)
mais_influente <- ranking |>
  dplyr::filter(posicao_influencia==1L)
if (nrow(mais_influente)!=34L*2L) {
  stop("Ranking nao tem 1 ator principal para partido e vereador em cada modelo.",call.=FALSE)
}
message("[05] ETAPA 4/7 - Rank por alteracao ABSOLUTA do coeficiente (68 cabecalhos)")

# ---------------------------------------------------------------------------
# ETAPA 5/7 - Reconstruir as exclusoes especificas discutidas no TCC
# ---------------------------------------------------------------------------
# Verificar se as chaves pertencem ao painel. Nao fazer correspondencias vagas.
alvos_tcc <- tibble::tribble(
  ~tema,~tipo_ator,~chave_ator,~rotulo_tcc,
  "cultura","partido","PSOL","PSOL (Cultura)",
  "cultura","vereador","izalourenca","Iza Lourenca (Cultura)",
  "02","partido","PSOL","PSOL (COD02)",
  "02","vereador","izalourenca","Iza Lourenca (COD02)",
  "14","partido","NOVO","NOVO (COD14)",
  "14","vereador","fernandapereiraaltoe","Fernanda Pereira Altoe (COD14)",
  "12","partido","NOVO","NOVO (COD12)",
  "12","vereador","marcelatropia","Marcela Tropia (COD12)",
  "10","partido","NOVO","NOVO (COD10)",
  "10","vereador","brauliolara","Braulio Lara (COD10)"
)
confere_alvos <- function(t) {
  x <- matriz[matriz$tema==t$tema,,drop=FALSE]
  chave <- if(t$tipo_ator=="partido") x$sigla_partido else x$pessoa_chave
  t$chave_ator %in% chave
}
# Dados de 03 usam nomes normalizados do partido base; conferir antes do filtro.
invalidos <- !vapply(seq_len(nrow(alvos_tcc)),function(i)
  confere_alvos(as.list(alvos_tcc[i,])),logical(1))
if (any(invalidos)) {
  salvar_csv(alvos_tcc[invalidos,,drop=FALSE],"05_alvos_tcc_nao_localizados.csv")
  message("[05] AVISO: ",sum(invalidos)," alvo(s) nao encontrados. Ver 05_alvos_tcc_nao_localizados.csv")
}
comparacoes_tcc <- loo |>
  dplyr::inner_join(alvos_tcc,by=c("tema","tipo_ator","chave_ator")) |>
  dplyr::select(rotulo_tcc,dplyr::everything())
esperadas <- nrow(alvos_tcc)*length(escalas)
if (nrow(comparacoes_tcc)!=esperadas && !any(invalidos)) {
  stop("A tabela especifica do TCC deveria ter ",esperadas," observacoes.",call.=FALSE)
}
message("[05] ETAPA 5/7 - ",nrow(comparacoes_tcc)," comparacoes dirigidas TCC/2 escalas")

# ---------------------------------------------------------------------------
# ETAPA 6/7 - CR2/Satterthwaite nas exclusoes dirigidas
# ---------------------------------------------------------------------------
# Deixar claro que o ranking geral compara coeficientes OLS; nao p-valores.
calcular_cr2_dirigido <- function(t) {
  esc <- names(nomes_escala_por_coluna)[match(t$escala,nomes_escala_por_coluna)]
  ix <- which(vapply(configs,function(z) z$tema==t$tema && z$escala==esc,logical(1)))
  if (length(ix)!=1L) stop("Modelo alvo ausente: ",t$tema,"/",t$escala,call.=FALSE)
  conf <- configs[[ix]]
  campo <- if (t$tipo_ator=="partido") "sigla_partido" else "pessoa_chave"
  reduzido <- conf$x[conf$x[[campo]]!=t$chave_ator,,drop=FALSE]
  mod <- fit_ols(reduzido)
  if (mod$status!="ok") return(tibble::tibble(
    p_CR2_sem_ator=NA_real_,SE_CR2_sem_ator=NA_real_,
    df_Satterthwaite_sem_ator=NA_real_,IC95_inferior_sem_ator=NA_real_,
    IC95_superior_sem_ator=NA_real_,status_CR2="modelo_nao_estimavel"))
  tryCatch({
    v <- clubSandwich::vcovCR(mod$modelo,cluster=reduzido$pessoa_chave,type="CR2")
    teste <- as.data.frame(clubSandwich::coef_test(mod$modelo,vcov=v,test="Satterthwaite"))
    j <- which(rownames(teste)=="ideologia")
    if(length(j)!=1L && "Coef" %in% names(teste))
      j <- which(as.character(teste$Coef)=="ideologia")
    if(length(j)!=1L || !all(c("beta","SE","df_Satt","p_Satt") %in% names(teste)))
      stop("Formato da tabela CR2 mudou")
    se<-as.numeric(teste$SE[[j]]);df<-as.numeric(teste$df_Satt[[j]])
    p<-as.numeric(teste$p_Satt[[j]])
    if(!all(is.finite(c(se,df,p))) || df<=0) stop("CR2 invalido")
    ic<-stats::qt(0.975,df=df)*se
    tibble::tibble(p_CR2_sem_ator=p,SE_CR2_sem_ator=se,
      df_Satterthwaite_sem_ator=df,IC95_inferior_sem_ator=mod$beta-ic,
      IC95_superior_sem_ator=mod$beta+ic,status_CR2="ok")
  },error=function(e) {
    message("[05] AVISO no CR2 de ",t$rotulo_tcc," / ",t$escala,": ",conditionMessage(e))
    tibble::tibble(p_CR2_sem_ator=NA_real_,SE_CR2_sem_ator=NA_real_,
      df_Satterthwaite_sem_ator=NA_real_,IC95_inferior_sem_ator=NA_real_,
      IC95_superior_sem_ator=NA_real_,status_CR2="erro_CR2_revisar")
  })
}
if(nrow(comparacoes_tcc)) {
  detalhes_cr2 <- dplyr::bind_rows(lapply(seq_len(nrow(comparacoes_tcc)),function(i)
    calcular_cr2_dirigido(as.list(comparacoes_tcc[i,]))))
  comparacoes_tcc <- dplyr::bind_cols(comparacoes_tcc,detalhes_cr2)
}
message("[05] ETAPA 6/7 - CR2 recalculado nas exclusoes dirigidas; veja status_CR2")

# ---------------------------------------------------------------------------
# ETAPA 7/7 - Exportar dados e auditoria, sem substituir o TCC
# ---------------------------------------------------------------------------
metadados <- tibble::tibble(
  campo=c("base","ano","unidade","repeticoes","metodo","modelo",
          "controle_ano","coeficiente","variancia_cr2","nivel_cluster",
          "exclusoes_gerais","amostra_dirigida","cautela"),
  valor=c("RDS de 03 (17 temas)","2022-2026","vereador-ano nao-saude",
          "cada partido e cada vereador removido em TODOS os anos",
          "deletar um ator e reestimar lm","participacao ~ ideologia + factor(ano)",
          "efeitos fixos de ano","beta OLS com e sem o ator",
          "CR2 para 20 exclusoes dirigidas","pessoa longitudinal",
          as.character(nrow(loo)),as.character(nrow(comparacoes_tcc)),
          "Nao causal; delta relativo nao e contribuicao percentual do ator"))
salvar_csv(loo,"05_todas_exclusoes_partidos_vereadores.csv")
salvar_csv(ranking,"05_ranking_exclusoes.csv")
salvar_csv(top10,"05_top10_influencia_por_tema_escala.csv")
salvar_csv(mais_influente,"05_ator_mais_influente_cada_modelo.csv")
salvar_csv(comparacoes_tcc,"05_tabela_comparativa_tcc.csv")
salvar_csv(metadados,"05_metadados.csv")
if(nrow(loo)<100L || nrow(mais_influente)!=68L) stop(
  "Saidas incompletas: conferir as tabelas 05.",call.=FALSE)
message("[05] ETAPA 7/7 - Saidas salvas em ",TCC_SAIDAS)
message("[05] FINALIZADO: ",nrow(loo)," exclusoes; 34 modelos; ",
        nrow(comparacoes_tcc)," comparacoes dirigidas")
print(comparacoes_tcc |>
        dplyr::select(rotulo_tcc,escala,beta_original,beta_sem_ator,
                      delta_beta_abs,mudanca_relativa_pct,p_CR2_sem_ator,status_CR2),
      n=nrow(comparacoes_tcc))
message("[05] ATENCAO: a pendencia manual do script 04 e independente."
)
