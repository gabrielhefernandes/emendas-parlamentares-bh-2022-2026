# 12_tabela_e_bolhas_COD12_zucco_ATUALIZADO.R
# Atualizacao do script 12:
#  (i) mantém o gráfico 1 de composição anual do COD 12;
#  (ii) mantém a lógica das tabelas por partido;
#  (iii) adiciona/explicita a coluna de valor monetário total do COD 12 por partido
#       na tabela completa dos 15 partidos;
#  (iv) exporta a tabela completa em PNG (fundo branco), além do CSV;
#  (v) mantém o gráfico de bolhas horizontais na escala contínua Zucco-Power.
#
# Projeto esperado:
#   <RAIZ_REPOSITORIO>
# Saídas:
#   resultados/replicacao/analises

options(scipen = 999)

# =========================
# ETAPA 1 - Dependências
# =========================
req <- c('readr', 'dplyr', 'tidyr', 'ggplot2', 'scales', 'stringr')
miss <- req[!vapply(req, requireNamespace, logical(1), quietly = TRUE)]
if (length(miss) > 0) stop('Pacotes ausentes: ', paste(miss, collapse = ', '))

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(scales)
  library(stringr)
})

has_ggrepel <- requireNamespace('ggrepel', quietly = TRUE)
if (has_ggrepel) suppressPackageStartupMessages(library(ggrepel))

# =========================
# ETAPA 2 - Pastas e fontes
# =========================
source(file.path(Sys.getenv("TCC_BH_RAIZ", unset=getwd()),
  "scripts", "R", "01_importacao_padronizacao", "_config_funcoes.R"), encoding="UTF-8")
ROOT <- TCC_RAIZ
OUT  <- TCC_SAIDAS
if (!dir.exists(OUT)) dir.create(OUT, recursive = TRUE, showWarnings = FALSE)

cand <- function(...) {
  x <- c(...)
  y <- x[file.exists(x)]
  if (length(y) == 0) return(NA_character_)
  y[1]
}

arq_ano    <- cand(file.path(OUT, '10_cod12_resumo_ano_categoria.csv'))
arq_painel <- cand(file.path(OUT, '10_cod12_painel_206_vereador_ano.csv'))

if (is.na(arq_ano) || is.na(arq_painel)) {
  stop('Fontes do script 10 nao encontradas em R/scripts_refazer/saidas. Execute o script 10 primeiro.')
}

ano_cat <- readr::read_csv(arq_ano, show_col_types = FALSE)
painel  <- readr::read_csv(arq_painel, show_col_types = FALSE)

# =========================
# ETAPA 3 - Funções auxiliares
# =========================
fmt_mi <- function(x) paste0('R$ ', format(round(x/1e6, 2), decimal.mark = ',', nsmall = 2), ' mi')
fmt_pct1 <- function(x) paste0(format(round(x, 1), decimal.mark = ',', nsmall = 1), '%')
fmt_brl0 <- function(x) paste0('R$ ', format(round(x, 0), decimal.mark = ',', big.mark = '.', scientific = FALSE, trim = TRUE))
fmt_zucco <- function(x) {
  ifelse(x > 0,
         paste0('+', format(round(x, 3), decimal.mark = ',', nsmall = 3)),
         format(round(x, 3), decimal.mark = ',', nsmall = 3))
}

cat_labels <- c(
  'V' = 'Videomonitoramento',
  'I' = 'Segurança institucional',
  'D' = 'Violência contra mulheres, de gênero e doméstica/familiar',
  'O' = 'Outros / não identificável'
)
cat_levels <- unname(cat_labels[c('V', 'I', 'D', 'O')])
cat_colors <- c(
  'Videomonitoramento' = '#1678B2',
  'Segurança institucional' = '#D96A00',
  'Violência contra mulheres, de gênero e doméstica/familiar' = '#7E379D',
  'Outros / não identificável' = '#6A7075'
)

# -------------------------
# Função para desenhar tabela em PNG/PDF via ggplot
# -------------------------
plot_table_cod12 <- function(tab, titulo, subtitulo, rodape, arquivo_png,
                             arquivo_pdf = NULL, width = 18, base_size = 17) {

  stopifnot(all(c('Partido', 'Zucco-Power', 'Valor total do COD 12', 'Modalidade dominante dentro de seu COD 12') %in% names(tab)))

  tab_plot <- tab %>%
    mutate(.row_id = dplyr::row_number(),
           .y = rev(seq_len(n())))

  n <- nrow(tab_plot)
  x_left  <- 0
  x_right <- 15.8

  # posições das colunas
  x_partido <- 0.30
  x_zucco   <- 6.20
  x_valor   <- 9.35
  x_modal   <- 9.75

  # fundos alternados
  fundos <- tab_plot %>%
    transmute(.y,
              xmin = x_left,
              xmax = x_right,
              ymin = .y - 0.5,
              ymax = .y + 0.5,
              fill_id = ifelse(.row_id %% 2 == 0, 'cinza', 'branco'))

  p <- ggplot() +
    geom_rect(data = fundos,
              aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = fill_id),
              color = NA, show.legend = FALSE) +
    scale_fill_manual(values = c('branco' = 'white', 'cinza' = '#F2F2F2')) +
    annotate('text', x = x_left, y = n + 2.0, label = titulo,
             hjust = 0, vjust = 1, size = 8.5, fontface = 'bold') +
    annotate('text', x = x_left, y = n + 1.35, label = subtitulo,
             hjust = 0, vjust = 1, size = 5.2) +
    annotate('text', x = x_partido, y = n + 0.45, label = 'Partido',
             hjust = 0, vjust = 0.5, size = 5.9, fontface = 'bold') +
    annotate('text', x = x_zucco, y = n + 0.45, label = 'Zucco-Power',
             hjust = 1, vjust = 0.5, size = 5.9, fontface = 'bold') +
    annotate('text', x = x_valor, y = n + 0.45, label = 'Valor total do COD 12',
             hjust = 1, vjust = 0.5, size = 5.9, fontface = 'bold') +
    annotate('text', x = x_modal, y = n + 0.45, label = 'Modalidade dominante dentro de seu COD 12',
             hjust = 0, vjust = 0.5, size = 5.9, fontface = 'bold') +
    annotate('segment', x = x_left, xend = x_right, y = n + 0.10, yend = n + 0.10,
             colour = '#BEBEBE', linewidth = 0.7) +
    geom_text(data = tab_plot, aes(x = x_partido, y = .y, label = Partido),
              hjust = 0, vjust = 0.5, size = 5.3) +
    geom_text(data = tab_plot, aes(x = x_zucco, y = .y, label = `Zucco-Power`),
              hjust = 1, vjust = 0.5, size = 5.1) +
    geom_text(data = tab_plot, aes(x = x_valor, y = .y, label = `Valor total do COD 12`),
              hjust = 1, vjust = 0.5, size = 5.1) +
    geom_text(data = tab_plot, aes(x = x_modal, y = .y, label = `Modalidade dominante dentro de seu COD 12`),
              hjust = 0, vjust = 0.5, size = 5.1) +
    annotate('text', x = x_left, y = -0.95, label = rodape,
             hjust = 0, vjust = 1, size = 4.5) +
    coord_cartesian(xlim = c(x_left, x_right), ylim = c(-1.1, n + 2.25), clip = 'off') +
    theme_void(base_size = base_size) +
    theme(
      plot.background = element_rect(fill = 'white', color = NA),
      panel.background = element_rect(fill = 'white', color = NA),
      plot.margin = margin(20, 28, 20, 28)
    )

  ggsave(arquivo_png, p, width = width, height = max(4.8, 1.6 + n * 0.52), dpi = 320, bg = 'white')
  if (!is.null(arquivo_pdf)) {
    ggsave(arquivo_pdf, p, width = width, height = max(4.8, 1.6 + n * 0.52), bg = 'white')
  }

  invisible(p)
}

# =========================
# ETAPA 4 - Gráfico 1 (composição anual)
# =========================
# Se houver categoria NA por algum motivo residual, ela é removida do gráfico.
ano_plot <- ano_cat %>%
  filter(!is.na(categoria)) %>%
  mutate(categoria = factor(categoria, levels = cat_levels),
         ano = factor(ano))

totais_ano <- ano_cat %>% distinct(ano, total_cod12_ano)

p1 <- ggplot(ano_plot, aes(x = ano, y = pct_cod12_ano / 100, fill = categoria)) +
  geom_col(width = 0.74, color = 'white', linewidth = 0.7) +
  geom_text(aes(label = ifelse(pct_cod12_ano >= 5, fmt_pct1(pct_cod12_ano), '')),
            position = position_stack(vjust = 0.5), color = 'white',
            fontface = 'bold', size = 5.2, lineheight = 0.9) +
  geom_text(data = totais_ano,
            aes(x = factor(ano), y = 1.02, label = fmt_mi(total_cod12_ano)),
            inherit.aes = FALSE, fontface = 'bold', size = 5.1) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                     limits = c(0, 1.08),
                     expand = expansion(mult = c(0, 0.02))) +
  scale_fill_manual(values = cat_colors, drop = FALSE) +
  labs(
    title = 'Composição anual das emendas do COD 12 (2022-2026)',
    subtitle = 'Participação no valor do COD 12 em cada exercício; valores sobre as barras em R$',
    x = 'Ano da emenda',
    y = 'Participação no COD 12 do ano',
    fill = 'Modalidade',
    caption = '108 emendas; R$ 23.990.135. Cada barra soma 100% do ano; segmentos abaixo de 5% ficam sem rótulo. Outros respeita as decisões manuais.'
  ) +
  theme_minimal(base_size = 16) +
  theme(
    legend.position = 'bottom',
    panel.grid.minor = element_blank(),
    axis.title.x = element_text(face = 'bold'),
    axis.title.y = element_text(face = 'bold'),
    plot.title = element_text(face = 'bold', size = 21),
    plot.subtitle = element_text(size = 12.5),
    plot.caption = element_text(hjust = 0)
  )

ggsave(file.path(OUT, '12_cod12_01_composicao_anual.png'), p1, width = 16, height = 10, dpi = 320, bg = 'white')
ggsave(file.path(OUT, '12_cod12_01_composicao_anual.pdf'), p1, width = 16, height = 10, bg = 'white')
write_csv(ano_cat, file.path(OUT, '12_cod12_01_dados_do_grafico_anual.csv'))
message('[12 COD12] ETAPA 1/3 - Grafico anual mantido e exportado')

# =========================
# ETAPA 5 - Agregados partidários Zucco
# =========================
painel_z <- painel %>%
  filter(!is.na(zucco_final), valor_cod12 > 0)

if (nrow(painel_z) == 0) stop('Nao ha perfis com COD 12 e Zucco-Power no painel do script 10.')

ag_partido <- painel_z %>%
  group_by(sigla_partido, zucco_final) %>%
  summarise(
    valor_V = sum(valor_V, na.rm = TRUE),
    valor_I = sum(valor_I, na.rm = TRUE),
    valor_D = sum(valor_D, na.rm = TRUE),
    valor_O = sum(valor_O, na.rm = TRUE),
    cod12_partido = sum(valor_cod12, na.rm = TRUE),
    n_perfis = n(),
    .groups = 'drop'
  ) %>%
  mutate(
    pct_V = 100 * valor_V / cod12_partido,
    pct_I = 100 * valor_I / cod12_partido,
    pct_D = 100 * valor_D / cod12_partido,
    pct_O = 100 * valor_O / cod12_partido
  )

ag_long <- ag_partido %>%
  transmute(
    sigla_partido, zucco_final, n_perfis, cod12_partido,
    `Videomonitoramento` = valor_V,
    `Segurança institucional` = valor_I,
    `Violência contra mulheres, de gênero e doméstica/familiar` = valor_D,
    `Outros / não identificável` = valor_O
  ) %>%
  pivot_longer(cols = c(`Videomonitoramento`, `Segurança institucional`,
                        `Violência contra mulheres, de gênero e doméstica/familiar`,
                        `Outros / não identificável`),
               names_to = 'categoria', values_to = 'valor_modalidade') %>%
  group_by(sigla_partido, zucco_final, n_perfis, cod12_partido) %>%
  mutate(percentual = 100 * valor_modalidade / unique(cod12_partido)) %>%
  ungroup() %>%
  filter(valor_modalidade > 0) %>%
  mutate(categoria = factor(categoria, levels = cat_levels))

# -------------------------
# Tabela principal (15 partidos)
# -------------------------
moda_tbl <- ag_long %>%
  group_by(sigla_partido, zucco_final, cod12_partido) %>%
  arrange(desc(percentual), desc(valor_modalidade), .by_group = TRUE) %>%
  slice(1) %>%
  ungroup() %>%
  mutate(
    Partido = sigla_partido,
    `Zucco-Power` = fmt_zucco(zucco_final),
    `Valor total do COD 12` = fmt_brl0(cod12_partido),
    categoria_texto = case_when(
      categoria == 'Videomonitoramento' ~ 'videomonitoramento',
      categoria == 'Segurança institucional' ~ 'segurança institucional',
      categoria == 'Violência contra mulheres, de gênero e doméstica/familiar' ~ 'violência de gênero/doméstica',
      categoria == 'Outros / não identificável' ~ 'outros/não identificável',
      TRUE ~ as.character(categoria)
    ),
    `Modalidade dominante dentro de seu COD 12` = paste0(fmt_pct1(percentual), ' em ', categoria_texto),
    observacao = ifelse(percentual < 50, 'Modalidade dominante abaixo de 50% do COD 12 do partido', '')
  ) %>%
  arrange(zucco_final) %>%
  select(Partido, `Zucco-Power`, `Valor total do COD 12`, `Modalidade dominante dentro de seu COD 12`,
         observacao, zucco_final, percentual, valor_modalidade, cod12_partido)

write_csv(moda_tbl, file.path(OUT, '12_cod12_02_tabela_modalidade_dominante_partido.csv'))
write_csv(moda_tbl, file.path(OUT, '12_cod12_02_tabela_modalidade_dominante_partido_com_valor.csv'))

rodape_tabela <- 'Modalidade dominante = a maior fatia do COD 12 do partido, mesmo se inferior a 50%. Percentuais ponderados pelos valores monetários; somente partidos com escore Zucco-Power.'

plot_table_cod12(
  tab = moda_tbl %>% select(Partido, `Zucco-Power`, `Valor total do COD 12`, `Modalidade dominante dentro de seu COD 12`),
  titulo = 'COD 12: modalidade dominante por partido',
  subtitulo = 'Quinze partidos com COD 12 e posição Zucco-Power; ordenados pela escala ideológica',
  rodape = rodape_tabela,
  arquivo_png = file.path(OUT, '12_cod12_02_tabela_todos_15_partidos_com_valor.png'),
  arquivo_pdf = file.path(OUT, '12_cod12_02_tabela_todos_15_partidos_com_valor.pdf')
)

# Opcional: mantém também a tabela ilustrativa de 6 partidos, agora igualmente com valor.
partidos_seis <- c('PSOL', 'PT', 'CIDADANIA', 'PL', 'UNIAO', 'NOVO')
moda_tbl_6 <- moda_tbl %>% filter(Partido %in% partidos_seis)
write_csv(moda_tbl_6, file.path(OUT, '12_cod12_02_tabela_seis_partidos_com_valor.csv'))

plot_table_cod12(
  tab = moda_tbl_6 %>% select(Partido, `Zucco-Power`, `Valor total do COD 12`, `Modalidade dominante dentro de seu COD 12`),
  titulo = 'COD 12: modalidade dominante por partido',
  subtitulo = 'Recorte dos seis partidos da tabela ilustrativa enviada pelo autor',
  rodape = rodape_tabela,
  arquivo_png = file.path(OUT, '12_cod12_02_tabela_seis_partidos_com_valor.png'),
  arquivo_pdf = file.path(OUT, '12_cod12_02_tabela_seis_partidos_com_valor.pdf'),
  width = 17
)

message('[12 COD12] ETAPA 2/3 - Tabelas (CSV, PNG e PDF) exportadas com a coluna de valor monetario do COD 12 por partido')

# =========================
# ETAPA 6 - Gráfico de bolhas horizontais
# =========================
# Cada bolha = partido x modalidade.
# Tamanho = valor destinado pelo partido à modalidade.
# Rótulos: seis partidos do recorte ilustrativo.

rotulos_partidos <- c('PSOL', 'PT', 'CIDADANIA', 'PL', 'UNIAO', 'NOVO')
rotulos <- ag_long %>%
  filter(sigla_partido %in% rotulos_partidos) %>%
  group_by(sigla_partido) %>%
  arrange(desc(valor_modalidade), .by_group = TRUE) %>%
  slice(1) %>%
  ungroup() %>%
  mutate(label = sigla_partido)

p2 <- ggplot(ag_long, aes(x = zucco_final, y = categoria)) +
  geom_vline(xintercept = 0, linetype = 'dashed', color = 'gray45') +
  geom_point(aes(size = valor_modalidade, fill = categoria), shape = 21,
             color = 'black', alpha = 0.82, stroke = 0.35) +
  scale_fill_manual(values = cat_colors, guide = 'none') +
  scale_size_area(max_size = 18,
                  breaks = c(250000, 1000000, 3000000),
                  labels = c('R$ 0,25 mi', 'R$ 1,00 mi', 'R$ 3,00 mi'),
                  name = 'Valor da modalidade no partido') +
  scale_x_continuous(limits = c(-1.05, 1.05),
                     breaks = c(-1, -0.5, 0, 0.5, 1),
                     labels = function(x) format(x, decimal.mark = ',', nsmall = 1)) +
  labs(
    title = 'Modalidades do COD 12 ao longo da escala continua Zucco-Power',
    subtitle = 'Cada bolha representa um partido. O tamanho da bolha e proporcional ao valor da modalidade dentro do COD 12 do partido.',
    x = 'Posicao do partido: esquerda (-1) | centro (0) | direita (+1)',
    y = NULL,
    caption = paste0('Partidos com Zucco-Power e gasto no COD 12: ', n_distinct(ag_long$sigla_partido),
                     '. Cobertura monetaria: ', fmt_mi(sum(ag_partido$cod12_partido, na.rm = TRUE)),
                     ' com escore Zucco (83,95% do COD 12). Valores por partido e modalidade.')
  ) +
  theme_minimal(base_size = 16) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = 'bold', size = 21),
    plot.subtitle = element_text(size = 12.5),
    legend.position = 'bottom',
    axis.title.x = element_text(face = 'bold'),
    axis.text.y = element_text(face = 'bold'),
    plot.caption = element_text(hjust = 0)
  )

if (has_ggrepel) {
  p2 <- p2 +
    ggrepel::geom_label_repel(
      data = rotulos,
      aes(label = label),
      size = 4.0,
      label.size = 0.25,
      label.padding = unit(0.12, 'lines'),
      min.segment.length = 0,
      box.padding = 0.25,
      point.padding = 0.15,
      seed = 123,
      show.legend = FALSE
    )
} else {
  p2 <- p2 +
    geom_label(data = rotulos, aes(label = label), size = 3.8, label.size = 0.25,
               nudge_y = 0.12, show.legend = FALSE)
}

ggsave(file.path(OUT, '12_cod12_03_bolhas_horizontais_zucco.png'), p2, width = 16, height = 9.5, dpi = 320, bg = 'white')
ggsave(file.path(OUT, '12_cod12_03_bolhas_horizontais_zucco.pdf'), p2, width = 16, height = 9.5, bg = 'white')
write_csv(ag_long, file.path(OUT, '12_cod12_03_dados_bolhas_horizontais.csv'))
message('[12 COD12] ETAPA 3/3 - Grafico de bolhas horizontais e dados exportados')

cat('\n========== AMOSTRAS E SAIDAS ==========')
cat('\nGrafico 1: composicao anual | 108 emendas | 5 anos | R$ 23.990.135')
cat('\nTabela  : partidos com Zucco e COD12 > 0 |', nrow(moda_tbl), 'partidos')
cat('\nGrafico 2: bolhas horizontais |', n_distinct(ag_long$sigla_partido), 'partidos |', nrow(ag_long), 'combinacoes partido-modalidade com valor > 0')
cat('\nARQUIVOS EM:', OUT)
cat('\n12_cod12_01_composicao_anual.png/.pdf')
cat('\n12_cod12_02_tabela_modalidade_dominante_partido.csv')
cat('\n12_cod12_02_tabela_modalidade_dominante_partido_com_valor.csv')
cat('\n12_cod12_02_tabela_todos_15_partidos_com_valor.png/.pdf')
cat('\n12_cod12_02_tabela_seis_partidos_com_valor.png/.pdf/.csv')
cat('\n12_cod12_03_bolhas_horizontais_zucco.png/.pdf')
cat('\n12_cod12_01_dados_do_grafico_anual.csv')
cat('\n12_cod12_03_dados_bolhas_horizontais.csv')
cat('\n')
