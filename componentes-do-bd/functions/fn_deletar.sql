CREATE OR REPLACE FUNCTION deletar (nome_tabela TEXT, nome_coluna TEXT DEFAULT null, operador TEXT DEFAULT null, valor TEXT DEFAULT NULL)
RETURNS VOID
AS $$
DECLARE 

    mensagem_erro text;
    codigo_sqlstate text;

BEGIN 
    
    IF (nome_coluna IS NULL AND operador IS NULL AND valor IS NULL) THEN 
        EXECUTE format('DELETE FROM %I', nome_tabela);
        RAISE NOTICE 'Todos os dados da tabela "%" foram deletados!', nome_tabela;
	ELSIF NOT (trim(upper(operador)) IN ('=', '>', '<', '>=', '<=', '<>', '!=', 'LIKE', 'ILIKE', 'IS NULL', 'IS NOT NULL')) THEN
        RAISE EXCEPTION 'Operador "%" inválido ou não permitido por motivos de segurança.', operador;
	ELSIF (trim(upper(operador)) IN ('IS NULL', 'IS NOT NULL')) THEN
		EXECUTE format('DELETE FROM %I WHERE %I %s', nome_tabela, nome_coluna, operador);
        RAISE NOTICE 'Todos os dados onde "% %" foram deletados.', nome_coluna, operador;
	ELSE 
		EXECUTE format('DELETE FROM %I WHERE %I %s %L', nome_tabela, nome_coluna, operador, valor);
		RAISE NOTICE 'Todos os dados da tabela "%" foram deletados seguindo as seguintes condições: % % %', nome_tabela, nome_coluna, operador, valor;
        
    END IF;

EXCEPTION 
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            mensagem_erro = MESSAGE_TEXT,
            codigo_sqlstate = RETURNED_SQLSTATE;

        IF codigo_sqlstate = '42501' THEN 
            RAISE EXCEPTION 'Acesso negado. O seu perfil não tem permissão para deletar dados na tabela "%".', nome_tabela;
        ELSE 
            RAISE EXCEPTION 'Erro ao deletar dados na tabela "%". Por favor, verifique os dados fornecidos ou as dependências entre as tabelas. (Erro: %)', nome_tabela, mensagem_erro;
        END IF;
END;
$$ LANGUAGE plpgsql;