CREATE OR REPLACE FUNCTION venda(
    p_id_funcionario int,
    p_id_franquia    int,
    p_itens          jsonb
)
RETURNS VOID AS $$
DECLARE
    v_id_pedido  int;
    v_preco_base float;
    item         jsonb;
    v_valor_total float;
BEGIN

    v_valor_total := calcular_valor_total(p_itens);

    INSERT INTO pedido (status, total, id_funcionario, id_franquia)
    VALUES ('Em Andamento', v_valor_total, p_id_funcionario, p_id_franquia)
    RETURNING id_pedido INTO v_id_pedido;

    FOR item IN SELECT * FROM jsonb_array_elements(p_itens)
    LOOP

        SELECT preco_base INTO v_preco_base
        FROM produto
        WHERE id_produto = (item->>'id_produto')::int;

        INSERT INTO item_pedido (id_pedido, id_produto, preco_unitario, quantidade)
        VALUES (
            v_id_pedido,
            (item->>'id_produto')::int,
            v_preco_base,
            (item->>'qtd')::int 
        );

    END LOOP;

    UPDATE pedido
    SET status = 'Finalizado'
    WHERE id_pedido = v_id_pedido;
    
    RAISE NOTICE 'Venda % finalizada com sucesso! Valor Total: R$ %', v_id_pedido, v_valor_total;

END;
$$ LANGUAGE plpgsql;



SELECT venda(
    1, 
    1, 
    '[
        {"id_produto": 1, "qtd": 2},
        {"id_produto": 3, "qtd": 1}
    ]'::jsonb
);


SELECT venda(
    1, 
    2, -- Franquia incorreta
    '[{"id_produto": 1, "qtd": 1}]'::jsonb
);

SELECT * FROM item_pedido;