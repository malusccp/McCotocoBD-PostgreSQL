# 🗂️ Visão Geral das Tabelas e Dados de Teste — Banco McCotoco

Este documento resume o **conjunto de dados (seed)** inserido pelo `componentes-do-bd/inserts/all_inserts.sql`, usado para testar e demonstrar o banco.

> ⚠️ Os pedidos **não** são inseridos direto como "Finalizado": o seed usa a função `venda()`, que faz o fluxo real (Em Andamento → itens → finaliza), exercitando os triggers de validação, total e baixa de estoque.

---

## Resumo quantitativo

| Tabela | Qtd. de registros | Observação |
|---|---|---|
| categoria | 5 | catálogo fixo |
| ingrediente | 11 | insumos |
| meta | 4 | inclui metas baixas para testar bônus |
| franquia | 4 | 2 originais + 2 novas |
| produto | 15 | hambúrgueres, combos, batatas, bebidas, sobremesa |
| funcionario | 11 | pelo menos 2 por franquia |
| receita_produto | vários | ficha técnica dos produtos |
| item_combo | vários | composição dos 4 combos |
| estoque_unid | 4 franquias × ingredientes | abastecido (500 un.) + 2 itens baixos |
| meta_franquia | 4 | 1 meta vigente por franquia |
| pedido | 13 | 11 finalizados, 1 aberto, 1 cancelado |

---

## Catálogo

### Categorias
Hambúrgueres · Acompanhamentos · Combos · Bebidas · Sobremesas

### Ingredientes (11)
Pão com gergelim · Carne bovina 200g · Alface · Molho tasty · Queijo cheddar · Batata frita · Bacon · Casquinha de sorvete · Cebola caramelizada · Pão brioche · Queijo prato

### Franquias (4)
| id | Nome |
|---|---|
| 1 | McCotoco Frei Serafim |
| 2 | McCotoco Shopping PSG |
| 3 | McCotoco Teresina Shopping |
| 4 | McCotoco Timon Centro |

### Produtos (15)
| id | Produto | Categoria |
|---|---|---|
| 1 | McMourão | Hambúrguer |
| 2 | Batata M | Acompanhamento |
| 3 | Refrigerante 500ml | Bebida |
| 4 | **Combo McMourão** | Combo |
| 5 | McCotoco Duplo | Hambúrguer |
| 6 | Casquinha | Sobremesa |
| 7 | Suco Natural 300ml | Bebida |
| 8 | Big Jambo | Hambúrguer |
| 9 | Mc Melt Lazaro | Hambúrguer |
| 10 | Brabo Melt Baleia | Hambúrguer |
| 11 | Batata G | Acompanhamento |
| 12 | Batata P | Acompanhamento |
| 13 | **Combo Mc Jambo** | Combo |
| 14 | **Combo Mc Lázaro** | Combo |
| 15 | **Combo Mc Baleia** | Combo |

### Composição dos combos
Cada combo = **hambúrguer + Batata M + Refrigerante**:
| Combo | Hambúrguer |
|---|---|
| Combo McMourão (4) | McMourão (1) |
| Combo Mc Jambo (13) | Big Jambo (8) |
| Combo Mc Lázaro (14) | Mc Melt Lazaro (9) |
| Combo Mc Baleia (15) | Brabo Melt Baleia (10) |

### Funcionários (11)
| id | Nome | Cargo | Franquia |
|---|---|---|---|
| 1 | Maria Luiza Morais | Gerente | 1 |
| 2 | Isaac Santos | Atendente | 1 |
| 3 | Ana Beatriz Sousa | Atendente | 1 |
| 4 | Arthur Vinicius | Gerente | 2 |
| 5 | Nicolas Rafael | Atendente | 2 |
| 6 | Pedro Henrique Lima | Atendente | 1 |
| 7 | Joana Carvalho | Atendente | 2 |
| 8 | Rafael Mendes | Gerente | 3 |
| 9 | Beatriz Rocha | Atendente | 3 |
| 10 | Carla Dias | Gerente | 4 |
| 11 | Lucas Farias | Atendente | 4 |

---

## Metas e vigência
| Meta | Valor | % Bônus | Franquia vigente |
|---|---|---|---|
| 1 | R$ 50.000 | 10% | franquia 1 e 4 |
| 2 | R$ 150.000 | 15% | — |
| 3 | R$ 100 | 5% | franquia 2 |
| 4 | R$ 200 | 8% | franquia 3 |

> As metas **3 e 4** são baixas de propósito: permitem demonstrar o **pagamento de bônus** (franquias 2 e 3 batem a meta com poucas vendas). As franquias 1 e 4 (meta de R$ 50.000) demonstram o caminho "meta **não** atingida".

---

## Dados transacionais (pedidos)
| Pedidos | Status | Como foram criados |
|---|---|---|
| 1 – 6 | Finalizado | via `venda()` nas franquias 1 e 2 |
| 7 | Em Andamento | inserido em aberto (para testar finalizar/cancelar) |
| 8 | Cancelado | inserido e cancelado (testa transição de status) |
| 9 – 13 | Finalizado | via `venda()` nas franquias 3 e 4 (combos/hambúrgueres novos) |

## Estoque
Todas as franquias começam com **500 unidades** de cada ingrediente. Dois itens são reduzidos de propósito para alimentar a `fn_alerta_estoque`:
- Franquia 2, **Carne bovina** → 8 unidades
- Franquia 1, **Casquinha de sorvete** → 5 unidades

---

## Ordem de carga (build do zero)
```
tabelas → views → functions → triggers → roles → inserts
```
Os IDs acima assumem o banco **zerado** (sequências começando em 1).
