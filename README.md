# Emendas parlamentares municipais de Belo Horizonte (2022–2026)

Repositório de transparência e replicabilidade da pesquisa de **Gabriel Henriques Fernandes** (Ciências Sociais, UFMG). O recorte central da monografia é **2023–2025**, com extensão longitudinal a **2022 e 2026**.

## Organização

| Diretório | Conteúdo |
| --- | --- |
| [dados/brutos](dados/brutos/) | Bases oficiais da Prefeitura de Belo Horizonte (2022–2026), em arquivos Excel identificados por ano, preservados sem alterações |
| [dados/codificados](dados/codificados/) | Planilhas de emendas codificadas de 2022 a 2026, reunidas em uma única pasta |
| [dados/localidades](dados/localidades/) | Planilhas anuais com as abas `LOCALIDADES_APRESENTACAO`, `LOCALIDADES_MESTRE` e `RELACOES` |
| [dados/partidos](dados/partidos/) | Base geral de partidos, classificação ideológica e referências metodológicas |
| [dados/eleitorais](dados/eleitorais/) | Dados de votação por seção eleitoral, locais de votação geocodificados e tabelas de correspondência |
| [mapas](mapas/) | Mapas de emendas georreferenciáveis (GEO=1), organizados por ano (2022–2026) e vereador, com versões incluindo e excluindo as emendas de saúde. Também há mapas de votação eleitoral e a sobreposição dos mapas |
| [referencias/manuais_orcamentarios](referencias/manuais_orcamentarios/) | Manual PPAG 2022–2025 em PDF e tabelas de referência PPAG/LOA de 2023 a 2026 em Excel |
| [scripts/R](scripts/R/) | Estrutura destinada aos scripts de preparação, codificação, localidades, georreferenciamento, mapas e análises; os scripts executáveis ainda serão incorporados |

Os arquivos anuais de dados brutos, codificados e de localidades estão diretamente em suas respectivas pastas, **sem subdiretórios por ano**. Os mapas permanecem separados por ano, em [2022](mapas/2022/), [2023](mapas/2023/), [2024](mapas/2024/), [2025](mapas/2025/) e [2026](mapas/2026/).

## Replicabilidade

1. Consultar as bases disponibilizadas em [dados/brutos](dados/brutos/) e sua origem no [Portal da PBH](https://prefeitura.pbh.gov.br/governo/emendas-parlamentares-acompanhamento), registrando URL, versão e datas de atualização e extração.
2. Preservar os arquivos brutos e consultar as [tabelas e os manuais orçamentários oficiais](https://prefeitura.pbh.gov.br/transparencia/contas-publicas/lei-orcamentaria-anual-loa/manuais-de-elaboracao-orcamentaria) correspondentes a cada exercício.
3. Consultar o [Manual de Codificação CAP/Brasil (2019)](https://comparativeagendas.s3.amazonaws.com/codebookfiles/CodeManual_Junho_2019_4.pdf). A codificação temática atribui um macrocódigo e um subcódigo conforme a política substantiva; saúde, público-alvo e georreferenciabilidade são dimensões adicionais da pesquisa.
4. Relacionar as emendas às localidades pelas chaves e pelas tabelas `RELACOES`, observando que a presença de endereço cadastral ou sede única de uma entidade **não basta**, por si só, para classificar a emenda como georreferenciável (GEO=1).
5. Distinguir coordenadas de locais identificados de aproximações espaciais (proxies), como pontos médios de trechos de vias, e documentar as rotinas em R utilizadas na preparação dos dados e na produção dos mapas.

**Nota:** a presença de pastas reservadas para scripts não significa que o código de reprodução já tenha sido publicado integralmente. As classificações analíticas das emendas são resultados da pesquisa, não classificações oficiais da Prefeitura de Belo Horizonte.
