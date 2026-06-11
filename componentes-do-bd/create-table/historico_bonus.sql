CREATE TABLE historico_bonus (
    id_historico serial PRIMARY KEY,
    id_funcionario int REFERENCES funcionario(id_funcionario),
    mes int NOT NULL,
    ano int NOT NULL,
    valor_bonus float NOT NULL,
    data_pagamento timestamp DEFAULT current_timestamp,
    
    UNIQUE (id_funcionario, mes, ano)
);