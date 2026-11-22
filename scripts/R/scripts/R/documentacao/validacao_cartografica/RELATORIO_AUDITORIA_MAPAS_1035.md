# Auditoria cartográfica final — 2022–2026

**Origem:** execução integral em R 4.5.2 pelo pesquisador e arquivo `vereadores.rar`.

| Ano | Vereador–ano | PNGs gerados |
| --- | ---: | ---: |
| 2022 | 40 | 200 |
| 2023 | 44 | 220 |
| 2024 | 41 | 205 |
| 2025 | 41 | 205 |
| 2026 | 41 | 205 |
| **Total** | **207** | **1.035** |

Foram localizados exatamente 207 conjuntos de cinco mapas cada (`eleitoral`, `com_saude`, `sem_saude`, `comparacao_com_saude` e `comparacao_sem_saude`). O arquivo RAR contém, adicionalmente, os três CSVs de auditoria incluídos nesta pasta.

**Rateio de emendas:** 2,246 linhas com `confere = TRUE` e diferença monetária máxima de 0.000000001048 real.

**Localidades sem geometria:** 6 pares, preservados na lista de exclusão. **Mapas sem localidades:** 42 combinações; essas saídas vazias são esperadas quando não há alocação georreferenciável para o vereador–ano.

Os PNGs foram totalmente descomprimidos e apresentaram a assinatura PNG esperada, dimensões uniformes 1936 × 2332 px e ausência de erros de descompressão para as entradas regulares.

**Recomendação de repositório:** conservar este inventário e o script que gera os mapas, evitando versionar mais de mil imagens derivadas em Git. Publicar apenas uma pequena seleção de mapas ilustrativos caso seja útil para navegação.
