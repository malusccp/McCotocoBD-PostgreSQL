

 --CATEGORIAS 
insert into categoria (nome_cat) values 
('Hambúrgueres'), ('Acompanhamentos'), ('Combos'), ('Bebidas'), ('Sobremesas');

-- INGREDIENTES
insert into ingrediente (nome_ingrediente) values
('Pão com gergelim'), ('Carne bovina 200g'), ('Alface'), ('Molho tasty'), ('Queijo cheddar'), ('Batata frita');

--  METAS
insert into meta (valor_meta, porcentagem) values 
(50000, 10.0), (150000, 15.0);

-- FRANQUIAS
insert into franquia (nome_franquia, endereco, cnpj) values
('McCotoco Frei Serafim', 'Av. Frei Serafim, 501', '98765432000188'),
('McCotoco Shopping PSG', 'Rua das Abelhas, 450', '12345678000199');

-- PRODUTOS SIMPLES 
insert into produto (preco_base, nome_prod, id_categoria) values
(36.90, 'McMourão', 1),
(16.90, 'Batata M', 2),
(12.00, 'Refrigerante 500ml', 4);

-- FUNCIONÁRIOS 
insert into funcionario (cpf, nome_funcionario, cargo, salario_base, id_franquia) values
('11122233344', 'Maria Luiza Morais', 'Gerente', 3500, 1),
('55566677788', 'Isaac Santos', 'Atendente', 1530, 1);

-- RECEITA 
insert into receita_produto (id_produto, id_ingrediente , qtd_necessaria) values
(1, 1, 1), 
(1, 2, 1),
(1, 3, 1); 

-- COMBO 
insert into produto (preco_base, nome_prod, id_categoria) values
(49.99, 'Combo McMourão', 3);

insert into item_combo (id_combo, id_produto, qtd_prod) values
(4, 1, 1),
(4, 2, 1), 
(4, 3, 1); 

-- ESTOQUE
insert into estoque_unid(id_franquia, id_ingrediente, qtd_atual) values
(1, 1, 100), (1, 2, 50);

-- META VIGENTE
insert into meta_franquia(id_meta, id_franquia, eh_vigente) values (1, 1, true);

-- PEDIDO 
insert into pedido (status, total, id_funcionario, id_franquia) values 
('Finalizado', 53.80, 1, 1);

-- ITENS DO PEDIDO
insert into item_pedido(id_pedido, id_produto, preco_unitario, quantidade) values 
(1, 1, 36.90, 1),
(1, 2, 16.90, 1);

