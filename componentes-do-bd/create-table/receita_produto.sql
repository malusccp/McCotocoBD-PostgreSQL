create table receita_produto
(id_produto int references produto(id_produto), 
id_ingrediente int references ingrediente(id_ingrediente), 
qtd_necessaria int not null, 
primary key(id_produto, id_ingrediente) );