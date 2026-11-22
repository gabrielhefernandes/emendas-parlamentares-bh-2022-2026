# ================================================================
# 10 — Decomposicao substantiva do COD 12; BH, emendas 2022–2026
# 
# UNIDADES: 108 emendas COD12; 206 perfis vereador-ano.
# Fonte: resultados ja auditados do script 06. Sem modificar bases.
# Classificacao por id_emenda em arquivo manual separado e editavel.
# ================================================================
options(scipen = 999)
for (p in c('readr', 'dplyr', 'tidyr')) {
  if (!requireNamespace(p, quietly = TRUE)) stop('Instale o pacote R: ', p)
}
# requireNamespace() verifica instalacao mas nao habilita o operador %>%.
# dplyr reexporta o pipe, usado em toda a etapa de agregacao.
library(dplyr)
source(file.path(Sys.getenv("TCC_BH_RAIZ", unset=getwd()),
  "scripts", "R", "01_importacao_padronizacao", "_config_funcoes.R"), encoding="UTF-8")
raiz <- TCC_SCRIPTS
dir_saida <- TCC_SAIDAS
arquivo_emendas <- file.path(dir_saida, '06_sinais_emendas_kuschnir.csv')
arquivo_perfis <- file.path(dir_saida, '06_perfis_dimensoes_vereador_ano.csv')
arquivo_mapa <- file.path(raiz, 'insumos', 'COD12_mapa_manual_108.csv')
arquivo_decisoes <- file.path(raiz, 'insumos', 'COD12_decisoes_manuais_17_aprovadas.csv')
for (p in c(arquivo_emendas, arquivo_perfis, arquivo_mapa, arquivo_decisoes)) {
  if (!file.exists(p)) stop('Fonte ausente: ', p)
}
ler_texto <- function(p) readr::read_csv(p,
  col_types = readr::cols(.default = readr::col_character()),
  show_col_types = FALSE)
salvar <- function(d, nome) {
  readr::write_csv(d, file.path(dir_saida, nome), na = '')
}
msg <- function(s) message('[10 COD12] ', s)

emendas <- ler_texto(arquivo_emendas)
perfis <- ler_texto(arquivo_perfis)
mapa <- ler_texto(arquivo_mapa)
decisoes <- ler_texto(arquivo_decisoes)
if (nrow(emendas) != 2491L || nrow(perfis) != 206L)
  stop('Universos do script 06 divergem dos validados (2491 / 206).')
if (anyDuplicated(emendas$id_emenda) || anyDuplicated(perfis$id_vereador_ano))
  stop('Duplicacao de identificadores nas fontes 06.')
if (anyDuplicated(mapa$id_emenda)) stop('IDs repetidos no mapa manual.')
mapa <- mapa %>%
 dplyr::select(id_emenda, categoria_codigo, revisao_recomendada, nota_auditoria)
# Preservar a rastreabilidade das 17 decisoes explicitas do pesquisador.
if (nrow(decisoes) != 17L || anyDuplicated(decisoes$id_emenda) ||
    any(!decisoes$categoria_aprovada %in% c('V', 'I', 'D', 'O')))
  stop('Arquivo de decisoes: esperadas 17 decisoes unicas com classes V/I/D/O.')
conferencia_decisoes <- decisoes %>%
  dplyr::left_join(mapa, by = 'id_emenda')
if (nrow(conferencia_decisoes) != 17L ||
    any(is.na(conferencia_decisoes$categoria_codigo)) ||
    any(conferencia_decisoes$categoria_aprovada != conferencia_decisoes$categoria_codigo) ||
    any(conferencia_decisoes$revisao_recomendada != 'NAO'))
  stop('O mapa manual e as decisoes do pesquisador divergem. Verifique os dois CSVs.')
if (any(mapa$revisao_recomendada == 'SIM'))
  stop('Existem decisoes ainda marcadas como pendentes: conferir mapa manual.')
salvar(decisoes, '10_cod12_decisoes_manuais_aprovadas.csv')
if (any(!mapa$categoria_codigo %in% c('V', 'I', 'D', 'O')))
  stop('Categoria invalida no mapa: use somente V, I, D ou O.')

cod12 <- emendas %>%
 dplyr::filter(grepl('^12', subcodigo_cap_final)) %>%
 dplyr::mutate(valor_emenda = as.numeric(valor_emenda))
if (nrow(cod12) != 108L || any(is.na(cod12$valor_emenda)) ||
    abs(sum(cod12$valor_emenda) - 23990135) > 0.01)
 stop('Universo COD12 mudou: conferir CAP, emendas e montantes.')
if (!setequal(cod12$id_emenda, mapa$id_emenda))
 stop('Mapa incompleto ou com emendas extras: revisar IDs manualmente.')
cod12 <- cod12 %>% dplyr::left_join(mapa, by = 'id_emenda')
if (any(is.na(cod12$categoria_codigo)) || nrow(cod12) != 108L)
 stop('Falha na aplicacao integral do mapa manual.')
msg('108 emendas, R$ 23.990.135; mapa de 4 classes aplicado sem duplicatas')

nomes <- c(V = 'Videomonitoramento', I = 'Seguranca institucional',
           D = 'Violencia contra mulheres, violencia de genero e violencia domestica/familiar',
           O = 'Outros / nao identificavel')
cod12 <- cod12 %>% dplyr::mutate(
 categoria = unname(nomes[categoria_codigo]))
salvar(cod12 %>% dplyr::select(ano, id_emenda, id_vereador_ano,
 parlamentar, subcodigo_cap_final, valor_emenda,
 categoria_codigo, categoria, revisao_recomendada,
 nota_auditoria, objeto_emenda, beneficiario),
 '10_cod12_classificacao_por_emenda.csv')
salvar(cod12 %>% dplyr::filter(revisao_recomendada == 'SIM') %>%
 dplyr::select(ano, id_emenda, id_vereador_ano,
 valor_emenda, categoria_codigo, nota_auditoria, objeto_emenda),
 '10_cod12_pendencias_manuais.csv')

resumo <- cod12 %>% dplyr::group_by(categoria_codigo, categoria) %>%
 dplyr::summarise(n_emendas = dplyr::n(),
 valor = sum(valor_emenda), .groups = 'drop') %>%
 dplyr::mutate(pct_cod12 = 100 * valor / sum(valor)) %>%
 dplyr::arrange(match(categoria_codigo, c('V', 'I', 'D', 'O')))
salvar(resumo, '10_cod12_resumo_geral.csv')

anos <- sort(unique(as.integer(cod12$ano)))
base_ano <- expand.grid(ano = anos, categoria_codigo = c('V', 'I', 'D', 'O'),
 stringsAsFactors = FALSE)
resumo_ano <- cod12 %>% dplyr::mutate(ano = as.integer(ano)) %>%
 dplyr::group_by(ano, categoria_codigo) %>%
 dplyr::summarise(n_emendas = dplyr::n(), valor = sum(valor_emenda),
 .groups = 'drop')
resumo_ano <- base_ano %>% dplyr::left_join(resumo_ano,
 by = c('ano', 'categoria_codigo')) %>%
 dplyr::mutate(n_emendas = dplyr::coalesce(n_emendas, 0L),
 valor = dplyr::coalesce(valor, 0),
 categoria = unname(nomes[categoria_codigo])) %>%
 dplyr::group_by(ano) %>% dplyr::mutate(
 total_cod12_ano = sum(valor),
 pct_cod12_ano = 100 * valor / total_cod12_ano) %>%
 dplyr::ungroup() %>%
 dplyr::arrange(ano, match(categoria_codigo, c('V','I','D','O')))
salvar(resumo_ano, '10_cod12_resumo_ano_categoria.csv')

perfil_totais <- cod12 %>% dplyr::group_by(id_vereador_ano) %>%
 dplyr::summarise(n_emendas_cod12 = dplyr::n(),
 valor_cod12 = sum(valor_emenda), .groups = 'drop')
painel <- perfis %>% dplyr::left_join(perfil_totais,
 by = 'id_vereador_ano') %>%
 dplyr::mutate(n_emendas_cod12 = dplyr::coalesce(n_emendas_cod12, 0L),
 valor_cod12 = dplyr::coalesce(valor_cod12, 0),
 valor_total_nao_saude = as.numeric(valor_total_nao_saude))
for (classe in c('V','I','D','O')) {
  tmp <- cod12 %>% dplyr::filter(categoria_codigo == classe) %>%
    dplyr::group_by(id_vereador_ano) %>%
    dplyr::summarise(n_classe = dplyr::n(), valor_classe = sum(valor_emenda),
    .groups = 'drop')
  names(tmp)[names(tmp) == 'n_classe'] <- paste0('n_', classe)
  names(tmp)[names(tmp) == 'valor_classe'] <- paste0('valor_', classe)
  painel <- painel %>% dplyr::left_join(tmp, by = 'id_vereador_ano')
  painel[[paste0('n_', classe)]] <-
   dplyr::coalesce(painel[[paste0('n_', classe)]], 0L)
  painel[[paste0('valor_', classe)]] <-
   dplyr::coalesce(painel[[paste0('valor_', classe)]], 0)
  painel[[paste0('pct_', classe, '_do_cod12')]] <- ifelse(
   painel$valor_cod12 > 0,
   100 * painel[[paste0('valor_', classe)]] / painel$valor_cod12,
   NA_real_)
  painel[[paste0('pct_', classe, '_no_portfolio')]] <- ifelse(
   painel$valor_total_nao_saude > 0,
   100 * painel[[paste0('valor_', classe)]] / painel$valor_total_nao_saude,
   NA_real_)
}
painel$pct_cod12_no_portfolio <- ifelse(
 painel$valor_total_nao_saude > 0,
 100 * painel$valor_cod12 / painel$valor_total_nao_saude,
 NA_real_)
if (nrow(painel) != 206L || sum(painel$n_emendas_cod12) != 108L ||
    abs(sum(painel$valor_cod12) - 23990135) > .01 ||
    sum(painel$n_emendas_cod12 > 0) != 73L)
 stop('Falha de reconciliacao por vereador-ano.')
chaves <- c('ano', 'id_vereador_ano', 'parlamentar_partido',
 'pessoa_chave', 'sigla_partido', 'zucco_final', 'bolognesi_media',
 'n_emendas_nao_saude', 'valor_total_nao_saude',
 'n_emendas_cod12', 'valor_cod12', 'pct_cod12_no_portfolio')
colunas_classe <- unlist(lapply(c('V','I','D','O'), function(k)
 c(paste0('n_', k), paste0('valor_', k),
   paste0('pct_', k, '_do_cod12'), paste0('pct_', k, '_no_portfolio'))))
salvar(painel %>% dplyr::select(dplyr::all_of(c(chaves, colunas_classe))),
 '10_cod12_painel_206_vereador_ano.csv')

amostras <- list(
 total_206 = rep(TRUE, nrow(painel)),
 ZuccoPower_173 = !is.na(painel$zucco_final) & painel$zucco_final != '',
 Bolognesi_140 = !is.na(painel$bolognesi_media) & painel$bolognesi_media != '',
 ambas_112 = !is.na(painel$zucco_final) & painel$zucco_final != '' &
             !is.na(painel$bolognesi_media) & painel$bolognesi_media != '')
lista <- list()
for (nm in names(amostras)) {
 d <- painel[amostras[[nm]],,drop=FALSE]
 total <- sum(d$valor_cod12)
 for (classe in c('V','I','D','O')) {
  lista[[length(lista)+1L]] <- tibble::tibble(
   amostra = nm, n_perfis = nrow(d),
   n_perfis_com_cod12 = sum(d$n_emendas_cod12>0),
   categoria_codigo = classe,
   n_emendas = sum(d[[paste0('n_',classe)]]),
   valor = sum(d[[paste0('valor_',classe)]]),
   total_cod12_amostra = total,
   pct_cod12_amostra = if (total>0) 100*sum(d[[paste0('valor_',classe)]])/total else NA_real_)
 }
}
salvar(dplyr::bind_rows(lista), '10_cod12_resumo_amostras.csv')
msg('206 perfis preservados; 73 com COD 12; distribuicao por 4 classes e por ano exportada')
print(resumo)
print(resumo_ano %>% dplyr::select(ano, categoria_codigo, n_emendas, valor, pct_cod12_ano))
msg('FINALIZADO: 17 decisoes aprovadas, 7 reclassificacoes, zero pendencias manuais.')
