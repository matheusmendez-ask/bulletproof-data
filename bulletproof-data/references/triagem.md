# Triagem de fluxo quebrado

## Três perguntas antes do log

- Desde quando? Última execução boa, primeira ruim. Não sabe → `MAX(data)` por dia de ingestão.
- O que mudou na janela? Deploy, query, fonte, credencial, planilha, cota, fuso/horário. Falha nova
  em código velho vem de fora do código.
- Sintoma: ausência, excesso ou distorção? Cada um leva a um lugar.

## Isolar a etapa

Cadeia. Acha o primeiro elo onde o dado já está errado. Do fim para o começo, ou busca binária.
Por etapa: entrou errado ou ficou errado aqui? Conta linhas entrada/saída; onde muda sem
explicação, é ali.

Ordem de custo: log do orquestrador → contagem por dia no destino → bruto/staging (bruto certo e
mart errado = transformação; bruto errado = ingestão/fonte) → a fonte, à mão.
Reproduz com o menor recorte: 1 dia, 1 chave.

## Sintoma → causa provável

**Parou**: token/credencial expirada · cota/429 · schema mudou · timeout por volume · agendamento
desligado · exceção engolida (sai com código 0) · disco · endpoint/versão de API.

**Duplicou**: retry pós-timeout que já tinha gravado · `INSERT` sem chave · sobreposição
incremental sem MERGE · manual + agendado ao mesmo tempo · fan-out novo.

**Faltou**: watermark avançou além do gravado (inclusive com 0 lidos) · fuso cortando borda do
dia · paginação parou na página 1 (contagem = limite exato é assinatura) · `LEFT JOIN` virou
inner · `UNNEST` sem `LEFT JOIN` apagando registros com array vazio · limite de linhas · fonte deletou.

**Errado, volume certo**: campo reaproveitado/status novo · conversão de tipo (vírgula → nulo,
zero à esquerda) · métrica redefinida de um lado · fuso · ordem de coluna posicional.

**Atrasou**: volume · sem filtro de partição · cast implícito desativando partição · data skew em join (99% do tempo num único worker por nulos concentrados) · dependência a montante · fila · colisão de janela.

Log que diz "atualizado" e no dia seguinte lê o valor velho: update não persistiu (commit de
carona no insert). Confere o valor real no banco antes de planejar.

## Reprocessar sem duplicar

Etapa idempotente? Não → torna antes. Reprocessar append cego = dois problemas.

1. Período afetado, com 1 dia de folga dos dois lados.
2. Dado parcial já gravado no período? Quase sempre sim.
3. Escrita: sobrescrever partição ou MERGE pela chave. Nunca `INSERT` por cima.
4. 1 dia primeiro: contagem e soma vs fonte.
5. Resto, em lotes. Bateria de `qualidade.md` no período todo.
6. Compara com o número anterior e explica a diferença.

Vai alterar número já usado (relatório enviado, meta batida)? Avisa antes. Decisão do usuário.

## Fechar

4 linhas: **Causa** (não "instabilidade") · **Impacto** (dados, período, quem) · **Correção** ·
**Prevenção** (checagem que faz o mesmo erro aparecer sozinho; não deu para fazer → diz qual é).
