create table categoria(
id_categoria serial primary key, 
nome_cat varchar(50) not null);

create table ingrediente
(id_ingrediente serial primary key, 
nome_ingrediente varchar(50) not null);

create table meta(
id_meta serial primary key, 
valor_meta float not null, 
porcentagem float not null );

create table franquia(
id_franquia serial primary key, 
nome_franquia varchar(50) not null, 
endereco varchar(100) not null, 
cnpj varchar(14) not null);

create table produto(
id_produto serial primary key, 
preco_base float not null, 
nome_prod varchar(50), 
id_categoria int not null references categoria(id_categoria));

create table funcionario1(
id_funcionario serial primary key, 
cpf varchar(11) not null, 
nome_funcionario varchar(100) not null, 
cargo varchar(50) not null, 
salario_base float not null, 
id_franquia int references franquia(id_franquia) );

create table pedido (
id_pedido serial primary key,
data_venda timestamp default current_timestamp,
status varchar(50) not null,
total float not null,
id_funcionario int references funcionario(id_funcionario),
id_franquia int references franquia(id_franquia)
);

create table item_pedido(
id_pedido int references pedido(id_pedido),
id_produto int references produto(id_produto),
preco_unitario float not null,
quantidade int not null,
primary key(id_pedido, id_produto)
);

create table item_combo(
id_combo int references produto(id_produto),
id_produto int references produto(id_produto),
qtd_prod int not null,
primary key(id_combo, id_produto)
);

create table receita_produto(
id_produto int references produto(id_produto),
id_ingrediente int references ingrediente(id_ingrediente),
qtd_necessaria int not null,
primary key(id_produto, id_ingrediente) );

create table estoque_unid(
id_franquia int references franquia(id_franquia),
id_ingrediente int references ingrediente(id_ingrediente),
qtd_atual int not null,
primary key(id_franquia, id_ingrediente) );


create table meta_franquia(
id_meta_vigente serial primary key,
id_meta int references meta(id_meta),
id_franquia int references franquia(id_franquia),
eh_vigente boolean not null default true);
