# Publicação definitiva da replicabilidade do TCC BH 2022–2026

## O que será publicado

Este ZIP contém somente arquivos novos ou complementares, organizados conforme a estrutura existente do repositório `gabrielhefernandes/emendas-parlamentares-bh-2022-2026`. Não exclua nem substitua as cinco planilhas de `dados/codificados`, a planilha `dados/partidos/BASE PARTIDOS GERAL.xlsx` ou os demais arquivos já publicados.

## Publicação pelo GitHub Desktop

1. Abra o GitHub Desktop e entre na conta proprietária do repositório.
2. Selecione **File > Clone repository**, escolha `gabrielhefernandes/emendas-parlamentares-bh-2022-2026` e defina uma pasta local para o clone. Se ele já estiver clonado, use o clone existente e **Fetch origin**.
3. Extraia este ZIP em uma pasta temporária.
4. Copie para **a raiz do clone** as pastas `scripts`, `dados` e `documentacao`, além de `README_REPLICACAO_ANALITICA.md` e `MANIFESTO_PUBLICACAO_SHA256.csv`. **Não copie este guia**, a menos que queira publicá-lo.
5. Confirme no GitHub Desktop que somente os arquivos previstos foram adicionados e que nada foi excluído ou sobrescrito acidentalmente. O arquivo `.gpkg` é o único arquivo binário novo deste pacote.
6. Use a mensagem de commit `Publicar pipeline validada de replicabilidade do TCC BH 2022–2026` e clique **Commit to main** e **Push origin**.
7. Confirme que os arquivos aparecem no GitHub, especialmente `scripts/R/executar_analises_tcc.R`, `scripts/R/executar_territorial_tcc.R`, `dados/geoespaciais/LOCALIDADES_GEO_CANONICAS_2022_2026.gpkg` e `documentacao/DOSSIE_REPLICABILIDADE_2022_2026.md`.

## Como executar a partir do clone

Com o RStudio aberto na raiz do clone, rode:

```r
Sys.setenv(TCC_BH_RAIZ = normalizePath(getwd(), winslash = '/'))
source('scripts/R/verificar_instalacao_tcc.R', encoding = 'UTF-8')
source('scripts/R/executar_analises_tcc.R', encoding = 'UTF-8')
source('scripts/R/executar_territorial_tcc.R', encoding = 'UTF-8')
Sys.unsetenv('TCC_TESTAR_APENAS')
source('scripts/R/06_mapas_eleitorais/01_mapas_eleitorais_emendas.R', encoding = 'UTF-8')
```

O pacote foi validado em computador Windows com R 4.5.2 e `clubSandwich` 0.7.0. A reprodução parte de bases manualmente codificadas e geometrias canônicas já consolidadas; não automatiza as decisões humanas de codificação e geocodificação.
