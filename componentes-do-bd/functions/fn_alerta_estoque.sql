

CREATE OR REPLACE FUNCTION fn_alerta_estoque(p_limite int DEFAULT 10)
RETURNS TABLE(
    nome_franquia    varchar,
    nome_ingrediente varchar,
    qtd_atual        int
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.nome_franquia,
        i.nome_ingrediente,
        e.qtd_atual
    FROM estoque_unid e
    JOIN franquia f    ON e.id_franquia = f.id_franquia
    JOIN ingrediente i ON e.id_ingrediente = i.id_ingrediente
    WHERE e.qtd_atual <= p_limite
    ORDER BY e.qtd_atual ASC;
END;
$$ LANGUAGE plpgsql;

