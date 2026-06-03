create or replace function fn_obter_ingredientes_necessarios(p_id_pedido int)
returns table(id_ingrediente int, qtd_final_necessaria int) as $$
begin
    return query
    SELECT 
        ingredientes_necessarios.id_ingrediente,
        CAST(SUM(qtd_total) AS INT) AS qtd_final_necessaria
    FROM (
 
        SELECT 
            rp.id_ingrediente,
            (ip.quantidade * rp.qtd_necessaria) AS qtd_total
        FROM item_pedido ip
        JOIN receita_produto rp ON ip.id_produto = rp.id_produto
        WHERE ip.id_pedido = p_id_pedido
        
        UNION ALL
        
        SELECT 
            rp.id_ingrediente,
            (ip.quantidade * ic.qtd_prod * rp.qtd_necessaria) AS qtd_total
        FROM item_pedido ip
        JOIN item_combo ic ON ip.id_produto = ic.id_combo
        JOIN receita_produto rp ON ic.id_produto = rp.id_produto
        WHERE ip.id_pedido = p_id_pedido 
    ) AS ingredientes_necessarios
    GROUP BY ingredientes_necessarios.id_ingrediente;
END;
$$ LANGUAGE plpgsql;