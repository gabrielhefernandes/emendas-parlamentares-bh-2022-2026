# Reprodutibilidade analítica — emendas municipais de Belo Horizonte (2022–2026)

Este pacote reúne os **scripts R efetivamente executados e validados** pelo pesquisador para as análises temáticas, públicos-alvo, segurança (COD 12), modelos territoriais CR2 e mapas eleitorais da monografia, além dos insumos derivados e arquivos de referência.

## Limites do escopo

A reprodução parte das cinco planilhas anuais **já codificadas manualmente**, da base de partidos e das **geometrias canônicas consolidadas**. Não se afirma a reprodução automática da codificação humana nem de toda a cadeia histórica de geocodificação, que exigiu inspeções e correções manuais. A procedência e as decisões manuais estão documentadas em `documentacao/`.

**Não contém os 1.035 PNGs gerados.** Eles são produtos derivados reproduzíveis pelo script cartográfico, não entradas. Os relatórios de auditoria da execução integral estão em `documentacao/validacao_cartografica/`.

## Instalação no repositório

Os diretórios `scripts/`, `dados/` e `documentacao/` deste ZIP são um acréscimo à estrutura atual de `gabrielhefernandes/emendas-parlamentares-bh-2022-2026`. Não apague as planilhas e outras bases já publicadas no GitHub.

Para executar o projeto **a partir do repositório**, os arquivos já presentes devem permanecer nos caminhos exatos:

- `dados/codificados/codificacao_emendas_{2022,2023,2024,2025,2026}_FINAL_21-09-2026.xlsx`;
- `dados/partidos/BASE PARTIDOS GERAL.xlsx`;
- `dados/eleitorais/votos_vereadores_relevantes_geografia_eleitoral_v4.csv`.

O ZIP acrescenta `dados/analiticos`, `dados/geoespaciais` e o CSV do universo em `dados/eleitorais`. A configuração dos scripts também aceita as seis planilhas colocadas **diretamente na raiz** (como testado na pasta `C:/TCC_BH_EMENDAS/replicacao`), sem alterar os dados.

## Execução validada

Com R 4.5.2 e pacotes necessários instalados, a partir da raiz:

```r
Sys.setenv(TCC_BH_RAIZ = normalizePath(getwd(), winslash = '/'))
source('scripts/R/verificar_instalacao_tcc.R', encoding = 'UTF-8')
source('scripts/R/executar_analises_tcc.R', encoding = 'UTF-8')
source('scripts/R/executar_territorial_tcc.R', encoding = 'UTF-8')
```

Para um teste cartográfico pontual:

```r
Sys.setenv(TCC_TESTAR_APENAS = '2022_BELLA_GONCALVES')
source('scripts/R/06_mapas_eleitorais/01_mapas_eleitorais_emendas.R', encoding='UTF-8')
```

Para todos os 207 vereador–anos:

```r
Sys.unsetenv('TCC_TESTAR_APENAS')
source('scripts/R/06_mapas_eleitorais/01_mapas_eleitorais_emendas.R', encoding='UTF-8')
```

As saídas são criadas sob `resultados/replicacao/` e não sobrescrevem os dados originais.

## Validações documentadas (R 4.5.2, `clubSandwich` 0.7.0)

- 4.796 emendas; 4.553 com CAP; 2.491 não-saúde; 207 perfis vereador–ano e 206 portfólios não-saúde;
- 34 regressões temáticas CR2 e 30 regressões por público-alvo executadas;
- COD 12: 108 emendas, R$ 23.990.135, 17 decisões manuais aprovadas; saídas gráficas geradas;
- 10 modelos territoriais CR2 conferidos numericamente com as referências Python dentro das tolerâncias do script;
- 2 modelos de interação saúde–concentração conferidos numericamente com Python;
- 207 conjuntos cartográficos (40, 44, 41, 41, 41 por ano), contendo exatamente 5 mapas cada: **1.035 PNGs**;
- 2.246 rateios conferidos; diferenças máximas de aproximadamente R$ 1,05 × 10⁻⁹; 6 pares sem geometria devidamente listados.

Esses números derivam dos logs de execução e dos relatórios produzidos no computador do pesquisador, não de uma reexecução do R neste ambiente de preparação. O arquivo compactado dos PNGs foi inspecionado separadamente e confirmou os 1.035 arquivos distribuídos em 207 conjuntos, sem falhas de extração de dados.

## Notas importantes

- O conjunto dos modelos geográficos utiliza 2.351 observações elegíveis de uma base com 2.357 pares emenda–localidade.
- Uma mesma emenda pode beneficiar várias localidades; o valor é rateado segundo os critérios do projeto.
- Os mapas «com saúde» **incluem** as emendas de saúde; os «sem saúde» as excluem. No caso de ausência de emendas de saúde no recorte, as comparações podem ser idênticas.
- O material permite **replicar as análises a partir de dados manualmente codificados e geometria final**, e não reivindica refazer decisões humanas automaticamente.
- Os arquivos de dados no GitHub devem ser conferidos quanto à versão utilizada antes de declarar identidades de hashes de entradas entre computadores.
