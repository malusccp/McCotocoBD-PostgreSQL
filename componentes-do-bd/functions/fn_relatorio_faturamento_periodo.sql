
CREATE OR REPLACE FUNCTION fn_relatorio_faturamento_periodo(
    p_data_inicio timestamp,
    p_data_fim    timestamp
)
RETURNS TABLE(
    id_franquia   int,
    nome_franquia varchar,
    qtd_pedidos   bigint,
    faturamento   float
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.id_franquia,
        f.nome_franquia,
        COUNT(p.id_pedido),
        COALESCE(SUM(p.total), 0)
    FROM franquia f
    LEFT JOIN pedido p
        ON p.id_franquia = f.id_franquia
        AND p.status = 'Finalizado'
        AND p.data_venda BETWEEN p_data_inicio AND p_data_fim
    GROUP BY f.id_franquia, f.nome_franquia
    ORDER BY COALESCE(SUM(p.total), 0) DESC;
END;
$$ LANGUAGE plpgsql;


