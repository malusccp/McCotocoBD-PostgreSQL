CREATE OR REPLACE FUNCTION atualizar (
    nome_tabela TEXT, 
    nome_coluna TEXT, 
    valor TEXT, 
    nome_coluna_where TEXT DEFAULT null, 
    operador TEXT DEFAULT null, 
    valor_where TEXT DEFAULT null
)
RETURNS VOID
AS $$
DECLARE 
    mensagem_erro text;
    codigo_sqlstate text;
BEGIN 
    
    IF (nome_coluna_where IS NULL AND operador IS NULL AND valor_where IS NULL) THEN 
        EXECUTE format('UPDATE %I SET %I = %L', nome_tabela, nome_coluna, valor);
        RAISE NOTICE 'Todos os dados da tabela "%" foram atualizados!', nome_tabela;
    
    ELSIF NOT (trim(upper(operador)) IN ('=', '>', '<', '>=', '<=', '<>', '!=', 'LIKE', 'ILIKE', 'IS NULL', 'IS NOT NULL')) THEN
        RAISE EXCEPTION 'Operador "%" inválido ou não permitido por motivos de segurança.', operador;

    ELSIF (trim(upper(operador)) IN ('IS NULL', 'IS NOT NULL')) THEN
        EXECUTE format('UPDATE %I SET %I = %L WHERE %I %s', nome_tabela, nome_coluna, valor, nome_coluna_where, operador);
        RAISE NOTICE 'Todos os dados onde "% %" foram atualizados.', nome_coluna_where, operador;

    ELSE 
        EXECUTE format('UPDATE %I SET %I = %L WHERE %I %s %L', nome_tabela, nome_coluna, valor, nome_coluna_where, operador, valor_where);
        RAISE NOTICE 'Todos os dados da tabela "%" foram atualizados seguindo a condição: % % %', nome_tabela, nome_coluna_where, operador, valor_where;
        
    END IF;

EXCEPTION 
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            mensagem_erro = MESSAGE_TEXT,
            codigo_sqlstate = RETURNED_SQLSTATE;

        IF codigo_sqlstate = '42501' THEN 
            RAISE EXCEPTION 'Acesso negado. O seu perfil não tem permissão para atualizar dados na tabela "%".', nome_tabela;
        ELSE 
            RAISE EXCEPTION 'Erro ao atualizar dados na tabela "%". (Erro: %)', nome_tabela, mensagem_erro;
        END IF;
END;
$$ LANGUAGE plpgsql;