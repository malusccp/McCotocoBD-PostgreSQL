create table pedido
(id_pedido serial primary key, 
data_venda timestamp default current_timestamp, 
status varchar(50) not null, 
total float not null, 
id_funcionario int references funcionario(id_funcionario), 
id_franquia int references franquia(id_franquia) );
