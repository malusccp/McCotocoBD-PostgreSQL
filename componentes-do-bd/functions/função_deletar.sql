CREATE OR REPLACE
FUNCTION deletar (nome_tabela TEXT,
condicoes JSONB DEFAULT NULL)

RETURNS VOID

AS $$

DECLARE



mensagem_erro text;

codigo_sqlstate text;

where_completo text := '';

condicao_atual jsonb;

coluna text;

operador text;

valor text;

operador_logico text;

BEGIN


IF (condicoes IS NULL
OR jsonb_array_length(condicoes) = 0) THEN

EXECUTE format('DELETE FROM %I', nome_tabela);

RAISE NOTICE 'Todos os dados da tabela "%" foram deletados!',
nome_tabela;
ELSE

FOR condicao_atual IN
SELECT
    *
FROM
    jsonb_array_elements(condicoes)

LOOP


operador_logico := COALESCE(condicao_atual ->> 'operador_logico', '');

coluna := condicao_atual ->> 'coluna';

operador := condicao_atual ->> 'operador';

valor := condicao_atual ->> 'valor';

IF operador IS NULL
OR operador NOT IN ('=', '!=', '>', '<', '>=', '<=', 'LIKE', 'ILIKE') THEN

RAISE EXCEPTION 'Operador inválido ou não permitido de segurança: %',
operador;
END IF;

where_completo := where_completo || format(' %s %I %s %L', operador_logico, coluna, operador, valor);
END LOOP;

EXECUTE format('DELETE FROM %I WHERE %s', nome_tabela, where_completo);

RAISE NOTICE 'Os dados da tabela "%" foram deletados conforme as condições repassadas.',
nome_tabela;
END IF;

EXCEPTION
WHEN OTHERS THEN

GET STACKED DIAGNOSTICS

mensagem_erro = MESSAGE_TEXT,

codigo_sqlstate = RETURNED_SQLSTATE;

IF codigo_sqlstate = '42501' THEN

RAISE EXCEPTION 'Acesso negado. O seu perfil não tem permissão para deletar dados na tabela "%".',
nome_tabela;
ELSE

RAISE EXCEPTION 'Erro ao deletar dados na tabela "%". Por favor, verifique os dados fornecidos ou as dependências entre as tabelas. (Erro: %)',
nome_tabela,
mensagem_erro;
END IF;
END;

$$ LANGUAGE plpgsql;