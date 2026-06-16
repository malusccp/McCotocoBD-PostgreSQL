
CREATE TABLE log_auditoria (
    id_log        serial PRIMARY KEY,
    nome_tabela   varchar(50) NOT NULL,             
    operacao      varchar(10) NOT NULL,              
    usuario       varchar(50) NOT NULL DEFAULT current_user,
    data_hora     timestamp   NOT NULL DEFAULT current_timestamp,
    dados_antigos jsonb,                                
    dados_novos   jsonb                                
);
