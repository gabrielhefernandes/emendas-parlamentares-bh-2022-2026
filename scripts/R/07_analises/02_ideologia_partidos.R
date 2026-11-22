# ===========================================================================
# 02_ideologia_partidos.R  |  6 ETAPAS
# TCC BH: coberturas Zucco-Power 2021/2017 e Bolognesi (media/mediana).
# Pre-requisito: executar 01_preparar.bases.R com sucesso.
# Executar: source("scripts/R/07_analises/02_ideologia_partidos.R", encoding="UTF-8")
# NUNCA modifica as planilhas originais.
# ===========================================================================
source(file.path(Sys.getenv("TCC_BH_RAIZ", unset=getwd()),
  "scripts", "R", "01_importacao_padronizacao", "_config_funcoes.R"), encoding="UTF-8")

# ETAPA 1/6: dependencias e dados validados pela etapa 01
verificar_pacotes(c("dplyr","readr","tibble"))
preparar_saida()
validar_manifesto_preparo()
origem <- file.path(TCC_SAIDAS,"01_painel_base_vereador_ano.rds")
if (!file.exists(origem)) stop("Execute PRIMEIRO 01_preparar.bases.R",call.=FALSE)
painel <- readRDS(origem)
if(nrow(painel)!=207) stop("Painel nao contem os 207 perfis esperados",call.=FALSE)
message("[02] ETAPA 1/6 - Painel anual carregado")

# ETAPA 2/6: identidade individual longitudinal e verificacao dos dados de partido
painel$pessoa_chave <- chave_nome(painel$parlamentar_partido)
if(any(painel$pessoa_chave=="")) stop("Nomes sem identificador longitudinal",call.=FALSE)
validar_unico(painel,"id_vereador_ano","partido-ano")
if(length(unique(painel$pessoa_chave))!=71L) stop(
 "Contagem inesperada de vereadores distintos; conferir apelidos e nomes.",call.=FALSE)
message("[02] ETAPA 2/6 - 71 vereadores distintos identificados por nome normalizado")

# ETAPA 3/6: Zucco-Power 2021 como principal; 2017 apenas onde falta 2021
painel$zucco_final <- dplyr::coalesce(painel$zucco_2021,painel$zucco_2017)
painel$zucco_origem <- dplyr::case_when(
 !is.na(painel$zucco_2021) ~ "2021",
 is.na(painel$zucco_2021) & !is.na(painel$zucco_2017) ~ "2017_supletivo",
 TRUE ~ "sem_estimativa"
)
# Nao considerar a aproximacao do Uniao Brasil observacao direta de 2021.
painel$uniao_aproximado <- grepl("^UNI",toupper(iconv(painel$sigla_partido,
                               from="",to="ASCII//TRANSLIT"))) &
                           !is.na(painel$zucco_final)
message("[02] ETAPA 3/6 - Zucco combinado com precedencia 2021 definida")

# ETAPA 4/6: Bolognesi media e mediana na escala -1 a +1
painel$bolognesi_media <- (painel$bolognesi_media_original - 5) / 5
painel$bolognesi_mediana <- (painel$bolognesi_mediana_original - 5) / 5
for(nm in c("zucco_final","bolognesi_media","bolognesi_mediana")) {
 x <- painel[[nm]]
 if(any(!is.na(x) & abs(x)>1.000001)) stop("Escala fora de [-1,1]: ",nm,call.=FALSE)
}
painel$tem_zucco <- !is.na(painel$zucco_final)
painel$tem_bolognesi <- !is.na(painel$bolognesi_media)
painel$tem_ambas <- painel$tem_zucco & painel$tem_bolognesi
message("[02] ETAPA 4/6 - Escalas verificadas")

# ETAPA 5/6: contagens por observacao/vereador e amostra efetiva nao saude
cobertura <- tibble::tibble(
 escala=c("Zucco 2021 (inclui aproximacao Uniao)","Zucco 2017 supletivo",
          "Zucco combinado","Bolognesi media","Ambas as escalas",
          "Sem Zucco em ao menos um ano"),
 observacoes=c(sum(painel$zucco_origem=="2021"),
  sum(painel$zucco_origem=="2017_supletivo"),
  sum(painel$tem_zucco),sum(painel$tem_bolognesi),
  sum(painel$tem_ambas),sum(!painel$tem_zucco)),
 vereadores_distintos=c(
  dplyr::n_distinct(painel$pessoa_chave[painel$zucco_origem=="2021"]),
  dplyr::n_distinct(painel$pessoa_chave[painel$zucco_origem=="2017_supletivo"]),
  dplyr::n_distinct(painel$pessoa_chave[painel$tem_zucco]),
  dplyr::n_distinct(painel$pessoa_chave[painel$tem_bolognesi]),
  dplyr::n_distinct(painel$pessoa_chave[painel$tem_ambas]),
  dplyr::n_distinct(painel$pessoa_chave[!painel$tem_zucco]))
)
por_ano <- painel |>
 dplyr::group_by(ano) |>
 dplyr::summarise(perfis=dplyr::n(),com_zucco=sum(tem_zucco),
  com_bolognesi=sum(tem_bolognesi),com_ambas=sum(tem_ambas),
  perfis_nao_saude=sum(tem_portfolio_nao_saude),
  zucco_nao_saude=sum(tem_zucco & tem_portfolio_nao_saude),
  bolognesi_nao_saude=sum(tem_bolognesi & tem_portfolio_nao_saude),
  .groups="drop")
amostra <- tibble::tibble(
 medida=c("Zucco disponivel: todos os perfis", "Zucco em perfis nao-saude",
          "Bolognesi disponivel: todos os perfis", "Bolognesi em perfis nao-saude"),
 n_observacoes=c(sum(painel$tem_zucco),
     sum(painel$tem_zucco & painel$tem_portfolio_nao_saude),
     sum(painel$tem_bolognesi),
     sum(painel$tem_bolognesi & painel$tem_portfolio_nao_saude)),
 n_vereadores=c(
     dplyr::n_distinct(painel$pessoa_chave[painel$tem_zucco]),
     dplyr::n_distinct(painel$pessoa_chave[painel$tem_zucco & painel$tem_portfolio_nao_saude]),
     dplyr::n_distinct(painel$pessoa_chave[painel$tem_bolognesi]),
     dplyr::n_distinct(painel$pessoa_chave[painel$tem_bolognesi & painel$tem_portfolio_nao_saude]))
)
if (sum(painel$tem_zucco)!=174L || sum(painel$tem_bolognesi)!=140L ||
    sum(painel$tem_ambas)!=112L ||
    sum(painel$tem_zucco & painel$tem_portfolio_nao_saude)!=173L) stop(
  "Coberturas diferentes das conferidas; nao use o resultado sem auditar.",call.=FALSE)
message("[02] ETAPA 5/6 - Coberturas, intersecoes e amostras calculadas")

# ETAPA 6/6: salvar tabelas e dados para os proximos scripts
salvar_csv(cobertura,"02_cobertura_ideologica.csv")
salvar_csv(por_ano,"02_cobertura_por_ano.csv")
salvar_csv(amostra,"02_amostras_analiticas.csv")
salvar_csv(painel |>
 dplyr::select(ano,id_vereador_ano,parlamentar_partido,sigla_partido,
    zucco_2021,zucco_2017,zucco_final,zucco_origem,uniao_aproximado,
    bolognesi_media_original,bolognesi_media,bolognesi_mediana,
    tem_portfolio_nao_saude,participacao_geo),
 "02_ideologias_por_vereador_ano.csv")
salvar_csv(painel |> dplyr::filter(!tem_zucco),"02_perfis_sem_zucco.csv")
saveRDS(painel,file.path(TCC_SAIDAS,"02_painel_com_ideologia.rds"),compress="xz")
message("[02] ETAPA 6/6 - Concluido. Saidas: ",TCC_SAIDAS)
print(cobertura)
print(amostra)
