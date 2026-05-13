create table item_combo
(id_combo int references produto(id_produto), 
id_produto int references produto(id_produto), 
qtd_prod int not null, 
primary key(id_combo, id_produto) );