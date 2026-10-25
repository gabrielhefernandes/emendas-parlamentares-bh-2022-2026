# Emendas parlamentares municipais de Belo Horizonte (2022–2026)

Repositório de transparência e replicabilidade da pesquisa de **Gabriel Henriques Fernandes** (Ciências Sociais, UFMG). O recorte central da monografia é **2023–2025**, com extensão longitudinal a **2022 e 2026**.

## Organização

| Diretório | Conteúdo |
| --- | --- |
| [dados/brutos](dados/brutos/) | Bases oficiais da PBH por exercício, preservadas sem alteração |
| [dados/codificados](dados/codificados/) | Planilhas codificadas por ano |
| [dados/localidades](dados/localidades/) | Relações, localidades de apresentação e localidades mestre |
| [dados/partidos](dados/partidos/) | Base partidária geral, ideologia e referências |
| [dados/eleitorais](dados/eleitorais/) | Dados de votos por seção eleitoral |
| [mapas/emendas](mapas/emendas/) | Cartografia GEO=1, com saúde e sem saúde |
| [mapas/eleitorais](mapas/eleitorais/) | Cartografia por eleição e candidato |
| [referencias/manuais_orcamentarios](referencias/manuais_orcamentarios/) | Tabelas e manuais PPAG/LOA |
| [documentacao/metodologia](documentacao/metodologia/) | Codebook CAP e decisões próprias de codificação |
| [scripts/R](scripts/R/) | Preparação, codificação, georreferenciamento, mapas e análises |
| [auditorias](auditorias/) | Relatórios de qualidade, controle e integridade |

## Replicabilidade

1. Baixar os arquivos originais no [Portal da PBH](https://prefeitura.pbh.gov.br/governo/emendas-parlamentares-acompanhamento), registrando URL, versão, data de atualização e extração.
2. Preservar os arquivos brutos e consultar as [tabelas orçamentárias oficiais](https://prefeitura.pbh.gov.br/transparencia/contas-publicas/lei-orcamentaria-anual-loa/manuais-de-elaboracao-orcamentaria).
3. Consultar o [Manual de Codificação CAP/Brasil (2019)](https://comparativeagendas.s3.amazonaws.com/codebookfiles/CodeManual_Junho_2019_4.pdf). A codificação temática segue uma política substantiva, com um macro e um subcódigo; saúde, público-alvo e GEO são dimensões adicionais do estudo.
4. Associar emendas e localidades pelos identificadores, observando que a presença de endereço cadastral ou sede única **não basta** para GEO=1.
5. Distinguir coordenadas confirmadas de proxies espaciais e documentar os scripts R utilizados.

**Situação da publicação:** alguns diretórios podem conter apenas documentação de preparação. Não considerar arquivos preparados localmente como publicados no GitHub antes de sua presença efetiva no repositório. Bases oficiais brutas e scripts R completos ainda serão acrescentados.

Consulte [CHANGELOG.md](CHANGELOG.md), [LICENCIAMENTO.md](LICENCIAMENTO.md), [CITATION.cff](CITATION.cff) e os READMEs de cada área.