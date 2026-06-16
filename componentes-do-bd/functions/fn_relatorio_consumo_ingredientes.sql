

CREATE OR REPLACE FUNCTION fn_relatorio_consumo_ingredientes(
    p_data_inicio timestamp,
    p_data_fim    timestamp
)
RETURNS TABLE(
    id_franquia      int,
    nome_franquia    varchar,
    id_ingrediente   int,
    nome_ingrediente varchar,
    qtd_consumida    bigint
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        v.id_franquia,
        f.nome_franquia,
        v.id_ingrediente,
        i.nome_ingrediente,
        CAST(SUM(v.qtd_total) AS bigint)
    FROM vw_consumo_ingrediente_pedido v
    JOIN ingrediente i ON i.id_ingrediente = v.id_ingrediente
    JOIN franquia f    ON f.id_franquia = v.id_franquia
    WHERE v.status = 'Finalizado'
      AND v.data_venda BETWEEN p_data_inicio AND p_data_fim
    GROUP BY v.id_franquia, f.nome_franquia, v.id_ingrediente, i.nome_ingrediente
    ORDER BY v.id_franquia, SUM(v.qtd_total) DESC;
END;
$$ LANGUAGE plpgsql;


