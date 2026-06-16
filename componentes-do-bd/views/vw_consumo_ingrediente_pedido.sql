

CREATE OR REPLACE VIEW vw_consumo_ingrediente_pedido AS

SELECT
    pe.id_pedido,
    pe.id_franquia,
    pe.status,
    pe.data_venda,
    rp.id_ingrediente,
    (ip.quantidade * rp.qtd_necessaria) AS qtd_total
FROM pedido pe
JOIN item_pedido ip     ON ip.id_pedido = pe.id_pedido
JOIN receita_produto rp ON ip.id_produto = rp.id_produto

UNION ALL


SELECT
    pe.id_pedido,
    pe.id_franquia,
    pe.status,
    pe.data_venda,
    rp.id_ingrediente,
    (ip.quantidade * ic.qtd_prod * rp.qtd_necessaria) AS qtd_total
FROM pedido pe
JOIN item_pedido ip     ON ip.id_pedido = pe.id_pedido
JOIN item_combo ic      ON ip.id_produto = ic.id_combo
JOIN receita_produto rp ON ic.id_produto = rp.id_produto;
