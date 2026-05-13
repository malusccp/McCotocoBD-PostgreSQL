create table funcionario
(id_funcionario serial primary key, 
cpf varchar(11) not null, 
nome_funcionario varchar(100) not null, 
cargo varchar(50) not null, 
salario_base float not null, 
id_franquia int 
references franquia(id_franquia) );
