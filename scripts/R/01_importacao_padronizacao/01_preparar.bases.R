# ===========================================================================
# 01_preparar.bases.R  |  8 ETAPAS
# TCC BH 2022-2026: integrar emendas e filiacoes e criar painel vereador-ano.
# Executar: source("scripts/R/01_importacao_padronizacao/01_preparar.bases.R", encoding="UTF-8")
# ENTRADAS: xlsx das cinco bases mais recentes, data_raw/BASE PARTIDOS GERAL.xlsx
# SAIDAS: somente em R/scripts_refazer/saidas; NUNCA modifica as fontes.
# ===========================================================================
source(file.path(Sys.getenv("TCC_BH_RAIZ", unset=getwd()),
  "scripts", "R", "01_importacao_padronizacao", "_config_funcoes.R"), encoding="UTF-8")

# ETAPA 1/8: ambiente, diretorios e pacotes
verificar_pacotes(c("readxl", "readr", "dplyr", "stringr", "tibble"))
preparar_saida()
message("[01] ETAPA 1/8 - Dependencias e pastas OK")

# ETAPA 2/8: abrir cinco fontes APENAS de coding e partidos APENAS de data_raw
arquivos_emendas <- vapply(TCC_ENTRADAS_ESPERADAS, localizar_arquivo, character(1))
arquivo_partidos <- localizar_arquivo(TCC_PARTIDOS_ARQUIVO)
fontes <- c(arquivos_emendas, partidos=arquivo_partidos)
manifesto <- tibble::tibble(
  grupo=names(fontes), arquivo=basename(fontes), caminho=unname(fontes),
  bytes=as.numeric(file.info(fontes)$size),
  alterado_em=as.character(file.info(fontes)$mtime)
)
salvar_csv(manifesto, "01_manifesto_fontes.csv")
message("[01] ETAPA 2/8 - Seis arquivos localizados sem busca recursiva")
message("[01] Fontes anuais: ", normalizePath(TCC_CODING, winslash="/"))
message("[01] Base de partidos: ", arquivo_partidos)

# ETAPA 3/8: ler as cinco planilhas, com campos da propria base preservados
ler_ano <- function(ano, arquivo) {
  sheet <- "EMENDAS_CODIFICACAO"
  abas <- readxl::excel_sheets(arquivo)
  if (!(sheet %in% abas)) stop("Aba ausente em ", basename(arquivo), call.=FALSE)
  x <- as.data.frame(readxl::read_excel(
    arquivo, sheet=sheet, col_types="text", .name_repair="unique"
  ), stringsAsFactors=FALSE)
  names(x) <- limpar_cabecalho(names(x))
  obrigatorias <- c("id_emenda", "ano", "parlamentar_original", "valor_emenda",
                   "subcodigo_cap_final", "georreferenciavel",
                   "publico_alvo_final", "publico_alvo_resumo", "cultura_ou_esporte")
  ausentes <- setdiff(obrigatorias, names(x))
  if (length(ausentes)) stop("Campos ausentes em ", ano, ": ",
                             paste(ausentes, collapse=", "), call.=FALSE)
  x <- x[!is.na(x$id_emenda) & trimws(x$id_emenda)!="",,drop=FALSE]
  x$id_emenda <- padronizar_texto(x$id_emenda)
  x$ano <- suppressWarnings(as.integer(x$ano))
  if (any(is.na(x$ano) | x$ano!=ano)) stop("Ano inconsistente: ", ano, call.=FALSE)
  if (!"id_vereador_ano" %in% names(x)) x$id_vereador_ano <- NA_character_
  x$fonte_arquivo <- basename(arquivo)
  x$fonte_aba <- sheet
  x
}
base_list <- lapply(names(arquivos_emendas), function(ano)
  ler_ano(as.integer(ano), arquivos_emendas[[ano]]))
names(base_list) <- names(arquivos_emendas)
contagens_fonte <- vapply(base_list, nrow, integer(1))
if (!identical(as.integer(contagens_fonte), as.integer(TCC_ESPERADO_N_ANO))) stop(
  "As quantidades por ano diferem das fontes conferidas: ",
  paste(names(contagens_fonte), contagens_fonte, collapse="; "), call.=FALSE
)
emendas <- dplyr::bind_rows(base_list)
validar_unico(emendas, "id_emenda", "emendas")
message("[01] ETAPA 3/8 - 4.796 IDs de emenda carregados, sem duplicacao")

# ETAPA 4/8: ler partidos; vincular prioritariamente por id_vereador_ano e,
# em 2025 (sem esse campo na planilha), por ano + nome normalizado.
partidos <- as.data.frame(readxl::read_excel(
  arquivo_partidos, sheet="Planilha1", col_types="text", .name_repair="unique"
), stringsAsFactors=FALSE)
names(partidos) <- limpar_cabecalho(names(partidos))
campos_partido <- c("ano", "id_vereador_ano", "parlamentar_original", "Sigla",
  "Estimativa ZUCCO POWER 2021", "Estimativa ZUCCO POWER 2017",
  "Estimativa Bolognesi Media", "Estimativa Bolognesi Mediana")
if (length(setdiff(campos_partido,names(partidos)))) stop(
  "Colunas ausentes na planilha de partidos: ",
  paste(setdiff(campos_partido,names(partidos)), collapse=", "), call.=FALSE)
partidos$ano <- as.integer(partidos$ano)
partidos <- partidos[!is.na(partidos$ano) & !is.na(partidos$id_vereador_ano),,drop=FALSE]
partidos$nome_chave <- chave_nome(partidos$parlamentar_original)
validar_unico(partidos, c("id_vereador_ano"), "partidos por ID")
validar_unico(partidos, c("ano", "nome_chave"), "partidos por ano-nome")

# Auditoria de conversoes de sinais Unicode: preserva o valor original
# na planilha Excel; apenas a copia em memoria sera convertida para numero.
colunas_ideologicas <- c(
  "Estimativa ZUCCO POWER 2021", "Estimativa ZUCCO POWER 2017",
  "Estimativa Bolognesi Media", "Estimativa Bolognesi Mediana"
)
normalizacoes <- lapply(colunas_ideologicas, function(campo) {
  bruto <- padronizar_texto(partidos[[campo]])
  normalizado <- normalizar_sinal_numerico(bruto)
  indices <- which(!is.na(bruto) & bruto != normalizado)
  if (length(indices)==0L) return(NULL)
  tibble::tibble(
    indice_partidos=indices,
    id_vereador_ano=partidos$id_vereador_ano[indices],
    parlamentar=partidos$parlamentar_original[indices],
    campo=campo,
    valor_original=bruto[indices],
    valor_normalizado=normalizado[indices]
  )
})
normalizacoes <- dplyr::bind_rows(normalizacoes)
if (nrow(normalizacoes)==0L) normalizacoes <- tibble::tibble(
  indice_partidos=integer(), id_vereador_ano=character(),
  parlamentar=character(), campo=character(),
  valor_original=character(), valor_normalizado=character()
)
salvar_csv(normalizacoes, "01_normalizacoes_sinais_partidos.csv")
if (nrow(normalizacoes)>0L) {
  message("[01] ETAPA 4/8 - ",nrow(normalizacoes),
          " sinal(is) negativo(s) Unicode normalizado(s); veja ",
          "saidas/01_normalizacoes_sinais_partidos.csv")
}

# Observacoes de partido sao preservadas mesmo se nao houver emendas nao-saude.
partidos_base <- tibble::tibble(
  ano=partidos$ano, id_vereador_ano=partidos$id_vereador_ano,
  parlamentar_partido=partidos$parlamentar_original,
  sigla_partido=partidos$Sigla,
  nome_chave=partidos$nome_chave,
  zucco_2021=converter_valor(partidos[["Estimativa ZUCCO POWER 2021"]],"Zucco 2021"),
  zucco_2017=converter_valor(partidos[["Estimativa ZUCCO POWER 2017"]],"Zucco 2017"),
  bolognesi_media_original=converter_valor(partidos[["Estimativa Bolognesi Media"]],"Bolognesi media"),
  bolognesi_mediana_original=converter_valor(partidos[["Estimativa Bolognesi Mediana"]],"Bolognesi mediana")
)

emendas$nome_chave <- chave_nome(emendas$parlamentar_original)
chaves_id <- partidos_base[,c("id_vereador_ano","ano","sigla_partido")]
names(chaves_id) <- c("id_vereador_ano","ano","sigla_via_id")
emendas <- dplyr::left_join(emendas, chaves_id,
  by=c("id_vereador_ano","ano"))
chaves_nome <- partidos_base[,c("ano","nome_chave","id_vereador_ano","sigla_partido")]
names(chaves_nome) <- c("ano","nome_chave","id_via_nome","sigla_via_nome")
emendas <- dplyr::left_join(emendas, chaves_nome,
  by=c("ano","nome_chave"))

incongruencia <- !is.na(emendas$id_vereador_ano) & !is.na(emendas$id_via_nome) &
  emendas$id_vereador_ano != emendas$id_via_nome
if (any(incongruencia)) stop("ID e nome divergem em ", sum(incongruencia),
  " emendas. Exemplo: ", paste(head(emendas$id_emenda[incongruencia],8),collapse=", "),
  call.=FALSE)
emendas$id_vereador_ano <- dplyr::coalesce(emendas$id_vereador_ano,
                                            emendas$id_via_nome)
emendas$sigla_partido <- dplyr::coalesce(emendas$sigla_via_id,
                                         emendas$sigla_via_nome)
sem_partido <- is.na(emendas$id_vereador_ano) | is.na(emendas$sigla_partido)
if (any(sem_partido)) stop("Emendas sem partido/ID: ",
  paste(head(emendas$id_emenda[sem_partido],20),collapse=", "), call.=FALSE)
emendas <- dplyr::select(emendas,-dplyr::any_of(c(
 "sigla_via_id","sigla_via_nome","id_via_nome")))
message("[01] ETAPA 4/8 - Filiacoes vinculadas; 2025 reconciliado por ano+nome")

# ETAPA 5/8: tipar campos e aplicar CAP; preservar cultura vs esporte e lazer
emendas$valor_emenda_num <- converter_valor(emendas$valor_emenda,"valor_emenda")
emendas$cap_final <- normalizar_cap(emendas$subcodigo_cap_final)
emendas$macro_cap <- ifelse(is.na(emendas$cap_final), NA_character_,
                              substr(emendas$cap_final,1,2))
emendas$tem_cap <- !is.na(emendas$cap_final)
emendas$eh_saude_cap <- emendas$tem_cap & emendas$macro_cap=="03"
emendas$eh_nao_saude <- emendas$tem_cap & emendas$macro_cap!="03"
emendas$geo_bin <- numero_binario(emendas$georreferenciavel,"georreferenciavel")
emendas$publico_bin <- numero_binario(emendas$publico_alvo_final,"publico_alvo_final")
rotulo <- tolower(trimws(as.character(emendas$cultura_ou_esporte)))
rotulo <- iconv(rotulo,from="",to="ASCII//TRANSLIT")
rotulo[is.na(rotulo) | rotulo==""] <- NA_character_
rotulo[rotulo %in% c("esportes e lazer","esporte/lazer")] <- "esporte e lazer"
emendas$tema_23 <- rotulo
existe_cap23 <- emendas$macro_cap=="23" & !is.na(emendas$macro_cap)
rotulo_invalido <- (!is.na(rotulo) & !(rotulo %in% c("cultura","esporte e lazer"))) |
  (existe_cap23 & is.na(rotulo)) | (!existe_cap23 & !is.na(rotulo))
if (any(rotulo_invalido)) stop("Problema na separacao cultura/esporte: ",
  paste(head(emendas$id_emenda[rotulo_invalido],15),collapse=", "), call.=FALSE)
emendas$tema_analitico <- ifelse(existe_cap23, emendas$tema_23, emendas$macro_cap)
message("[01] ETAPA 5/8 - CAP, saude, GEO e cultura/esporte validados")

# ETAPA 6/8: gerar portfólios anuais sem atribuir NA monetario a zero sem registro
somas <- emendas |>
  dplyr::group_by(id_vereador_ano,ano) |>
  dplyr::summarise(
    n_emendas=dplyr::n(), n_cap=sum(tem_cap), n_nao_saude=sum(eh_nao_saude),
    n_valor_ausente=sum(is.na(valor_emenda_num)),
    n_valor_nao_saude_ausente=sum(eh_nao_saude & is.na(valor_emenda_num)),
    valor_total=sum(valor_emenda_num,na.rm=TRUE),
    valor_nao_saude=sum(valor_emenda_num[eh_nao_saude],na.rm=TRUE),
    valor_geo_nao_saude=sum(valor_emenda_num[eh_nao_saude & geo_bin==1L],na.rm=TRUE),
    .groups="drop")
painel <- dplyr::left_join(partidos_base,somas,by=c("id_vereador_ano","ano"))
if(any(is.na(painel$n_emendas))) stop("Partido-ano sem emendas: revisar painel",call.=FALSE)
painel$participacao_geo <- ifelse(painel$valor_nao_saude>0,
                                  painel$valor_geo_nao_saude/painel$valor_nao_saude,NA_real_)
painel$tem_portfolio_nao_saude <- painel$valor_nao_saude>0
validar_unico(painel,c("id_vereador_ano"),"painel anual")
message("[01] ETAPA 6/8 - Painel com denominadores anuais construido")

# ETAPA 7/8: invariantes das cinco fontes e relatorio de excecoes
resumo <- emendas |>
 dplyr::group_by(ano) |>
 dplyr::summarise(n_emendas=dplyr::n(),n_cap=sum(tem_cap),
   n_sem_cap=sum(!tem_cap),n_nao_saude=sum(eh_nao_saude),
   valor_total=sum(valor_emenda_num,na.rm=TRUE),
   valor_nao_saude=sum(valor_emenda_num[eh_nao_saude],na.rm=TRUE),
   n_cultura=sum(tema_23=="cultura",na.rm=TRUE),
   n_esporte=sum(tema_23=="esporte e lazer",na.rm=TRUE),
   n_valor_ausente=sum(is.na(valor_emenda_num)), .groups="drop")
controle <- c(n_emendas=sum(resumo$n_emendas),n_cap=sum(resumo$n_cap),
 n_nao_saude=sum(resumo$n_nao_saude),n_portfolios=nrow(painel),
 n_portfolios_nao_saude=sum(painel$tem_portfolio_nao_saude))
esperado <- c(n_emendas=4796,n_cap=4553,n_nao_saude=2491,
              n_portfolios=207,n_portfolios_nao_saude=206)
if (!identical(as.numeric(controle),as.numeric(esperado))) stop(
 "Controles nao bateram! Encontrado: ",paste(names(controle),controle,collapse="; "),
 " | esperado: ",paste(names(esperado),esperado,collapse="; "),call.=FALSE)
valor_total_esperado <- 781159690.79
valor_nao_saude_esperado <- 383849795.50
if(abs(sum(resumo$valor_total)-valor_total_esperado)>0.02 |
   abs(sum(resumo$valor_nao_saude)-valor_nao_saude_esperado)>0.02) stop(
  "Somas monetarias diferem do universo auditado. Nao prosseguir sem conferir.",
  call.=FALSE)
excecoes <- emendas |>
 dplyr::filter(is.na(valor_emenda_num) | (eh_nao_saude & is.na(geo_bin))) |>
 dplyr::select(id_emenda,ano,id_vereador_ano,parlamentar_original,
   valor_emenda,cap_final,georreferenciavel,fonte_arquivo)
salvar_csv(resumo,"01_resumo_anual.csv")
salvar_csv(excecoes,"01_excecoes_para_revisar.csv")
message("[01] ETAPA 7/8 - Controle de totais, CAP, IDs e fontes aprovado")

# ETAPA 8/8: exportacoes em formatos R e CSV sem tocar os xlsx
saveRDS(emendas,file.path(TCC_SAIDAS,"01_emendas_integradas.rds"),compress="xz")
saveRDS(painel,file.path(TCC_SAIDAS,"01_painel_base_vereador_ano.rds"),compress="xz")
saveRDS(partidos_base,file.path(TCC_SAIDAS,"01_partidos_base.rds"),compress="xz")
salvar_csv(painel,"01_painel_base_vereador_ano.csv")
salvar_csv(tibble::as_tibble(emendas[,c("id_emenda","ano","id_vereador_ano",
  "sigla_partido","valor_emenda_num","cap_final","macro_cap",
  "tema_analitico","eh_nao_saude","geo_bin","publico_bin")]),
  "01_emendas_analiticas_resumo.csv")
message("[01] ETAPA 8/8 - ARQUIVOS GERADOS EM ",TCC_SAIDAS)
message("[01] FINALIZADO. 4796 emendas; 4553 CAP; 2491 nao-saude; 207 perfis.")
print(resumo)
