# ==========================================================================
# 03_composicao_tematica.R | 8 ETAPAS | TCC BH 2022-2026
# Secao 4.1: participacoes do orçamento nao-saude por tema (vereador-ano).
#
# REQUISITOS:
#   executar primeiro 01_preparar.bases.R e 02_ideologia_partidos.R
#   install.packages("clubSandwich")  # se ainda nao estiver instalado
# ENTRADAS: saidas/01_emendas_integradas.rds e 02_painel_com_ideologia.rds
# FONTES: somente coding/ e data_raw/, conforme _config_funcoes.R
# SAIDAS: apenas R/scripts_refazer/saidas; nao altera Excel original.
#
# ESTIMADOR: lm(share ~ ideologia + factor(ano)); erros CR2 por vereador
# com graus de liberdade de Satterthwaite (clubSandwich::coef_test).
# 17 temas: CAP 23 desmembrado em Cultura e Esporte e Lazer.
# ==========================================================================

source(file.path(Sys.getenv("TCC_BH_RAIZ", unset=getwd()),
  "scripts", "R", "01_importacao_padronizacao", "_config_funcoes.R"), encoding="UTF-8")

# --------------------------------------------------------------------------
# ETAPA 1/8 - Ambiente, pre-requisitos e integridade das fontes
# --------------------------------------------------------------------------
verificar_pacotes(c("dplyr", "readr", "tibble", "clubSandwich"))
preparar_saida()
validar_manifesto_preparo()
entrada_emendas <- file.path(TCC_SAIDAS, "01_emendas_integradas.rds")
entrada_painel  <- file.path(TCC_SAIDAS, "02_painel_com_ideologia.rds")
if (!file.exists(entrada_emendas) || !file.exists(entrada_painel)) {
  stop("Faltam RDS de 01/02. Execute 01_preparar.bases.R e 02_ideologia_partidos.R, nessa ordem.",
       call.=FALSE)
}
# Impede que o 03 use painel 02 mais antigo do que a nova preparacao 01.
if (file.info(entrada_painel)$mtime < file.info(entrada_emendas)$mtime) {
  stop("02_painel_com_ideologia.rds e mais antigo que as emendas do 01. Reexecute o script 02.",
       call.=FALSE)
}
message("[03] ETAPA 1/8 - Fontes e dependencias validadas")

# --------------------------------------------------------------------------
# ETAPA 2/8 - Carregar dados e validar unidades de observacao
# --------------------------------------------------------------------------
emendas <- readRDS(entrada_emendas)
painel <- readRDS(entrada_painel)
if (nrow(emendas) != 4796L || nrow(painel) != 207L) {
  stop("Universo inesperado: esperava 4.796 emendas e 207 perfis vereador-ano.",call.=FALSE)
}
validar_unico(emendas, "id_emenda", "emendas (script 03)")
validar_unico(painel, c("id_vereador_ano", "ano"), "vereador-ano (script 03)")
campos_emendas <- c("id_emenda", "ano", "id_vereador_ano", "eh_nao_saude", "macro_cap",
                   "tema_analitico", "valor_emenda_num")
campos_painel <- c("id_vereador_ano", "ano", "pessoa_chave", "sigla_partido",
                  "parlamentar_partido", "valor_nao_saude", "tem_portfolio_nao_saude",
                  "zucco_final", "bolognesi_media")
if (length(setdiff(campos_emendas,names(emendas))) ||
    length(setdiff(campos_painel,names(painel)))) {
  stop("Colunas essenciais ausentes dos RDS. Reexecute 01 e 02; confira as versoes instaladas.",
       call.=FALSE)
}
chave_base <- unique(paste(painel$ano,painel$id_vereador_ano,sep="::"))
chave_emenda <- paste(emendas$ano,emendas$id_vereador_ano,sep="::")
if (any(!(chave_emenda %in% chave_base))) {
  stop("Emendas sem correspondente vereador-ano. Exemplos: ",
       paste(head(emendas$id_emenda[!(chave_emenda %in% chave_base)],10),collapse=", "),
       call.=FALSE)
}
if (sum(painel$tem_portfolio_nao_saude,na.rm=TRUE) != 206L ||
    sum(painel$tem_portfolio_nao_saude & !is.na(painel$zucco_final)) != 173L ||
    sum(painel$tem_portfolio_nao_saude & !is.na(painel$bolognesi_media)) != 140L) {
  stop("Amostras de 01/02 divergentes dos controles aprovados: esperados 206/173/140.",call.=FALSE)
}
message("[03] ETAPA 2/8 - 4.796 emendas, 207 perfis, 206 com recursos nao-saude")

# --------------------------------------------------------------------------
# ETAPA 3/8 - Definir e validar os 17 temas analiticos
# --------------------------------------------------------------------------
temas <- c("02", "04", "05", "06", "07", "08", "09", "10", "12", "13",
           "14", "15", "17", "20", "21", "cultura", "esporte e lazer")
rotulos <- c(
  `02`="Direitos civis, politicos, liberdades e minorias",
  `04`="Agricultura, pecuaria e pesca (inclui bem-estar animal codificado)",
  `05`="Trabalho, emprego e previdencia",
  `06`="Educacao", `07`="Meio ambiente", `08`="Energia",
  `09`="Imigracao e refugiados", `10`="Transportes",
  `12`="Judiciario, justica, crimes e violencia",
  `13`="Politicas sociais", `14`="Habitacao, infraestrutura e reforma agraria",
  `15`="Sistema bancario, instituicoes financeiras e comercio interno",
  `17`="Ciencia, tecnologia e comunicacoes",
  `20`="Governo e administracao publica", `21`="Territorio e recursos naturais",
  `cultura`="Cultura (CAP 23 desmembrado)",
  `esporte e lazer`="Esporte e lazer (CAP 23 desmembrado)"
)
if (length(temas)!=17L || length(rotulos)!=17L || !identical(sort(names(rotulos)),sort(temas))) {
  stop("O mapa de temas nao contem exatamente 17 categorias distintas.",call.=FALSE)
}
nao_saude <- emendas[!is.na(emendas$eh_nao_saude) & emendas$eh_nao_saude,,drop=FALSE]
if (nrow(nao_saude)!=2491L || any(is.na(nao_saude$tema_analitico)) ||
    any(!(nao_saude$tema_analitico %in% temas))) {
  stop("Tema vazio/invalido entre as 2.491 emendas nao-saude. Veja exemplos: ",
       paste(head(nao_saude$id_emenda[is.na(nao_saude$tema_analitico) |
             !(nao_saude$tema_analitico %in% temas)],10),collapse=", "),call.=FALSE)
}
if (sum(nao_saude$tema_analitico=="cultura")!=219L ||
    sum(nao_saude$tema_analitico=="esporte e lazer")!=436L) {
  stop("A separacao de CAP 23 divergiu do esperado: 219 Cultura e 436 Esporte/Lazer.",call.=FALSE)
}
if (any(!is.na(nao_saude$valor_emenda_num) & nao_saude$valor_emenda_num < 0)) {
  stop("Valores negativos em emendas nao-saude: verificar fonte",call.=FALSE)
}
excecoes_valor <- nao_saude[is.na(nao_saude$valor_emenda_num),
                            c("id_emenda","ano","id_vereador_ano","tema_analitico"),drop=FALSE]
salvar_csv(tibble::as_tibble(excecoes_valor),"03_emendas_nao_saude_sem_valor.csv")
if (nrow(excecoes_valor)>0L) message(
  "[03] ATENCAO: ",nrow(excecoes_valor)," emenda(s) nao-saude sem valor;",
  " nao imputar zero. Registro(s) em saidas/03_emendas_nao_saude_sem_valor.csv")
message("[03] ETAPA 3/8 - 17 temas aprovados (219 Cultura; 436 Esporte/Lazer)")

# --------------------------------------------------------------------------
# ETAPA 4/8 - Valores e participacoes por vereador-ano/tema; zeros genuinos
# --------------------------------------------------------------------------
perfis <- painel[painel$tem_portfolio_nao_saude &
                 is.finite(painel$valor_nao_saude) & painel$valor_nao_saude>0,,drop=FALSE]
if(nrow(perfis)!=206L || anyDuplicated(perfis$id_vereador_ano)) {
  stop("Nao foram identificados exatamente 206 perfis nao-saude distintos.",call.=FALSE)
}
por_tema <- nao_saude |>
  dplyr::group_by(ano,id_vereador_ano,tema_analitico) |>
  dplyr::summarise(valor_tema=sum(valor_emenda_num,na.rm=TRUE),
                   n_emendas_tema=dplyr::n(),
                   n_sem_valor=sum(is.na(valor_emenda_num)),.groups="drop") |>
  dplyr::rename(tema=tema_analitico)
# A grade completa e necessaria: sem emenda para tema = zero de participacao.
# Uma emenda existente com valor ausente NA nao e confundida com ausencia
# de emenda; o campo n_sem_valor permite auditar esses casos.
grade <- tibble::tibble(
  id_vereador_ano=rep(perfis$id_vereador_ano,each=length(temas)),
  tema=rep(temas,times=nrow(perfis))
)
matriz <- grade |>
  dplyr::left_join(por_tema,by=c("id_vereador_ano","tema"))
if (any(!is.na(matriz$ano) & matriz$ano !=
        rep(perfis$ano,each=length(temas)))) {
  stop("Conflito de anos ao construir matriz vereador-tema.",call.=FALSE)
}
matriz <- matriz |>
  dplyr::mutate(
    valor_tema=dplyr::coalesce(valor_tema,0),
    n_emendas_tema=dplyr::coalesce(n_emendas_tema,0L),
    n_sem_valor=dplyr::coalesce(n_sem_valor,0L)
  ) |>
  dplyr::select(-ano) |>
  dplyr::left_join(perfis |>
      dplyr::select(id_vereador_ano,ano,pessoa_chave,parlamentar_partido,
          sigla_partido,valor_nao_saude,zucco_final,bolognesi_media),
      by="id_vereador_ano") |>
  dplyr::mutate(participacao=valor_tema/valor_nao_saude,
                nome_tema=unname(rotulos[tema]))
if (nrow(matriz)!=206L*17L || any(is.na(matriz$participacao)) ||
    any(matriz$participacao < -1e-10 | matriz$participacao > 1+1e-10)) {
  stop("Participacao invalida na matriz de temas.",call.=FALSE)
}
verificacao <- matriz |>
  dplyr::group_by(ano,id_vereador_ano,parlamentar_partido,valor_nao_saude) |>
  dplyr::summarise(valor_temas=sum(valor_tema),
                   soma_participacoes=sum(participacao),
                   emendas_sem_valor=sum(n_sem_valor), .groups="drop") |>
  dplyr::mutate(diferenca_reais=valor_temas-valor_nao_saude)
if (any(abs(verificacao$diferenca_reais)>0.02) ||
    any(abs(verificacao$soma_participacoes-1)>1e-8)) {
  stop("Soma de participacoes diferente de 100% em algum vereador-ano.",call.=FALSE)
}
message("[03] ETAPA 4/8 - Matriz 206 x 17 criada; participacoes fecham 100%")

# --------------------------------------------------------------------------
# ETAPA 5/8 - Descricao (agregados ponderados versus media de portfolios)
# --------------------------------------------------------------------------
den_ano <- perfis |>
  dplyr::group_by(ano) |>
  dplyr::summarise(denominador_ano=sum(valor_nao_saude),
                   n_perfis_ano=dplyr::n(),.groups="drop")
descritivo_ano <- matriz |>
  dplyr::group_by(ano,tema,nome_tema) |>
  dplyr::summarise(valor_tema=sum(valor_tema),
                   n_emendas=sum(n_emendas_tema),
                   media_portfolio=mean(participacao),
                   prevalencia_perfis=mean(n_emendas_tema>0),.groups="drop") |>
  dplyr::left_join(den_ano,by="ano") |>
  dplyr::mutate(percentual_monetario=100*valor_tema/denominador_ano,
                percentual_medio_vereador=100*media_portfolio,
                prevalencia_percentual=100*prevalencia_perfis)
den_total <- sum(perfis$valor_nao_saude)
descritivo_total <- matriz |>
  dplyr::group_by(tema,nome_tema) |>
  dplyr::summarise(valor_tema=sum(valor_tema),n_emendas=sum(n_emendas_tema),
                   media_portfolio=mean(participacao),
                   prevalencia_perfis=mean(n_emendas_tema>0),
                   n_perfis=dplyr::n(),.groups="drop") |>
  dplyr::mutate(valor_nao_saude_total=den_total,
                percentual_monetario=100*valor_tema/den_total,
                percentual_medio_vereador=100*media_portfolio,
                prevalencia_percentual=100*prevalencia_perfis)
if (abs(sum(descritivo_total$valor_tema)-383849795.50)>0.02 ||
    abs(sum(descritivo_total$percentual_monetario)-100)>1e-8 ||
    sum(descritivo_total$n_emendas)!=2491L ||
    abs(descritivo_total$valor_tema[descritivo_total$tema=="cultura"]-26246943)>0.02 ||
    abs(descritivo_total$valor_tema[descritivo_total$tema=="esporte e lazer"]-68337577)>0.02) {
  stop("Totais tematicos diferem dos valores-base ja validados.",call.=FALSE)
}
message("[03] ETAPA 5/8 - Descritivas por ano e periodo, ponderacoes distintas verificadas")

# --------------------------------------------------------------------------
# ETAPA 6/8 - Regressao linear para cada tema/escala com CR2 e Satterthwaite
# --------------------------------------------------------------------------
# O coeficiente beta representa diferenca de PARTICIPACAO (0 a 1) por 1 ponto
# de ideologia (escala -1 a +1). Negativo: maior participacao a esquerda.
# Isso e diferente dos modelos piecewise para o estilo de vereanca (script 08).
estimar_tema <- function(t, escala, nome_escala) {
  z <- matriz[matriz$tema==t & !is.na(matriz[[escala]]),,drop=FALSE]
  z$ideologia <- z[[escala]]
  z <- z[is.finite(z$ideologia) & is.finite(z$participacao) &
           !is.na(z$pessoa_chave),,drop=FALSE]
  n <- nrow(z)
  np <- dplyr::n_distinct(z$pessoa_chave)
  if (n<10L || np<8L || stats::sd(z$ideologia)==0) stop(
    "Amostra/modelo insuficiente em tema ",t, " escala ",nome_escala,
    "; n=",n,"; vereadores=",np,call.=FALSE)
  ajuste <- stats::lm(participacao ~ ideologia + factor(ano),data=z)
  if(stats::nobs(ajuste)!=n || is.na(stats::coef(ajuste)[["ideologia"]])) stop(
    "Amostra mudou/coeficiente aliased no ajuste de ",t,"/",nome_escala,call.=FALSE)
  vcr <- clubSandwich::vcovCR(ajuste,cluster=z$pessoa_chave,type="CR2")
  tab <- as.data.frame(clubSandwich::coef_test(ajuste,vcov=vcr,test="Satterthwaite"))
  indices <- which(rownames(tab)=="ideologia")
  if(length(indices)!=1L && "Coef" %in% names(tab))
    indices <- which(as.character(tab$Coef)=="ideologia")
  if (length(indices)!=1L) stop(
    "Nao identifiquei a linha 'ideologia' na saida coef_test (tema ",t,
    "). Colunas presentes: ",paste(names(tab),collapse=", "),call.=FALSE)
  col_p <- if ("p_Satt" %in% names(tab)) "p_Satt" else "p_Satt"
  requeridas <- c("beta","SE","df_Satt",col_p)
  if(length(setdiff(requeridas,names(tab)))>0L) stop(
     "O formato retornado por clubSandwich mudou: ",paste(names(tab),collapse=", "),
     ". Envie essa mensagem antes de alterar o script.",call.=FALSE)
  b <- as.numeric(tab$beta[indices])
  se <- as.numeric(tab$SE[indices])
  df <- as.numeric(tab$df_Satt[indices])
  p <- as.numeric(tab[[col_p]][indices])
  if(!is.finite(b) || !is.finite(se) || !is.finite(df) || df<=0 ||
     !is.finite(p)) stop("CR2/Satterthwaite retornou estimativas invalidas em ",
                        t,"/",nome_escala,call.=FALSE)
  erro_ic <- stats::qt(0.975,df=df)*se
  tabela <- tibble::tibble(
    tema=t, nome_tema=unname(rotulos[t]), escala=nome_escala,
    n_observacoes=n, n_vereadores=np, n_anos=dplyr::n_distinct(z$ano),
    beta=b, erro_padrao_CR2=se, df_Satterthwaite=df,
    estatistica_t=b/se, p_CR2_Satterthwaite=p,
    IC95_inferior=b-erro_ic, IC95_superior=b+erro_ic,
    efeito_05_ponto_pp=b*50, IC95_05_inferior_pp=(b-erro_ic)*50,
    IC95_05_superior_pp=(b+erro_ic)*50
  )
  list(resumo=tabela,modelo=ajuste,amostra=z[,c("ano","id_vereador_ano",
                                                "pessoa_chave","participacao","ideologia")])
}
modelos <- list()
linhas <- list()
k <- 0L
for (escala in c("zucco_final","bolognesi_media")) {
  titulo <- if(escala=="zucco_final") "Zucco-Power (2021/2017)" else "Bolognesi (media)"
  for (t in temas) {
    k <- k+1L
    chave <- paste(escala,gsub(" ","_",t),sep="__")
    resultado <- tryCatch(estimar_tema(t,escala,titulo),error=function(e) {
      stop("Falha na regressao ",titulo," / ",t,": ",conditionMessage(e),call.=FALSE)
    })
    linhas[[k]] <- resultado$resumo
    modelos[[chave]] <- resultado$modelo
  }
}
regressoes <- dplyr::bind_rows(linhas)
if(nrow(regressoes)!=34L) stop("Esperava 17 x 2 = 34 regressoes",call.=FALSE)
message("[03] ETAPA 6/8 - 34 modelos com efeitos fixos de ano e erros CR2 estimados")

# --------------------------------------------------------------------------
# ETAPA 7/8 - Checagens de amostras, p, sinais e testes multiplos exploratorios
# --------------------------------------------------------------------------
verificar_zucco <- regressoes[regressoes$escala=="Zucco-Power (2021/2017)",,drop=FALSE]
verificar_bolog <- regressoes[regressoes$escala=="Bolognesi (media)",,drop=FALSE]
if(any(verificar_zucco$n_observacoes!=173L) ||
   any(verificar_bolog$n_observacoes!=140L) ||
   any(verificar_zucco$n_vereadores!=64L) ||
   any(verificar_bolog$n_vereadores!=56L)) {
  stop("Amostras dos 34 modelos diferem de 173/64 para Zucco e 140/56 para Bolognesi.",
       call.=FALSE)
}
regressoes <- regressoes |>
  dplyr::group_by(escala) |>
  dplyr::mutate(p_BH_FDR=stats::p.adjust(p_CR2_Satterthwaite,method="BH")) |>
  dplyr::ungroup() |>
  dplyr::mutate(direcao=ifelse(beta<0,"esquerda",ifelse(beta>0,"direita","nula")),
                significativo_05=p_CR2_Satterthwaite<0.05,
                significativo_FDR_05=p_BH_FDR<0.05)
# Importante: 34 testes; FDR e apresentado como sensibilidade, nao substitui
# a interpretacao original e nao estabelece relacao causal.
message("[03] ETAPA 7/8 - Amostras 173/64 e 140/56; IC95 e FDR auditados")

# --------------------------------------------------------------------------
# ETAPA 8/8 - Saidas completas e mensagem de resumo
# --------------------------------------------------------------------------
salvar_csv(matriz |>
   dplyr::select(ano,id_vereador_ano,parlamentar_partido,sigla_partido,
         pessoa_chave,tema,nome_tema,n_emendas_tema,n_sem_valor,valor_tema,
         valor_nao_saude,participacao,zucco_final,bolognesi_media),
   "03_matriz_vereador_ano_17_temas.csv")
salvar_csv(descritivo_ano,"03_descritivo_temas_por_ano.csv")
salvar_csv(descritivo_total,"03_descritivo_temas_total.csv")
salvar_csv(verificacao,"03_verificacao_somas_por_vereador_ano.csv")
salvar_csv(regressoes,"03_regressoes_tematicas_CR2.csv")
salvar_csv(regressoes |>
 dplyr::select(tema,nome_tema,escala,n_observacoes,n_vereadores,
               beta,p_CR2_Satterthwaite,IC95_inferior,IC95_superior,
               p_BH_FDR,significativo_05,significativo_FDR_05),
 "03_tabela_secao_4_1.csv")
saveRDS(modelos,file.path(TCC_SAIDAS,"03_objetos_modelos_tematicos.rds"),compress="xz")
saveRDS(matriz,file.path(TCC_SAIDAS,"03_painel_longo_17_temas.rds"),compress="xz")
metadados <- tibble::tibble(
  parametro=c("metodo","variavel_resposta","ideologia","efeitos_fixos",
              "variancia","cluster","teste","temas","n_portfolios_descritivos",
              "n_modelos","diretorio_fontes_emendas","diretorio_fontes_partidos"),
  valor=c("regressao linear por tema","participacao monetaria no portfolio nao-saude",
          "Zucco combinado e Bolognesi media","ano","CR2","vereador longitudinal",
          "Satterthwaite","17 (CAP 23 desmembrado)","206","34",TCC_CODING,
          TCC_PARTIDOS_PASTA)
)
salvar_csv(metadados,"03_metadados_modelos.csv")
message("[03] ETAPA 8/8 - Concluido. Arquivos salvos em ",TCC_SAIDAS)
message("[03] FINALIZADO: 17 temas, 206 portfolios, 34 regressoes CR2.")
print(descritivo_total |>
  dplyr::select(tema,n_emendas,percentual_monetario,percentual_medio_vereador))
print(regressoes |>
  dplyr::select(tema,escala,beta,p_CR2_Satterthwaite,p_BH_FDR) |>
  dplyr::arrange(escala,tema),n=34)
