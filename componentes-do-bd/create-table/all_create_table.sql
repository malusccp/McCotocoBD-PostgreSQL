CREATE TABLE categoria(
    id_categoria serial PRIMARY KEY, 
    nome_cat varchar(50) NOT NULL
);

CREATE TABLE ingrediente (
    id_ingrediente serial PRIMARY KEY, 
    nome_ingrediente varchar(50) NOT NULL
);

CREATE TABLE meta(
    id_meta serial PRIMARY KEY, 
    valor_meta float NOT NULL, 
    porcentagem float NOT NULL 
);

CREATE TABLE franquia(
    id_franquia serial PRIMARY KEY, 
    nome_franquia varchar(50) NOT NULL, 
    endereco varchar(100) NOT NULL, 
    cnpj varchar(14) NOT NULL
);

CREATE TABLE produto(
    id_produto serial PRIMARY KEY, 
    preco_base float NOT NULL, 
    nome_prod varchar(50), 
    id_categoria int NOT NULL REFERENCES categoria(id_categoria)
);

CREATE TABLE funcionario(
    id_funcionario serial PRIMARY KEY, 
    cpf varchar(11) NOT NULL, 
    nome_funcionario varchar(100) NOT NULL, 
    cargo varchar(50) NOT NULL, 
    salario_base float NOT NULL, 
    id_franquia int REFERENCES franquia(id_franquia) 
);

CREATE TABLE pedido (
    id_pedido serial PRIMARY KEY,
    data_venda timestamp DEFAULT current_timestamp,
    status varchar(50) NOT NULL,
    total float,
    id_funcionario int REFERENCES funcionario(id_funcionario),
    id_franquia int REFERENCES franquia(id_franquia)
);

CREATE TABLE item_pedido(
    id_pedido int REFERENCES pedido(id_pedido),
    id_produto int REFERENCES produto(id_produto),
    preco_unitario float NOT NULL,
    quantidade int NOT NULL,
    PRIMARY KEY(id_pedido, id_produto)
);

CREATE TABLE item_combo(
    id_combo int REFERENCES produto(id_produto),
    id_produto int REFERENCES produto(id_produto),
    qtd_prod int NOT NULL,
    PRIMARY KEY(id_combo, id_produto)
);

CREATE TABLE receita_produto(
    id_produto int REFERENCES produto(id_produto),
    id_ingrediente int REFERENCES ingrediente(id_ingrediente),
    qtd_necessaria int NOT NULL,
    PRIMARY KEY(id_produto, id_ingrediente) 
);

CREATE TABLE estoque_unid(
    id_franquia int REFERENCES franquia(id_franquia),
    id_ingrediente int REFERENCES ingrediente(id_ingrediente),
    qtd_atual int NOT NULL,
    PRIMARY KEY(id_franquia, id_ingrediente) 
);

CREATE TABLE meta_franquia(
    id_meta_vigente serial PRIMARY KEY,
    id_meta int REFERENCES meta(id_meta),
    id_franquia int REFERENCES franquia(id_franquia),
    eh_vigente boolean NOT NULL DEFAULT TRUE
);