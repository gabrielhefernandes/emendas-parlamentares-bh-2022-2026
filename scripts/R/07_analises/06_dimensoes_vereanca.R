# ===========================================================================
# 06_dimensoes_vereanca.R | 9 ETAPAS | TCC BH — Kuschnir / Q3CORR
# Reconstrucao auditavel das regras do legado 11_Q3CORR_v5 (2026-10-08).
# Usa os dados APROVADOS dos scripts 01 e 02; NAO reprocessa os XLSX.
# Nunca modifica fontes / codificacoes originais. Saidas em scripts_refazer/saidas.
# Nao cria tipos assistencialista/coletivista/ideologico automaticamente.
# IMPORTANTE: politico-programatica != projeto/programa nomeado em uma emenda.
# ===========================================================================
source(file.path(Sys.getenv("TCC_BH_RAIZ", unset=getwd()),
  "scripts", "R", "01_importacao_padronizacao", "_config_funcoes.R"), encoding="UTF-8")

# ETAPA 1/9 - ambiente, entradas, integridade
verificar_pacotes(c("readr","dplyr","stringr","tibble","tidyr"))
preparar_saida()
validar_manifesto_preparo()
suppressPackageStartupMessages({
  library(readr); library(dplyr); library(stringr); library(tibble); library(tidyr)
})
f01 <- file.path(TCC_SAIDAS,"01_emendas_integradas.rds")
f02 <- file.path(TCC_SAIDAS,"02_painel_com_ideologia.rds")
f_override <- file.path(TCC_SCRIPTS,"insumos","OVERRIDES_ENTIDADE_RESIDUAL_Q3_v1.csv")
for (p in c(f01,f02,f_override)) if (!file.exists(p)) stop(
  "Entrada necessaria ausente: ",p,".\nConfira 01/02 e a pasta insumos do pacote 06.",call.=FALSE)
if (file.info(f02)$mtime < file.info(f01)$mtime) stop(
  "02_painel_com_ideologia.rds anterior a 01; reexecute 02.",call.=FALSE)
emendas <- readRDS(f01)
painel <- readRDS(f02)
if (nrow(emendas)!=4796L || nrow(painel)!=207L) stop("Universo 01/02 inesperado.",call.=FALSE)
validar_unico(emendas,"id_emenda","emendas 06")
validar_unico(painel,"id_vereador_ano","perfis 06")
message("[06] ETAPA 1/9 - Fontes 01/02 e override localizados e validados")

# ETAPA 2/9 - converter campos estruturados do 01, sem confiar em copias RDS antigas
escolher_campo <- function(x,nomes,rotulo,obrigatorio=TRUE) {
  encontrados <- nomes[nomes %in% names(x)]
  if (!length(encontrados)) {
    if (obrigatorio) stop("Campo original nao encontrado (",rotulo,"). Candidatos: ",
      paste(nomes,collapse=", "),call.=FALSE)
    return(rep(NA_character_,nrow(x)))
  }
  as.character(x[[encontrados[[1]]]])
}
campos_req <- c("id_emenda","ano","id_vereador_ano","eh_nao_saude",
                "valor_emenda_num","geo_bin","publico_bin","publico_alvo_resumo",
                "parlamentar_original")
if (length(setdiff(campos_req,names(emendas)))) stop(
  "Campos essenciais do 01 ausentes: ",paste(setdiff(campos_req,names(emendas)),collapse=", "),
  call.=FALSE)
ns <- emendas[!is.na(emendas$eh_nao_saude) & emendas$eh_nao_saude,,drop=FALSE]
if (nrow(ns)!=2491L || sum(!is.na(ns$valor_emenda_num))!=2490L ||
    abs(sum(ns$valor_emenda_num,na.rm=TRUE)-383849795.50)>0.01) stop(
      "Universo nao-saude divergente de 2.491 / 2.490 com valor / R$ 383.849.795,50.",call.=FALSE)
base <- tibble(
  ano=as.integer(ns$ano), id_emenda=as.character(ns$id_emenda),
  id_vereador_ano=as.character(ns$id_vereador_ano),
  parlamentar=as.character(ns$parlamentar_original),
  valor_emenda=as.numeric(ns$valor_emenda_num),
  subcodigo_cap_final=escolher_campo(ns,c("subcodigo_cap_final"),"CAP"),
  georreferenciavel=as.integer(ns$geo_bin),
  localidade_final=escolher_campo(ns,c("localidade_final"),"localidade final",FALSE),
  localidade_resumo=escolher_campo(ns,c("localidade_resumo"),"localidade resumo",FALSE),
  publico_alvo_final=as.integer(ns$publico_bin),
  publico_alvo_resumo=as.character(ns$publico_alvo_resumo),
  objeto_emenda=escolher_campo(ns,c("objeto_emenda","objeto"),"objeto da emenda"),
  beneficiario=escolher_campo(ns,c("beneficiario_final_original","beneficiario_original"),"beneficiario",FALSE),
  tipo_beneficiario=escolher_campo(ns,c("tipo_beneficiario_original","tipo_beneficiario"),"tipo beneficiario",FALSE)
)
if (anyDuplicated(base$id_emenda) || anyNA(base$id_emenda) ||
    anyNA(base$id_vereador_ano) || anyNA(base$georreferenciavel)) stop(
    "IDs ou GEO invalidos na base 06.",call.=FALSE)
if (sum(base$georreferenciavel==1L)!=943L) stop(
  "GEO=1 divergiu da auditoria antiga (943 registros). Verificar bases.",call.=FALSE)
if (!any(nzchar(trimws(ifelse(is.na(base$beneficiario),"",base$beneficiario))))) stop(
  "Nenhum beneficiario recuperado das planilhas. Nao e seguro reconstruir entidade.",call.=FALSE)
message("[06] ETAPA 2/9 - 2491 emendas, 2490 valores observados, GEO validado")

# ETAPA 3/9 - overrides auditados da classificacao original
# No legado havia 43 positivos e 6 negativos; nunca trocar por regex genérico.
overrides_entidade_residual <- readr::read_csv(f_override,show_col_types=FALSE)
campos_override <- c("id_emenda","entidade_especifica_override")
if (!all(campos_override %in% names(overrides_entidade_residual))) stop(
  "Override sem colunas esperadas.",call.=FALSE)
if (anyDuplicated(overrides_entidade_residual$id_emenda) ||
    nrow(overrides_entidade_residual)!=49L ||
    sum(overrides_entidade_residual$entidade_especifica_override==1L)!=43L ||
    sum(overrides_entidade_residual$entidade_especifica_override==0L)!=6L ||
    anyNA(overrides_entidade_residual$entidade_especifica_override) ||
    any(!(overrides_entidade_residual$id_emenda %in% base$id_emenda))) stop(
    "Arquivo de overrides divergente (esperado 49: 43 positivos, 6 negativos, todos presentes).",
    call.=FALSE)
# Overrides adicionais do legado: dois casos sem publico social explicito.
overrides_publico_alvo <- tibble::tibble(
  id_emenda=c("2023_REINALDO_GOMES_PRETO_SACOLAO_966_01",
              "2023_WILSINHO_DA_TABU_710_01"),
  publico_alvo_override=c(0L,0L),
  justificativa="Beneficiario institucional sem publico social explicitamente identificado"
)
if (!all(overrides_publico_alvo$id_emenda %in% base$id_emenda)) stop(
  "IDs de overrides de publico ausentes.",call.=FALSE)
base <- base |>
  dplyr::left_join(overrides_publico_alvo |>
                     dplyr::select(id_emenda,publico_alvo_override),by="id_emenda") |>
  dplyr::mutate(publico_alvo_final=dplyr::coalesce(
    publico_alvo_override,publico_alvo_final)) |>
  dplyr::select(-publico_alvo_override)
if (anyNA(base$publico_alvo_final)) stop(
  "Ainda existem publico_alvo_final ausentes. Verificar casos manualmente.",call.=FALSE)
readr::write_csv(overrides_entidade_residual,file.path(TCC_SAIDAS,"06_overrides_entidade_utilizados.csv"))
readr::write_csv(overrides_publico_alvo,file.path(TCC_SAIDAS,"06_overrides_publico_utilizados.csv"))
message("[06] ETAPA 3/9 - 49 overrides de entidade e 2 de publico auditados")

# Funcoes de equivalencia textual, preservadas do script antigo 11_v5
normaliza_ascii <- function(x) {
  y <- iconv(as.character(x),from="",to="ASCII//TRANSLIT",sub="")
  y[is.na(y)] <- ""
  stringr::str_squish(toupper(y))
}
flag_regex <- function(texto,padrao) as.integer(stringr::str_detect(
  texto,stringr::regex(padrao,ignore_case=TRUE)))

# ETAPA 4/9 - texto, territorializacao, publico humano e animal
# 4. Textos normalizados e retirada de boilerplate
# ------------------------------------------------------------

base <- base %>%
  mutate(
    objeto_norm =
      normaliza_ascii(
        objeto_emenda
      ),

    beneficiario_norm =
      normaliza_ascii(
        beneficiario
      ),

    publico_norm =
      normaliza_ascii(
        publico_alvo_resumo
      ),

    localidade_norm =
      normaliza_ascii(
        localidade_resumo
      ),

    # Retirar fórmulas jurídicas padronizadas que geravam
    # falsos positivos de "conselho", "direitos" e "municipal".
    objeto_sem_boilerplate =
      objeto_norm %>%
      str_replace_all(
        "DE ACORDO COM O DISPOSTO NA LEI FEDERAL[^;,.]*",
        " "
      ) %>%
      str_replace_all(
        "EM CONSONANCIA COM A REFERIDA INSCRICAO NO CONSELHO MUNICIPAL DE ASSISTENCIA SOCIAL[^;,.]*",
        " "
      ) %>%
      str_replace_all(
        "CONSELHO MUNICIPAL DE ASSISTENCIA SOCIAL DE BELO HORIZONTE",
        " "
      ) %>%
      str_replace_all(
        "\\bCMAS[- ]?BH\\b",
        " "
      ) %>%
      str_squish()
  )


# ------------------------------------------------------------
# 5. Territorialidade — variável já validada
# ------------------------------------------------------------

base <- base %>%
  mutate(
    sinal_territorial =
      as.integer(
        georreferenciavel == 1
      )
  )


# ------------------------------------------------------------
# 6. Público categorial: separar social/humano de animal
# ------------------------------------------------------------

# Alvos exclusivamente animais não são tratados como representação
# categorial no sentido político-social de Kuschnir.
padrao_alvo_animal <- paste0(
  "\\b(",
  "ANIMAL|ANIMAIS|CAO|CAES|CACHORRO|CACHORROS|",
  "GATO|GATOS|CAES E GATOS|FAUNA",
  ")\\b"
)

base <- base %>%
  mutate(
    sinal_categorial_original =
      as.integer(
        publico_alvo_final == 1
      ),

    publico_exclusivamente_animal =
      as.integer(
        sinal_categorial_original == 1 &
          publico_norm != "" &
          str_detect(
            publico_norm,
            regex(
              padrao_alvo_animal,
              ignore_case = TRUE
            )
          ) &
          !str_detect(
            publico_norm,
            regex(
              paste0(
                "\\b(",
                "CRIANC|ADOLESC|JOV|IDOS|MULHER|",
                "PESSOA|POPULACAO|MIGRANTE|QUILOMB|",
                "INDIGENA|LGBT|TRANS|TRAVEST|",
                "TRABALHADOR|ESTUDANTE|GESTANTE|",
                "PARTURIENTE|PUERPERA|DEFICIENCIA|",
                "AUTISTA|TEA|DOWN|DEPENDENTE",
                ")"
              ),
              ignore_case = TRUE
            )
          )
      ),

    sinal_categorial_social =
      as.integer(
        sinal_categorial_original == 1 &
          publico_exclusivamente_animal == 0
      ),

    sinal_alvo_animal =
      as.integer(
        sinal_categorial_original == 1 &
          publico_exclusivamente_animal == 1
      )
  )


# ------------------------------------------------------------

message("[06] ETAPA 4/9 - Texto sem boilerplate e sinais GEO/categorial/animal")

# ETAPA 5/9 - entidade especifica; regras/overrides literalmente do legado
# 7. Entidade específica — campo estruturado + objeto
# ------------------------------------------------------------

padrao_forma_entidade_privada <- paste0(
  "\\b(",
  "ASSOCIACAO|INSTITUTO|ONG|OSC|",
  "ORGANIZACAO DA SOCIEDADE CIVIL|FEDERACAO|",
  "CONFEDERACAO|COOPERATIVA|CARITAS|",
  "CASA DE APOIO|COMUNIDADE CATOLICA|",
  "SOCIEDADE COMUNITARIA|GRUPO COMUNITARIO|",
  "CENTRO SOCIAL|CRECHE COMUNITARIA|",
  "LAR DOS|LAR DE|OBRA SOCIAL",
  ")\\b"
)

# "Fundação" isoladamente não é suficiente, pois há fundações
# municipais. Fundação privada continua sendo detectada quando
# houver CNPJ ou beneficiário estruturado.
sinal_cnpj <- flag_regex(
  base$objeto_norm,
  "\\bCNPJ\\b|[0-9]{2}[.]?[0-9]{3}[.]?[0-9]{3}/[0-9]{4}-?[0-9]{2}"
)

sinal_forma_entidade_privada <- flag_regex(
  base$objeto_norm,
  padrao_forma_entidade_privada
)

padrao_orgao_publico <- paste0(
  "\\b(",
  "PREFEITURA|PBH|MUNICIPIO DE BELO HORIZONTE|",
  "SECRETARIA MUNICIPAL|FUNDACAO MUNICIPAL|",
  "ESCOLA MUNICIPAL|EMEI|UPA|CENTRO DE SAUDE|",
  "ADMINISTRACAO REGIONAL|HOSPITAL MUNICIPAL",
  ")\\b"
)

sinal_orgao_publico_texto <- flag_regex(
  base$objeto_norm,
  padrao_orgao_publico
)

base <- base %>%
  mutate(
    sinal_entidade_campo =
      as.integer(
        beneficiario_norm != "" &
          !beneficiario_norm %in% c(
            "-",
            "PBH",
            "MUNICIPIO DE BELO HORIZONTE",
            "PREFEITURA DE BELO HORIZONTE",
            "PREFEITURA MUNICIPAL DE BELO HORIZONTE",
            "ASSOCIACOES DIVERSAS"
          )
      ),

    sinal_entidade_texto_refinado =
      as.integer(
        (
          sinal_cnpj == 1 |
            sinal_forma_entidade_privada == 1
        ) &
          sinal_orgao_publico_texto == 0
      ),

    sinal_entidade_especifica_refinada =
      as.integer(
        sinal_entidade_campo == 1 |
          sinal_entidade_texto_refinado == 1
      ),

    sinal_beneficiario_publico_geral =
      as.integer(
        beneficiario_norm %in% c(
          "PBH",
          "MUNICIPIO DE BELO HORIZONTE",
          "PREFEITURA DE BELO HORIZONTE",
          "PREFEITURA MUNICIPAL DE BELO HORIZONTE"
        ) |
          sinal_orgao_publico_texto == 1
      )
  )

# Overrides explícitos da auditoria do residual.
# A opção por override, em vez de ampliar o regex, preserva o
# caráter conservador do reconhecimento automático de entidades.
base <- base %>%
  left_join(
    overrides_entidade_residual %>%
      select(
        id_emenda,
        entidade_especifica_override
      ),
    by = "id_emenda"
  ) %>%
  mutate(
    sinal_entidade_especifica_refinada =
      if_else(
        !is.na(entidade_especifica_override),
        as.integer(entidade_especifica_override),
        sinal_entidade_especifica_refinada
      )
  ) %>%
  select(
    -entidade_especifica_override
  )

if (
  any(
    is.na(
      base$sinal_entidade_especifica_refinada
    )
  )
) {
  stop(
    "Há NA em sinal_entidade_especifica_refinada após os overrides.",
    call. = FALSE
  )
}


# ------------------------------------------------------------

message("[06] ETAPA 5/9 - Sinal de entidade privada/publica e overrides aplicados")

# ETAPA 6/9 - intervencoes materiais e politico-programatico, como no legado
# 8. Modalidade material / serviço
# ------------------------------------------------------------

# Obras e intervenções físicas — mais amplo que a v1.
padrao_obra_infra <- paste0(
  "\\b(",
  "OBRA|OBRAS|REFORMA|REFORMAR|CONSTRUCAO|CONSTRUIR|",
  "PAVIMENTACAO|PAVIMENTAR|RECAPEAMENTO|ASFALTAMENTO|",
  "URBANIZACAO|REVITALIZACAO|REQUALIFICACAO|DRENAGEM|",
  "CALCAMENTO|ILUMINACAO|GRAMADO|GRAMA SINTETICA|",
  "PASSARELA|MURO|COBERTURA|CERCAMENTO|ADEQUACAO|",
  "MANUTENCAO|MELHORIA|MELHORIAS|INTERVENCAO|INTERVENCOES|",
  "INSTALACAO|INSTALAR|SINALIZACAO|SEMAFOR|",
  "ALAMBRADO|TOLDO|TOLDOS|PLAYGROUND|VIDEOMONITORAMENTO",
  ")\\b"
)

padrao_bens_equip <- paste0(
  "\\b(",
  "AQUISICAO|ADQUIRIR|COMPRA|",
  "EQUIPAMENTO|EQUIPAMENTOS|MOBILIARIO|",
  "VEICULO|VEICULOS|MATERIAL|MATERIAIS|",
  "INSUMO|INSUMOS|COMPUTADOR|COMPUTADORES|",
  "BRINQUEDO|BRINQUEDOS|APARELHO|APARELHOS",
  ")\\b"
)

padrao_servico_atendimento <- paste0(
  "\\b(",
  "ATENDIMENTO|ATENDIMENTOS|SERVICO|SERVICOS|",
  "ATIVIDADE|ATIVIDADES|CUSTEIO|ACOLHIMENTO|",
  "ASSISTENCIA|SOCIOASSISTENCIAL|SOCIOASSISTENCIAIS|",
  "CASTRACAO|ESTERILIZACAO|TRATAMENTO|",
  "OFICINA|OFICINAS|EVENTO|EVENTOS",
  ")\\b"
)

padrao_formacao <- paste0(
  "\\b(",
  "FORMACAO|CAPACITACAO|QUALIFICACAO|",
  "PROFISSIONALIZACAO|TREINAMENTO|",
  "EDUCACAO CONTINUADA",
  ")\\b"
)

base <- base %>%
  mutate(
    sinal_obra_infra_refinado =
      flag_regex(
        objeto_sem_boilerplate,
        padrao_obra_infra
      ),

    sinal_bens_equipamentos_refinado =
      flag_regex(
        objeto_sem_boilerplate,
        padrao_bens_equip
      ),

    sinal_servico_atendimento_refinado =
      flag_regex(
        objeto_sem_boilerplate,
        padrao_servico_atendimento
      ),

    sinal_formacao_capacitacao_refinado =
      flag_regex(
        objeto_sem_boilerplate,
        padrao_formacao
      ),

    sinal_material_servico_concreto =
      as.integer(
        sinal_obra_infra_refinado == 1 |
          sinal_bens_equipamentos_refinado == 1 |
          sinal_servico_atendimento_refinado == 1
      )
  )


# ------------------------------------------------------------
# 9. Relação político-programática — regra estreita
# ------------------------------------------------------------

# Removidos: "implantação", "implementação" e "fortalecimento"
# isolados, pois apareciam em intervenções locais e projetos de OSC.

# Regra propositalmente conservadora: retirar termos que aparecem
# com frequência em nomes de entidades ("Cidadania") ou em objetos
# administrativos sem relação político-coletiva.
padrao_direitos_participacao <- paste0(
  "(",
  "PARTICIPACAO SOCIAL|PARTICIPACAO POPULAR|",
  "CONTROLE SOCIAL|MOVIMENTO SOCIAL|MOVIMENTOS SOCIAIS|",
  "CONFERENCIA MUNICIPAL|CONFERENCIAS MUNICIPAIS|",
  "PROMOCAO[^.;,]{0,80}DIREIT|",
  "PROTECAO[^.;,]{0,80}DIREIT|",
  "DEFESA[^.;,]{0,80}DIREIT|",
  "GARANTIA[^.;,]{0,80}DIREIT|",
  "ENFRENTAMENTO[^.;,]{0,80}DISCRIMINACAO|",
  "COMBATE[^.;,]{0,80}DISCRIMINACAO|",
  "IGUALDADE RACIAL|IGUALDADE DE GENERO",
  ")"
)

# "monitoramento" foi removido porque ativava videomonitoramento;
# "rede municipal" foi removida porque ativava a rede escolar.
padrao_programatico_estrito <- paste0(
  "\\b(",
  "POLITICA PUBLICA|POLITICAS PUBLICAS|",
  "POLITICA MUNICIPAL|POLITICAS MUNICIPAIS|",
  "PROGRAMA MUNICIPAL|PLANO MUNICIPAL|",
  "PLANO DIRETOR|SISTEMA MUNICIPAL|",
  "PROTOCOLO MUNICIPAL|",
  "REDE MUNICIPAL DE ENFRENTAMENTO|",
  "REDE MUNICIPAL DE PROTECAO|",
  "REDE MUNICIPAL DE ATENDIMENTO|",
  "CENSO|PESQUISA|DIAGNOSTICO|",
  "MAPEAMENTO|OBSERVATORIO|",
  "PLANEJAMENTO ESTRATEGICO",
  ")\\b"
)

base <- base %>%
  mutate(
    sinal_direitos_participacao_refinado =
      flag_regex(
        objeto_sem_boilerplate,
        padrao_direitos_participacao
      ),

    sinal_programatico_refinado =
      flag_regex(
        objeto_sem_boilerplate,
        padrao_programatico_estrito
      ),

    sinal_politico_programatico =
      as.integer(
        sinal_direitos_participacao_refinado == 1 |
          sinal_programatico_refinado == 1
      )
  )


# ------------------------------------------------------------
# 9.1. Auditorias dos sinais refinados
# ------------------------------------------------------------

if (
  any(
    is.na(
      base$sinal_categorial_social
    )
  )
) {
  stop(
    "Há NA nos sinais categoriais após os overrides auditados.",
    call. = FALSE
  )
}

# Casos que não devem voltar a ser falso-positivo político-programático.
casos_teste_negativo <- c(
  "2024_MARCELA_TROPIA_772_01",
  "2023_PROFESSORA_MARLI_880_01"
)

teste_negativo <- base %>%
  filter(
    id_emenda %in%
      casos_teste_negativo
  )

if (
  any(
    teste_negativo$sinal_politico_programatico == 1
  )
) {
  stop(
    "Falha na auditoria: falso positivo político-programático reapareceu.",
    call. = FALSE
  )
}


# ------------------------------------------------------------
# 10. Escopo geral/impessoal
# ------------------------------------------------------------

# "Geral/impessoal" é definido por ausência de destino territorial,
# categoria social e entidade específica observável.
# Não significa automaticamente "ideológico".

base <- base %>%
  mutate(
    sinal_geral_impessoal =
      as.integer(
        sinal_territorial == 0 &
          sinal_categorial_social == 0 &
          sinal_entidade_especifica_refinada == 0
      )
  )


# ------------------------------------------------------------
# 11. Dimensões candidatas — ainda NÃO são tipos finais
# ------------------------------------------------------------

base <- base %>%
  mutate(
    # Compatibilidade com lógica local/comunitária:
    # destino físico específico + benefício/intervenção concreta.
    dim_local_concreta =
      as.integer(
        sinal_territorial == 1 &
          sinal_material_servico_concreto == 1
      ),

    # Particularização institucional sem localidade física comprovada.
    dim_entidade_particularizada =
      as.integer(
        sinal_territorial == 0 &
          sinal_entidade_especifica_refinada == 1
      ),

    # Representação categorial não territorial.
    dim_categorial_nao_local =
      as.integer(
        sinal_territorial == 0 &
          sinal_categorial_social == 1
      ),

    # Relação político-programática/impessoal — sinal mais próximo
    # do polo coletivo-político, mas ainda insuficiente sozinho.
    dim_politico_programatica =
      as.integer(
        sinal_territorial == 0 &
          sinal_politico_programatico == 1
      ),

    # Residual geral/impessoal sem sinal político-programático forte.
    dim_geral_impessoal_residual =
      as.integer(
        sinal_geral_impessoal == 1 &
          sinal_politico_programatico == 0
      )
  )


if (
  any(
    is.na(
      base$dim_categorial_nao_local
    )
  )
) {
  stop(
    "Há NA em dim_categorial_nao_local.",
    call. = FALSE
  )
}


# ------------------------------------------------------------
# 12. Escopo refinado — descritivo
# ------------------------------------------------------------

base <- base %>%
  mutate(
    escopo_refinado =
      case_when(
        sinal_territorial == 1 &
          sinal_categorial_social == 1 &
          sinal_entidade_especifica_refinada == 1 ~
          "TERRITORIAL+CATEGORIAL+ENTIDADE",

        sinal_territorial == 1 &
          sinal_categorial_social == 1 ~
          "TERRITORIAL+CATEGORIAL",

        sinal_territorial == 1 &
          sinal_entidade_especifica_refinada == 1 ~
          "TERRITORIAL+ENTIDADE",

        sinal_territorial == 1 ~
          "TERRITORIAL",

        sinal_categorial_social == 1 &
          sinal_entidade_especifica_refinada == 1 ~
          "CATEGORIAL+ENTIDADE",

        sinal_categorial_social == 1 ~
          "CATEGORIAL",

        sinal_entidade_especifica_refinada == 1 ~
          "ENTIDADE_ESPECIFICA",

        TRUE ~
          "GERAL/IMPESSOAL"
      ),

    fila_revisao_refinada =
      case_when(
        dim_local_concreta == 1 ~
          "A_LOCAL_CONCRETA",

        sinal_territorial == 1 ~
          "B_LOCAL_OUTRA",

        dim_politico_programatica == 1 &
          dim_categorial_nao_local == 1 ~
          "C_CATEGORIAL_POLITICO_PROGRAMATICA",

        dim_politico_programatica == 1 ~
          "D_POLITICO_PROGRAMATICA",

        dim_categorial_nao_local == 1 ~
          "E_CATEGORIAL_NAO_LOCAL",

        dim_entidade_particularizada == 1 ~
          "F_ENTIDADE_NAO_LOCAL",

        sinal_alvo_animal == 1 ~
          "G_ALVO_ANIMAL_NAO_LOCAL",

        TRUE ~
          "H_GERAL_IMPESSOAL_RESIDUAL"
      )
  )


# ------------------------------------------------------------

if (anyNA(base$dim_categorial_nao_local) || anyNA(base$dim_entidade_particularizada) ||
    anyNA(base$dim_politico_programatica)) stop("Dimensoes ausentes apos regras legadas.",call.=FALSE)
message("[06] ETAPA 6/9 - Dimensoes originais do legado 11_v5 reconstruidas")

# ETAPA 7/9 - agregar ao id_vereador_ano oficial do painel 01/02
soma_flag <- function(valor,flag) sum(valor[!is.na(valor) & !is.na(flag) & flag==1L],na.rm=TRUE)
valor_todos <- sum(base$valor_emenda,na.rm=TRUE)
perfis <- base |>
  dplyr::group_by(ano,id_vereador_ano) |>
  dplyr::summarise(
    n_emendas_nao_saude=dplyr::n(),
    n_emendas_sem_valor=sum(is.na(valor_emenda)),
    valor_total_nao_saude=sum(valor_emenda,na.rm=TRUE),
    n_emendas_territoriais=sum(sinal_territorial==1L),
    valor_territorial=soma_flag(valor_emenda,sinal_territorial),
    n_categorial_nao_local=sum(dim_categorial_nao_local==1L),
    valor_categorial_nao_local=soma_flag(valor_emenda,dim_categorial_nao_local),
    n_entidade_nao_local=sum(dim_entidade_particularizada==1L),
    valor_entidade_nao_local=soma_flag(valor_emenda,dim_entidade_particularizada),
    n_politico_programatica=sum(dim_politico_programatica==1L),
    valor_politico_programatico=soma_flag(valor_emenda,dim_politico_programatica),
    n_alvo_exclusivamente_animal=sum(sinal_alvo_animal==1L),
    valor_alvo_exclusivamente_animal=soma_flag(valor_emenda,sinal_alvo_animal),
    n_categorial_e_entidade=sum(dim_categorial_nao_local==1L & dim_entidade_particularizada==1L),
    valor_categorial_e_entidade=sum(valor_emenda[
      dim_categorial_nao_local==1L & dim_entidade_particularizada==1L],na.rm=TRUE),
    n_residual=sum(dim_geral_impessoal_residual==1L),
    valor_residual=soma_flag(valor_emenda,dim_geral_impessoal_residual),
    .groups="drop"
  ) |>
  dplyr::mutate(
    share_valor_territorial=valor_territorial/valor_total_nao_saude,
    share_valor_categorial_nao_local=valor_categorial_nao_local/valor_total_nao_saude,
    share_valor_entidade_nao_local=valor_entidade_nao_local/valor_total_nao_saude,
    share_valor_politico_programatico=valor_politico_programatico/valor_total_nao_saude,
    share_valor_alvo_animal_exclusivo=valor_alvo_exclusivamente_animal/valor_total_nao_saude,
    share_valor_residual=valor_residual/valor_total_nao_saude
  )
if (nrow(perfis)!=206L || anyDuplicated(perfis$id_vereador_ano) ||
    any(!is.finite(perfis$share_valor_territorial)) ||
    abs(sum(perfis$valor_total_nao_saude)-valor_todos)>0.01 ||
    sum(perfis$n_emendas_nao_saude)!=2491L) stop(
    "Falha na agregacao de perfis vereador-ano.",call.=FALSE)
# Preservar as escalas ideologicas do pipeline ja validado, SEM novos matches por nome.
campos_painel <- c("ano","id_vereador_ano","pessoa_chave","parlamentar_partido",
                   "sigla_partido","zucco_final","bolognesi_media",
                   "valor_nao_saude")
if (length(setdiff(campos_painel,names(painel)))) stop("Painel 02 sem campos esperados.",call.=FALSE)
perfis <- perfis |>
  dplyr::left_join(painel[,campos_painel],by=c("ano","id_vereador_ano"),
                   suffix=c("","_painel"))
if (nrow(perfis)!=206L || anyNA(perfis$pessoa_chave) ||
    sum(!is.na(perfis$zucco_final))!=173L ||
    sum(!is.na(perfis$bolognesi_media))!=140L ||
    any(abs(perfis$valor_total_nao_saude-perfis$valor_nao_saude)>0.01)) stop(
    "Amostra/valores de 06 divergem do painel 02. Nao continuar.",call.=FALSE)
message("[06] ETAPA 7/9 - 206 perfis integrados com painel de ideologia 02 (173/140)")

# ETAPA 8/9 - auditoria anual, antiga base e distincao entre indicadores
indicadores <- c("sinal_territorial","dim_categorial_nao_local",
                "dim_entidade_particularizada","dim_politico_programatica",
                "sinal_alvo_animal")
resumo_ano <- dplyr::bind_rows(lapply(2022:2026,function(ano_atual) {
  d <- base[base$ano==ano_atual,,drop=FALSE]
  vt <- sum(d$valor_emenda,na.rm=TRUE)
  out <- tibble::tibble(ano=ano_atual,n_emendas=nrow(d),valor_nao_saude=vt)
  for (k in indicadores) {
    out[[paste0("n_",k)]] <- sum(d[[k]]==1L,na.rm=TRUE)
    out[[paste0("pct_valor_",k)]] <- 100*soma_flag(d$valor_emenda,d[[k]])/vt
  }
  out
}))
resumo_geral <- tibble::tibble(
  indicador=c("GEO","Categorial nao local","Entidade nao local",
              "Politico-programatica","Animal EXCLUSIVAMENTE"),
  variavel=indicadores,
  n_emendas=vapply(indicadores,function(k) sum(base[[k]]==1L),numeric(1)),
  valor=vapply(indicadores,function(k) soma_flag(base$valor_emenda,base[[k]]),numeric(1))
) |>
  dplyr::mutate(percentual_monetario=100*valor/valor_todos)
resumo_perfis <- dplyr::bind_rows(lapply(c("share_valor_territorial",
    "share_valor_categorial_nao_local","share_valor_entidade_nao_local",
    "share_valor_politico_programatico","share_valor_alvo_animal_exclusivo"),
  function(k) tibble::tibble(
     indicador=k,n=sum(!is.na(perfis[[k]])),media=mean(perfis[[k]]),
     mediana=stats::median(perfis[[k]]),
     Q1=as.numeric(stats::quantile(perfis[[k]],0.25)),
     Q3=as.numeric(stats::quantile(perfis[[k]],0.75)))))
# Importante: o antigo 'politico-programatica' e um sinal lexical estrito,
# NAO e automaticamente a variavel de 116 emendas de projetos nomeados do TCC.
# Importante: animal exclusivo (legado) difere da contagem de 124 do script04
# (que inclui 7 emendas com publicos humanos e animais).
readr::write_csv(resumo_ano,file.path(TCC_SAIDAS,"06_dimensoes_por_ano.csv"))
readr::write_csv(resumo_geral,file.path(TCC_SAIDAS,"06_dimensoes_agregado.csv"))
readr::write_csv(resumo_perfis,file.path(TCC_SAIDAS,"06_dimensoes_estatisticas_portfolios.csv"))
# Comparacao independente com sinais legados, SE disponiveis; nunca fonte atual.
legado_path <- file.path(TCC_RAIZ,"resultados","Q3","kuschnir",
  "BASE_SINAIS_OBSERVAVEIS_TIPOLOGIAS_KUSCHNIR_Q3CORR_v3.rds")
diferencas <- tibble::tibble(id_emenda=character(),variavel=character(),
  valor_novo=character(),valor_legado=character())
comparacao_status <- "BASE_LEGADA_NAO_ENCONTRADA"
if (file.exists(legado_path)) {
  leg <- readRDS(legado_path)
  chaves_legado <- c("id_emenda","sinal_territorial",
    "dim_categorial_nao_local","dim_entidade_particularizada",
    "dim_politico_programatica","sinal_alvo_animal")
  if (!all(chaves_legado %in% names(leg)) || anyDuplicated(leg$id_emenda)) {
    comparacao_status <- "BASE_LEGADA_ESTRUTURA_INCOMPATIVEL"
  } else if (!setequal(base$id_emenda,leg$id_emenda)) {
    comparacao_status <- "BASE_LEGADA_IDS_DIVERGENTES"
    readr::write_csv(tibble::tibble(
      id_emenda=c(setdiff(base$id_emenda,leg$id_emenda),setdiff(leg$id_emenda,base$id_emenda)),
      origem=c(rep("APENAS_NOVA",length(setdiff(base$id_emenda,leg$id_emenda))),
               rep("APENAS_LEGADO",length(setdiff(leg$id_emenda,base$id_emenda))))),
      file.path(TCC_SAIDAS,"06_ids_divergentes_legado.csv"))
  } else {
    leg <- leg[match(base$id_emenda,leg$id_emenda),,drop=FALSE]
    dif_list <- lapply(chaves_legado[-1],function(campo) {
      idx <- which(is.na(base[[campo]]) != is.na(leg[[campo]]) |
                   (!is.na(base[[campo]]) & !is.na(leg[[campo]]) &
                   as.character(base[[campo]])!=as.character(leg[[campo]])))
      if (!length(idx)) return(NULL)
      tibble::tibble(id_emenda=base$id_emenda[idx],variavel=campo,
        valor_novo=as.character(base[[campo]][idx]),
        valor_legado=as.character(leg[[campo]][idx]))
    })
    diferencas <- dplyr::bind_rows(dif_list)
    if (nrow(diferencas)==0) diferencas <- tibble::tibble(
      id_emenda=character(),variavel=character(),valor_novo=character(),
      valor_legado=character())
    comparacao_status <- if (nrow(diferencas)) "DIVERGENCIAS_DE_SINAIS" else "SINAIS_IDÊNTICOS_AO_LEGADO"
  }
}
readr::write_csv(diferencas,file.path(TCC_SAIDAS,"06_divergencias_sinais_legado.csv"))
readr::write_csv(tibble::tibble(
  base_legada=legado_path,comparacao_status=comparacao_status,
  n_divergencias=nrow(diferencas),
  nota="Comparacao por id_emenda; nao substituir a base nova por RDS antigo"),
  file.path(TCC_SAIDAS,"06_status_comparacao_legado.csv"))
message("[06] ETAPA 8/9 - Descritivos conferidos; comparacao legado: ",comparacao_status)

# ETAPA 9/9 - saidas verificaveis, sem sobrescrever arquivos 01-05
saveRDS(base,file.path(TCC_SAIDAS,"06_sinais_emendas_kuschnir.rds"),compress="xz")
saveRDS(perfis,file.path(TCC_SAIDAS,"06_perfis_dimensoes_vereador_ano.rds"),compress="xz")
readr::write_csv(base,file.path(TCC_SAIDAS,"06_sinais_emendas_kuschnir.csv"),na="")
readr::write_csv(perfis,file.path(TCC_SAIDAS,"06_perfis_dimensoes_vereador_ano.csv"),na="")
fontes_06 <- c(f01,f02,f_override)
readr::write_csv(tibble::tibble(
    papel=c("emendas_01","painel_02","overrides_entidade"),
    arquivo=fontes_06,md5=unname(tools::md5sum(fontes_06))),
    file.path(TCC_SAIDAS,"06_manifesto_fontes.csv"))
message("[06] ETAPA 9/9 - Saidas 06_* gravadas em ",TCC_SAIDAS)
message("[06] FINALIZADO: ",nrow(base)," emendas; ",nrow(perfis),
        " perfis; ",sum(!is.na(perfis$zucco_final))," perfis com ZP.")
print(resumo_geral)
print(resumo_perfis)
if (comparacao_status=="DIVERGENCIAS_DE_SINAIS") message(
 "[06] ATENCAO: ha divergencias em 06_divergencias_sinais_legado.csv. Auditar antes do M3.")
if (comparacao_status=="BASE_LEGADA_IDS_DIVERGENTES") message(
 "[06] ATENCAO: base antiga usa universo diferente. Veja 06_ids_divergentes_legado.csv.")
