CREATE OR REPLACE FUNCTION atualizar (
    nome_tabela TEXT, 
    dados_atualizar JSONB,       
    condicoes JSONB DEFAULT NULL 
)
RETURNS VOID
AS $$
DECLARE 
    mensagem_erro text;
    codigo_sqlstate text;
    set_completo text;
    where_completo text := '';
    condicao_atual jsonb;
    coluna text;
    operador text;
    valor text;
    operador_logico text;
BEGIN 
    IF (dados_atualizar IS NULL OR dados_atualizar::text = '{}') THEN 
        RAISE EXCEPTION 'Por favor, forneça os dados a serem atualizados em formato JSON.';
    END IF;

    SELECT string_agg(format('%I = %L', key, value), ', ')
    INTO set_completo
    FROM jsonb_each_text(dados_atualizar);

    IF (condicoes IS NOT NULL AND jsonb_array_length(condicoes) > 0) THEN
        FOR condicao_atual IN SELECT * FROM jsonb_array_elements(condicoes)
        LOOP
            operador_logico := COALESCE(condicao_atual ->> 'operador_logico', ''); 
            coluna := condicao_atual ->> 'coluna';
            operador := condicao_atual ->> 'operador';
            valor := condicao_atual ->> 'valor';

            IF operador IS NULL OR operador NOT IN ('=', '!=', '>', '<', '>=', '<=', 'LIKE', 'ILIKE', 'IS NULL', 'IS NOT NULL') THEN
                RAISE EXCEPTION 'Operador inválido ou ausente.';
            ELSIF operador IN ('IS NULL', 'IS NOT NULL') THEN
                where_completo := where_completo || format(' %s %I %s', operador_logico, coluna, operador);
            ELSE
                where_completo := where_completo || format(' %s %I %s %L', operador_logico, coluna, operador, valor);
            END IF;
        END LOOP;
        
        EXECUTE format('UPDATE %I SET %s WHERE %s', nome_tabela, set_completo, where_completo);
        RAISE NOTICE 'Os dados da tabela "%" foram atualizados conforme as condições!', nome_tabela;
    
    ELSE
        EXECUTE format('UPDATE %I SET %s', nome_tabela, set_completo);
        RAISE NOTICE 'Todos os registros da tabela "%" foram atualizados!', nome_tabela;
    END IF;

EXCEPTION 
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            mensagem_erro = MESSAGE_TEXT,
            codigo_sqlstate = RETURNED_SQLSTATE;

        IF codigo_sqlstate = '42501' THEN 
            RAISE EXCEPTION 'Acesso negado. O seu perfil não tem permissão para atualizar a tabela "%".', nome_tabela;
        ELSE 
            RAISE EXCEPTION 'Erro ao atualizar dados na tabela "%". (Erro: %)', nome_tabela, mensagem_erro;
        END IF;
END;
$$ LANGUAGE plpgsql;