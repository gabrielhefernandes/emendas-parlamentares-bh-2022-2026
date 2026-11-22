# Reproduz as Tabelas 7 e 8 e o teste formal de interacao de saude (CR2).
# Executar na raiz: Rscript scripts/R/executar_territorial_tcc.R
raiz_rep <- normalizePath(Sys.getenv("TCC_BH_RAIZ", unset=getwd()), winslash="/", mustWork=TRUE)
if (!dir.exists(file.path(raiz_rep,"dados","analiticos"))) {
  stop("Execute da raiz do repositorio ou configure TCC_BH_RAIZ.",call.=FALSE)
}
Sys.setenv(TCC_BH_RAIZ=raiz_rep)
for (nome in c("08_modelos_territoriais_CR2.R",
               "09_interacao_saude_CR2.R")) {
  script <- file.path(raiz_rep,"scripts","R","07_analises",nome)
  if (!file.exists(script)) stop("Script ausente: ",script,call.=FALSE)
  message("\n=== TCC BH: ",nome," ===\n")
  source(script,encoding="UTF-8",local=FALSE)
}
message("\nResultados CR2 em: ",file.path(raiz_rep,"resultados","replicacao","territorial"))
