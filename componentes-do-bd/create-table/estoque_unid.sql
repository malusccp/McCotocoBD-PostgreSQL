create table estoque_unid
(id_franquia int references franquia(id_franquia), 
id_ingrediente int references ingrediente(id_ingrediente), 
qtd_atual int not null, 
primary key(id_franquia, id_ingrediente) );
