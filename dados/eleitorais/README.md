# Dados eleitorais — Eleições municipais de Belo Horizonte (2020 e 2024)

## 1. Descrição

Este diretório reúne bases eleitorais utilizadas na pesquisa sobre as emendas parlamentares impositivas apresentadas pelos vereadores de Belo Horizonte entre 2022 e 2026.

Os dados eleitorais têm como fonte primária o **Tribunal Superior Eleitoral (TSE)** e abrangem as eleições municipais de 2020 e 2024.

As bases aqui disponibilizadas são produtos derivados dos dados eleitorais oficiais e não devem ser confundidas com os arquivos brutos originalmente publicados pelo TSE.

## 2. Arquivos disponíveis

### `votos_vereadores_relevantes_geografia_eleitoral_v4(2).csv`

Base eleitoral consolidada, contendo a votação dos candidatos selecionados por estabelecimento de votação nas eleições de 2020 e 2024.

Possui **41.001 registros**, distribuídos entre:

- Eleições de 2020: 23.002 registros, referentes a 53 candidatos e 434 estabelecimentos eleitorais.
- Eleições de 2024: 17.999 registros, referentes a 41 candidatos e 439 estabelecimentos eleitorais.

Cada registro associa um candidato, uma eleição e um estabelecimento de votação.

Entre as informações disponíveis estão a identificação do candidato, os votos nominais registrados, o total de votos do candidato em Belo Horizonte, a identificação do estabelecimento eleitoral, suas coordenadas geográficas e indicadores derivados de desempenho eleitoral.

Esta é a principal base eleitoral utilizada para construir os indicadores de concentração territorial dos votos empregados na análise das emendas.

### `locais_votacao_2020_BH_geocodificados_final_v1(3).csv`

Cadastro de **434 estabelecimentos de votação de Belo Horizonte nas eleições municipais de 2020**.

Contém informações sobre zona eleitoral, identificação e nome do estabelecimento, endereço, coordenadas geográficas e procedimentos de atribuição espacial.

### `locais_votacao_2024_BH_geocodificados_final_v1(3).csv`

Cadastro de **439 estabelecimentos de votação de Belo Horizonte nas eleições municipais de 2024**.

Apresenta estrutura semelhante à base de 2020, permitindo identificar e localizar os estabelecimentos utilizados nas análises eleitorais.

**Nota sobre as coordenadas:** os arquivos individuais de estabelecimentos preservam versões cadastrais que apresentaram divergências de posicionamento em três escolas. Essas divergências foram examinadas em auditoria geográfica posterior. Para reproduzir os indicadores territoriais finais, devem ser utilizadas as coordenadas refinadas da base eleitoral consolidada `v4(2)`, ou aplicadas as correções documentadas aos arquivos individuais.

### `crosswalk_vereadores_relevantes_TSE_munzona_v2(1).csv`

Tabela de correspondência entre os vereadores incluídos na pesquisa e seus respectivos registros eleitorais no TSE.

Contém 94 correspondências candidato–eleição, distribuídas entre 2020 e 2024.

Inclui nomes padronizados, números e identificadores dos candidatos, eleição de referência, partido registrado no TSE e informações sobre o procedimento de correspondência.

A tabela permite relacionar os parlamentares identificados nas bases de emendas aos registros de votação.

O partido registrado nessa tabela corresponde à eleição do TSE e não substitui a classificação partidária por exercício orçamentário adotada na pesquisa, cuja referência é a `BASE PARTIDOS GERAL.xlsx`, disponível em `dados/partidos/`.

## 3. Construção dos indicadores de concentração eleitoral

Para investigar a associação entre apoio eleitoral e distribuição territorial das emendas, foram calculados indicadores de concentração dos votos do vereador nas proximidades de cada localidade beneficiada.

A concentração eleitoral corresponde à porcentagem dos votos nominais municipais do vereador registrada em estabelecimentos de votação localizados dentro de determinado raio da localidade.

O indicador é calculado pela expressão:

**Concentração eleitoral (%) = (votos do vereador nos estabelecimentos situados dentro do raio ÷ total de votos nominais observados do vereador em Belo Horizonte) × 100.**

Foram considerados três raios de distância: 1 km, 2 km e 5 km.

A análise principal utiliza **2 km**, enquanto os demais raios são empregados em verificações de sensibilidade.

As distâncias foram calculadas em metros, utilizando o sistema de referência projetado EPSG:31983, a partir das geometrias das localidades beneficiadas e dos pontos correspondentes aos estabelecimentos eleitorais.

O processamento admite localidades representadas por pontos, linhas ou polígonos.

É importante ressaltar que o indicador representa a distribuição geográfica dos votos recebidos pelo próprio vereador, não a porcentagem dos eleitores da região que votaram nele. Também não permite identificar diretamente o local de residência dos eleitores, sendo uma aproximação.

## 4. Correspondência temporal entre eleições e emendas

Na especificação principal da análise territorial, adotou-se a seguinte correspondência entre exercícios das emendas e eleições de referência:

| Ano das emendas | Eleição de referência |
|---|---|
| 2022 | 2020 |
| 2023 | 2020 |
| 2024 | 2020 |
| 2025 | 2020 |
| 2026 | 2024 |

Adicionalmente, foi construída uma comparação exploratória utilizando os resultados eleitorais de 2024 para parte das emendas de 2025.

A escolha das eleições de referência constitui uma decisão metodológica da pesquisa e deve ser considerada na interpretação dos resultados. Em especial, o emprego dos votos de 2020 nas emendas de 2025 não corresponde ao pleito imediatamente anterior à legislatura iniciada naquele ano.

## 5. Limitações

Os dados deste diretório abrangem os candidatos relevantes para o universo de vereadores investigado, não constituindo uma base de todos os candidatos das eleições municipais de Belo Horizonte.

A localização de um estabelecimento eleitoral não equivale necessariamente à localização residencial de seus eleitores. Dessa forma, os indicadores produzidos representam aproximações da geografia eleitoral dos parlamentares.

Pequenas diferenças de georreferenciamento também podem influenciar a inclusão de estabelecimentos nos limites dos raios de distância.

Por fim, a concentração dos votos de um vereador em determinada área não demonstra, isoladamente, que a localidade constitua um reduto eleitoral em termos de desempenho relativo. Áreas com maior número de estabelecimentos e eleitores podem concentrar parcelas elevadas da votação de diferentes candidatos.

Essas limitações são consideradas na interpretação das análises estatísticas da pesquisa.

## 6. Fonte dos dados

**Fonte primária:** Tribunal Superior Eleitoral (TSE), dados eleitorais das eleições municipais de 2020 e 2024.

Portal oficial: https://dadosabertos.tse.jus.br/

As bases territoriais podem ser consultadas em `dados/localidades/`, enquanto a base analítica utilizada nas regressões e os scripts de estimação devem ser consultados, respectivamente, em `dados/analiticos/` e `scripts/`.

A reprodução integral dos indicadores espaciais requer tanto os dados eleitorais deste diretório quanto as geometrias das localidades e os scripts de processamento correspondentes.
