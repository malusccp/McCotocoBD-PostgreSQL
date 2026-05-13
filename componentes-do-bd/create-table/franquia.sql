create table franquia
(id_franquia serial primary key, 
nome_franquia varchar(50) not null, 
endereco varchar(100) not null, 
cnpj varchar(14) not null);