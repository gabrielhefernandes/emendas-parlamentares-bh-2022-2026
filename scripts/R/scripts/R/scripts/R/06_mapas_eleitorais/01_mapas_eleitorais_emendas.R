# ============================================================================
# TCC BH 2022-2026 | CARTOGRAFIA POR VEREADOR-ANO | V2.2
# V2.2: corrige rodape de fontes cortado com quebra explicita de linhas.
# Preserva os ajustes de validacao de dados e geometrias da v2.1.
# Melhorias de layout/legenda:
# - bolhas SEM logaritmo; area proporcional a votos ou R$
# - legenda de emendas com a MESMA cor das bolhas do mapa
# - bloco de resumo abaixo da legenda
# - legendas mais compactas e melhor organizadas
# - 5 PNG por vereador/ano:
#     1) eleitoral
#     2) emendas sem saude
#     3) emendas com saude
#     4) comparacao votacao x emendas sem saude
#     5) comparacao votacao x emendas com saude
#
# Requer: R >= 4.2 e entradas explicitas em dados/geoespaciais e dados/eleitorais.
# Nao modifica CSV, GPKG ou planilhas originais.
# ============================================================================

# 0. CONFIGURACAO =============================================================
base_dir <- normalizePath(Sys.getenv("TCC_BH_RAIZ", unset=getwd()),
                         winslash="/", mustWork=TRUE)
saida_dir <- file.path(base_dir, "resultados", "replicacao", "cartografia", "vereadores")

# Padrao = gerar os mapas de TODOS os vereadores/anos.
# Para ensaio, defina TCC_TESTAR_APENAS=2022_BELLA_GONCALVES,2022_ALVARO_DAMIAO.
teste_env <- Sys.getenv("TCC_TESTAR_APENAS", unset="")
testar_apenas <- if (nzchar(teste_env)) trimws(strsplit(teste_env, ",", fixed=TRUE)[[1]]) else NULL

MAX_DIAMETRO_EMENDAS_MM <- 19
MAX_DIAMETRO_VOTOS_MM   <- 12
DPI_PNG <- 220
LARGURA_POLEGADAS <- 8.8
ALTURA_POLEGADAS  <- 10.6

# 1. PACOTES ==================================================================
pacotes <- c("sf", "dplyr", "readr", "ggplot2", "scales", "ggnewscale", "stringi", "grid")
a_instalar <- setdiff(pacotes, rownames(installed.packages()))
if (length(a_instalar)) install.packages(a_instalar, repos = "https://cloud.r-project.org")
invisible(lapply(pacotes, library, character.only = TRUE))
options(scipen = 999)
dir.create(saida_dir, recursive = TRUE, showWarnings = FALSE)

# 2. LEITURA E LOCALIZACAO DOS ARQUIVOS =======================================
# Caminhos EXATOS no repositorio: nao procurar backups nem selecionar por nome.
arquivo_painel <- file.path(base_dir, "dados", "geoespaciais", "PAINEL_EMENDA_LOCALIDADE_CANONICO_2022_2026.csv")
arquivo_geo <- file.path(base_dir, "dados", "geoespaciais", "LOCALIDADES_GEO_CANONICAS_2022_2026.gpkg")
arquivo_votos <- file.path(base_dir, "dados", "eleitorais", "votos_vereadores_relevantes_geografia_eleitoral_v4.csv")
arquivo_universo <- file.path(base_dir, "dados", "eleitorais", "universo_vereadores_emendas_partidos_2022_2026_v1.csv")
arquivo_regionais <- file.path(base_dir, "dados", "geoespaciais", "malhas_pbh", "20220601_regional.csv")
arquivo_limite <- file.path(base_dir, "dados", "geoespaciais", "malhas_pbh", "20240416_limite_municipio.csv")
entradas_cartografia <- c(painel=arquivo_painel, geo=arquivo_geo, votos=arquivo_votos,
                          universo=arquivo_universo, regionais=arquivo_regionais, limite=arquivo_limite)
faltantes_cartografia <- entradas_cartografia[!file.exists(entradas_cartografia)]
if (length(faltantes_cartografia)) {
  stop("Faltam entradas para os mapas; confira os caminhos relativos ao repositorio:\n",
       paste(sprintf("%s: %s", names(faltantes_cartografia), faltantes_cartografia), collapse="\n"),
       call.=FALSE)
}
message("Fontes cartograficas conferidas: ", paste(names(entradas_cartografia),collapse=", "))

ler_tabela <- function(caminho) {
  h <- readLines(caminho, n = 1L, warn = FALSE, encoding = "UTF-8")
  sep <- if (grepl(";", h, fixed = TRUE) && !grepl('\",\"', h, fixed = TRUE)) ";" else ","
  x <- readr::read_delim(caminho, delim = sep,
    col_types = readr::cols(.default = readr::col_character()),
    locale = readr::locale(encoding = "UTF-8"),
    show_col_types = FALSE, progress = FALSE, name_repair = "minimal")
  names(x) <- sub("^\\ufeff", "", names(x))
  names(x) <- sub("^ï»¿", "", names(x))
  x
}

num <- function(x) suppressWarnings(as.numeric(gsub(",", ".", as.character(x), fixed = TRUE)))

ler_malha <- function(caminho) {
  ext <- tolower(tools::file_ext(caminho))
  if (ext == "csv") {
    tb <- ler_tabela(caminho)
    opcoes <- c("WKT", "GEOMETRIA", "geometry", "geom", "geometria_wkt", "GEOMETRIA_WKT", "the_geom")
    col <- opcoes[opcoes %in% names(tb)][1]
    if (is.na(col)) stop("Malha CSV sem campo WKT reconhecido: ", caminho,
                         "\nDefina um arquivo GPKG ou um CSV com coluna WKT.")
    exemplo <- tb[[col]][which(!is.na(tb[[col]]) & nzchar(tb[[col]]))[1]]
    parece_graus <- grepl("-4[0-9]\\.[0-9]+[[:space:]]+-1[0-9]\\.[0-9]+", exemplo)
    epsg <- if (isTRUE(parece_graus)) 4674 else 31983
    return(sf::st_as_sf(tb, wkt = col, crs = epsg) |> sf::st_transform(31983))
  }
  geom <- sf::st_read(caminho, quiet = TRUE)
  if (is.na(sf::st_crs(geom))) stop("CRS ausente na malha: ", caminho)
  sf::st_transform(geom, 31983)
}

message("Lendo as tabelas e camadas...")
painel <- ler_tabela(arquivo_painel)
universo <- ler_tabela(arquivo_universo)
votos <- ler_tabela(arquivo_votos)

camadas <- sf::st_layers(arquivo_geo)$name
if (!"pontos_representativos_961" %in% camadas) {
  stop("A camada 'pontos_representativos_961' nao esta no GeoPackage. Camadas: ",
       paste(camadas, collapse = ", "))
}
locais <- sf::st_read(arquivo_geo, layer = "pontos_representativos_961", quiet = TRUE) |>
  sf::st_transform(31983)
regionais <- ler_malha(arquivo_regionais)
limite <- ler_malha(arquivo_limite)
if (any(!sf::st_is_valid(regionais))) regionais <- sf::st_make_valid(regionais)
if (any(!sf::st_is_valid(limite))) limite <- sf::st_make_valid(limite)

possiveis_nomes <- c("NOME", "nome", "REGIONAL", "regional", "NOME_REGIONAL",
                     "nome_regional", "NM_REGIONAL", "nm_regional", "regional_nome")
nome_col <- possiveis_nomes[possiveis_nomes %in% names(regionais)][1]
if (is.na(nome_col)) stop("Nome da regional ausente. Colunas: ", paste(names(regionais), collapse = ", "))
regionais$NOME_EXIBICAO <- toupper(as.character(regionais[[nome_col]]))
centros <- sf::st_point_on_surface(regionais)
limite <- sf::st_sf(geometry = sf::st_union(sf::st_geometry(limite)))

# 3. TRATAMENTO + AUDITORIA ===================================================
necessarias_painel <- c("ANO", "ID_EMENDA", "ID_VEREADOR_ANO", "ID_LOCALIDADE",
                        "VALOR_EMENDA_ORIGINAL", "VALOR_EMENDA_ALOCADO_LOCALIDADE", "SUBCODIGO_CAP_FINAL")
stopifnot(all(necessarias_painel %in% names(painel)))
stopifnot(all(c("ano_emenda", "id_vereador_ano", "vereador_norm", "ano_eleicao_base") %in% names(universo)))
stopifnot(all(c("ano_eleicao", "vereador_norm", "id_local_tse", "latitude_final",
                "longitude_final", "votos_candidato_observados", "lq_nominal") %in% names(votos)))
stopifnot("ID_LOCALIDADE" %in% names(locais))

painel <- painel |>
  dplyr::mutate(
    ANO = as.integer(.data$ANO),
    ID_VEREADOR_ANO = as.character(.data$ID_VEREADOR_ANO),
    ID_LOCALIDADE = as.character(.data$ID_LOCALIDADE),
    VALOR_EMENDA_ORIGINAL = num(.data$VALOR_EMENDA_ORIGINAL),
    VALOR_EMENDA_ALOCADO_LOCALIDADE = num(.data$VALOR_EMENDA_ALOCADO_LOCALIDADE),
    CAP_NUM = num(.data$SUBCODIGO_CAP_FINAL),
    SAUDE = !is.na(.data$CAP_NUM) & .data$CAP_NUM >= 300 & .data$CAP_NUM < 400
  )

if (anyDuplicated(painel[c("ID_EMENDA", "ID_LOCALIDADE")]))
  stop("Duplicacao de par emenda-localidade na base; nao vou somar em duplicidade.")
if (any(is.na(painel$VALOR_EMENDA_ALOCADO_LOCALIDADE)))
  stop("Ha valores alocados ausentes. Revise o painel antes de gerar os mapas.")

auditoria_emendas <- painel |>
  dplyr::group_by(.data$ANO, .data$ID_EMENDA) |>
  dplyr::summarise(
    valor_original = dplyr::first(.data$VALOR_EMENDA_ORIGINAL),
    soma_rateada = sum(.data$VALOR_EMENDA_ALOCADO_LOCALIDADE),
    numero_localidades = dplyr::n(), .groups = "drop") |>
  dplyr::mutate(diferenca = .data$soma_rateada - .data$valor_original,
                confere = abs(.data$diferenca) < 0.02)
readr::write_csv2(auditoria_emendas,
                  file.path(saida_dir, "AUDITORIA_VALORES_EMENDAS_E_RATEIO.csv"), na = "")
if (any(!auditoria_emendas$confere)) {
  stop("Valores originais nao coincidem com a soma alocada em todas as localidades. ",
       "Veja AUDITORIA_VALORES_EMENDAS_E_RATEIO.csv. Mapas nao gerados.")
}

if (anyDuplicated(locais$ID_LOCALIDADE)) stop("IDs duplicados na geometria de localidades")
locais$ID_LOCALIDADE <- as.character(locais$ID_LOCALIDADE)
geo_ids <- locais$ID_LOCALIDADE[!sf::st_is_empty(locais)]
sem_geo <- painel |> dplyr::filter(!.data$ID_LOCALIDADE %in% geo_ids)
readr::write_csv2(
  sem_geo |> dplyr::select("ANO", "ID_EMENDA", "ID_VEREADOR_ANO", "ID_LOCALIDADE", "VALOR_EMENDA_ALOCADO_LOCALIDADE"),
  file.path(saida_dir, "AUDITORIA_PARES_SEM_GEOMETRIA.csv"), na = "")

agg <- painel |>
  dplyr::group_by(.data$ANO, .data$ID_VEREADOR_ANO, .data$ID_LOCALIDADE) |>
  dplyr::summarise(
    total_rs = sum(.data$VALOR_EMENDA_ALOCADO_LOCALIDADE),
    saude_rs = sum(.data$VALOR_EMENDA_ALOCADO_LOCALIDADE[.data$SAUDE]),
    nao_saude_rs = sum(.data$VALOR_EMENDA_ALOCADO_LOCALIDADE[!.data$SAUDE]),
    n_emendas_localidade = dplyr::n_distinct(.data$ID_EMENDA),
    .groups = "drop")

geo_agg <- locais |>
  dplyr::select("ID_LOCALIDADE") |>
  dplyr::inner_join(agg, by = "ID_LOCALIDADE")
if (!inherits(geo_agg, "sf")) stop("A juncao de localidades perdeu a classe sf. Verifique o GeoPackage.")
geo_agg <- geo_agg[!sf::st_is_empty(geo_agg), , drop = FALSE]

universo <- universo |>
  dplyr::mutate(ano_emenda = as.integer(.data$ano_emenda),
                ano_eleicao_base = as.integer(.data$ano_eleicao_base))
if (anyDuplicated(universo$id_vereador_ano)) stop("Duplicidade no universo vereador-ano")

norm <- function(x) {
  x <- stringi::stri_trans_general(as.character(x), "Latin-ASCII")
  trimws(gsub("[[:space:]]+", " ", toupper(x)))
}
slug <- function(x) {
  y <- tolower(stringi::stri_trans_general(as.character(x), "Latin-ASCII"))
  gsub("(^_+|_+$)", "", gsub("[^a-z0-9]+", "_", y))
}
fmt_int <- function(x) scales::label_number(big.mark = ".", decimal.mark = ",", accuracy = 1)(x)
fmt_rs <- function(x) paste0("R$ ", scales::label_number(big.mark = ".", decimal.mark = ",", accuracy = 1)(x))

universo$CHAVE <- norm(universo$vereador_norm)
votos <- votos |>
  dplyr::mutate(
    ano_eleicao = as.integer(.data$ano_eleicao),
    CHAVE = norm(.data$vereador_norm),
    votos_num = num(.data$votos_candidato_observados),
    lq_num = num(.data$lq_nominal),
    lat_num = num(.data$latitude_final),
    lon_num = num(.data$longitude_final)
  ) |>
  dplyr::filter(is.finite(.data$lon_num), is.finite(.data$lat_num),
                is.finite(.data$votos_num), .data$votos_num >= 0)

votos_geo <- sf::st_as_sf(votos, coords = c("lon_num", "lat_num"), crs = 4674) |>
  sf::st_transform(31983)

if (anyDuplicated(sf::st_drop_geometry(votos_geo)[c("ano_eleicao", "CHAVE", "id_local_tse")])) {
  stop("A base eleitoral tem registros duplicados por candidato/ano/local TSE")
}

# Escalas globais ==============================================================
max_rs <- max(geo_agg$total_rs, na.rm = TRUE)
max_votos <- max(votos_geo$votos_num, na.rm = TRUE)
quebras_rs <- c(50000, 200000, 500000, 1000000, 2000000, 3500000)
quebras_rs <- quebras_rs[quebras_rs <= max_rs]
quebras_votos <- c(10, 50, 100, 500, 1000, 2000)
quebras_votos <- quebras_votos[quebras_votos <= max_votos]

escala_rs_emendas <- function(cor_fill = "#919191", cor_linha = "#525252") {
  ggplot2::scale_size_area(
    max_size = MAX_DIAMETRO_EMENDAS_MM,
    limits = c(0, max_rs),
    breaks = quebras_rs,
    labels = fmt_int,
    name = "Valor indicado (R$)",
    guide = ggplot2::guide_legend(
      order = 1,
      nrow = 2,
      byrow = TRUE,
      override.aes = list(
        shape = 21,
        fill = cor_fill,
        colour = cor_linha,
        stroke = .35,
        alpha = 0.80
      )
    )
  )
}

escala_votos_puro <- function() {
  ggplot2::scale_size_area(
    max_size = MAX_DIAMETRO_VOTOS_MM,
    limits = c(0, max_votos),
    breaks = quebras_votos,
    labels = fmt_int,
    name = "Votos nominais",
    guide = ggplot2::guide_legend(
      order = 1,
      nrow = 2,
      byrow = TRUE,
      override.aes = list(colour = "#444444", alpha = 0.85)
    )
  )
}

escala_votos_comparacao <- function() {
  ggplot2::scale_size_area(
    max_size = MAX_DIAMETRO_VOTOS_MM,
    limits = c(0, max_votos),
    breaks = quebras_votos,
    labels = fmt_int,
    name = "Votos nominais",
    guide = ggplot2::guide_legend(
      order = 1,
      nrow = 2,
      byrow = TRUE,
      override.aes = list(
        shape = 21,
        fill = scales::alpha("#516dd3", .26),
        colour = scales::alpha("#3b56a5", .36),
        stroke = .20,
        alpha = 1
      )
    )
  )
}

# 4. COMPOSICAO DOS MAPAS =====================================================
bb <- sf::st_bbox(limite)
x_centro <- mean(c(bb["xmin"], bb["xmax"]))
y_centro <- mean(c(bb["ymin"], bb["ymax"]))

base_mapa <- function() {
  ggplot2::ggplot() +
    ggplot2::geom_sf(data = limite, fill = "#fafaf9", colour = "#3a3a3a", linewidth = .72) +
    ggplot2::geom_sf(data = regionais, fill = NA, colour = "#b2b2b2", linewidth = .32) +
    ggplot2::coord_sf(datum = NA, expand = FALSE, clip = "on") +
    ggplot2::theme_void(base_size = 10.5) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "white", colour = NA),
      plot.title = ggplot2::element_text(face = "bold", size = 15.5, margin = ggplot2::margin(b = 3)),
      plot.subtitle = ggplot2::element_text(size = 10, margin = ggplot2::margin(b = 7)),
      plot.caption = ggplot2::element_text(size = 8.0, colour = "#505050", hjust = 0,
                                                 lineheight = 1.18, margin = ggplot2::margin(t = 5)),
      plot.caption.position = "plot",
      legend.position = "bottom",
      legend.box = "vertical",
      legend.justification = "center",
      legend.direction = "horizontal",
      legend.title = ggplot2::element_text(size = 8.8),
      legend.text = ggplot2::element_text(size = 7.7),
      legend.key.height = grid::unit(3.4, "mm"),
      legend.key.width = grid::unit(10, "mm"),
      legend.spacing.y = grid::unit(1.2, "mm"),
      legend.spacing.x = grid::unit(3.2, "mm"),
      legend.box.spacing = grid::unit(1.2, "mm"),
      legend.margin = ggplot2::margin(t = 0, r = 0, b = 0, l = 0),
      plot.margin = ggplot2::margin(8, 9, 8, 9)
    )
}

rotulos <- function() ggplot2::geom_sf_text(
  data = centros, ggplot2::aes(label = .data$NOME_EXIBICAO),
  colour = "#666666", fontface = "bold", size = 3.05, check_overlap = TRUE)

sem_dados <- function(titulo, detalhe) {
  base_mapa() + rotulos() +
    ggplot2::annotate("label", x = x_centro, y = y_centro,
                      label = detalhe, fill = "white", colour = "#555555", size = 3.5) +
    ggplot2::labs(title = titulo, subtitle = "Sem observacoes cartografaveis neste recorte")
}

texto_resumo_emendas <- function(est) {
  paste0(
    "Resumo do mapa\n",
    "Soma representada: ", fmt_rs(est$soma_rs),
    " | Localidades: ", fmt_int(est$n_localidades),
    " | Numero de emendas: ", fmt_int(est$n_emendas)
  )
}

texto_resumo_eleitoral <- function(est) {
  paste0(
    "Resumo do mapa\n",
    "Estabelecimentos com votos: ", fmt_int(est$n_estabelecimentos),
    " | Votos representados: ", fmt_int(est$votos)
  )
}

texto_resumo_comparacao <- function(est_em, est_vt) {
  paste0(
    "Resumo do mapa\n",
    "Soma: ", fmt_rs(est_em$soma_rs),
    " | Localidades emendas: ", fmt_int(est_em$n_localidades),
    " | Numero de emendas: ", fmt_int(est_em$n_emendas), "\n",
    "Estabelecimentos com votos: ", fmt_int(est_vt$n_estabelecimentos),
    " | Votos representados: ", fmt_int(est_vt$votos)
  )
}

# O ggplot2 nao quebra automaticamente legendas longas de rodape.
# A fonte e a nota metodologica sao repartidas em linhas de ate 78 caracteres,
# deixando o resumo dos indicadores intacto. Isso evita corte a direita do PNG.
caption_duplo <- function(resumo, fonte) {
  fonte_formatada <- paste(strwrap(fonte, width = 78), collapse = "\n")
  paste0(resumo, "\n\n", fonte_formatada)
}

montar_emendas <- function(df, titulo, incluir_saude, est_resumo) {
  if (!incluir_saude) {
    df <- df |>
      dplyr::filter(.data$nao_saude_rs > 0) |>
      dplyr::mutate(valor_mapa = .data$nao_saude_rs, categoria = "Demais temas")
  } else {
    df <- df |>
      dplyr::filter(.data$total_rs > 0) |>
      dplyr::mutate(
        valor_mapa = .data$total_rs,
        categoria = dplyr::case_when(
          .data$saude_rs > 0 & .data$nao_saude_rs > 0 ~ "Saúde e demais temas",
          .data$saude_rs > 0 ~ "Saúde (CAP 03)",
          TRUE ~ "Demais temas"
        )
      )
  }
  if (nrow(df) == 0) return(sem_dados(titulo, "Nenhuma emenda com geometria neste recorte"))

  base_mapa() +
    ggplot2::geom_sf(
      data = df,
      ggplot2::aes(size = .data$valor_mapa, fill = .data$categoria),
      shape = 21, colour = "#525252", stroke = .30, alpha = .76
    ) +
    escala_rs_emendas(cor_fill = "#919191", cor_linha = "#525252") +
    ggplot2::scale_fill_manual(
      name = "Classificacao tematica",
      values = c("Demais temas" = "#919191",
                 "Saúde (CAP 03)" = "#d97a74",
                 "Saúde e demais temas" = "#a76d9a"),
      drop = TRUE,
      guide = ggplot2::guide_legend(order = 2, nrow = 1, byrow = TRUE,
                                    override.aes = list(size = 4.3, alpha = .85))
    ) +
    rotulos() +
    ggplot2::labs(
      title = titulo,
      subtitle = if (incluir_saude) {
        "Inclui saúde; uma bolha por localidade (total em R$)"
      } else {
        "Exclui saúde (CAP 03); valores indicados em R$"
      },
      caption = caption_duplo(
        texto_resumo_emendas(est_resumo),
        paste0(
          "Fontes: bases de emendas e localidades do TCC; limites PBH/PRODABEL. ",
          "Area das bolhas proporcional aos reais indicados (sem log). ",
          "Multiplas emendas na mesma localidade somadas; emendas multilocalidade rateadas."
        )
      )
    )
}

montar_eleitoral <- function(df, titulo, ano_eleicao, est_resumo) {
  df <- df |> dplyr::filter(is.finite(.data$votos_num), .data$votos_num > 0)
  if (!nrow(df)) return(sem_dados(titulo, paste0("Sem votacao disponivel para ", ano_eleicao)))

  coord <- sf::st_coordinates(df)
  if (nrow(coord) != nrow(df)) stop("Os locais de votacao precisam ser pontos simples; coordenadas inesperadas.")
  pts <- sf::st_drop_geometry(df)
  pts$x_utm <- coord[, "X"]
  pts$y_utm <- coord[, "Y"]

  invalidos <- !is.finite(pts$lq_num) | pts$lq_num <= 0
  pts$lq_vis <- pts$lq_num
  pts$lq_vis[invalidos] <- 1
  pts$cor_lq <- pmax(-2, pmin(2, log2(pts$lq_vis)))

  fig <- base_mapa() +
    ggplot2::geom_point(
      data = pts,
      ggplot2::aes(x = .data$x_utm, y = .data$y_utm,
                   size = .data$votos_num, colour = .data$cor_lq),
      shape = 16, alpha = .78
    ) +
    escala_votos_puro() +
    ggplot2::scale_colour_gradient2(
      low = "#8f92cf", mid = "#ece9ee", high = "#d84c45",
      midpoint = 0, limits = c(-2, 2), breaks = c(-2, -1, 0, 1, 2),
      labels = c("0,25", "0,5", "1,0", "2,0", "4,0"),
      name = "LQ nominal\n(cor da bolha)",
      guide = ggplot2::guide_colourbar(order = 2,
                                       barwidth = grid::unit(36, "mm"),
                                       barheight = grid::unit(4, "mm"),
                                       title.position = "top")
    ) +
    rotulos() +
    ggplot2::labs(
      title = titulo,
      subtitle = paste0("Eleicao de referencia: ", ano_eleicao,
                        " | area das bolhas = numero de votos; cor = desempenho relativo"),
      caption = caption_duplo(
        texto_resumo_eleitoral(est_resumo),
        paste0(
          "Fonte: TSE (dados tratados); malhas PBH/PRODABEL. ",
          "LQ>1: desempenho acima da media municipal; LQ<1: abaixo. ",
          "Area proporcional aos votos absolutos; sem logaritmo no tamanho."
        )
      )
    )

  attr(fig, "n_pontos_eleitorais_esperados") <- nrow(pts)
  fig
}

montar_comparacao <- function(em, vt, titulo, incluir_saude, ano_eleicao, est_em, est_vt) {
  if (incluir_saude) {
    em <- em |> dplyr::filter(.data$total_rs > 0) |> dplyr::mutate(valor_mapa = .data$total_rs)
  } else {
    em <- em |> dplyr::filter(.data$nao_saude_rs > 0) |> dplyr::mutate(valor_mapa = .data$nao_saude_rs)
  }
  vt <- vt |> dplyr::filter(.data$votos_num > 0)
  if (!nrow(vt) || !nrow(em)) {
    return(sem_dados(titulo, "Sem votos ou sem localidades com emendas neste recorte"))
  }

  base_mapa() +
    ggplot2::geom_sf(
      data = vt, ggplot2::aes(size = .data$votos_num), shape = 21,
      fill = scales::alpha("#516dd3", .25), colour = scales::alpha("#3b56a5", .34),
      stroke = .18, alpha = 1
    ) +
    escala_votos_comparacao() +
    ggnewscale::new_scale("size") +
    ggplot2::geom_sf(
      data = em, ggplot2::aes(size = .data$valor_mapa), shape = 21,
      fill = scales::alpha("#f3a24c", .26), colour = scales::alpha("#c96b12", .86),
      stroke = .55, alpha = 1
    ) +
    escala_rs_emendas(cor_fill = scales::alpha("#f3a24c", .26), cor_linha = scales::alpha("#c96b12", .86)) +
    rotulos() +
    ggplot2::labs(
      title = titulo,
      subtitle = paste0("Azul = votos (eleicao ", ano_eleicao, ") | Laranja = emendas ",
                        if (incluir_saude) "com saude" else "sem saude"),
      caption = caption_duplo(
        texto_resumo_comparacao(est_em, est_vt),
        paste0(
          "Fontes: TSE, emendas e localidades do TCC; malhas PBH/PRODABEL. ",
          "Areas proporcionais aos valores absolutos, em escalas fixas em toda a serie. ",
          "Sobreposicao visual nao demonstra relacao causal."
        )
      )
    )
}

salvar <- function(fig, destino) {
  esperado <- attr(fig, "n_pontos_eleitorais_esperados")
  if (!is.null(esperado)) {
    construido <- ggplot2::ggplot_build(fig)
    camadas_pontos <- which(vapply(fig$layers, function(z) inherits(z$geom, "GeomPoint"), logical(1)))
    if (length(camadas_pontos) != 1L) stop("Camada eleitoral GeomPoint nao encontrada: ", destino)
    desenhados <- construido$data[[camadas_pontos]]
    n_validos <- sum(is.finite(desenhados$x) & is.finite(desenhados$y) &
                       is.finite(desenhados$size) & !is.na(desenhados$colour))
    if (n_validos != esperado) {
      stop("Grafico eleitoral perdeu pontos antes de salvar: ", destino,
           " | esperados=", esperado, " | validos=", n_validos)
    }
  }
  ggplot2::ggsave(destino, plot = fig, width = LARGURA_POLEGADAS,
                  height = ALTURA_POLEGADAS, dpi = DPI_PNG, bg = "white", limitsize = FALSE)
}

# 5. FUNCOES DE ESTATISTICA ===================================================
estats_emendas <- function(painel_em, incluir_saude) {
  if (!nrow(painel_em)) return(list(soma_rs = 0, n_localidades = 0, n_emendas = 0))
  if (incluir_saude) {
    x <- painel_em
  } else {
    x <- painel_em |> dplyr::filter(!.data$SAUDE)
  }
  if (!nrow(x)) return(list(soma_rs = 0, n_localidades = 0, n_emendas = 0))
  list(
    soma_rs = sum(x$VALOR_EMENDA_ALOCADO_LOCALIDADE, na.rm = TRUE),
    n_localidades = dplyr::n_distinct(x$ID_LOCALIDADE),
    n_emendas = dplyr::n_distinct(x$ID_EMENDA)
  )
}

estats_eleitorais <- function(vt) {
  x <- vt |> dplyr::filter(.data$votos_num > 0)
  if (!nrow(x)) return(list(n_estabelecimentos = 0, votos = 0))
  list(
    n_estabelecimentos = nrow(x),
    votos = sum(x$votos_num, na.rm = TRUE)
  )
}

# 6. GERACAO, INVENTARIO E VERIFICACOES =======================================
indices <- universo |>
  dplyr::select("ano_emenda", "id_vereador_ano", "parlamentar",
                "partido_emenda", "vereador_norm", "ano_eleicao_base", "CHAVE") |>
  dplyr::arrange(.data$ano_emenda, .data$vereador_norm)
if (!is.null(testar_apenas)) {
  indices <- indices |> dplyr::filter(.data$id_vereador_ano %in% testar_apenas)
}
if (nrow(indices) == 0) stop("Nenhum vereador-ano corresponde a testar_apenas")

log_execucao <- vector("list", nrow(indices))
message("Gerando PNGs para ", nrow(indices), " combinacoes vereador-ano.")

for (i in seq_len(nrow(indices))) {
  u <- indices[i, ]
  ano <- u$ano_emenda[[1]]
  eleicao <- u$ano_eleicao_base[[1]]
  id <- u$id_vereador_ano[[1]]
  nome <- u$parlamentar[[1]]
  partido <- u$partido_emenda[[1]]
  chave <- u$CHAVE[[1]]

  pasta <- file.path(saida_dir, as.character(ano), slug(u$vereador_norm[[1]]))
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  prefixo <- paste0("mapa_", slug(u$vereador_norm[[1]]), "_", ano)
  tit <- paste0(nome, " (", partido, ") — ", ano)

  em <- geo_agg |>
    dplyr::filter(.data$ANO == .env$ano, .data$ID_VEREADOR_ANO == .env$id)
  vt <- votos_geo |>
    dplyr::filter(.data$ano_eleicao == .env$eleicao, .data$CHAVE == .env$chave)
  painel_em_geom <- painel |>
    dplyr::filter(.data$ANO == .env$ano,
                  .data$ID_VEREADOR_ANO == .env$id,
                  .data$ID_LOCALIDADE %in% .env$geo_ids)

  est_em_sem <- estats_emendas(painel_em_geom, incluir_saude = FALSE)
  est_em_com <- estats_emendas(painel_em_geom, incluir_saude = TRUE)
  est_vt <- estats_eleitorais(vt)

  message(sprintf("[%d/%d] %s | localidades: %d | locais eleitorais: %d",
                  i, nrow(indices), tit, nrow(em), nrow(vt)))

  figuras <- list(
    eleitoral = montar_eleitoral(vt, paste0("Votacao eleitoral — ", tit), eleicao, est_vt),
    sem_saude = montar_emendas(em, paste0("Emendas sem saude — ", tit), FALSE, est_em_sem),
    com_saude = montar_emendas(em, paste0("Emendas com saude — ", tit), TRUE, est_em_com),
    comparacao_sem_saude = montar_comparacao(
      em, vt, paste0("Votacao x emendas sem saude — ", tit), FALSE, eleicao,
      est_em_sem, est_vt
    ),
    comparacao_com_saude = montar_comparacao(
      em, vt, paste0("Votacao x emendas com saude — ", tit), TRUE, eleicao,
      est_em_com, est_vt
    )
  )

  for (tipo in names(figuras)) {
    destino <- file.path(pasta, paste0(prefixo, "_", tipo, ".png"))
    salvar(figuras[[tipo]], destino)
  }

  log_execucao[[i]] <- data.frame(
    ano_emenda = ano,
    id_vereador_ano = id,
    parlamentar = nome,
    ano_eleicao = eleicao,
    n_localidades = nrow(em),
    n_locais_eleitorais = nrow(vt),
    valor_cartografado_rs = est_em_com$soma_rs,
    valor_sem_saude_cartografado_rs = est_em_sem$soma_rs,
    n_emendas_com_saude = est_em_com$n_emendas,
    n_emendas_sem_saude = est_em_sem$n_emendas,
    votos_totais_observados = est_vt$votos,
    pasta = pasta,
    stringsAsFactors = FALSE
  )
}

log_df <- dplyr::bind_rows(log_execucao)
readr::write_csv2(log_df, file.path(saida_dir, "INVENTARIO_MAPAS_GERADOS.csv"), na = "")
message("FINALIZADO! Mapas e auditorias em ", saida_dir)
message("Foram feitas ", nrow(log_df) * 5L, " imagens PNG.")
