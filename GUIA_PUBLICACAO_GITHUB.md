# Como incorporar arquivos sem modificá-los

Use GitHub Desktop ou a opção **Add file → Upload files** para enviar planilhas XLSX, PDFs e PNGs às pastas correspondentes. Para garantir preservação binária, compare o SHA-256 do arquivo enviado com o SHA-256 do original. Não abra e salve novamente a planilha apenas para publicá-la.

Os arquivos devem preservar dados, identificadores, abas e formatação. Modificações futuras devem ter registro claro em CHANGELOG e, preferencialmente, em commits separados. O manifesto de hashes deve indicar a versão efetivamente publicada, sem afirmar que arquivos ausentes estejam disponíveis.
