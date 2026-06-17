CREATE OR REPLACE FUNCTION inserir (nome_tabela TEXT, valores JSONB)
RETURNS VOID
AS $$
DECLARE 
    mensagem_erro text;
    codigo_sqlstate text;
    v_colunas text; 
BEGIN 
    SELECT string_agg(quote_ident(chaves), ', ') 
    INTO v_colunas 
    FROM jsonb_object_keys(valores) as chaves;

    IF v_colunas IS NULL THEN
        RAISE EXCEPTION 'O valores fornecido estão vazios.';
    END IF;

    EXECUTE format('INSERT INTO %I (%s) SELECT %s FROM jsonb_populate_record(NULL::%I, $1)', 
                   nome_tabela, v_colunas, v_colunas, nome_tabela)
    USING valores;

    RAISE NOTICE 'Dados inseridos com sucesso na tabela %!', nome_tabela;

EXCEPTION 
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            mensagem_erro = MESSAGE_TEXT,
            codigo_sqlstate = RETURNED_SQLSTATE;

        IF codigo_sqlstate = '42501' THEN 
            RAISE EXCEPTION 'Acesso negado. O seu perfil não tem permissão para inserir na tabela "%".', nome_tabela;
        ELSIF codigo_sqlstate = 'P0001' THEN 
            RAISE EXCEPTION 'Erro ao inserir dados na tabela "%". %. Por favor, verifique os dados fornecidos.', nome_tabela, mensagem_erro;
        ELSE 
            RAISE EXCEPTION 'Erro ao inserir dados na tabela "%". Por favor, verifique os dados fornecidos ou a estrutura da tabela. (Erro: %)', nome_tabela, mensagem_erro;
        END IF;
END;
$$ LANGUAGE plpgsql;