# ⚡ Triggers — Banco McCotoco

Os **triggers (gatilhos)** automatizam regras de negócio e garantem a integridade dos dados sem depender da aplicação. Estão agrupados por finalidade.

> **BEFORE** = roda antes de gravar (pode validar/bloquear ou ajustar o dado).
> **AFTER** = roda depois de gravar (usado para efeitos colaterais, como baixar estoque).

---

## 1. Validações de cadastro

### `trg_checar_cpf_unico_funcionario` · função `checar_cpf_unico_funcionario()`
- **Tabela/Evento:** `funcionario` — BEFORE INSERT OR UPDATE
- **Regra:** o CPF deve ter **exatamente 11 dígitos numéricos** e ser **único**.

### `trg_nomes_nao_numeros` · função `validar_nome_funcionario()`
- **Tabela/Evento:** `funcionario` — BEFORE INSERT OR UPDATE
- **Regra:** o nome do funcionário **não pode conter números**.

### `trg_checar_cnpj_unico_franquia` · função `checar_cnpj_unico_franquia()`
- **Tabela/Evento:** `franquia` — BEFORE INSERT OR UPDATE
- **Regra:** o CNPJ da franquia deve ser **único**.

---

## 2. Valores positivos (uma função para várias tabelas)

A função `checar_valores_positivos()` usa `TG_TABLE_NAME` para saber qual tabela disparou e aplicar a checagem correta. É reutilizada por **5 triggers**:

| Trigger | Tabela | Valida |
|---|---|---|
| `trg_checar_preco_produto` | produto | `preco_base` > 0 |
| `trg_checar_preco_item_pedido` | item_pedido | `preco_unitario` > 0 **e** `quantidade` > 0 |
| `trg_checar_salario_funcionario` | funcionario | `salario_base` > 0 |
| `trg_checar_total_pedido` | pedido | `total` > 0 |
| `trg_checar_valores_meta` | meta | `valor_meta` > 0 **e** `porcentagem` > 0 |

Todos em **BEFORE INSERT OR UPDATE**.

---

## 3. Regras do pedido

### `trg_validar_data_pedido` · `validar_data_pedido()`
- **pedido** — BEFORE INSERT OR UPDATE
- **Regra:** `data_venda` não pode ser **no futuro**.

### `trg_validar_status_pedido` · `validar_valores_status()`
- **pedido** — BEFORE INSERT OR UPDATE
- **Regra:** o `status` deve pertencer ao domínio **Em Andamento / Finalizado / Cancelado**. O valor é normalizado com `trim`, e a comparação é *case-insensitive*.

### `validar_transicao_status` · `transicao_status()`
- **pedido** — BEFORE UPDATE OF status
- **Regra:** um pedido **CANCELADO** ou **FINALIZADO** não pode ter o status alterado (são estados finais).

### `validacao_de_venda_pela_franquia_funcionario` · `validar_venda()`
- **pedido** — BEFORE INSERT
- **Regra:** o funcionário só pode registrar venda na **sua própria franquia**.

---

## 4. Itens do pedido

### `trg_impedir_modificacao_item` · `fn_impedir_modificacao_item()`
- **item_pedido** — BEFORE INSERT OR UPDATE OR DELETE
- **Regra:** não é permitido adicionar, alterar ou remover itens de um pedido **Finalizado**.

### `trg_atualizar_total_pedido` · `fn_atualizar_total_pedido()`
- **item_pedido** — AFTER INSERT OR UPDATE OR DELETE
- **Efeito:** **recalcula automaticamente** o `total` do pedido a partir da soma dos itens.

---

## 5. Controle de estoque

### `trg_baixar_estoque_pedido` · `fn_baixar_estoque_pedido()`
- **pedido** — AFTER UPDATE OF status, quando passa para **Finalizado**
- **Efeito:** verifica disponibilidade (`fn_verificar_estoque`) e **dá baixa** nos ingredientes consumidos.

### `trg_devolver_estoque_pedido` · `fn_devolver_estoque()`
- **pedido** — AFTER UPDATE OF status, quando **sai** de Finalizado
- **Efeito:** devolve os ingredientes ao estoque.
- ⚠️ *Observação de design:* como a transição a partir de "Finalizado" é proibida pelo `validar_transicao_status`, este gatilho na prática não é acionado (ver doc de apresentação).

### `validar_estoque_minimo` · `estoque_minimo()`
- **estoque_unid** — BEFORE INSERT OR UPDATE OF qtd_atual
- **Regra:** o estoque **não pode ficar negativo**. (O alerta de estoque baixo ficou a cargo da função `fn_alerta_estoque`.)

---

## 6. Metas

### `atualizar_meta_vigente` · `meta_vigente()`
- **meta_franquia** — BEFORE INSERT OR UPDATE
- **Efeito:** ao marcar uma meta como vigente, **desativa automaticamente** a meta vigente anterior daquela franquia (garante **uma única meta vigente por franquia**).

---

## 7. Auditoria

### `fn_auditoria_generica()` (função única) + 8 triggers
- **Tabelas:** funcionario, franquia, produto, pedido, item_pedido, estoque_unid, meta_franquia, historico_bonus — AFTER INSERT OR UPDATE OR DELETE
- **Efeito:** registra na `log_auditoria` **quem** alterou, **o quê**, **quando**, com os dados antigos/novos em `jsonb`.
- Usa `SECURITY DEFINER` para que o log seja sempre gravado, sem que usuários comuns possam apagar os rastros.
