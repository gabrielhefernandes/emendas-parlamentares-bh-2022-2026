# TCC BH 2022--2026: diagnostico de arquivos, sem executar analises.
raiz <- normalizePath(Sys.getenv("TCC_BH_RAIZ", unset=getwd()),
                      winslash="/", mustWork=TRUE)
nomes_anuais <- sprintf("codificacao_emendas_%d_FINAL_21-09-2026.xlsx", 2022:2026)
fontes <- c(file.path(raiz, nomes_anuais),
            file.path(raiz, "BASE PARTIDOS GERAL.xlsx"))
raiz_orga <- c(file.path(raiz, "dados", "codificados", nomes_anuais),
               file.path(raiz, "dados", "partidos", "BASE PARTIDOS GERAL.xlsx"))
bloco_plano <- all(file.exists(fontes))
bloco_orga <- all(file.exists(raiz_orga))
# Tambem aceita bases codificadas/partidos em diferentes pastas, como a configuracao.
bloco_misto <- all(file.exists(file.path(raiz, nomes_anuais))) &&
  file.exists(file.path(raiz, "dados", "partidos", "BASE PARTIDOS GERAL.xlsx")) ||
  all(file.exists(file.path(raiz, "dados", "codificados", nomes_anuais))) &&
  file.exists(file.path(raiz, "BASE PARTIDOS GERAL.xlsx"))
if (!(bloco_plano || bloco_orga || bloco_misto)) {
  warning("As cinco bases e BASE PARTIDOS GERAL.xlsx nao foram encontradas numa disposicao valida.")
} else message("[OK] Fontes XLSX localizadas")
base_scripts <- file.path(raiz, "scripts", "R")
files <- c(
  "01_importacao_padronizacao/_config_funcoes.R",
  "01_importacao_padronizacao/01_preparar.bases.R",
  paste0("07_analises/", c("02_ideologia_partidos.R", "03_composicao_tematica.R",
    "04_publicos_alvo.R", "05_diagnostico_influencia.R",
    "06_dimensoes_vereanca.R", "08_modelos_territoriais_CR2.R",
    "09_interacao_saude_CR2.R", "10_decompor_COD12_vereador_ano.R",
    "12_tabela_e_bolhas_COD12_zucco.R")),
  "06_mapas_eleitorais/01_mapas_eleitorais_emendas.R",
  "07_analises/insumos/COD12_mapa_manual_108.csv",
  "07_analises/insumos/COD12_decisoes_manuais_17_aprovadas.csv",
  "executar_analises_tcc.R", "executar_territorial_tcc.R"
)
p <- file.path(base_scripts, files)
faltantes <- p[!file.exists(p)]
if(length(faltantes)) stop("Arquivos faltantes:\n",paste(faltantes,collapse="\n"),call.=FALSE)
message("[OK] Todos os ",length(files)," scripts e insumos esperados estao instalados")
message("[OK] Estrutura do pacote instalada em ",raiz)
