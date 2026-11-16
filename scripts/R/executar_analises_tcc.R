# Execucao sequencial da analise TEMATICA e do COD 12 do TCC BH 2022--2026.
# Execute: Rscript scripts/R/executar_analises_tcc.R
# Diretoria atual deve ser a raiz do repositorio ou defina TCC_BH_RAIZ.
raiz <- normalizePath(Sys.getenv("TCC_BH_RAIZ", unset=getwd()),
                      winslash="/", mustWork=TRUE)
# A configuracao aceita o layout plano do Windows (planilhas e partidos
# diretamente na raiz) e o layout organizado do GitHub. Confere nomes exatos.
config <- file.path(raiz, "scripts", "R", "01_importacao_padronizacao", "_config_funcoes.R")
if (!file.exists(config)) stop("Configuracao ausente: ", config, call.=FALSE)
Sys.setenv(TCC_BH_RAIZ=raiz)
source(config, encoding="UTF-8", local=FALSE)
# Confere as fontes selecionadas antes de executar a integracao.
invisible(lapply(c(unname(TCC_ENTRADAS_ESPERADAS), TCC_PARTIDOS_ARQUIVO), localizar_arquivo))
preparacao <- file.path(raiz,"scripts","R","01_importacao_padronizacao","01_preparar.bases.R")
analises <- file.path(raiz,"scripts","R","07_analises")
ordem <- c("01_preparar.bases.R", "02_ideologia_partidos.R",
           "03_composicao_tematica.R", "04_publicos_alvo.R",
           "05_diagnostico_influencia.R", "06_dimensoes_vereanca.R",
           "10_decompor_COD12_vereador_ano.R",
           "12_tabela_e_bolhas_COD12_zucco.R")
# Conferir TODOS os scripts antes de iniciar a execucao.
# Assim uma extracao parcial do ZIP nao causa falhas entre as etapas.
caminhos_scripts <- vapply(ordem, function(arq) {
  if (identical(arq, "01_preparar.bases.R")) preparacao else file.path(analises, arq)
}, character(1), USE.NAMES=TRUE)
ausentes <- caminhos_scripts[!file.exists(caminhos_scripts)]
if (length(ausentes)) {
  stop("INSTALACAO INCOMPLETA: faltam ", length(ausentes),
       " scripts no diretorio de replicacao:\n  - ",
       paste(ausentes, collapse="\n  - "),
       "\nExtraia a pasta scripts INTEIRA do pacote definitivo de replicabilidade",
       " em ", raiz, " mantendo as subpastas.", call.=FALSE)
}
# Insumos manuais dos resultados de COD 12.
insumos_cod12 <- file.path(analises, "insumos", c(
  "COD12_mapa_manual_108.csv",
  "COD12_decisoes_manuais_17_aprovadas.csv"
))
ausentes_cod12 <- insumos_cod12[!file.exists(insumos_cod12)]
if (length(ausentes_cod12)) stop("Insumos COD12 ausentes:\n  - ",
  paste(ausentes_cod12, collapse="\n  - "), call.=FALSE)
message("[INSTALACAO OK] Os ", length(caminhos_scripts),
        " scripts tematicos/COD12 e os 2 insumos manuais foram encontrados.")
for (arq in ordem) {
  caminho <- caminhos_scripts[[arq]]
  message("\n========== EXECUTANDO ",arq," ==========\n")
  source(caminho,encoding="UTF-8",local=FALSE)
}
message("\nConcluido: resultados em ",file.path(raiz,"resultados","replicacao","analises"))
