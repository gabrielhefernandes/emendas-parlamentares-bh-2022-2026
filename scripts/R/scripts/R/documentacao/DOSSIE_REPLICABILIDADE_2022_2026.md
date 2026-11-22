# Dossiê de documentação e replicabilidade — Emendas municipais de Belo Horizonte (2022–2026)

**Versão do dossiê:** 15 de novembro de 2026 (v2)  \
**Escopo:** classificação de públicos-alvo (script 04); COD 12; base territorial CR2; geometrias canônicas e decisões espaciais.

> **Integridade e limites.** Os arquivos em `fontes_originais/` são cópias binárias idênticas dos documentos recebidos, confirmadas pelos hashes SHA-256. Este dossiê registra e reúne os dados finais solicitados, **não demonstra uma reconstrução automatizada integral** desde as fontes brutas e não substitui a documentação histórica de cada decisão espacial.

## 1. O que está incluído

| Dimensão | Arquivos originais preservados | Verificação |
|---|---|---|
| Públicos-alvo | `04_publicos_alvo.R`, `04_decisoes_manuais.csv`, `04_pendencias_manual(1).csv` | 1 decisão específica aprovada, 0 pendências no relatório recebido |
| COD 12 | `COD12_mapa_manual_108.csv`, `10_cod12_classificacao_por_emenda(2).csv`, `10_cod12_decisoes_manuais_aprovadas(1).csv` | 108 classificações correspondentes, 17 decisões históricas |
| Análise territorial CR2 | `02_BASE_ANALITICA_COM_PARTIDOS_OFICIAIS_2022_2026(1).csv` | 2.357 pares, 2.351 selecionados; segunda cópia recebida tem o mesmo SHA-256 |
| Geometrias canônicas | `LOCALIDADES_GEO_CANONICAS_2022_2026(3).gpkg` | 961 localidades com geometria, seis exclusões coerentes com a base CR2 |
| Dependências dos públicos-alvo | `_config_funcoes.R`, `01_preparar.bases.R`, `02_ideologia_partidos.R` | Códigos preservados, porém não reexecutados neste dossiê |

## 2. Decisões manuais de público-alvo (script 04)

O script `04_publicos_alvo.R` constrói 15 indicadores a partir do texto `publico_alvo_resumo` e de `publico_alvo_final`. A extração dos rótulos é **multietiqueta**: uma emenda pode beneficiar mais de um grupo. Os indicadores não são construídos por leitura automática livre do objeto da emenda; apenas os resumos explicitamente codificados alimentam os padrões de busca (além de decisões individuais documentadas).

### 2.1. Categorias operacionais do script

`Criancas`, `Adolescentes_jovens`, `Animais`, `Pessoas_com_deficiencia`, `Idosos`, `Mulheres`, `Pessoas_em_situacao_de_rua`, `Populacao_negra`, `LGBT_mais`, `Matriz_africana_quilombolas`, `Migrantes_refugiados`, `Dependentes_quimicos`, `Gestantes_materno_infantil`, `Trabalhadoras_sexuais` e `Povos_comunidades_tradicionais_outros`.

O dicionário completo de expressões regulares está no script original; este documento não o substitui. Cada categoria recebe o valor integral da emenda quando identificada, de modo que o total das participações por público **não precisa somar 100%**.

### 2.2. Decisão manual explicitamente registrada no arquivo recebido

| ID da emenda | Público originalmente informado | Categoria aprovada | Data | Justificativa |
|---|---|---|---|---|
| `2026_BRUNO_PEDRALVA_1273_01` | comunidades tradicionais afroperiféricas | `Matriz_africana_quilombolas` | 2026-10-13 | Classificacao manual aprovada pelo pesquisador; nao generalizar para outros casos |

A exceção é **específica desse ID**. O script explicita que `comunidades tradicionais afroperiféricas` foi aprovada como `Matriz_africana_quilombolas` e que a regra não deve ser extrapolada automaticamente para outros objetos.

### 2.3. Pendências e reprodutibilidade

O arquivo `04_pendencias_manual(1).csv` contém **0 linhas de pendências**, preservando somente o cabeçalho. Isso registra o estado do relatório recebido; **não comprova**, por si só, que toda a taxonomia ou todas as decisões históricas foram auditadas individualmente. O script também gera `04_dicionario_rotulos_observados.csv`, `04_classificacao_por_emenda.csv`, `04_regressoes_publicos_CR2.csv` e outros outputs, que não foram fornecidos neste lote.

## 3. COD 12 — matriz completa e decisões de 17 casos

O arquivo `10_cod12_classificacao_por_emenda(2).csv` reúne as **108 emendas** da classificação complementar, com `id_emenda`, ano, parlamentar, subcódigo CAP, valor, categoria, objeto e beneficiário. O arquivo **de entrada** `COD12_mapa_manual_108.csv` contém 108 IDs e as categorias, e corresponde integralmente ao CSV de resultado (zero divergências de categoria ou status de revisão).

| Código | Categoria | Emendas |
|---|---|---:|
| **I** | Segurança institucional | 55 |
| **V** | Videomonitoramento | 36 |
| **D** | Violência contra mulheres/de gênero/doméstica | 15 |
| **O** | Outros/não identificável | 2 |

**Valor nominal total:** R$ 23.990.135,00. **Todas as 108 linhas estão com `revisao_recomendada = NAO`.**

### 3.1. Histórico das decisões manuais aprovadas

O arquivo `10_cod12_decisoes_manuais_aprovadas(1).csv` contém 17 decisões: **7 reclassificações** e **10 manutenções**. Todas as categorias aprovadas coincidem com o mapa manual de 108 emendas anexado.

| `id_emenda` | Antes → aprovado | Decisão | Justificativa registrada pelo pesquisador |
|---|---|---|---|
| `2022_MACAE_EVARISTO_388_01` | `D` → `D` | MANTER | Benvinda: atendimento a mulheres em situacao de violencia; manter D. |
| `2022_MARILDA_PORTELA_526_01` | `I` → `I` | MANTER | Motocicletas para policiamento escolar; manter seguranca institucional. |
| `2022_NIKOLAS_FERREIRA_793_01` | `I` → `I` | MANTER | Monitoramento interno de batalhao da PM; manter como seguranca institucional. |
| `2023_PEDRO_PATRUS_764_01` | `D` → `D` | MANTER | Rede municipal de enfrentamento a violencia contra mulheres e meninas; D em sentido amplo. |
| `2024_BRAULIO_LARA_1133_01` | `O` → `D` | RECLASSIFICAR | Projeto Centro Kilamba classificado em D pelo pesquisador sob definicao ampla. |
| `2024_MARCELA_TROPIA_772_01` | `V` → `V` | MANTER | Pontos de monitoramento na Centro-Sul; manter videomonitoramento. |
| `2025_BRAULIO_LARA_1339_01` | `O` → `D` | RECLASSIFICAR | Projeto Kilamba para mulheres classificado em D pelo pesquisador sob definicao ampla. |
| `2025_BRUNO_PEDRALVA_1183_01` | `V` → `V` | MANTER | Videomonitoramento da UPA Pampulha; manter V. |
| `2025_DR_CELIO_FROIS_583_01` | `O` → `I` | RECLASSIFICAR | Equipamentos de APH tatico-policial; pesquisador decidiu classificar em I. |
| `2025_MARCELA_TROPIA_891_01` | `V` → `V` | MANTER | Cameras de seguranca em parques; manter V. |
| `2026_BRAULIO_LARA_1141_01` | `O` → `O` | MANTER | Seguranca publica municipal generica de R$ 2 milhoes; pesquisador manteve O. |
| `2026_CIDA_FALABELLA_589_01` | `D` → `D` | MANTER | Seminario Guardia Maria da Penha; manter D. |
| `2026_JUHLIA_SANTOS_1006_01` | `O` → `D` | RECLASSIFICAR | Prevencao a violencia de genero contra mulheres trans; D em sentido amplo. |
| `2026_JUHLIA_SANTOS_1021_01` | `O` → `O` | MANTER | Prevencao social a criminalidade via Instituto Macunaima, sem submodalidade especificada; manter O. |
| `2026_JUNINHO_LOS_HERMANOS_537_01` | `O` → `I` | RECLASSIFICAR | Veiculos destinados a Guarda Municipal, segundo informacao adicional do pesquisador. |
| `2026_MARILDA_PORTELA_1169_01` | `O` → `V` | RECLASSIFICAR | Monitoramento eletronico em unidades SUS-BH; pesquisador decidiu classificar em V. |
| `2026_PABLO_ALMEIDA_1137_01` | `O` → `I` | RECLASSIFICAR | Armas destinadas a Guarda Municipal, segundo informacao adicional do pesquisador. |

### 3.2. Índice completo da matriz de 108 emendas

As 108 linhas abaixo apresentam os códigos finais, com os detalhes substantivos completos (objeto e beneficiário) preservados no CSV original. Não houve recodificação neste dossiê.

| Ano | `id_emenda` | Categoria | Valor nominal (R$) |
|---|---|---|---:|
| 2022 | `2022_BIM_DA_AMBULANCIA_853_01` | `I` | 66.000,00 |
| 2022 | `2022_CLAUDIO_DO_MUNDO_NOVO_206_01` | `I` | 100.000,00 |
| 2022 | `2022_MACAE_EVARISTO_388_01` | `D` | 46.000,00 |
| 2022 | `2022_MARILDA_PORTELA_519_01` | `I` | 217.047,00 |
| 2022 | `2022_MARILDA_PORTELA_526_01` | `I` | 176.000,00 |
| 2022 | `2022_NIKOLAS_FERREIRA_497_01` | `I` | 350.610,00 |
| 2022 | `2022_NIKOLAS_FERREIRA_707_01` | `I` | 1.673,00 |
| 2022 | `2022_NIKOLAS_FERREIRA_728_01` | `I` | 115.187,00 |
| 2022 | `2022_NIKOLAS_FERREIRA_759_01` | `I` | 85.149,00 |
| 2022 | `2022_NIKOLAS_FERREIRA_761_01` | `I` | 6.709,00 |
| 2022 | `2022_NIKOLAS_FERREIRA_793_01` | `I` | 25.000,00 |
| 2022 | `2022_NIKOLAS_FERREIRA_864_01` | `I` | 116.870,00 |
| 2022 | `2022_REINALDO_GOMES_PRETO_SACOLAO_815_01` | `I` | 302.098,00 |
| 2023 | `2023_BRUNO_MIRANDA_617_01` | `V` | 200.000,00 |
| 2023 | `2023_CLAUDIO_DO_MUNDO_NOVO_403_01` | `I` | 200.000,00 |
| 2023 | `2023_DUDA_SALABERT_602_01` | `I` | 100.000,00 |
| 2023 | `2023_HENRIQUE_BRAGA_949_01` | `V` | 250.000,00 |
| 2023 | `2023_MACAE_EVARISTO_471_01` | `I` | 60.000,00 |
| 2023 | `2023_MARCELA_TROPIA_700_01` | `V` | 400.000,00 |
| 2023 | `2023_MARILDA_PORTELA_508_01` | `V` | 200.000,00 |
| 2023 | `2023_MARILDA_PORTELA_509_01` | `D` | 140.000,00 |
| 2023 | `2023_NIKOLAS_FERREIRA_930_01` | `I` | 700.000,00 |
| 2023 | `2023_PEDRO_PATRUS_764_01` | `D` | 120.000,00 |
| 2023 | `2023_PROFESSOR_JULIANO_LOPES_985_01` | `V` | 200.000,00 |
| 2023 | `2023_REINALDO_GOMES_PRETO_SACOLAO_937_01` | `I` | 160.266,00 |
| 2023 | `2023_REINALDO_GOMES_PRETO_SACOLAO_954_01` | `I` | 100.000,00 |
| 2023 | `2023_ALVARO_DAMIAO_1057_01` | `V` | 380.000,00 |
| 2024 | `2024_BRAULIO_LARA_1133_01` | `D` | 93.801,00 |
| 2024 | `2024_BRUNO_MIRANDA_1159_01` | `I` | 80.000,00 |
| 2024 | `2024_CLEITON_XAVIER_496A_01` | `I` | 800.000,00 |
| 2024 | `2024_FERNANDA_PEREIRA_ALTOE_392_01` | `V` | 250.000,00 |
| 2024 | `2024_GABRIEL_707_01` | `V` | 150.000,00 |
| 2024 | `2024_HELINHO_DA_FARMACIA_999A_01` | `D` | 100.000,00 |
| 2024 | `2024_JANAINA_CARDOSO_517_01` | `D` | 650.000,00 |
| 2024 | `2024_JUNINHO_LOS_HERMANOS_526_01` | `I` | 50.000,00 |
| 2024 | `2024_MARCELA_TROPIA_753_01` | `V` | 200.000,00 |
| 2024 | `2024_MARCELA_TROPIA_754_01` | `V` | 200.000,00 |
| 2024 | `2024_MARCELA_TROPIA_772_01` | `V` | 100.000,00 |
| 2024 | `2024_MARILDA_PORTELA_252_01` | `I` | 900.000,00 |
| 2024 | `2024_MILTINHO_CGE_1123_01` | `I` | 50.000,00 |
| 2024 | `2024_WAGNER_FERREIRA_949_01` | `V` | 50.000,00 |
| 2024 | `2024_WAGNER_FERREIRA_950_01` | `V` | 150.000,00 |
| 2024 | `2024_WILSINHO_DA_TABU_304A_01` | `I` | 100.000,00 |
| 2025 | `2025_BRAULIO_LARA_1338_01` | `I` | 60.000,00 |
| 2025 | `2025_BRAULIO_LARA_1339_01` | `D` | 60.000,00 |
| 2025 | `2025_BRAULIO_LARA_913351_01` | `V` | 250.000,00 |
| 2025 | `2025_BRUNO_MIRANDA_725_01` | `D` | 100.000,00 |
| 2025 | `2025_BRUNO_PEDRALVA_1161_01` | `D` | 50.000,00 |
| 2025 | `2025_BRUNO_PEDRALVA_1183_01` | `V` | 200.000,00 |
| 2025 | `2025_BRUNO_PEDRALVA_1184_01` | `V` | 300.000,00 |
| 2025 | `2025_CIDA_FALABELLA_1401_01` | `D` | 50.000,00 |
| 2025 | `2025_CIDA_FALABELLA_1417_01` | `V` | 100.000,00 |
| 2025 | `2025_CLAUDIO_DO_MUNDO_NOVO_909791_01` | `I` | 50.000,00 |
| 2025 | `2025_CLAUDIO_DO_MUNDO_NOVO_909831_01` | `I` | 50.000,00 |
| 2025 | `2025_DR_CELIO_FROIS_583_01` | `I` | 250.000,00 |
| 2025 | `2025_DR_CELIO_FROIS_592_01` | `V` | 300.000,00 |
| 2025 | `2025_FERNANDA_PEREIRA_ALTOE_833_01` | `V` | 574.000,00 |
| 2025 | `2025_FERNANDA_PEREIRA_ALTOE_908311_01` | `V` | 100.000,00 |
| 2025 | `2025_HELINHO_DA_FARMACIA_1256_01` | `D` | 350.000,00 |
| 2025 | `2025_HELINHO_DA_FARMACIA_1377_01` | `V` | 200.000,00 |
| 2025 | `2025_JANAINA_CARDOSO_770_01` | `V` | 301.000,00 |
| 2025 | `2025_JANAINA_CARDOSO_781_01` | `D` | 589.750,00 |
| 2025 | `2025_JUNINHO_LOS_HERMANOS_1119_01` | `V` | 300.000,00 |
| 2025 | `2025_JUNINHO_LOS_HERMANOS_1123_01` | `I` | 100.000,00 |
| 2025 | `2025_LOIDE_GONCALVES_1503_01` | `V` | 200.000,00 |
| 2025 | `2025_MARCELA_TROPIA_890_01` | `V` | 250.000,00 |
| 2025 | `2025_MARCELA_TROPIA_891_01` | `V` | 200.000,00 |
| 2025 | `2025_MARILDA_PORTELA_1055_01` | `I` | 50.000,00 |
| 2025 | `2025_MARILDA_PORTELA_910371_01` | `I` | 220.000,00 |
| 2025 | `2025_MILTINHO_CGE_1272_01` | `I` | 80.000,00 |
| 2025 | `2025_MILTINHO_CGE_1273_01` | `I` | 79.500,00 |
| 2025 | `2025_PEDRO_PATRUS_914761_01` | `I` | 50.000,00 |
| 2025 | `2025_PRETO_566_01` | `V` | 400.000,00 |
| 2025 | `2025_PROFESSOR_JULIANO_LOPES_940_01` | `V` | 50.000,00 |
| 2025 | `2025_PROFESSOR_JULIANO_LOPES_941_01` | `V` | 50.000,00 |
| 2025 | `2025_PROFESSOR_JULIANO_LOPES_942_01` | `V` | 50.000,00 |
| 2025 | `2025_PROFESSOR_JULIANO_LOPES_943_01` | `V` | 50.000,00 |
| 2025 | `2025_SERGIO_FERNANDO_PINHO_TAVARES_1544_01` | `V` | 200.000,00 |
| 2025 | `2025_SERGIO_FERNANDO_PINHO_TAVARES_1547_01` | `V` | 200.000,00 |
| 2026 | `2026_ARRUDA_264_01` | `I` | 115.000,00 |
| 2026 | `2026_BRAULIO_LARA_1141_01` | `O` | 2.000.000,00 |
| 2026 | `2026_BRUNO_MIRANDA_1255_01` | `I` | 150.000,00 |
| 2026 | `2026_CIDA_FALABELLA_589_01` | `D` | 90.000,00 |
| 2026 | `2026_CLAUDIO_DO_MUNDO_NOVO_1335_01` | `I` | 140.000,00 |
| 2026 | `2026_CLEITON_XAVIER_509_01` | `I` | 600.000,00 |
| 2026 | `2026_DIEGO_SANCHES_644_01` | `I` | 100.000,00 |
| 2026 | `2026_DRA_MICHELLY_SIQUEIRA_1396_01` | `I` | 700.000,00 |
| 2026 | `2026_FERNANDA_PEREIRA_ALTOE_717_01` | `I` | 350.000,00 |
| 2026 | `2026_FERNANDA_PEREIRA_ALTOE_718_01` | `I` | 70.000,00 |
| 2026 | `2026_HELTON_JUNIOR_99_01` | `V` | 160.000,00 |
| 2026 | `2026_IRLAN_MELO_1437_01` | `I` | 70.000,00 |
| 2026 | `2026_IZA_LOURENCA_863_01` | `I` | 78.475,00 |
| 2026 | `2026_JANAINA_CARDOSO_1475_01` | `D` | 430.000,00 |
| 2026 | `2026_JUHLIA_SANTOS_1006_01` | `D` | 250.000,00 |
| 2026 | `2026_JUHLIA_SANTOS_1021_01` | `O` | 140.000,00 |
| 2026 | `2026_JUNINHO_LOS_HERMANOS_537_01` | `I` | 150.000,00 |
| 2026 | `2026_LUCAS_GANEM_1544_01` | `I` | 100.000,00 |
| 2026 | `2026_MARCELA_TROPIA_1502_01` | `I` | 140.000,00 |
| 2026 | `2026_MARILDA_PORTELA_1169_01` | `V` | 70.000,00 |
| 2026 | `2026_MARILDA_PORTELA_1176_01` | `I` | 200.000,00 |
| 2026 | `2026_MARILDA_PORTELA_1177_01` | `I` | 100.000,00 |
| 2026 | `2026_MARILDA_PORTELA_1178_01` | `I` | 100.000,00 |
| 2026 | `2026_NENEM_DA_FARMACIA_768_01` | `I` | 700.000,00 |
| 2026 | `2026_PABLO_ALMEIDA_1137_01` | `I` | 360.000,00 |
| 2026 | `2026_PROFESSORA_MARLI_1345_01` | `V` | 70.000,00 |
| 2026 | `2026_SARGENTO_JALYSON_919_01` | `I` | 800.000,00 |
| 2026 | `2026_UNER_AUGUSTO_984_01` | `I` | 350.000,00 |
| 2026 | `2026_WAGNER_FERREIRA_1258_01` | `I` | 200.000,00 |

## 4. Base analítica territorial CR2

A fonte anexada `02_BASE_ANALITICA_COM_PARTIDOS_OFICIAIS_2022_2026(1).csv` é um **CSV separado por ponto e vírgula (`;`)**, com **2.357 linhas e 69 colunas**. Há **2.351 pares emenda–localidade com `amostra_analitica = 1`** e seis excluídos. A segunda cópia enviada, com sufixo `(2)`, possui o mesmo SHA-256; por economia, apenas uma das duas cópias idênticas integra o ZIP.

A unidade de observação é o **par `id_emenda` × `id_localidade`**. O valor `valor_alocado_rs` é o montante atribuível ao par conforme regra analítica de rateio, **não valor executado no endereço**. O campo `log_valor_alocado` representa o desfecho modelado. A concentração eleitoral está registrada como `concentracao_pct_1000m`, `concentracao_pct_2000m` e `concentracao_pct_5000m`, acompanhada de `n_locais_*`, votos próximos e controles orçamentários e partidários.

**Pares elegíveis:** 2,351; **vereadores distintos no painel elegível:** 72. O recorte central da monografia usa 2 km; 1 km e 5 km entram em análises de sensibilidade. Inferência CR2 com correção de Satterthwaite é realizada em scripts estatísticos separados, não no CSV.

### 4.1. As seis exclusões por ausência de geometria canônica

| ID emenda | Localidade | Motivo informado na base |
|---|---|---|
| `2022_WANDERLEY_PORTO_316_01` | `LOC_265` | SEM_GEOMETRIA_CANONICA |
| `2022_WILSINHO_DA_TABU_447_01` | `LOC_291` | SEM_GEOMETRIA_CANONICA |
| `2022_WILSINHO_DA_TABU_451_01` | `LOC_10` | SEM_GEOMETRIA_CANONICA |
| `2023_BRAULIO_LARA_369_01` | `LOC_556` | SEM_GEOMETRIA_CANONICA |
| `2025_MARCELA_TROPIA_1174_01` | `LOC_845` | SEM_GEOMETRIA_CANONICA |
| `2025_PRETO_1144_01` | `LOC_846` | SEM_GEOMETRIA_CANONICA |

A lista também consta em `inventarios_derivados/SEIS_EXCLUSOES_SEM_GEOMETRIA.csv`. Todos os 2.351 pares elegíveis possuem `id_localidade` presente no GeoPackage fornecido.

### 4.2. Proveniência e interpretação dos valores

O painel traz campos como `fonte_partido_oficial`, `ideologia_zucco_prioritaria_oficial`, `origem_ideologia_ajustada`, `ano_eleicao_coorte` e `versao_coordenadas_tse`. Os registros recebidos apontam para `BASE PARTIDOS GERAL(9).xlsx` como fonte partidária do painel territorial, **diferente** do nome esperado pelo `_config_funcoes.R` do módulo anual (`BASE PARTIDOS GERAL.xlsx`). A equivalência das versões precisa ser auditada antes de alegar reprodução automatizada integral.

## 5. Geometrias canônicas e decisões espaciais

O GeoPackage `LOCALIDADES_GEO_CANONICAS_2022_2026(3).gpkg` tem seis camadas, que podem ser abertas no QGIS ou lidas com software compatível com GeoPackage:

| Camada | Registros | SRS | Finalidade |
|---|---:|---|---|
| `localidades_geometria_961` | 961 | EPSG:31983 | geometrias canônicas integradas |
| `localidades_pontos_815` | 815 | EPSG:31983 | pontos |
| `localidades_linhas_72` | 72 | EPSG:31983 | linhas e multilinhas |
| `localidades_poligonos_74` | 74 | EPSG:31983 | polígonos e multipolígonos |
| `pontos_representativos_961` | 961 | EPSG:31983 | ponto de referência de cada localidade no CRS métrico |
| `pontos_representativos_4674` | 961 | EPSG:4674 | pontos representativos no CRS geográfico |

Na camada canônica há **815 POINT**, **65 LINESTRING**, **7 MULTILINESTRING**, **63 POLYGON** e **11 MULTIPOLYGON**; em conjunto: 815 pontos, 72 linhas e 74 polígonos. O CRS métrico indicado é **EPSG:31983**; a camada final de pontos representativos também é oferecida no CRS **EPSG:4674**.

### 5.1. Identidade longitudinal, redirects e divisões

Os metadados espaciais registram **7 localidades com `possui_redirect = 1`**, **2 com `possui_split = 1`** e **80 com `proxy_logradouro_sem_numero = 1`**. Esses marcadores indicam decisões e procedimentos, mas **não substituem os motivos narrativos das auditorias anteriores**. O campo `ids_historicos` permite rastrear correspondências de identificadores.

| Natureza espacial (`tipo_origem_geo`) | Localidades |
|---|---:|
| `ENDERECO_NUMERO` | 686 |
| `VIARIA` | 95 |
| `LOGRADOURO_SEM_NUMERO` | 92 |
| `ESPACO_PUBLICO` | 88 |

### 5.2. Tratamento espacial da pesquisa

- **GEO=1:** exige evidência suficiente de vinculação espacial da aplicação de recursos ao nível de rua. Endereço cadastral ou sede administrativa isolada não bastam.
- **Equipamentos territorialmente identificáveis:** creches, escolas, hospitais, abrigos, centros de saúde e outras unidades com aplicação espacial demonstrada podem ser materializados quando o destinatário é inequívoco. A exceção provisória hospitalar da base 2025 deve permanecer explicitamente documentada.
- **Pontos, linhas e polígonos:** representam diferentes graus e formas de determinação espacial; pontos representativos servem para cartografia e determinadas operações, mas não apagam a geometria canônica original.
- **Trechos e ruas sem número:** podem recorrer a geometria linear ou proxies auditáveis; o proxy deve ser distinguido de uma coordenada física exata.
- **Vínculos emenda–localidade:** uma emenda pode apontar para vários locais e um local pode receber várias emendas em exercícios diferentes. A identidade longitudinal usa a chave `ID_LOCALIDADE`.

### 5.3. Inventário geográfico separado

O arquivo `inventarios_derivados/INVENTARIO_PROVENIENCIA_GEOMETRIAS_961.csv` extrai **somente atributos textuais** do GeoPackage para facilitar a auditoria (origem, precisão, tipo de geometria, redirects, splits e proxies). **A geometria vetorial íntegra permanece no `.gpkg` original** e não foi editada.

### 5.4. O que não está resolvido pelos arquivos disponíveis

As decisões espaciais históricas foram parcialmente incorporadas como atributos ao GeoPackage, mas os arquivos aqui recebidos não contêm **a sequência completa dos scripts de geocodificação e todos os logs de overrides manuais**, nem a rotina que gerou o CSV analítico CR2 a partir das fontes eleitorais e geográficas. Essas dependências precisam ser adicionadas ao GitHub para reprodução de ponta a ponta.

## 6. Como executar os scripts R fornecidos sem alterar os dados

A sequência do **módulo de públicos-alvo** é: `_config_funcoes.R` (carregado por `source()`); `01_preparar.bases.R`; `02_ideologia_partidos.R`; `04_publicos_alvo.R`. Os códigos usam caminhos fixos `C:/TCC_BH_EMENDAS` e esperam cinco bases codificadas em `coding/` e uma base de partidos com o nome **`BASE PARTIDOS GERAL.xlsx`** em `data_raw/`. Os XLSX de origem não são regravados pelos scripts. Não executamos esses R scripts neste dossiê; suas dependências de pacotes e a equivalência da base de partidos devem ser conferidas antes.

O **módulo COD 12** depende adicionalmente dos scripts de decomposição e visualização (`10_decompor_COD12_vereador_ano_CORRIGIDO.R` e `12_tabela_e_bolhas_COD12_zucco_ATUALIZADO.R`), que **não foram anexados neste lote**. Os insumos aprovados estão incluídos integralmente.

O **módulo de regressão territorial** requer as rotinas de inferência CR2, por exemplo `REPRODUZIR_INFERENCIA_CR2_TCC_BH.R` e `02_reproduzir_interacao_CR2_no_R.R`, que **não integram este pacote**. Sua base analítica de entrada está incluída, pronta para ser lida com separador `;`.

## 7. Integridade e limites de publicação

`MANIFESTO_SHA256.csv` contém nome, tamanho e hashes de cada arquivo original preservado; a identidade byte a byte das cópias foi verificada. Os CSVs da pasta `inventarios_derivados/` são derivados **sem alterações das fontes**, somente para consulta. Não houve criação de geometria nova, substituição de classificação ou recodificação manual.

**Situação final:** documentação e preservação integral dos **quatro insumos solicitados**, com rastreabilidade de 17 decisões COD 12 e a decisão individual do script 04. **Reprodução automatizada completa** do início ao fim depende ainda dos scripts e logs anteriores explicitamente identificados.

## Apêndice — referência dos arquivos originais fornecidos

| Arquivo em `fontes_originais/` | Formato |
|---|---|
| `04_decisoes_manuais.csv` | CSV |
| `04_pendencias_manual(1).csv` | CSV |
| `04_publicos_alvo.R` | R |
| `COD12_mapa_manual_108.csv` | CSV |
| `10_cod12_decisoes_manuais_aprovadas(1).csv` | CSV |
| `10_cod12_classificacao_por_emenda(2).csv` | CSV |
| `02_BASE_ANALITICA_COM_PARTIDOS_OFICIAIS_2022_2026(1).csv` | CSV |
| `LOCALIDADES_GEO_CANONICAS_2022_2026(3).gpkg` | GPKG |
| `_config_funcoes.R` | R |
| `01_preparar.bases.R` | R |
| `02_ideologia_partidos.R` | R |
