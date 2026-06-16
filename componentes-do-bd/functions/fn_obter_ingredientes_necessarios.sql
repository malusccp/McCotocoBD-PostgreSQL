create or replace function fn_obter_ingredientes_necessarios(p_id_pedido int)
returns table(id_ingrediente int, qtd_final_necessaria int) as $$
begin
    return query
    SELECT
        v.id_ingrediente,
        CAST(SUM(v.qtd_total) AS INT) AS qtd_final_necessaria
    FROM vw_consumo_ingrediente_pedido v
    WHERE v.id_pedido = p_id_pedido
    GROUP BY v.id_ingrediente;
END;
$$ LANGUAGE plpgsql;