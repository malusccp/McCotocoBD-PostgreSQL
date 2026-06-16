-- =============================================================================
--                  DADOS DE TESTE (SEED) - BANCO McCOTOCO
-- =============================================================================
-- Pré-requisitos (rodar ANTES deste arquivo, nesta ordem):
--   tabelas -> views -> functions -> triggers -> roles
--
-- IMPORTANTE: os pedidos NÃO são inseridos direto como 'Finalizado', porque o
-- trigger trg_impedir_modificacao_item bloqueia adicionar itens a pedidos
-- finalizados. Em vez disso usamos a função venda(), que faz o fluxo real
-- (cria 'Em Andamento' -> adiciona itens -> finaliza), exercitando de quebra a
-- validação de franquia, o cálculo de total, a baixa de estoque e a auditoria.
-- =============================================================================


-- =========================== CATÁLOGO / CADASTROS ============================

-- CATEGORIAS (1..5)
INSERT INTO categoria (nome_cat) VALUES
('Hambúrgueres'),
('Acompanhamentos'),
('Combos'),
('Bebidas'),
('Sobremesas');

-- INGREDIENTES (1..8)
INSERT INTO ingrediente (nome_ingrediente) VALUES
('Pão com gergelim'),
('Carne bovina 200g'),
('Alface'),
('Molho tasty'),
('Queijo cheddar'),
('Batata frita'),
('Bacon'),
('Casquinha de sorvete');

-- METAS (1..3) — meta 3 é baixa de propósito, para testar o pagamento de bônus
INSERT INTO meta (valor_meta, porcentagem) VALUES
(50000, 10.0),
(150000, 15.0),
(100, 5.0);

-- FRANQUIAS (1..2)
INSERT INTO franquia (nome_franquia, endereco, cnpj) VALUES
('McCotoco Frei Serafim', 'Av. Frei Serafim, 501', '98765432000188'),
('McCotoco Shopping PSG',  'Rua das Abelhas, 450',  '12345678000199');

-- PRODUTOS (1..7)
INSERT INTO produto (preco_base, nome_prod, id_categoria) VALUES
(36.90, 'McMourão',            1),  -- 1
(16.90, 'Batata M',            2),  -- 2
(12.00, 'Refrigerante 500ml',  4),  -- 3
(49.99, 'Combo McMourão',      3),  -- 4 (combo)
(42.90, 'McCotoco Duplo',      1),  -- 5
(8.00,  'Casquinha',           5),  -- 6
(10.00, 'Suco Natural 300ml',  4);  -- 7

-- FUNCIONÁRIOS (1..5) — 3 na franquia 1, 2 na franquia 2
INSERT INTO funcionario (cpf, nome_funcionario, cargo, salario_base, id_franquia) VALUES
('11122233344', 'Maria Luiza Morais', 'Gerente',   3500, 1),  -- 1
('55566677788', 'Isaac Santos',       'Atendente', 1530, 1),  -- 2
('22233344455', 'Ana Beatriz Sousa',  'Atendente', 1530, 1),  -- 3
('99988877766', 'Arthur Vinicius',    'Gerente',   3500, 2),  -- 4
('33344455566', 'Nicolas Rafael',     'Atendente', 1530, 2);  -- 5

-- RECEITAS (ficha técnica dos produtos)
INSERT INTO receita_produto (id_produto, id_ingrediente, qtd_necessaria) VALUES
-- McMourão (1): pão, carne, alface, molho, queijo
(1, 1, 1), (1, 2, 1), (1, 3, 1), (1, 4, 1), (1, 5, 1),
-- Batata M (2): batata frita
(2, 6, 1),
-- McCotoco Duplo (5): pão, 2x carne, 2x queijo, 2x bacon
(5, 1, 1), (5, 2, 2), (5, 5, 2), (5, 7, 2),
-- Casquinha (6): casquinha de sorvete
(6, 8, 1);
-- (Refrigerante 3 e Suco 7 são revenda: sem ficha técnica)

-- COMBO McMourão (produto 4) = McMourão + Batata M + Refrigerante
INSERT INTO item_combo (id_combo, id_produto, qtd_prod) VALUES
(4, 1, 1),
(4, 2, 1),
(4, 3, 1);

-- ESTOQUE — todos os 8 ingredientes nas 2 franquias, com folga para os testes
INSERT INTO estoque_unid (id_franquia, id_ingrediente, qtd_atual) VALUES
(1, 1, 500), (1, 2, 500), (1, 3, 500), (1, 4, 500), (1, 5, 500), (1, 6, 500), (1, 7, 500), (1, 8, 500),
(2, 1, 500), (2, 2, 500), (2, 3, 500), (2, 4, 500), (2, 5, 500), (2, 6, 500), (2, 7, 500), (2, 8, 500);

-- META VIGENTE por franquia
--   franquia 1 -> meta 1 (50.000) : realista, NÃO será batida pelo seed
--   franquia 2 -> meta 3 (100)    : baixa, SERÁ batida (testa o bônus)
INSERT INTO meta_franquia (id_meta, id_franquia, eh_vigente) VALUES
(1, 1, true),
(3, 2, true);


-- ====================== VENDAS FINALIZADAS (via venda()) =====================
-- Cada chamada cria 1 pedido, finaliza e baixa o estoque. Pedidos 1 a 6.

-- Franquia 1
SELECT venda(1, 1, '[{"id_produto": 1, "qtd": 2}, {"id_produto": 3, "qtd": 2}]'::jsonb); -- Maria
SELECT venda(2, 1, '[{"id_produto": 4, "qtd": 1}]'::jsonb);                               -- Isaac (combo)
SELECT venda(2, 1, '[{"id_produto": 2, "qtd": 3}, {"id_produto": 6, "qtd": 2}]'::jsonb);  -- Isaac
SELECT venda(3, 1, '[{"id_produto": 5, "qtd": 1}, {"id_produto": 7, "qtd": 1}]'::jsonb);  -- Ana

-- Franquia 2
SELECT venda(4, 2, '[{"id_produto": 1, "qtd": 1}, {"id_produto": 2, "qtd": 1}]'::jsonb);  -- Arthur
SELECT venda(5, 2, '[{"id_produto": 5, "qtd": 2}]'::jsonb);                               -- Nicolas


-- ===================== PEDIDO EM ABERTO (Em Andamento) =======================
-- Pedido 7: fica aberto para você testar finalizar/cancelar manualmente.
INSERT INTO pedido (status, total, id_funcionario, id_franquia)
VALUES ('Em Andamento', 1, 3, 1);  -- total recalculado pelo trigger ao inserir itens

INSERT INTO item_pedido (id_pedido, id_produto, preco_unitario, quantidade) VALUES
(7, 1, 36.90, 1),
(7, 7, 10.00, 2);


-- ===================== PEDIDO CANCELADO (Em Andamento -> Cancelado) ===========
-- Pedido 8: criado e cancelado, para testar a validação de status/transição.
INSERT INTO pedido (status, total, id_funcionario, id_franquia)
VALUES ('Em Andamento', 1, 5, 2);

INSERT INTO item_pedido (id_pedido, id_produto, preco_unitario, quantidade) VALUES
(8, 2, 16.90, 1);

UPDATE pedido SET status = 'Cancelado' WHERE id_pedido = 8;


-- ===================== ESTOQUE BAIXO (testa alerta + notice) =================
-- Deixa 2 ingredientes abaixo de 10 para que a função fn_alerta_estoque passe a
-- listá-los como itens que precisam de reposição.
UPDATE estoque_unid SET qtd_atual = 8 WHERE id_franquia = 2 AND id_ingrediente = 2;
UPDATE estoque_unid SET qtd_atual = 5 WHERE id_franquia = 1 AND id_ingrediente = 8;


-- #############################################################################
--   AMPLIAÇÃO: novos hambúrgueres, combos, batatas, franquias e funcionários
-- #############################################################################

-- NOVOS INGREDIENTES (9..11)
INSERT INTO ingrediente (nome_ingrediente) VALUES
('Cebola caramelizada'),  -- 9
('Pão brioche'),          -- 10
('Queijo prato');         -- 11

-- NOVOS PRODUTOS
--   Hambúrgueres (8,9,10) + Batatas G/P (11,12) + Combos (13,14,15)
INSERT INTO produto (preco_base, nome_prod, id_categoria) VALUES
(38.90, 'Big Jambo',         1),  -- 8  (hambúrguer)
(40.90, 'Mc Melt Lazaro',    1),  -- 9  (hambúrguer)
(45.90, 'Brabo Melt Baleia', 1),  -- 10 (hambúrguer)
(20.90, 'Batata G',          2),  -- 11
(12.90, 'Batata P',          2),  -- 12
(54.99, 'Combo Mc Jambo',    3),  -- 13 (combo)
(56.99, 'Combo Mc Lázaro',   3),  -- 14 (combo)
(61.99, 'Combo Mc Baleia',   3);  -- 15 (combo)

-- FICHAS TÉCNICAS dos novos hambúrgueres e batatas
INSERT INTO receita_produto (id_produto, id_ingrediente, qtd_necessaria) VALUES
-- Big Jambo (8): pão gergelim, 2x carne, queijo cheddar, bacon, cebola
(8, 1, 1), (8, 2, 2), (8, 5, 1), (8, 7, 1), (8, 9, 1),
-- Mc Melt Lazaro (9): pão brioche, 2x carne, 2x queijo prato, cebola
(9, 10, 1), (9, 2, 2), (9, 11, 2), (9, 9, 1),
-- Brabo Melt Baleia (10): pão brioche, 3x carne, 2x queijo cheddar, 2x bacon, cebola
(10, 10, 1), (10, 2, 3), (10, 5, 2), (10, 7, 2), (10, 9, 1),
-- Batata G (11): 2x batata frita ; Batata P (12): 1x batata frita
(11, 6, 2),
(12, 6, 1);

-- COMPOSIÇÃO DOS COMBOS — cada combo = hambúrguer + Batata M (2) + Refri (3)
INSERT INTO item_combo (id_combo, id_produto, qtd_prod) VALUES
-- Combo Mc Jambo (13) = Big Jambo + Batata M + Refri
(13, 8, 1), (13, 2, 1), (13, 3, 1),
-- Combo Mc Lázaro (14) = Mc Melt Lazaro + Batata M + Refri
(14, 9, 1), (14, 2, 1), (14, 3, 1),
-- Combo Mc Baleia (15) = Brabo Melt Baleia + Batata M + Refri
(15, 10, 1), (15, 2, 1), (15, 3, 1);

-- NOVAS FRANQUIAS (3..4)
INSERT INTO franquia (nome_franquia, endereco, cnpj) VALUES
('McCotoco Teresina Shopping', 'Av. Raul Lopes, 1000', '45678912000133'),  -- 3
('McCotoco Timon Centro',      'Rua Grande, 25',       '78912345000144');  -- 4

-- NOVA META (4) — baixa, para testar bônus na franquia 3
INSERT INTO meta (valor_meta, porcentagem) VALUES
(200, 8.0);  -- 4

-- METAS VIGENTES das novas franquias
--   franquia 3 -> meta 4 (200)   : baixa, SERÁ batida
--   franquia 4 -> meta 1 (50000) : realista, NÃO será batida
INSERT INTO meta_franquia (id_meta, id_franquia, eh_vigente) VALUES
(4, 3, true),
(1, 4, true);

-- MAIS FUNCIONÁRIOS (6..11) — pelo menos 2 por franquia
INSERT INTO funcionario (cpf, nome_funcionario, cargo, salario_base, id_franquia) VALUES
('66677788800', 'Pedro Henrique Lima', 'Atendente', 1530, 1),  -- 6  (franquia 1)
('77788899911', 'Joana Carvalho',      'Atendente', 1530, 2),  -- 7  (franquia 2)
('88899900022', 'Rafael Mendes',       'Gerente',   3600, 3),  -- 8  (franquia 3)
('99900011133', 'Beatriz Rocha',       'Atendente', 1540, 3),  -- 9  (franquia 3)
('10100122244', 'Carla Dias',          'Gerente',   3600, 4),  -- 10 (franquia 4)
('11200233355', 'Lucas Farias',        'Atendente', 1540, 4);  -- 11 (franquia 4)

-- ESTOQUE: novos ingredientes nas franquias antigas (1,2) e estoque completo
-- das franquias novas (3,4) com todos os 11 ingredientes.
INSERT INTO estoque_unid (id_franquia, id_ingrediente, qtd_atual) VALUES
(1, 9, 500), (1, 10, 500), (1, 11, 500),
(2, 9, 500), (2, 10, 500), (2, 11, 500),
(3, 1, 500), (3, 2, 500), (3, 3, 500), (3, 4, 500), (3, 5, 500), (3, 6, 500), (3, 7, 500), (3, 8, 500), (3, 9, 500), (3, 10, 500), (3, 11, 500),
(4, 1, 500), (4, 2, 500), (4, 3, 500), (4, 4, 500), (4, 5, 500), (4, 6, 500), (4, 7, 500), (4, 8, 500), (4, 9, 500), (4, 10, 500), (4, 11, 500);

-- VENDAS NAS NOVAS FRANQUIAS (via venda()) — pedidos 9 em diante
-- Franquia 3 (funcionários 8 e 9)
SELECT venda(8, 3, '[{"id_produto": 13, "qtd": 1}]'::jsonb);                                 -- Combo Mc Jambo
SELECT venda(9, 3, '[{"id_produto": 13, "qtd": 2}]'::jsonb);                                 -- 2x Combo Mc Jambo
SELECT venda(8, 3, '[{"id_produto": 15, "qtd": 1}, {"id_produto": 11, "qtd": 1}]'::jsonb);   -- Combo Baleia + Batata G

-- Franquia 4 (funcionários 10 e 11)
SELECT venda(10, 4, '[{"id_produto": 14, "qtd": 1}]'::jsonb);                                -- Combo Mc Lázaro
SELECT venda(11, 4, '[{"id_produto": 9, "qtd": 2}, {"id_produto": 12, "qtd": 2}]'::jsonb);   -- 2x Mc Melt Lazaro + 2x Batata P


-- =============================================================================
--   TESTES SUGERIDOS (rode manualmente depois do seed)
-- =============================================================================
-- Relatórios:
--   SELECT * FROM fn_relatorio_faturamento_periodo('2026-06-01', '2026-06-30');
--   SELECT * FROM fn_ranking_funcionarios_vendas('2026-06-01', '2026-06-30');
--   SELECT * FROM fn_relatorio_consumo_ingredientes('2026-06-01', '2026-06-30');
--   SELECT * FROM fn_alerta_estoque();         -- limite padrão (10)
--   SELECT * FROM fn_alerta_estoque(550);      -- mostra tudo
--   SELECT * FROM fn_desempenho_atendente(1);  -- atendentes da franquia 1
--   SELECT * FROM fn_produto_mais_vendido(1);
--
-- Bônus (meta vigente):
--   SELECT fn_calcular_bonus_mensal(2, 6, 2026);  -- franquia 2: meta batida -> paga bônus
--   SELECT fn_calcular_bonus_mensal(1, 6, 2026);  -- franquia 1: meta NÃO batida
--   SELECT * FROM historico_bonus;
--
-- Auditoria:
--   SELECT * FROM log_auditoria ORDER BY data_hora;
--
-- Regras que devem FALHAR (testes negativos):
--   SELECT venda(2, 2, '[{"id_produto":1,"qtd":1}]'::jsonb);  -- funcionário 2 não é da franquia 2
--   UPDATE pedido SET status = 'Em Andamento' WHERE id_pedido = 8;  -- não pode sair de Cancelado
--   INSERT INTO item_pedido VALUES (1, 7, 10.00, 1);  -- pedido 1 está Finalizado
-- =============================================================================
