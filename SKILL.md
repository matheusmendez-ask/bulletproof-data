---
name: bulletproof-data
description: "Método padrão de engenharia de dados à prova de falhas (Bulletproof Data) — pipeline, ETL/ELT, modelagem, SQL defensivo, validação de qualidade e diagnóstico de carga quebrada. Use sempre que a tarefa envolver mover, transformar, modelar, carregar, deduplicar, conciliar ou auditar dados (banco, warehouse, planilha, API, orquestrador), escrever ou revisar SQL, criar/alterar tabela, backfill ou carga incremental, investigar fluxo que parou/duplicou/trouxe número errado, ou avaliar se um dataset é confiável. Vale para pedido pequeno também ('só roda essa query', 'junta essas planilhas', 'por que não bate?') — é onde o erro silencioso nasce. In English: bulletproof data engineering, data pipeline, ETL, data model, backfill, incremental load, data quality, schema drift, dedupe, reconcile, data warehouse."
---

# bulletproof-data

Dado falha em silêncio: roda, sem erro, número errado. Método abaixo evita isso. Ordem fixa.
Tarefa pequena = 2 min. Nunca pular direto para o passo 3.

**Economia.** Resposta curta. Número, não adjetivo. Só o entregável pedido — script de
checagem, patch, planilha extra: oferece em 1 linha, não produz sem pedir.

## 1. Olhar a fonte antes de codar

- Grão: 1 linha = o quê?
- Chave: única de verdade? `COUNT(*)` vs `COUNT(DISTINCT)`. Coluna `id` mente.
- Volume, min/max de data.
- Fonte atualiza como: append / update / delete / recarga total.
- Fuso e tipo de data. Nulo disfarçado: `""`, `"NULL"`, `0`, `-1`, `1970-01-01`.
- Sem acesso ao banco? Procura amostra antes: CSV, export, fixture, log na pasta. Só
  depois vira suposição — e suposição é declarada, nunca escondida.
- 1 query resolve: count, count distinct da chave, min/max, 20 linhas no olho.

## 2. Contrato de saída (1–2 frases na resposta)

Grão + chave. Colunas e tipos. Duplicata / nulo / atrasado → o quê. Frequência.
Escolha irreversível que muda resultado → pergunta. Reversível com padrão óbvio → decide,
diz qual, segue.

## 3. Construir para rodar duas vezes

Pergunta guia: "rodou de novo com o mesmo dado, o que muda?" Resposta certa: nada.

- MERGE/upsert pela chave de negócio (padrão). Ou sobrescrever a partição (delete+insert).
- `INSERT` cego = duplicata silenciosa. Inevitável → avisa.
- Incremental: watermark = `MAX(updated_at)` do que foi gravado, não relógio do job.
  Só avança depois de gravar. Janela de sobreposição de 2–3 dias (registro atrasa).
- Ordem: dedup (versão mais nova) **antes** do filtro de status. Inverter pega versão
  velha de registro que virou cancelado.
- Falhe alto. Exceção engolida = tabela pela metade que parece inteira.
- Bruto preservado antes de transformar. Original do usuário intocado; versão tratada ao lado.
- Zero hardcode: data de hoje, caminho, credencial.

## 4. Validar antes de dizer pronto

Rodar sem erro ≠ validar. Sempre:

- contagem saída vs fonte — diferença explicada;
- `COUNT(*)` vs `COUNT(DISTINCT chave)`;
- soma da métrica principal: fonte vs destino;
- min/max de data, buraco de dia;
- 5 linhas no olho.

Dia de borda incompleto (fuso, janela de extração) → flag no dado, não só em prosa.
Reporta os números. "Funcionou" não é entrega. Não bateu e não explicou → diz isso.

## 5. Entregar

4 linhas: o que fez · onde está · como rodar de novo · o que quebra (suposição frágil).

## Aprofundar só quando precisar

| Situação | Leia |
| --- | --- |
| Modelar tabela, nomear, camadas, SQL de transformação, JSON, skew, partição, custo, revisar SQL | `references/modelagem-sql.md` |
| Bateria de qualidade, conciliação "não bate", schema drift, relatório de veredito | `references/qualidade.md` |
| Fluxo parou / duplicou / atrasou / dado errado; reprocessar | `references/triagem.md` |

## Tom

Usuário é engenheiro de dados. Não explica join. Risco → 1 frase + alternativa, segue.
SQL grande → diz a decisão de modelagem embutida nele.
