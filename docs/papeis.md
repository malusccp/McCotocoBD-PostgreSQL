# 👥 Papéis de Acesso (Roles) — Banco McCotoco

O banco usa o sistema de **roles** do PostgreSQL para aplicar o **princípio do menor privilégio**: cada perfil recebe apenas as permissões necessárias para sua função. Os papéis são **hierárquicos** — um herda as permissões do outro.

```
atendente_caixa  ⊂  gerente  ⊂  admin
```

---

## 1. `atendente_caixa`
Perfil da operação de balcão (registrar vendas).

| Permissão | Objeto |
|---|---|
| SELECT | produto, categoria, item_combo, ingrediente, receita_produto |
| SELECT | **vw_cardapio** (cardápio pronto) |
| SELECT, INSERT, UPDATE | pedido, item_pedido |
| USAGE, SELECT | sequência `pedido_id_pedido_seq` |
| EXECUTE | `venda(int,int,jsonb)`, `calcular_valor_total(jsonb)` |

> 💡 O atendente não acessa salários, metas ou estoque diretamente — só o necessário para vender.

---

## 2. `gerente`
Herda tudo do atendente e ganha gestão de pessoas, estoque e metas.

| Permissão | Objeto |
|---|---|
| **herda** | `atendente_caixa` |
| SELECT, INSERT, UPDATE | funcionario (+ sequência) |
| SELECT, INSERT, UPDATE | estoque_unid |
| SELECT, INSERT, UPDATE | meta, meta_franquia (+ sequências) |
| SELECT | franquia |
| EXECUTE | `inserir`, `atualizar`, `deletar` (CRUD genérico) |

---

## 3. `admin`
Controle total do banco.

| Permissão | Objeto |
|---|---|
| **herda** | `gerente` |
| ALL PRIVILEGES | todas as tabelas do schema `public` |
| ALL PRIVILEGES | todas as sequências |
| EXECUTE | todas as funções |

---

## Segurança e auditoria
- As operações sensíveis passam por **funções** (`venda`, `inserir`, `atualizar`, `deletar`) em vez de acesso direto, o que centraliza validações e mensagens de erro.
- A função de auditoria usa `SECURITY DEFINER`, de modo que toda alteração é registrada na `log_auditoria` **mesmo** para perfis que não têm acesso direto a essa tabela — impedindo que um usuário "apague os próprios rastros".

## Ordem de criação
Por causa da herança e das dependências (a `vw_cardapio` precisa existir antes do grant do atendente), criar nesta ordem:
```
vw_cardapio → role_atendente → role_gerente → role_admin
```
