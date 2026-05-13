create table item_pedido
(id_pedido int references pedido(id_pedido), 
id_produto int references produto(id_produto), 
preco_unitario float not null, 
quantidade int not null, 
primary key(id_pedido, id_produto));
