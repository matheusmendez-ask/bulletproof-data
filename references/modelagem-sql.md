# Modelagem e SQL

## Camadas

- **raw/bronze**: cópia fiel. Zero regra de negócio. Serve para reprocessar sem tocar a origem.
- **staging/silver**: tipado, nomes normalizados, nulos tratados, dedup, 1 linha por entidade.
- **mart/gold**: fato/dimensão ou tabela larga por assunto. Métrica definida aqui.
- Transformação irreversível na camada mais alta possível. Filtro de "cancelado" no raw = dado perdido.
- Uma métrica, uma definição, um lugar. Duas "receitas" diferentes → aponta, não replica.

## Nomes

- `snake_case`, minúsculo, sem acento.
- `fato_vendas`, `dim_cliente`, `stg_pedidos`, `raw_tiny_pedidos`.
- Chave `<entidade>_id`, mesmo nome dos dois lados do join.
- `_data` = date; `_em`/`_at` = timestamp. Fuso no nome se houver mais de um: `criado_em_utc`.
- Booleano afirmativo: `is_ativo`, nunca `nao_ativo`.
- Moeda no nome se houver mais de uma: `valor_brl`.
- Sem abreviação privada (`vl_ped_liq`).

## Tipos e controle

- Dinheiro: `NUMERIC`/`DECIMAL`. Float quebra conciliação.
- CNPJ, CEP, código com zero à esquerda: `STRING`.
- Data como `DATE`/`TIMESTAMP`, nunca string. Um fuso só, declarado.
- `CAST` implícito no `ON` ou `WHERE` (`string` = `int`): desativa poda de partição/índice e vira full scan. Tipos idênticos nos dois lados. `SAFE_CAST` para blindar carga contra sujeira de origem.
- Toda tabela destino: `carregado_em`, `fonte` (se >1 origem), `hash_linha` (opcional).

## Grão, fan-out e skew

- Antes do join: grão dos dois lados. Lado direito não único pela chave → multiplica.
- Defesa: agrega o lado "muitos" antes do join. Ou aceita e nunca soma métrica do lado "um".
- Depois do join: contagem igual à tabela base. Subiu = fan-out.
- `LEFT JOIN` + condição da direita no `WHERE` = inner. Condição vai no `ON`.
- `IS NULL` de coluna da direita no `WHERE` = anti-join do registro inteiro. Se a intenção era
  descontar valor, isso apaga o pedido.
- Data skew em join: chave com muitos nulos ou valor padrão (`-1`, `'N/A'`) estrangula 1 worker (trava em 99%). Filtra nulo antes ou separa o join em duas vias.

## JSON e semi-estruturado

- Bruto intocado no raw. Extrai na staging com tipo explícito (`SAFE_CAST`).
- `UNNEST` / `FLATTEN` explode grão: 1 pai com 3 itens vira 3 linhas.
- Array vazio (`[]`) ou nulo: `UNNEST` padrão apaga a linha inteira. Usa sempre `LEFT JOIN UNNEST(...)` para não sumir com o registro pai.
- Campo de filtro frequente dentro de JSON: extrai para coluna física. Filtrar dentro de JSON em tabela grande = custo e scan desnecessários.

## SQL que sobrevive

- CTEs nomeadas, em ordem de leitura. Nome diz o que faz.
- Dedup explícito: `ROW_NUMBER() OVER (PARTITION BY chave ORDER BY atualizado_em DESC) = 1`
  (`QUALIFY` onde existe). `DISTINCT` esconde qual versão venceu.
- Dedup antes do filtro de status.
- `SELECT *` só em exploração. Em transformação lista coluna: `*` propaga drift em silêncio.
- Comenta o porquê, não o quê.
- `UNION ALL`, não `UNION` (dedup silencioso, caro).
- Não misturar grão na mesma tabela (linha `'total'` junto com linha por canal → soma dobra).
- Nulo: `IS NULL` / `IS DISTINCT FROM`. `NOT IN (subquery)` com nulo → resultado vazio; usa `NOT EXISTS`.
- Data hardcoded (`BETWEEN '2026-01-01' AND '2026-12-31'`) → tabela nasce vazia ano que vem.
  `BETWEEN` em timestamp perde o último dia.

## Partição e custo

- Particiona pela data de evento que os filtros usam. Cluster por join/filtro de alta cardinalidade.
- Filtro de partição: constante ou parâmetro, não função na coluna.
- Recorte pequeno antes de rodar tudo.
- View sobre view sobre view relê tudo: materializa o que é consultado muito.

## Atributo que muda no tempo (SCD)

- Tipo 1 sobrescreve: só se histórico não importa (escolha padrão errada mais comum).
- Tipo 2 versiona: `valido_de`, `valido_ate`, `is_atual`.
- Snapshot diário: mais simples, cresce, fácil de auditar.
- Pergunta se histórico importa antes de escolher. Retroagir é caro.

## Revisar SQL alheio — ordem

1. Grão do resultado / fan-out (inclui `UNNEST` sem `LEFT JOIN` ou que multiplicou linha).
2. `LEFT JOIN` virou inner ou anti-join.
3. Tipos e Cast: implícito no `ON` desativando partição, float em dinheiro, id com zero à esquerda.
4. Nulos e Skew: `NOT IN`, filtro que exclui nulo, chave de join com nulos estrangulando worker.
5. Datas: fuso, borda de `BETWEEN`, string, hardcode.
6. Custo: sem filtro de partição, `SELECT *` largo, filtro direto em campo JSON não extraído.
7. Nomes / legibilidade.

Reporta por gravidade, com efeito prático ("duplica receita de pedido com >1 item"), não só o
nome do problema. Coluna que dá para conferir na amostra: confere, não supõe.
