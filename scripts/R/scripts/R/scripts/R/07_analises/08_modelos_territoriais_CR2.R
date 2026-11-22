# ============================================================================
# TCC BH - Emendas municipais 2022-2026
# REPRODUCAO INDEPENDENTE DA INFERENCIA CR2 / SATTERTHWAITE EM R
#
# Entrada: base analitica da Etapa CR2 (CSV ja auditado).
# Referencias: resultados calculados anteriormente em Python.
# Metodo: MQO + efeitos fixos vereador-ano e macrocategoria CAP;
#         CR2 com alvo identidade, clusters por vereador;
#         teste t com graus de liberdade Satterthwaite.
#
# Execucao: a partir da raiz do repositorio, via scripts/R/executar_territorial_tcc.R
# Caminhos relativos ao projeto; nao execute setwd() para uma subpasta.
#
# Nao modifica a base de entrada nem os arquivos originais do TCC.
# So grava verificacao_cr2_resultados_R.csv e verificacao_cr2_comparacao.csv.
# ============================================================================

# Alterar para TRUE se desejar rodar tambem os sete testes de robustez de 2 km.
EXECUTAR_ROBUSTEZ <- TRUE

if (!requireNamespace('clubSandwich', quietly=TRUE)) {
  stop("Pacote clubSandwich ausente. Instale com install.packages('clubSandwich').", call.=FALSE)
}
raiz_rep <- normalizePath(Sys.getenv('TCC_BH_RAIZ', unset=getwd()), winslash='/', mustWork=TRUE)
saida_cr2 <- file.path(raiz_rep,'resultados','replicacao','territorial')
dir.create(saida_cr2,recursive=TRUE,showWarnings=FALSE)

arquivo_base <- file.path(raiz_rep,'dados','analiticos','02_BASE_ANALITICA_COM_PARTIDOS_OFICIAIS_2022_2026.csv')
arquivo_ref_principal <- file.path(raiz_rep,'dados','analiticos','referencias_cr2','01_TRES_RAIOS_CR2_SATTERTHWAITE.csv')
arquivo_ref_robustez <- file.path(raiz_rep,'dados','analiticos','referencias_cr2','02_ROBUSTEZ_2KM_CR2_SATTERTHWAITE.csv')

if (!file.exists(arquivo_base)) {
  stop('Arquivo nao localizado: ', arquivo_base,
       '\nVerifique a pasta dados/analiticos na raiz do repositorio.')
}

# Os CSVs do projeto usam separador ; e ponto como separador decimal.
ler_csv <- function(arq) {
  read.csv(arq, sep=';', dec='.', fileEncoding='UTF-8-BOM',
           stringsAsFactors=FALSE, check.names=FALSE)
}
base <- ler_csv(arquivo_base)
d <- base[as.character(base$amostra_analitica)=='1', , drop=FALSE]

colunas <- c('valor_alocado_rs', 'vereador_estavel',
             'id_vereador_ano_recuperado', 'macro_cap_ajustado',
             'concentracao_pct_1000m', 'concentracao_pct_2000m',
             'concentracao_pct_5000m', 'n_locais_1000m',
             'n_locais_2000m', 'n_locais_5000m', 'ano_emenda',
             'saude_cap03', 'multilocalidade',
             'sensivel_coordenadas_tse_3_escolas')
faltando <- setdiff(colunas, names(d))
if (length(faltando)>0) stop('Colunas ausentes: ', paste(faltando, collapse=', '))
if (nrow(d)!=2351) stop('Esperadas 2351 observacoes; encontradas ', nrow(d))
if (anyNA(d[,colunas]) || any(d$valor_alocado_rs<=0)) {
  stop('A amostra tem valores ausentes ou valores monetarios nao positivos.')
}
if (length(unique(d$vereador_estavel))!=72) {
  stop('Esperados 72 vereadores; confira a base de entrada.')
}
cat('\nBASE OK | N=',nrow(d),
    '| vereadores=',length(unique(d$vereador_estavel)),
    '| vereador-ano=',length(unique(d$id_vereador_ano_recuperado)), '\n',sep='')

# Extrai os graus de liberdade devolvidos pelo teste Satterthwaite.
extrair_gl <- function(teste) {
  tb <- as.data.frame(teste)
  nomes <- names(tb)
  candidatos <- c('df_Satt','d.f. (Satt)','df.Satt')
  encontrado <- candidatos[candidatos %in% nomes]
  if (length(encontrado)!=1L) {
    stop('Nao reconheci a coluna de graus de liberdade do clubSandwich. ',
         'Colunas recebidas: ', paste(nomes, collapse=', '))
  }
  as.numeric(tb[[encontrado]][1])
}

# Este modelo reproduz EXATAMENTE as covariaveis dos resultados em Python.
estimar <- function(dados, raio, nome, incluir_cap=TRUE) {
  tmp <- dados
  tmp$y <- log(as.numeric(tmp$valor_alocado_rs))
  tmp$x <- as.numeric(tmp[[paste0('concentracao_pct_',raio,'m')]])
  tmp$ln_nlocais <- log1p(as.numeric(tmp[[paste0('n_locais_',raio,'m')]]))
  tmp$fe_vereador_ano <- factor(tmp$id_vereador_ano_recuperado)
  tmp$fe_cap <- factor(tmp$macro_cap_ajustado)
  tmp$grupo <- factor(tmp$vereador_estavel)

  if (anyNA(tmp[,c('x','y','ln_nlocais','fe_vereador_ano','grupo')])) {
    stop('Faltam observacoes no modelo ', nome)
  }

  # Em saude-only o CAP 03 e constante. Nesse teste retira-se o FE de CAP.
  formula <- if (incluir_cap) {
    y ~ x + ln_nlocais + fe_vereador_ano + fe_cap
  } else {
    y ~ x + ln_nlocais + fe_vereador_ano
  }

  ajuste <- lm(formula, data=tmp, na.action=na.fail)
  N <- nobs(ajuste)
  G <- nlevels(tmp$grupo)
  beta <- unname(coef(ajuste)['x'])
  if (!is.finite(beta)) stop('O efeito x nao e estimavel em ', nome)

  # target=rep(1,N): covariancia-identidade sob o modelo de trabalho CR2.
  V2 <- clubSandwich::vcovCR(ajuste, cluster=tmp$grupo, type='CR2',
                             target=rep(1,N))
  t2 <- clubSandwich::coef_test(ajuste, vcov=V2,
                                test='Satterthwaite', coefs='x')
  ep2 <- sqrt(unname(V2['x','x']))
  gl2 <- extrair_gl(t2)
  tstat <- beta/ep2
  p2 <- 2*pt(-abs(tstat), df=gl2)
  crit <- qt(0.975,df=gl2)
  inferior <- beta-crit*ep2
  superior <- beta+crit*ep2

  # CR1S apenas como comparacao com as etapas anteriores (naive-t: G - 1).
  V1S <- clubSandwich::vcovCR(ajuste, cluster=tmp$grupo, type='CR1S')
  ep1s <- sqrt(unname(V1S['x','x']))
  p1s <- 2*pt(-abs(beta/ep1s),df=G-1)

  transformar_10pp <- function(b) 100*expm1(10*b)
  saida <- data.frame(
    especificacao=nome, raio_m=raio, n_pares=N,
    clusters_vereador=G, grupos_vereador_ano=nlevels(tmp$fe_vereador_ano),
    posto_total=ajuste$rank,
    beta_por_pp=beta, efeito_10pp_pct=transformar_10pp(beta),
    erro_padrao_cr1s=ep1s, p_cr1s_t_gmenos1=p1s,
    erro_padrao_cr2=ep2, gl_satterthwaite=gl2,
    t_cr2=tstat, p_cr2_satterthwaite=p2,
    ic95_beta_inf=inferior, ic95_beta_sup=superior,
    ic95_efeito_10pp_inf_pct=transformar_10pp(inferior),
    ic95_efeito_10pp_sup_pct=transformar_10pp(superior),
    stringsAsFactors=FALSE
  )
  cat(sprintf('\n%s | raio=%d m | N=%d | G=%d\n',nome,raio,N,G))
  cat(sprintf('  beta=%.10f | efeito 10pp=%.5f%%\n',beta,saida$efeito_10pp_pct))
  cat(sprintf('  CR2: EP=%.10f | gl=%.5f | p=%.6f\n',ep2,gl2,p2))
  cat(sprintf('  CR1S: EP=%.10f | p=%.6f\n',ep1s,p1s))
  saida
}

# 1, 2 e 5 km: MESMAS observacoes e MESMOS controles.
principais <- do.call(rbind,lapply(c(1000L,2000L,5000L),function(r) {
  estimar(d, r, 'A01_FE_VEREADOR_ANO',incluir_cap=TRUE)
}))

# Correcoes para multiplas comparacoes APENAS dos tres raios principais.
principais$q_bh_cr2_3raios <- p.adjust(principais$p_cr2_satterthwaite,method='BH')
principais$p_holm_cr2_3raios <- p.adjust(principais$p_cr2_satterthwaite,method='holm')

# Testes de robustez: opcional, desativado por padrao para executar mais rapido.
robustez <- NULL
if (EXECUTAR_ROBUSTEZ) {
  cenarios <- list(
    list('A03_FE_VEREADOR_ANO_NAO_SAUDE',
         d[as.character(d$saude_cap03)=='0',,drop=FALSE],TRUE),
    list('A04_FE_VEREADOR_ANO_SAUDE',
         d[as.character(d$saude_cap03)=='1',,drop=FALSE],FALSE),
    list('A05_FE_VEREADOR_ANO_SEM_2025',
         d[as.character(d$ano_emenda)!='2025',,drop=FALSE],TRUE),
    list('A06_FE_VEREADOR_ANO_SEM_2026',
         d[as.character(d$ano_emenda)!='2026',,drop=FALSE],TRUE),
    list('A07_FE_VEREADOR_ANO_SO_EMENDAS_LOCAL_UNICO',
         d[as.character(d$multilocalidade)=='0',,drop=FALSE],TRUE),
    list('A08_FE_VEREADOR_ANO_SEM_SENSIVEIS_COORDENADAS',
         d[as.character(d$sensivel_coordenadas_tse_3_escolas)=='0',,drop=FALSE],TRUE)
  )
  # Separa o 1% superior a partir do ponto de corte da AMOSTRA TOTAL.
  corte <- unname(quantile(as.numeric(d$valor_alocado_rs),0.99))
  cenarios[[length(cenarios)+1L]] <- list(
    'A09_FE_VEREADOR_ANO_EXCLUI_1PC_MAIORES',
    d[d$valor_alocado_rs<=corte,,drop=FALSE],TRUE)
  robustez <- do.call(rbind,lapply(cenarios,function(z) {
    estimar(z[[2]],2000L,z[[1]],incluir_cap=z[[3]])
  }))
}

# As colunas de correcao BH/Holm aplicam-se somente aos tres raios
# principais. Os modelos de robustez possuem as mesmas estatisticas, mas
# nao recebem essas correcoes. Acrescentar NA explicitamente ANTES de
# concatenar as tabelas evita erro de rbind por quantidades de colunas
# diferentes; nao modifica nenhum coeficiente ou p-valor ja estimado.
if (!is.null(robustez)) {
  robustez$q_bh_cr2_3raios <- NA_real_
  robustez$p_holm_cr2_3raios <- NA_real_
  robustez <- robustez[,names(principais),drop=FALSE]
}

# Compara os resultados R com a referencia calculada anteriormente em Python.
comparar <- function(result, arquivo) {
  if (is.null(result) || !file.exists(arquivo)) return(NULL)
  ref <- ler_csv(arquivo)
  chave <- paste(result$especificacao,result$raio_m,sep='|')
  chave_ref <- paste(ref$especificacao,ref$raio_m,sep='|')
  idx <- match(chave,chave_ref)
  if (anyNA(idx)) stop('Modelo nao encontrado no arquivo de referencia: ',
                       paste(chave[is.na(idx)],collapse=', '))
  saida <- data.frame(
    especificacao=result$especificacao,
    raio_m=result$raio_m,
    n_R=result$n_pares,
    n_Python=ref$n_pares[idx],
    beta_R=result$beta_por_pp,
    beta_Python=ref$beta_por_pp[idx],
    ep_CR2_R=result$erro_padrao_cr2,
    ep_CR2_Python=ref$erro_padrao_cr2[idx],
    gl_R=result$gl_satterthwaite,
    gl_Python=ref$gl_satterthwaite[idx],
    p_R=result$p_cr2_satterthwaite,
    p_Python=ref$p_cr2_satterthwaite[idx],
    stringsAsFactors=FALSE
  )
  saida$dif_beta <- saida$beta_R-saida$beta_Python
  saida$dif_EP <- saida$ep_CR2_R-saida$ep_CR2_Python
  saida$dif_gl <- saida$gl_R-saida$gl_Python
  saida$dif_p <- saida$p_R-saida$p_Python
  # Tolerancias para arredondamento/algoritmos numericos distintos.
  saida$confere <- with(saida,
    n_R==n_Python & abs(dif_beta)<1e-7 & abs(dif_EP)<1e-6 &
    abs(dif_gl)<0.05 & abs(dif_p)<0.002)
  saida
}

comp <- rbind(comparar(principais,arquivo_ref_principal),
              comparar(robustez,arquivo_ref_robustez))

write.csv2(rbind(principais, robustez),
           file.path(saida_cr2,'verificacao_cr2_resultados_R.csv'),row.names=FALSE,
           fileEncoding='UTF-8')
if (!is.null(comp)) {
  write.csv2(comp, file.path(saida_cr2,'verificacao_cr2_comparacao.csv'),row.names=FALSE,
             fileEncoding='UTF-8')
  cat('\n============== COMPARACAO R x PYTHON ==============\n')
  print(comp[,c('especificacao','raio_m','dif_beta','dif_EP','dif_gl',
                'dif_p','confere')],row.names=FALSE,digits=7)
  if (all(comp$confere)) {
    cat('\nTODOS OS RESULTADOS CONFEREM COM AS TOLERANCIAS DEFINIDAS.\n')
  } else {
    stop('Uma ou mais comparacoes CR2 R x Python divergiram. Verifique a auditoria em ',saida_cr2,call.=FALSE)
  }
}
cat('\nArquivos gerados em resultados/replicacao/territorial:\n',
    '  verificacao_cr2_resultados_R.csv\n',
    '  verificacao_cr2_comparacao.csv\n',sep='')
cat('\nVersao R: ',as.character(getRversion()),
    ' | clubSandwich: ',as.character(packageVersion('clubSandwich')),'\n',sep='')
