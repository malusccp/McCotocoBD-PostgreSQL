CREATE OR REPLACE
FUNCTION inserir (nome_tabela TEXT,
valores JSONB)
RETURNS VOID
AS $$
DECLARE 

    mensagem_erro text;

	codigo_sqlstate text;

BEGIN 

    EXECUTE format('INSERT INTO %I SELECT * FROM jsonb_populate_record(NULL::%I, $1)', nome_tabela, nome_tabela)
    USING valores;

RAISE NOTICE 'Dados inseridos com sucesso na tabela %!',
nome_tabela;

EXCEPTION
WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
        
            mensagem_erro = MESSAGE_TEXT,
            codigo_sqlstate = RETURNED_SQLSTATE;

IF codigo_sqlstate = '42501' THEN 
            RAISE EXCEPTION 'Acesso negado. O seu perfil não tem  permissão para inserir na tabela "%".',
nome_tabela;

ELSIF codigo_sqlstate = 'P0001' THEN 
            RAISE EXCEPTION 'Erro ao inserir dados na tabela "%". %. Por favor, verifique os dados fornecidos.',
nome_tabela,
mensagem_erro;
ELSE 
            RAISE EXCEPTION 'Erro ao inserir dados na tabela "%". Por favor, verifique os dados fornecidos ou a estrutura da tabela. (Erro: %)',
nome_tabela,
SQLERRM;
END IF;
END;

$$ LANGUAGE plpgsql;
