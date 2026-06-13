CREATE OR REPLACE FUNCTION calcular_valor_total(p_itens jsonb)
RETURNS FLOAT
AS $$
DECLARE 
    v_valor_total float := 0; 
    v_valor_calculado float;
    item jsonb;
BEGIN
    FOR item IN SELECT * FROM jsonb_array_elements(p_itens)
    LOOP 
        SELECT (preco_base * (item ->> 'qtd')::int) 
        INTO v_valor_calculado
        FROM produto 
        WHERE id_produto = (item ->> 'id_produto')::int;
    
        v_valor_total := v_valor_total + v_valor_calculado;
        
        IF v_valor_calculado IS NULL THEN
            RAISE EXCEPTION 'Produto com ID % não foi encontrado no banco de dados.', (item->>'id_produto')::int;
        END IF;
        
    END LOOP; 
    
    RETURN v_valor_total;
    
END;
$$ LANGUAGE plpgsql;




SELECT * FROM produto;
