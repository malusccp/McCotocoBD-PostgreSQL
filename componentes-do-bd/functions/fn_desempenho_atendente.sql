

CREATE OR REPLACE FUNCTION fn_desempenho_atendente(p_id_franquia int)
RETURNS TABLE(
    id_funcionario   int,
    nome_funcionario varchar,
    qtd_pedidos      bigint,
    total_vendido    float,
    ticket_medio     float
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        fu.id_funcionario,
        fu.nome_funcionario,
        COUNT(p.id_pedido),
        COALESCE(SUM(p.total), 0),
        COALESCE(AVG(p.total), 0)
    FROM funcionario fu
    LEFT JOIN pedido p
        ON p.id_funcionario = fu.id_funcionario
        AND p.status = 'Finalizado'
    WHERE fu.id_franquia = p_id_franquia
    GROUP BY fu.id_funcionario, fu.nome_funcionario
    ORDER BY COALESCE(SUM(p.total), 0) DESC;
END;
$$ LANGUAGE plpgsql;



