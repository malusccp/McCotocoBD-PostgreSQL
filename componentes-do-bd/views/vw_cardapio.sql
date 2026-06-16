

CREATE OR REPLACE VIEW vw_cardapio AS
SELECT
    p.id_produto,
    p.nome_prod,
    c.nome_cat AS categoria,
    p.preco_base
FROM produto p
JOIN categoria c ON p.id_categoria = c.id_categoria
ORDER BY c.nome_cat, p.nome_prod;
