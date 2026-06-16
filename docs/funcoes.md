# 🛠️ Funções — Banco McCotoco

As **funções (functions)** concentram a lógica de negócio e os relatórios. Estão organizadas por finalidade. (As funções que servem apenas de corpo para triggers estão documentadas em [triggers.md](triggers.md).)

---

## 1. Operação de venda

### `calcular_valor_total(p_itens jsonb) → float`
Recebe uma lista de itens em JSON (`[{"id_produto":1,"qtd":2}, ...]`) e retorna o **valor total**. Lança erro se algum produto não existir.

### `venda(p_id_funcionario int, p_id_franquia int, p_itens jsonb) → void`
Função principal de venda. Cria o pedido como **Em Andamento**, insere os itens e o **finaliza** — disparando, em cascata, a validação de franquia, o recálculo de total, a baixa de estoque e a auditoria.
```sql
SELECT venda(1, 1, '[{"id_produto":1,"qtd":2},{"id_produto":3,"qtd":1}]'::jsonb);
```

### `fn_obter_ingredientes_necessarios(p_id_pedido int) → tabela`
Retorna, para um pedido, quanto de cada ingrediente é necessário (produtos diretos **+** componentes de combos). Lê da view `vw_consumo_ingrediente_pedido`.

### `fn_verificar_estoque(p_id_pedido int, p_id_franquia int) → void`
Confere se há estoque suficiente para o pedido; lança erro se faltar algum ingrediente. Usada antes da baixa de estoque.

---

## 2. Metas e bônus

### `fn_obter_vendas_franquia(p_id_franquia, p_mes, p_ano) → float`
Soma o total das vendas **Finalizadas** de uma franquia em um mês/ano.

### `fn_obter_meta_vigente(p_id_franquia) → (valor_meta, porcentagem)`
Retorna a meta vigente da franquia e o respectivo percentual de bônus.

### `fn_calcular_bonus_mensal(p_id_franquia, p_mes, p_ano) → void`
Se a franquia **bateu a meta** no período, registra o bônus de cada funcionário em `historico_bonus` (`salário × %`). Valida o mês (1–12) e a existência de meta vigente. Usa `ON CONFLICT` para não duplicar o bônus do mesmo mês.

---

## 3. Relatórios

### `fn_relatorio_faturamento_periodo(p_data_inicio, p_data_fim) → tabela`
Faturamento e nº de pedidos **por franquia** no período. Inclui franquias sem vendas (faturamento 0).

### `fn_ranking_funcionarios_vendas(p_data_inicio, p_data_fim) → tabela`
Ranking de vendedores por total vendido, com **posição**, **franquia** e total. Usa a *window function* `RANK()` (trata empates).

### `fn_relatorio_consumo_ingredientes(p_data_inicio, p_data_fim) → tabela`
Consumo de cada ingrediente **por franquia** no período (produtos diretos + combos). Útil para reposição de estoque.

### `fn_desempenho_atendente(p_id_franquia) → tabela`
Métricas por atendente de uma franquia: nº de pedidos, total vendido e **ticket médio** (`AVG`).

### `fn_produto_mais_vendido(p_id_franquia) → tabela`
Produto campeão de vendas da franquia (maior soma de quantidade).

### `fn_alerta_estoque(p_limite int DEFAULT 10) → tabela`
Lista ingredientes com estoque **≤ limite**, por franquia — um relatório de reposição sob demanda.
```sql
SELECT * FROM fn_alerta_estoque();    -- limite padrão (10)
SELECT * FROM fn_alerta_estoque(25);  -- limite personalizado
```

---

## 4. CRUD genérico (usadas pelos papéis Gerente/Admin)

### `inserir(nome_tabela text, valores jsonb) → void`
Insere em qualquer tabela a partir de um JSON, com tratamento de erro amigável (inclusive permissão negada).

### `atualizar(nome_tabela, nome_coluna, valor, nome_coluna_where, operador, valor_where) → void`
UPDATE genérico com **validação de operador** (impede operadores não permitidos, por segurança).

### `deletar(nome_tabela, nome_coluna, operador, valor) → void`
DELETE genérico, também com validação de operador.

---

## Observações de design
- **Reúso:** a lógica difícil (explosão de ingredientes de combos) está centralizada na view `vw_consumo_ingrediente_pedido`, consumida por duas funções — evitando código duplicado.
- **Dimensão de franquia:** os três relatórios principais (faturamento, ranking, consumo) enxergam a franquia, contando uma história consistente.
