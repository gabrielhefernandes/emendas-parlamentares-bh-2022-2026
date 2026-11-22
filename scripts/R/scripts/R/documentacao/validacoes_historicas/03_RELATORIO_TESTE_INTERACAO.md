# Teste formal de interação: emendas de saúde versus demais temas — BH, 2022–2026

## Pergunta

A relação entre a parcela dos votos do vereador registrada até 2 km das localidades contempladas e os valores das emendas indicadas **difere entre saúde e demais temas**?

## Duas perguntas estatísticas diferentes

- **Coeficiente setorial diferente de zero?** Testado separadamente com regressões para saúde ou não saúde.
- **Coeficientes setoriais diferentes entre si?** Testado pela interação saúde × concentração eleitoral na amostra conjunta. A significância num setor e não significância no outro **não é** demonstração de diferença entre setores (Gelman e Stern, 2006).

## Modelo de interação

`ln(valor alocado) = beta * concentracao_2km + theta * (concentracao_2km * saude) + controles + erro`

- `saude = 1` para macrocategoria CAP 03 e `0` para as demais.
- Inclinação fora da saúde: `beta`.
- Inclinação na saúde: `beta + theta`.
- Contraste de interesse: `theta` (saúde menos não saúde), hipótese nula `theta = 0`.
- O indicador de saúde individual não é acrescentado como intercepto separado porque a macrocategoria CAP já captura diferenças de nível entre esses grupos, e/ou os efeitos fixos desagregados capturam essas diferenças.
- 2.351 pares emenda–localidade; 72 grupos de vereadores; erros-padrão CR2 com alvo de identidade e graus de liberdade de Satterthwaite.

## Resultado

| Especificação | Fora da saúde (+10 pp) | Saúde (+10 pp) | Interação: beta por ponto percentual | p CR2 da interação |
|---|---:|---:|---:|---:|
| Controles comuns | +3,34% | +1,02% | -0,002267 | 0,3861 |
| Controles inteiramente flexíveis por setor | +4,27% | +1,24% | -0,002947 | 0,2662 |

A especificação flexível é **diretamente comparável às duas regressões setoriais anteriores**: permite efeitos fixos vereador–ano específicos para cada setor e um coeficiente específico do controle de número de estabelecimentos em cada setor, além dos controles CAP. Seus coeficientes reproduzem os mesmos +4,27% e +1,24% das regressões isoladas. O coeficiente de diferença (saúde menos não saúde) corresponde a -0,0029465 por ponto percentual, com erro-padrão CR2 ≈ 0,0025395, gl de Satterthwaite ≈ 13,38, p = 0,2662. O intervalo de confiança de 95% para o coeficiente de diferença vai aproximadamente de -0,008417 a +0,002524 e **inclui zero**.

A especificação com controles comuns corresponde ao teste anterior da Etapa 03, agora atualizado de CR1S para CR2. A diferença também não é estatisticamente identificada (p = 0,3861).

## O que se pode afirmar

1. A associação geral no modelo principal de todas as emendas (2 km) é positiva: +2,27% por dez pontos percentuais de concentração eleitoral (p CR2 = 0,0186).
2. Na subamostra sem saúde, a associação estimada é +4,27% (p CR2 = 0,0328).
3. Na subamostra somente de saúde, o coeficiente é positivo, +1,24%, mas com imprecisão estatística (p CR2 = 0,3959).
4. As estimativas pontuais diferem numericamente, mas o contraste formal de interação **não identifica uma diferença significativa** entre os setores; não se pode afirmar que a associação é maior fora da saúde.
5. Os resultados continuam sendo associativos, não causais, e somente entre localidades efetivamente contempladas.
6. Não rejeitar a diferença nula tampouco prova equivalência setorial; um teste formal de equivalência exigiria margem substantiva pré-definida e precisão suficiente.

## Nota sobre inferência

A execução em Python implementa CR2 via matriz de projeção com alvo identidade e Satterthwaite; a réplica correspondente em R (`clubSandwich`) foi escrita, mas **ainda não executada pelo usuário** para esse novo contraste. Os dez modelos anteriores, incluindo as subamostras, foram independentemente reproduzidos em R.

## Referência conceitual

Gelman, A.; Stern, H. (2006). The difference between “significant” and “not significant” is not itself statistically significant. *The American Statistician*, 60(4), 328–331. https://doi.org/10.1198/000313006X152649
