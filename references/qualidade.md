# Qualidade e validação

## Seis dimensões

| Dimensão | Pergunta | Checagem |
| --- | --- | --- |
| Completude | falta linha/valor? | contagem vs fonte; % nulo por coluna crítica |
| Unicidade | chave duplica? | `COUNT(*)` vs `COUNT(DISTINCT chave)` |
| Validade | valor possível? | domínio de status, faixa, regex de documento |
| Consistência | bate com o outro sistema? | soma da métrica em A vs B |
| Atualidade | fresco? | `MAX(data)` vs agora; buraco de dia |
| Acurácia | é o número certo? | 5 registros conferidos na origem, no olho |

Acurácia nenhuma query prova. Olha 5 casos antes de assinar dataset novo.

## Bateria mínima (roda de verdade, mostra os números)

```sql
SELECT COUNT(*) linhas, COUNT(DISTINCT <chave>) chaves, MIN(<data>) ini, MAX(<data>) fim FROM t;
SELECT <chave>, COUNT(*) n FROM t GROUP BY 1 HAVING n > 1 ORDER BY n DESC LIMIT 20;
SELECT COUNTIF(<col> IS NULL) / COUNT(*) pct_nulo FROM t;
-- buraco de dia: GENERATE_DATE_ARRAY / generate_series LEFT JOIN dias distintos WHERE nulo
SELECT <categoria>, COUNT(*) FROM t GROUP BY 1 ORDER BY 2 DESC;
```

Mais: negativo onde não deveria, total absurdo, data futura, data antes da operação, registro de
teste.

## Conciliação ("não bate")

Isola a diferença; não teoriza.

1. Mesmo recorte dos dois lados: intervalo, fuso, filtros de status. Metade morre aqui.
2. Total: diferença absoluta e %.
3. Quebra por dia. Todos os dias = regra sistemática (filtro, fuso). Dias específicos = carga.
4. Quebra por categoria no dia divergente.
5. `FULL OUTER JOIN` pela chave: só de um lado / dos dois com valor diferente.
6. Explica a diferença inteira. "Sobrou R$ 300, deve ser arredondamento" não é explicação.

Causas por frequência: recorte/fuso · filtro de status (cancelado, teste) · duplicata de um lado ·
fan-out · carga incompleta · definição de métrica (bruto/líquido, com/sem frete).
Reproduz a regra do outro lado ao centavo antes de dizer que ele está errado.
Erros de sinal oposto se cancelam no total — quebra por componente.

## Schema drift

- Lista coluna, nunca `SELECT *` → falha alto quando some.
- Compara schema esperado na entrada; diferença → para e reporta.
- Coluna nova: em geral ignora. Coluna sumida ou tipo mudado: nunca.
- Planilha: ancora no cabeçalho, nunca na posição.

## Onde a checagem mora

- Entrada: chegou? volume esperado? schema bate?
- Pós-transformação, pré-publicação: unicidade, contagem, conciliação. Falhou → não publica.
  Desatualizado é visível; errado não é.
- Pós-publicação: freshness, volume (zero, queda >50%, múltiplo exato do limite de página).
- Severidade: aborta (chave duplicada, zero linhas, schema) vs avisa (volume 20% fora, nulo subindo).

## Relatório

Veredito primeiro. Número sempre.

```
Veredito: dá para usar, com 1 ressalva.
- 128.430 linhas, 01/01–08/09, sem buraco de dia.
- pedido_id único.
- receita_brl bate com a fonte: R$ 4.182.331,20 = R$ 4.182.331,20.
- Ressalva: 3,1% cliente_id nulo, todos marketplace (fonte não envia). Afeta análise por cliente, não receita.
```
