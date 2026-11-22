# TCC BH - Configuracao compartilhada de reproducao.
# Os seis arquivos originais podem ficar DIRETAMENTE na raiz do projeto,
# como em C:/TCC_BH_EMENDAS/replicacao, ou nas pastas padrao do GitHub.
# Prioridade explicita: pasta raiz completa -> dados/codificados completa.
# Nao ha pesquisa recursiva nem mistura de planilhas de pastas diferentes.
# Nenhuma funcao altera arquivos de entrada.

TCC_RAIZ <- normalizePath(Sys.getenv("TCC_BH_RAIZ", unset=getwd()),
                          winslash="/", mustWork=TRUE)
TCC_SCRIPTS <- file.path(TCC_RAIZ, "scripts", "R", "07_analises")
TCC_SAIDAS <- file.path(TCC_RAIZ, "resultados", "replicacao", "analises")
TCC_ENTRADAS_ESPERADAS <- c(
  `2022` = "codificacao_emendas_2022_FINAL_21-09-2026.xlsx",
  `2023` = "codificacao_emendas_2023_FINAL_21-09-2026.xlsx",
  `2024` = "codificacao_emendas_2024_FINAL_21-09-2026.xlsx",
  `2025` = "codificacao_emendas_2025_FINAL_21-09-2026.xlsx",
  `2026` = "codificacao_emendas_2026_FINAL_21-09-2026.xlsx"
)
TCC_PARTIDOS_ARQUIVO <- "BASE PARTIDOS GERAL.xlsx"
TCC_ESPERADO_N_ANO <- c(`2022`=610L,`2023`=883L,`2024`=1089L,`2025`=1063L,`2026`=1151L)

# Seleciona um unico conjunto completo das cinco fontes. Nao combinar anos
# da raiz com anos de dados/codificados: isso misturaria versoes da pesquisa.
locais_codificacao <- c(
  TCC_RAIZ,
  file.path(TCC_RAIZ, "dados", "codificados")
)
fonte_completa <- vapply(locais_codificacao, function(pasta) {
  all(file.exists(file.path(pasta, unname(TCC_ENTRADAS_ESPERADAS))))
}, logical(1))
if (!any(fonte_completa)) {
  diagnostico <- vapply(locais_codificacao, function(pasta) {
    faltam <- unname(TCC_ENTRADAS_ESPERADAS)[
      !file.exists(file.path(pasta, unname(TCC_ENTRADAS_ESPERADAS)))]
    paste0("Em ", pasta, ": faltam ", paste(faltam, collapse=", "))
  }, character(1))
  stop("Nao encontrei as cinco planilhas juntas em uma pasta.\n",
       paste(diagnostico, collapse="\n"), "\n",
       "Use nomes sem sufixos (1), (2) etc. ",
       "A pasta raiz e dados/codificados sao aceitas.", call.=FALSE)
}
TCC_CODING <- locais_codificacao[which(fonte_completa)[1L]]

# Base partidaria: raiz tem prioridade; alternativa: dados/partidos.
locais_partidos <- c(
  TCC_RAIZ,
  file.path(TCC_RAIZ, "dados", "partidos")
)
partidos_disponivel <- file.exists(file.path(locais_partidos, TCC_PARTIDOS_ARQUIVO))
if (!any(partidos_disponivel)) {
  stop("Nao encontrei ", TCC_PARTIDOS_ARQUIVO, " em:\n",
       paste(locais_partidos, collapse="\n"), call.=FALSE)
}
TCC_PARTIDOS_PASTA <- locais_partidos[which(partidos_disponivel)[1L]]

message("[CONFIG] Planilhas anuais: ", TCC_CODING)
message("[CONFIG] Base de partidos: ", file.path(TCC_PARTIDOS_PASTA, TCC_PARTIDOS_ARQUIVO))

verificar_pacotes <- function(pacotes) {
  ausentes <- pacotes[!vapply(pacotes, requireNamespace, logical(1), quietly = TRUE)]
  if (length(ausentes)) stop(
    "Faltam pacotes R: ", paste(ausentes, collapse=", "),
    ". Instale uma vez com: install.packages(c(",
    paste(sprintf('"%s"', ausentes), collapse=", "), "))",
    call.=FALSE
  )
}

preparar_saida <- function() {
  if (!dir.exists(TCC_RAIZ)) stop("Nao encontrei ", TCC_RAIZ, call.=FALSE)
  if (!dir.exists(TCC_CODING)) stop(
    "Nao encontrei a pasta das cinco bases: ", TCC_CODING,
    ". Confira o caminho TCC_CODING no _config_funcoes.R.", call.=FALSE)
  if (!dir.exists(TCC_SCRIPTS)) stop(
    "Nao encontrei a pasta de scripts: ", TCC_SCRIPTS,
    ". Copie a pasta scripts/R do pacote portatil para o repositorio.", call.=FALSE)
  dir.create(TCC_SAIDAS, recursive=TRUE, showWarnings=FALSE)
}

# Fontes selecionadas nos diretorios explicitos acima; sem busca recursiva.
localizar_arquivo <- function(nome) {
  eh_emenda <- nome %in% unname(TCC_ENTRADAS_ESPERADAS)
  pasta <- if (eh_emenda) TCC_CODING else if (identical(nome, TCC_PARTIDOS_ARQUIVO)) {
    TCC_PARTIDOS_PASTA
  } else {
    stop("Arquivo nao previsto na configuracao: ", nome, call.=FALSE)
  }
  caminho <- file.path(pasta, nome)
  if (!file.exists(caminho)) {
    stop(
      "Fonte nao encontrada no caminho exato: ", caminho, "\n",
      if (eh_emenda) "As planilhas anuais ficam juntas na raiz OU em dados/codificados."
      else "A base de partidos fica na raiz OU em dados/partidos/BASE PARTIDOS GERAL.xlsx.",
      call.=FALSE
    )
  }
  if (dir.exists(caminho)) stop("A fonte e uma pasta, nao um XLSX: ", caminho,
                                call.=FALSE)
  normalizePath(caminho, winslash="/", mustWork=TRUE)
}

limpar_cabecalho <- function(nm) trimws(nm)

padronizar_texto <- function(x) {
  x <- trimws(as.character(x))
  x[is.na(x) | x %in% c("", "NA", "N/A", "NULL", "-")] <- NA_character_
  x
}

chave_nome <- function(x) {
  s <- iconv(tolower(as.character(x)), from="", to="ASCII//TRANSLIT")
  s[is.na(s)] <- ""
  gsub("[^a-z0-9]", "", s)
}

# Alguns numeros digitados no Excel usam o sinal menos matematico (U+2212)
# ou o menos de largura cheia (U+FF0D), que as.numeric nao reconhece.
# Converter SOMENTE essas variantes inequívocas do sinal de menos; nao
# substituir travessoes, hifens de texto ou outros conteudos suspeitos.
normalizar_sinal_numerico <- function(x) {
  x <- as.character(x)
  x <- gsub("\u2212", "-", x, fixed=TRUE)
  x <- gsub("\uFF0D", "-", x, fixed=TRUE)
  x
}

# readxl com col_types='text' preserva as celulas de CAP como texto e reduz
# divergencias entre anos. Numeros nos XLSX podem estar como 1000.50 ou 1.000,50.
converter_valor <- function(x, coluna="valor") {
  x <- padronizar_texto(x)
  x <- normalizar_sinal_numerico(x)
  x <- gsub("R\\$|[[:space:]]", "", x)
  com_virgula <- !is.na(x) & grepl(",", x, fixed=TRUE)
  x[com_virgula] <- gsub(",", ".", gsub("\\.", "", x[com_virgula]))
  n <- suppressWarnings(as.numeric(x))
  suspeitos <- which(!is.na(x) & is.na(n))
  if (length(suspeitos)) stop(
    "Valores nao numericos na coluna ", coluna, ", indices: ",
    paste(head(suspeitos, 12), collapse=", "), call.=FALSE
  )
  n
}

normalizar_cap <- function(x) {
  x <- padronizar_texto(x)
  x <- gsub("\\.0+$", "", x)
  valido <- is.na(x) | grepl("^[0-9]{1,4}$", x)
  if (any(!valido)) stop(
    "CAP final com conteudo inesperado: ",
    paste(unique(x[!valido]), collapse=", "), call.=FALSE
  )
  x[!is.na(x)] <- sprintf("%04d", as.integer(x[!is.na(x)]))
  x
}

numero_binario <- function(x, campo) {
  x <- padronizar_texto(x)
  inval <- !is.na(x) & !(x %in% c("0", "1", "0.0", "1.0"))
  if (any(inval)) stop("Valores invalidos em ", campo, ": ",
                        paste(unique(x[inval]), collapse=", "), call.=FALSE)
  as.integer(as.numeric(x))
}

salvar_csv <- function(tabela, nome) {
  readr::write_csv(tabela, file.path(TCC_SAIDAS, nome), na="")
}

validar_unico <- function(tab, campos, descricao) {
  z <- dplyr::count(tab, dplyr::across(dplyr::all_of(campos)), name="n")
  erro <- z[z$n>1, , drop=FALSE]
  if (nrow(erro)) stop(
    "Chave duplicada em ", descricao, ": ",
    paste(utils::capture.output(print(utils::head(erro,8))), collapse="\n"),
    call.=FALSE
  )
}

# Todos os scripts subsequentes devem conferir que o painel 01 foi criado
# A PARTIR DOS nomes de entrada configurados AQUI, nunca de versoes anteriores.
validar_manifesto_preparo <- function() {
  caminho <- file.path(TCC_SAIDAS, "01_manifesto_fontes.csv")
  if (!file.exists(caminho)) stop(
    "Manifesto de fontes nao encontrado. Execute novamente 01_preparar.bases.R.",
    call.=FALSE)
  manifesto <- readr::read_csv(caminho, show_col_types=FALSE)
  if (!all(c("grupo","arquivo","caminho") %in% names(manifesto))) stop(
    "Manifesto de fontes incompleto (faltam caminhos). Reexecute 01.", call.=FALSE)
  nomes_esperados <- c(TCC_ENTRADAS_ESPERADAS, partidos=TCC_PARTIDOS_ARQUIVO)
  for (grupo in names(nomes_esperados)) {
    linha <- manifesto[manifesto$grupo == grupo, , drop=FALSE]
    caminho_esperado <- localizar_arquivo(unname(nomes_esperados[[grupo]]))
    caminho_registrado <- if (nrow(linha)==1L) {
      normalizePath(linha$caminho[[1]], winslash="/", mustWork=FALSE)
    } else NA_character_
    if (nrow(linha)!=1L ||
        !identical(linha$arquivo[[1]], unname(nomes_esperados[[grupo]])) ||
        !identical(caminho_registrado, caminho_esperado)) {
      stop("O painel 01 foi preparado com arquivo ou pasta diferente em ", grupo,
           ". Reexecute 01_preparar.bases.R antes do script atual.\n",
           "Esperado: ", caminho_esperado, "\n",
           "Registrado: ", caminho_registrado, call.=FALSE)
    }
  }
  invisible(TRUE)
}
