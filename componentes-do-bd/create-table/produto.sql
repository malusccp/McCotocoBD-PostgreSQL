create table produto(id_produto serial primary key, 
preco_base float not null, 
nome_prod varchar(50), 
id_categoria int not null 
references categoria(id_categoria));