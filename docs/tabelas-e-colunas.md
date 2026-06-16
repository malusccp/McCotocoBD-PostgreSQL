# 📋 Tabelas e Colunas — Banco McCotoco

Banco de dados de uma rede de fast-food (**McCotoco**) em PostgreSQL. São **14 tabelas**, divididas em catálogo, entidades principais, relacionamentos/transações e infraestrutura.

> Legenda: 🔑 chave primária · 🔗 chave estrangeira

---

## 1. Catálogo (cadastros básicos)

### `categoria`
Categorias do cardápio (ex.: Hambúrgueres, Bebidas).

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| 🔑 id_categoria | serial | PK | Identificador |
| nome_cat | varchar(50) | NOT NULL | Nome da categoria |

### `ingrediente`
Insumos usados no preparo dos produtos.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| 🔑 id_ingrediente | serial | PK | Identificador |
| nome_ingrediente | varchar(50) | NOT NULL | Nome do ingrediente |

### `meta`
Metas de venda e o percentual de bônus associado.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| 🔑 id_meta | serial | PK | Identificador |
| valor_meta | float | NOT NULL, **> 0** (trigger) | Valor a ser atingido |
| porcentagem | float | NOT NULL, **> 0** (trigger) | % de bônus sobre o salário |

### `franquia`
Unidades/lojas da rede.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| 🔑 id_franquia | serial | PK | Identificador |
| nome_franquia | varchar(50) | NOT NULL | Nome da loja |
| endereco | varchar(100) | NOT NULL | Endereço |
| cnpj | varchar(14) | NOT NULL, **único** (trigger) | CNPJ da loja |

---

## 2. Entidades principais

### `produto`
Itens do cardápio (hambúrgueres, combos, bebidas, etc.).

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| 🔑 id_produto | serial | PK | Identificador |
| preco_base | float | NOT NULL, **> 0** (trigger) | Preço de venda |
| nome_prod | varchar(50) | | Nome do produto |
| 🔗 id_categoria | int | NOT NULL, FK → categoria | Categoria |

### `funcionario`
Colaboradores, vinculados a uma franquia.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| 🔑 id_funcionario | serial | PK | Identificador |
| cpf | varchar(11) | NOT NULL, **único + 11 dígitos** (trigger) | CPF |
| nome_funcionario | varchar(100) | NOT NULL, **sem números** (trigger) | Nome |
| cargo | varchar(50) | NOT NULL | Cargo |
| salario_base | float | NOT NULL, **> 0** (trigger) | Salário base |
| 🔗 id_franquia | int | FK → franquia | Loja onde trabalha |

### `pedido`
Registro de cada venda/atendimento.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| 🔑 id_pedido | serial | PK | Identificador |
| data_venda | timestamp | DEFAULT current_timestamp, **não futura** (trigger) | Data/hora da venda |
| status | varchar(50) | NOT NULL, **domínio fixo** (trigger) | Em Andamento / Finalizado / Cancelado |
| total | float | **> 0** (trigger) | Valor total (recalculado por trigger) |
| 🔗 id_funcionario | int | FK → funcionario | Quem realizou a venda |
| 🔗 id_franquia | int | FK → franquia | Loja da venda |

---

## 3. Relacionamentos e transações

### `item_pedido`
Produtos de um pedido (chave composta).

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| 🔑🔗 id_pedido | int | PK, FK → pedido | Pedido |
| 🔑🔗 id_produto | int | PK, FK → produto | Produto |
| preco_unitario | float | NOT NULL, **> 0** (trigger) | Preço no momento da venda |
| quantidade | int | NOT NULL, **> 0** (trigger) | Quantidade vendida |

### `item_combo`
Composição de combos (um produto "combo" agrupa outros produtos).

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| 🔑🔗 id_combo | int | PK, FK → produto | Produto que é o combo |
| 🔑🔗 id_produto | int | PK, FK → produto | Produto componente |
| qtd_prod | int | NOT NULL | Quantidade do componente |

### `receita_produto`
Ficha técnica: ingredientes necessários por produto.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| 🔑🔗 id_produto | int | PK, FK → produto | Produto |
| 🔑🔗 id_ingrediente | int | PK, FK → ingrediente | Ingrediente |
| qtd_necessaria | int | NOT NULL | Quantidade por unidade |

### `estoque_unid`
Estoque de cada ingrediente por franquia.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| 🔑🔗 id_franquia | int | PK, FK → franquia | Loja |
| 🔑🔗 id_ingrediente | int | PK, FK → ingrediente | Ingrediente |
| qtd_atual | int | NOT NULL, **≥ 0** (trigger) | Quantidade em estoque |

### `meta_franquia`
Atribui metas às franquias e controla a vigência.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| 🔑 id_meta_vigente | serial | PK | Identificador |
| 🔗 id_meta | int | FK → meta | Meta atribuída |
| 🔗 id_franquia | int | FK → franquia | Franquia |
| eh_vigente | boolean | NOT NULL, DEFAULT true, **única por franquia** (trigger) | Se está em vigor |

### `historico_bonus`
Histórico de bônus pagos aos funcionários.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| 🔑 id_historico | serial | PK | Identificador |
| 🔗 id_funcionario | int | FK → funcionario | Funcionário |
| mes | int | NOT NULL | Mês de referência |
| ano | int | NOT NULL | Ano de referência |
| valor_bonus | float | NOT NULL | Valor pago |
| data_pagamento | timestamp | DEFAULT current_timestamp | Data do pagamento |
| — | — | **UNIQUE (id_funcionario, mes, ano)** | Evita bônus duplicado no mesmo mês |

---

## 4. Infraestrutura

### `log_auditoria`
Registro técnico de auditoria (fora do modelo de negócio).

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| 🔑 id_log | serial | PK | Identificador |
| nome_tabela | varchar(50) | NOT NULL | Tabela afetada |
| operacao | varchar(10) | NOT NULL | INSERT / UPDATE / DELETE |
| usuario | varchar(50) | NOT NULL, DEFAULT current_user | Quem executou |
| data_hora | timestamp | NOT NULL, DEFAULT current_timestamp | Quando |
| dados_antigos | jsonb | | Estado anterior |
| dados_novos | jsonb | | Estado novo |

---

## Views

| View | Descrição |
|---|---|
| `vw_cardapio` | Produtos com o nome da categoria (cardápio pronto para leitura). |
| `vw_consumo_ingrediente_pedido` | "Explosão" produto → ingredientes por pedido (produtos diretos + componentes de combos). Reutilizada por funções de estoque e relatório. |
