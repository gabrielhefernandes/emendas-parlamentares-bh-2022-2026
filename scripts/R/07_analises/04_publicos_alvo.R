# ===========================================================================
# 04_publicos_alvo.R | 8 ETAPAS | TCC BH 2022-2026
# Reconstroi PUBLICOS-ALVO a partir da codificacao manual das planilhas.
# ATENCAO: publico_alvo_resumo e TEXTO LIVRE, nao uma tabela de categorias.
# Este script cria uma regra EXPLICITA e AUDITAVEL, nunca modifica a fonte.
# A revisao de rotulos incompletos/ambiguos precede uso definitivo no TCC.
# Requer scripts 01 e 02 aprovados (03 recomendado, mas nao obrigatorio).
# Entrada: 01_emendas_integradas.rds, 02_painel_com_ideologia.rds
# Saida: exclusivamente R/scripts_refazer/saidas/04_*
# ===========================================================================
source(file.path(Sys.getenv("TCC_BH_RAIZ", unset=getwd()),
  "scripts", "R", "01_importacao_padronizacao", "_config_funcoes.R"), encoding="UTF-8")

# ---------------------------------------------------------------------------
# ETAPA 1/8 - Dependencias, fontes e ordem de execucao
# ---------------------------------------------------------------------------
verificar_pacotes(c("dplyr", "readr", "tibble", "clubSandwich", "stringr"))
preparar_saida()
validar_manifesto_preparo()
origem_emendas <- file.path(TCC_SAIDAS, "01_emendas_integradas.rds")
origem_painel <- file.path(TCC_SAIDAS, "02_painel_com_ideologia.rds")
if (!file.exists(origem_emendas) || !file.exists(origem_painel)) {
  stop("Execute primeiro 01_preparar.bases.R e 02_ideologia_partidos.R.", call.=FALSE)
}
if (file.info(origem_painel)$mtime < file.info(origem_emendas)$mtime) {
  stop("O painel de 02 e anterior a preparacao de 01. Reexecute o script 02.", call.=FALSE)
}
message("[04] ETAPA 1/8 - Pre-requisitos e manifesto conferidos")

# ---------------------------------------------------------------------------
# ETAPA 2/8 - Identidade, universo e denominadores nao-saude
# ---------------------------------------------------------------------------
emendas <- readRDS(origem_emendas)
painel <- readRDS(origem_painel)
if (nrow(emendas)!=4796L || nrow(painel)!=207L) stop(
  "Universo diferente de 4796 emendas e 207 perfis.",call.=FALSE)
validar_unico(emendas,"id_emenda","emendas/publicos")
validar_unico(painel,"id_vereador_ano","painel/publicos")
col_e <- c("id_emenda","ano","id_vereador_ano","eh_nao_saude","publico_bin",
           "publico_alvo_resumo","valor_emenda_num","objeto")
# As versoes do banco podem nomear o texto da emenda objeto ou objeto_emenda:
col_e_essencial <- setdiff(col_e,"objeto")
if (length(setdiff(col_e_essencial,names(emendas)))) stop(
  "Campos de publico-alvo ausentes das emendas: ",
  paste(setdiff(col_e_essencial,names(emendas)),collapse=", "),call.=FALSE)
col_p <- c("id_vereador_ano","ano","pessoa_chave","parlamentar_partido",
           "tem_portfolio_nao_saude","valor_nao_saude","zucco_final","bolognesi_media")
if (length(setdiff(col_p,names(painel)))) stop(
  "Campos ausentes do painel: ",paste(setdiff(col_p,names(painel)),collapse=", "),call.=FALSE)
perfis <- painel[painel$tem_portfolio_nao_saude &
                  is.finite(painel$valor_nao_saude) & painel$valor_nao_saude>0,,drop=FALSE]
nao_saude <- emendas[!is.na(emendas$eh_nao_saude) & emendas$eh_nao_saude,,drop=FALSE]
if (nrow(perfis)!=206L || nrow(nao_saude)!=2491L ||
    sum(!is.na(perfis$zucco_final))!=173L ||
    sum(!is.na(perfis$bolognesi_media))!=140L) stop(
    "Amostras inesperadas. Esperado: 206 portfólios, 2491 emendas, 173 Zucco e 140 Bolognesi.",call.=FALSE)
if (anyNA(nao_saude$id_vereador_ano) ||
    any(!(nao_saude$id_vereador_ano %in% painel$id_vereador_ano))) stop(
    "Existem emendas nao-saude sem vereador-ano no painel.",call.=FALSE)
message("[04] ETAPA 2/8 - Universo de 2491 emendas e 206 perfis validado")

# ---------------------------------------------------------------------------
# ETAPA 3/8 - Dicionario transparente de rotulos, sem inferir grupos do objeto
# ---------------------------------------------------------------------------
# Padronizacao apenas para busca de termos; valores brutos preservados.
normalizar_rotulo_publico <- function(x) {
  z <- as.character(x)
  z[is.na(x)] <- ""
  z <- iconv(tolower(z),from="",to="ASCII//TRANSLIT",sub="")
  z[is.na(z)] <- ""
  z <- gsub("[[:space:]]+"," ",trimws(z))
  z
}
# Sao as 15 categorias da antiga Tabela 8; sem unificar automaticamente
# publico negro e comunidades tradicionais de matriz africana.
categorias <- c(
 "Criancas","Adolescentes_jovens","Animais","Pessoas_com_deficiencia",
 "Idosos","Mulheres","Pessoas_em_situacao_de_rua","Populacao_negra",
 "LGBT_mais","Matriz_africana_quilombolas","Migrantes_refugiados",
 "Dependentes_quimicos","Gestantes_materno_infantil","Trabalhadoras_sexuais",
 "Povos_comunidades_tradicionais_outros"
)
# Regras intencionalmente especificas: jamais classificar apenas pela sigla
# de partido ou pelo nome de uma instituicao.
padroes <- c(
 Criancas="crianc|infanto|infantil|recem.nasc|\\bbebes?\\b",
 Adolescentes_jovens="adolesc|jovens?|juven|juventud|infanto",
 Animais="animal|animais|caes|cachorr|gatos|felinos|caninos|\\bpets?\\b",
 Pessoas_com_deficiencia="deficienc|\\bpcds?\\b|sindrome de down|autistas?|\\btea\\b",
 Idosos="idosos?|terceira idade",
 Mulheres="mulheres?|feminin",
 Pessoas_em_situacao_de_rua="situacao de rua",
 Populacao_negra="negros?|negras?|afrodescendente|(^|[;, ])afro($|[;, ])",
 LGBT_mais="lgbt|trans|travestis?|lesbicas|gay|homossex",
 Matriz_africana_quilombolas="quilomb|matriz africana|congadeir|afroperiferic",
 Migrantes_refugiados="migrant|refugiad",
 Dependentes_quimicos="dependentes? quimic|dependencia quimic",
 Gestantes_materno_infantil="gestant|materno|parturient|puerper|recem.nasc",
 Trabalhadoras_sexuais="trabalhadoras? sexuais",
 Povos_comunidades_tradicionais_outros="indigen|povos originarios|cigan"
)
if(!identical(names(padroes),categorias)) stop("Dicionario de 15 categorias inconsistente.",call.=FALSE)
nao_saude$resumo_original <- as.character(nao_saude$publico_alvo_resumo)
nao_saude$resumo_normalizado <- normalizar_rotulo_publico(nao_saude$resumo_original)
nao_saude$resumo_presente <- nzchar(nao_saude$resumo_normalizado)
nao_saude$flag_publico_1 <- !is.na(nao_saude$publico_bin) & nao_saude$publico_bin==1L
for (cat in categorias) {
  nao_saude[[cat]] <- nao_saude$flag_publico_1 &
    grepl(padroes[[cat]],nao_saude$resumo_normalizado,perl=TRUE)
}
# Somente termos explicitos no RESUMO sao classificados automaticamente.
# RESUMO vazio nao vira categoria, mesmo que o objeto contenha um indicio.
nao_saude$n_categorias_recuperadas <- rowSums(as.data.frame(nao_saude[categorias]))
message("[04] ETAPA 3/8 - 15 categorias mapeadas com rotulos originais preservados")

# ---------------------------------------------------------------------------
# ETAPA 4/8 - Relatorio de excecoes/ambiguidade antes das regressoes
# ---------------------------------------------------------------------------
nao_saude$pendencia <- dplyr::case_when(
  nao_saude$flag_publico_1 & !nao_saude$resumo_presente ~ "FLAG_1_SEM_RESUMO",
  !nao_saude$flag_publico_1 & nao_saude$resumo_presente ~ "RESUMO_COM_FLAG_0_OU_NA",
  nao_saude$flag_publico_1 & nao_saude$resumo_presente &
    nao_saude$n_categorias_recuperadas==0L ~ "ROTULO_NAO_RECONHECIDO",
  TRUE ~ NA_character_
)
# Certos descritores sao politicamente e sociologicamente distintos de
# Mulheres/Negros por definicao; revisao manual, nunca inferencia automatica.
termos_duvidosos <- grepl("pessoas que menstruam|que menstruam|periferic|violencia sexual",
                         nao_saude$resumo_normalizado,perl=TRUE)
nao_saude$revisar_descricao <- termos_duvidosos

# DECISAO MANUAL VALIDADA PELO PESQUISADOR (2026-10-13):
# 2026_BRUNO_PEDRALVA_1273_01, rotulo original "comunidades tradicionais
# afroperifericas", pertence a Matriz_africana_quilombolas para FINS DE
# CODIFICACAO DESTA PESQUISA. Nao fazer inferencia automatica dessa
# equivalencia para outras emendas; esta excecao e ESPECIFICA do registro.
# O rotulo original permanece intacto nas fontes e nas tabelas de auditoria.
id_decisao_afro <- "2026_BRUNO_PEDRALVA_1273_01"
indice_decisao_afro <- which(nao_saude$id_emenda == id_decisao_afro)
if (length(indice_decisao_afro) != 1L) stop(
  "Decisao manual nao aplicavel: ID de Bruno Pedralva ausente ou duplicado.",
  call.=FALSE)
if (!identical(nao_saude$resumo_normalizado[indice_decisao_afro],
               "comunidades tradicionais afroperifericas") ||
    !isTRUE(nao_saude$Matriz_africana_quilombolas[indice_decisao_afro]) ||
    nao_saude$n_categorias_recuperadas[indice_decisao_afro] != 1L) stop(
  "Decisao manual nao aplicavel: rotulo/categoria mudaram; revisar registro.",
  call.=FALSE)
nao_saude$revisar_descricao[indice_decisao_afro] <- FALSE
nao_saude$decisao_manual <- NA_character_
nao_saude$decisao_manual[indice_decisao_afro] <-
  "Manter em Matriz_africana_quilombolas, conforme decisao do pesquisador em 2026-10-13"
salvar_csv(tibble::tibble(
  ano=nao_saude$ano[indice_decisao_afro],
  id_emenda=id_decisao_afro,
  publico_alvo_original=nao_saude$resumo_original[indice_decisao_afro],
  categoria_aprovada="Matriz_africana_quilombolas",
  justificativa="Classificacao manual aprovada pelo pesquisador; nao generalizar para outros casos",
  data_decisao="2026-10-13"
),"04_decisoes_manuais.csv")
message("[04] Decisao manual registrada para ", id_decisao_afro,
        " (matriz africana/quilombolas; nao e mais pendencia).")

cols_aud <- c("ano","id_emenda","id_vereador_ano","publico_bin",
  "resumo_original","resumo_normalizado","n_categorias_recuperadas",
  "pendencia","revisar_descricao","decisao_manual")
pendentes <- nao_saude[!is.na(nao_saude$pendencia) | nao_saude$revisar_descricao,
                       cols_aud,drop=FALSE]
salvar_csv(tibble::as_tibble(pendentes),"04_pendencias_manual.csv")
rotulos <- nao_saude |>
  dplyr::group_by(resumo_original,resumo_normalizado,publico_bin) |>
  dplyr::summarise(n_emendas=dplyr::n(),
    .groups="drop")
rotulos$n_categorias <- vapply(rotulos$resumo_normalizado,function(s) {
  if(!nzchar(s)) return(0L)
  as.integer(sum(vapply(padroes,function(p)grepl(p,s,perl=TRUE),logical(1))))
},integer(1))
rotulos$categorias_detectadas <- vapply(rotulos$resumo_normalizado,function(s) {
  if(!nzchar(s)) return("")
  paste(names(padroes)[vapply(padroes,function(p)grepl(p,s,perl=TRUE),logical(1))],collapse="; ")
},character(1))
salvar_csv(rotulos,"04_dicionario_rotulos_observados.csv")
if(nrow(pendentes)) message("[04] ATENCAO: ",nrow(pendentes),
  " registro(s) exigem exame manual. Resultados estatisticos sao PROVISORIOS.",
  " Consulte 04_pendencias_manual.csv e o dicionario.")
message("[04] ETAPA 4/8 - Dicionario e pendencias gravados para revisao")

# ---------------------------------------------------------------------------
# ETAPA 5/8 - Participacoes do VALOR nao-saude por categoria/vereador-ano
# ---------------------------------------------------------------------------
# Cada emenda pode constar em mais de um publico. As participacoes NAO somam
# 100%, e isto e esperado. Nada e imputado em valores em branco.
ausente_valor <- nao_saude[is.na(nao_saude$valor_emenda_num),
                           c("ano","id_emenda","id_vereador_ano","resumo_original"),drop=FALSE]
salvar_csv(tibble::as_tibble(ausente_valor),"04_emendas_sem_valor.csv")
if(nrow(ausente_valor)) message("[04] AVISO: ",nrow(ausente_valor),
  " emenda(s) nao-saude sem valor; as somas consideram somente valores conhecidos.")
montar_categoria <- function(cat) {
  x <- nao_saude[nao_saude[[cat]],,drop=FALSE]
  agg <- x |>
    dplyr::group_by(id_vereador_ano) |>
    dplyr::summarise(n_emendas=dplyr::n(),
      n_sem_valor=sum(is.na(valor_emenda_num)),
      valor_publico=sum(valor_emenda_num,na.rm=TRUE),.groups="drop")
  perfis |>
    dplyr::select(id_vereador_ano,ano,pessoa_chave,parlamentar_partido,
      valor_nao_saude,zucco_final,bolognesi_media) |>
    dplyr::left_join(agg,by="id_vereador_ano") |>
    dplyr::mutate(
      categoria=cat,
      n_emendas=dplyr::coalesce(n_emendas,0L),
      n_sem_valor=dplyr::coalesce(n_sem_valor,0L),
      valor_publico=dplyr::coalesce(valor_publico,0),
      participacao=valor_publico/valor_nao_saude,
      prevalencia=n_emendas>0)
}
matriz <- dplyr::bind_rows(lapply(categorias,montar_categoria))
if(nrow(matriz)!=206L*length(categorias) ||
   any(!is.finite(matriz$participacao)) ||
   any(matriz$participacao < -1e-10 | matriz$participacao > 1+1e-10)) stop(
  "Participacao fora de [0,1] na matriz de publico-alvo.",call.=FALSE)
val_nao_saude <- sum(perfis$valor_nao_saude)
descritivo <- matriz |>
  dplyr::group_by(categoria) |>
  dplyr::summarise(
    n_emendas=sum(n_emendas),valor_publico=sum(valor_publico),
    percentual_agregado=100*sum(valor_publico)/val_nao_saude,
    participacao_media_206=100*mean(participacao),
    prevalencia_206=100*mean(prevalencia),
    n_perfis_com_publico=sum(prevalencia),
    emendas_sem_valor=sum(n_sem_valor),.groups="drop")
message("[04] ETAPA 5/8 - 206 x 15 participacoes orcamentarias calculadas")

# ---------------------------------------------------------------------------
# ETAPA 6/8 - Modelos de ideologia continua, FE ano, CR2, Satterthwaite
# ---------------------------------------------------------------------------
rodar_um <- function(cat,escala,nome_escala) {
  x <- matriz[matriz$categoria==cat & !is.na(matriz[[escala]]),,drop=FALSE]
  x$ideologia <- x[[escala]]
  x <- x[is.finite(x$ideologia) & !is.na(x$pessoa_chave),,drop=FALSE]
  n <- nrow(x); np <- dplyr::n_distinct(x$pessoa_chave)
  ret_base <- tibble::tibble(categoria=cat,escala=nome_escala,
    n_observacoes=n,n_vereadores=np)
  if(n<10L || np<8L || stats::sd(x$participacao)==0 ||
     stats::sd(x$ideologia)==0) return(dplyr::mutate(ret_base,
       beta=NA_real_,erro_padrao_CR2=NA_real_,df_Satterthwaite=NA_real_,
       p_CR2_Satterthwaite=NA_real_,IC95_inferior=NA_real_,IC95_superior=NA_real_,
       efeito_05_ponto_pp=NA_real_,status="sem_variacao_ou_amostra_insuficiente"))
  modelo <- stats::lm(participacao ~ ideologia + factor(ano),data=x)
  if(is.na(stats::coef(modelo)[["ideologia"]])) return(dplyr::mutate(ret_base,
       beta=NA_real_,erro_padrao_CR2=NA_real_,df_Satterthwaite=NA_real_,
       p_CR2_Satterthwaite=NA_real_,IC95_inferior=NA_real_,IC95_superior=NA_real_,
       efeito_05_ponto_pp=NA_real_,status="coeficiente_nao_estimavel"))
  # P-values nao estimaveis em grupos rarissimos ficam NA com diagnostico.
  diagnostico <- tryCatch({
    v <- clubSandwich::vcovCR(modelo,cluster=x$pessoa_chave,type="CR2")
    tab <- as.data.frame(clubSandwich::coef_test(modelo,vcov=v,test="Satterthwaite"))
    j <- which(rownames(tab)=="ideologia")
    if(length(j)!=1L && "Coef" %in% names(tab)) j<-which(as.character(tab$Coef)=="ideologia")
    if(length(j)!=1L || !all(c("beta","SE","df_Satt","p_Satt") %in% names(tab)))
      stop("Formato de coef_test inesperado")
    b <- as.numeric(tab$beta[j]); se <- as.numeric(tab$SE[j]);
    df <- as.numeric(tab$df_Satt[j]);p <- as.numeric(tab$p_Satt[j]);
    if(any(!is.finite(c(b,se,df,p))) || df<=0) stop("Estimativa CR2 nao finita")
    e <- stats::qt(0.975,df=df)*se
    dplyr::mutate(ret_base,beta=b,erro_padrao_CR2=se,
      df_Satterthwaite=df,p_CR2_Satterthwaite=p,
      IC95_inferior=b-e,IC95_superior=b+e,
      efeito_05_ponto_pp=b*50,status="ok")
  },error=function(e) {
    message("[04] AVISO modelo ",cat," / ",nome_escala,": ",conditionMessage(e))
    dplyr::mutate(ret_base,beta=NA_real_,erro_padrao_CR2=NA_real_,
      df_Satterthwaite=NA_real_,p_CR2_Satterthwaite=NA_real_,
      IC95_inferior=NA_real_,IC95_superior=NA_real_,
      efeito_05_ponto_pp=NA_real_,status="erro_CR2_revisar")
  })
  diagnostico
}
regressoes <- dplyr::bind_rows(lapply(c("zucco_final","bolognesi_media"),function(col) {
  nome <- if(col=="zucco_final") "Zucco-Power (2021/2017)" else "Bolognesi (media)"
  dplyr::bind_rows(lapply(categorias,function(cat) rodar_um(cat,col,nome)))
}))
if(nrow(regressoes)!=2L*length(categorias) ||
   any(regressoes$n_observacoes[regressoes$escala=="Zucco-Power (2021/2017)"]!=173L) ||
   any(regressoes$n_observacoes[regressoes$escala=="Bolognesi (media)"]!=140L)) stop(
    "Amostra ou quantidade de modelos de publicos incorreta.",call.=FALSE)
regressoes <- regressoes |>
 dplyr::group_by(escala) |>
 dplyr::mutate(p_BH_FDR=stats::p.adjust(p_CR2_Satterthwaite,method="BH")) |>
 dplyr::ungroup()
message("[04] ETAPA 6/8 - ",nrow(regressoes)," modelos tentados com CR2 e efeitos fixos de ano")

# ---------------------------------------------------------------------------
# ETAPA 7/8 - Especializacao na causa animal e multiplos publicos
# ---------------------------------------------------------------------------
animal <- nao_saude[nao_saude$Animais,,drop=FALSE]
exclusivos <- animal$n_categorias_recuperadas==1L
misto <- animal$n_categorias_recuperadas>1L
animais_resumo <- tibble::tibble(
  n_animais_nos_resumos=nrow(animal),
  n_so_animais=sum(exclusivos),
  n_mistos=sum(misto),
  valor_animais_conhecido=sum(animal$valor_emenda_num,na.rm=TRUE),
  participacao_animais_percentual=100*sum(animal$valor_emenda_num,na.rm=TRUE)/val_nao_saude,
  n_animais_sem_valor=sum(is.na(animal$valor_emenda_num)),
  n_pendencias_publicos=nrow(pendentes),
  status_reprodutibilidade=if(nrow(pendentes)) "PENDENTE_REVISAO_MANUAL" else "SEM_PENDENCIAS_TEXTUAIS"
)
# Nomes da especializacao sao exploratorios ate inspecao manual de todos os
# resumos vazio/ambiguos. Nao contar excecoes ocultas como se fossem zero.
especializacao <- matriz |>
  dplyr::filter(categoria=="Animais",prevalencia) |>
  dplyr::mutate(percentual_portfolio=100*participacao) |>
  dplyr::select(ano,id_vereador_ano,parlamentar_partido,
     pessoa_chave,n_emendas,valor_publico,percentual_portfolio) |>
  dplyr::arrange(dplyr::desc(percentual_portfolio),ano)
message("[04] ETAPA 7/8 - Causa animal, sobreposicoes e excepcionais auditadas")

# ---------------------------------------------------------------------------
# ETAPA 8/8 - Exportar auditoria, amostras e resultados SEM alterar Excel
# ---------------------------------------------------------------------------
salvar_csv(tibble::as_tibble(nao_saude)[c("ano","id_emenda","id_vereador_ano",
  "publico_bin","resumo_original","resumo_normalizado","n_categorias_recuperadas",
  "pendencia","revisar_descricao","decisao_manual",categorias)],"04_classificacao_por_emenda.csv")
salvar_csv(matriz,"04_matriz_vereador_ano_publicos.csv")
salvar_csv(descritivo,"04_descritivo_publicos.csv")
salvar_csv(regressoes,"04_regressoes_publicos_CR2.csv")
salvar_csv(animais_resumo,"04_auditoria_animal.csv")
salvar_csv(especializacao,"04_especializacao_animal_vereador_ano.csv")
meta <- tibble::tibble(
  propriedade=c("fonte","denominador","n_portfolios","n_nao_saude",
    "n_categorias","n_regressoes","classificacao","pendencias","nota"),
  valor=c("01/02 RDS com manifesto coding/data_raw",
    "valor total de emendas nao-saude por vereador-ano", "206","2491","15","30",
    "resumo explicito; publico_bin=1", as.character(nrow(pendentes)),
    "Resultados PROVISORIOS se houver pendencias; nunca inferir publico a partir do objeto"))
salvar_csv(meta,"04_metadados.csv")
saveRDS(matriz,file.path(TCC_SAIDAS,"04_painel_longo_publicos.rds"),compress="xz")
message("[04] ETAPA 8/8 - Arquivos 04_* em ",TCC_SAIDAS)
print(descritivo)
print(regressoes[,c("categoria","escala","beta","p_CR2_Satterthwaite","p_BH_FDR","status")],n=30)
print(animais_resumo)
if (nrow(pendentes) > 0L) {
  message(
    "[04] RESULTADOS PROVISORIOS: revisar ", nrow(pendentes),
    " registro(s) em 04_pendencias_manual.csv ANTES de incorporar resultados ao TCC."
  )
} else {
  message(
    "[04] CONCLUIDO: sem pendencias textuais; ainda recomenda-se validacao com dicionario/manual original."
  )
}
