# TCC BH 2022–2026 – interação saúde × concentração eleitoral (raio 2 km)
# INFERÊNCIA: CR2 (alvo de covariância identidade), Satterthwaite,
# clusters = vereador estável. Não altera bases originais.
#
# Execucao: a partir da raiz do repositorio, via scripts/R/executar_territorial_tcc.R
# Caminhos relativos ao projeto; nao execute setwd() para uma subpasta.
if (!requireNamespace('clubSandwich', quietly=TRUE)) {
  stop("Pacote clubSandwich ausente. Instale com install.packages('clubSandwich').",call.=FALSE)
}
raiz_rep <- normalizePath(Sys.getenv('TCC_BH_RAIZ', unset=getwd()), winslash='/', mustWork=TRUE)
saida_cr2 <- file.path(raiz_rep,'resultados','replicacao','territorial')
dir.create(saida_cr2,recursive=TRUE,showWarnings=FALSE)

arq <- file.path(raiz_rep,'dados','analiticos','02_BASE_ANALITICA_COM_PARTIDOS_OFICIAIS_2022_2026.csv')
ref <- file.path(raiz_rep,'dados','analiticos','referencias_cr2','01_RESULTADOS_INTERACAO_SAUDE_CR2.csv')
if (!file.exists(arq)) stop('Faltou a base analitica em dados/analiticos: ', arq)
if (!file.exists(ref)) stop('Faltou o arquivo de resultados esperados: ', ref)

ler_csv <- function(f) read.csv(f, sep=';', dec='.', fileEncoding='UTF-8-BOM', stringsAsFactors=FALSE, check.names=FALSE)
d <- ler_csv(arq)
d <- d[as.character(d$amostra_analitica)=='1',,drop=FALSE]
stopifnot(nrow(d) == 2351L, length(unique(d$vereador_estavel)) == 72L)

d$saude <- as.integer(d$saude_cap03)
d$y <- log(as.numeric(d$valor_alocado_rs))
d$x <- as.numeric(d$concentracao_pct_2000m)
d$x_saude <- d$x*d$saude
d$ln_nlocais <- log1p(as.numeric(d$n_locais_2000m))
d$fe_cap <- factor(d$macro_cap_ajustado)
# Na especificacao flexivel, CAP03 seria redundante com FE vereador-ano x saude.
# Reetiquetamos a categoria de saude para uma categoria nao-saude de referencia:
# isso evita uma dummy perfeitamente colinear sem alterar os valores estimados.
ref_cap_nao <- as.character(d$macro_cap_ajustado[d$saude==0])[1]
d$fe_cap_dentro_nao_saude <- factor(ifelse(d$saude==1,ref_cap_nao,as.character(d$macro_cap_ajustado)))
d$fe_vereador_ano <- factor(d$id_vereador_ano_recuperado)
d$fe_vereador_ano_setor <- interaction(d$fe_vereador_ano, d$saude, drop=TRUE)
d$ln_nlocais_nao <- d$ln_nlocais*(1-d$saude)
d$ln_nlocais_saude <- d$ln_nlocais*d$saude
d$cluster <- factor(d$vereador_estavel)

extrair_gl <- function(res) {
  tt <- as.data.frame(res)
  nomes <- c('df_Satt','d.f. (Satt)','df.Satt')
  achado <- intersect(nomes,names(tt))
  if (length(achado)!=1L) stop('Coluna gl nao reconhecida: ',paste(names(tt),collapse=', '))
  as.numeric(tt[[achado]][1])
}

rodar <- function(nome,formula) {
  fit <- lm(formula, data=d, na.action=na.fail)
  V2 <- clubSandwich::vcovCR(fit, cluster=d$cluster, type='CR2', target=rep(1,nobs(fit)))
  b_nao <- unname(coef(fit)['x'])
  b_delta <- unname(coef(fit)['x_saude'])
  b_saude <- b_nao+b_delta
  if (!all(is.finite(c(b_nao,b_delta)))) stop('A interacao nao foi identificada em ',nome)
  ep_delta <- sqrt(unname(V2['x_saude','x_saude']))
  tst <- clubSandwich::coef_test(fit, vcov=V2, test='Satterthwaite', coefs='x_saude')
  gl <- extrair_gl(tst)
  p <- 2*pt(-abs(b_delta/ep_delta),df=gl)
  saida <- data.frame(
    modelo=nome, n=nobs(fit), n_clusters=nlevels(d$cluster),
    beta_nao_saude=b_nao, beta_interacao_saude_menos_nao=b_delta,
    beta_saude=b_saude, efeito_nao_10pp_pct=100*expm1(10*b_nao),
    efeito_saude_10pp_pct=100*expm1(10*b_saude),
    ep_CR2_interacao=ep_delta, gl_Satterthwaite=gl, p_CR2_interacao=p
  )
  cat('\n',toupper(nome),' | N=',nobs(fit),' | clusters=',nlevels(d$cluster),'\n',sep='')
  cat(sprintf('Fora da saúde: beta = %.10f | efeito +10 pp = %.4f%%\n',b_nao,saida$efeito_nao_10pp_pct))
  cat(sprintf('Na saúde:     beta = %.10f | efeito +10 pp = %.4f%%\n',b_saude,saida$efeito_saude_10pp_pct))
  cat(sprintf('INTERAÇÃO:    beta = %.10f | EP CR2 = %.10f | gl = %.5f | p = %.6f\n',b_delta,ep_delta,gl,p))
  saida
}

# A) Efeitos fixos de vereador-ano, CAP e ln(nº estabelecimentos) comuns.
a <- rodar('comum', y ~ x + x_saude + ln_nlocais + fe_vereador_ano + fe_cap)

# B) Reproduz as inclinações dos modelos estimados separadamente:
#    efeitos fixos vereador-ano × setor, e controle n_locs × setor.
#    CR2 avalia a diferença usando a covariância entre todas as observações
#    do mesmo vereador, que as regressões separadas não fornecem diretamente.
b <- rodar('flexivel', y ~ x + x_saude + ln_nlocais_nao + ln_nlocais_saude +
                         fe_vereador_ano_setor + fe_cap_dentro_nao_saude)

res <- rbind(a,b)
esperado <- ler_csv(ref)
delta_ref <- esperado[esperado$termo=='diferenca_saude_menos_nao_saude',,drop=FALSE]
pos <- match(res$modelo,delta_ref$modelo)
if (anyNA(pos)) stop('Resultado esperado não encontrado para um dos modelos.')
res$dif_beta_Python <- res$beta_interacao_saude_menos_nao-delta_ref$coeficiente_por_1pp[pos]
res$dif_ep_Python <- res$ep_CR2_interacao-delta_ref$erro_padrao_cr2[pos]
res$dif_gl_Python <- res$gl_Satterthwaite-delta_ref$gl_satterthwaite[pos]
res$dif_p_Python <- res$p_CR2_interacao-delta_ref$p_cr2[pos]
res$confere <- with(res, abs(dif_beta_Python)<1e-7 & abs(dif_ep_Python)<1e-6 &
                    abs(dif_gl_Python)<0.05 & abs(dif_p_Python)<0.002)
write.csv2(res,file.path(saida_cr2,'03_VERIFICACAO_INTERACAO_R_VS_PYTHON.csv'),row.names=FALSE,fileEncoding='UTF-8')
cat('\nCOMPARACAO INDEPENDENTE COM PYTHON:\n')
print(res[,c('modelo','dif_beta_Python','dif_ep_Python','dif_gl_Python','dif_p_Python','confere')],row.names=FALSE,digits=8)
cat('\n',sum(res$confere),'de',nrow(res),'modelos coincidem com a referência numérica.\n',sep='')
cat('Versão R: ',as.character(getRversion()),' | clubSandwich: ',as.character(packageVersion('clubSandwich')),'\n',sep='')
