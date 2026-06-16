CREATE OR REPLACE FUNCTION fn_produto_mais_vendido(p_id_franquia int)
RETURNS TABLE(id_produto int, nome_prod varchar, qtd_vendida int) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id_produto,
        p.nome_prod,
        CAST(SUM(ip.quantidade) AS int) AS qtd_vendida
    FROM item_pedido ip
    JOIN pedido pe ON ip.id_pedido = pe.id_pedido
    JOIN produto p ON ip.id_produto = p.id_produto
    WHERE pe.id_franquia = p_id_franquia
      AND pe.status = 'Finalizado'
    GROUP BY p.id_produto, p.nome_prod
    ORDER BY qtd_vendida DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;


