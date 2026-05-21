CREATE TABLE pedido (
    id_pedido serial PRIMARY KEY,
    data_venda timestamp DEFAULT current_timestamp,
    status varchar(50) NOT NULL,
    total float,
    id_funcionario int REFERENCES funcionario(id_funcionario),
    id_franquia int REFERENCES franquia(id_franquia)
);