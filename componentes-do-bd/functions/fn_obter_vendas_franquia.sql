CREATE OR REPLACE FUNCTION fn_obter_vendas_franquia(p_id_franquia INT, p_mes INT, p_ano INT)
RETURNS FLOAT AS $$
DECLARE
    v_total_vendas FLOAT := 0;
BEGIN


	select coalesce(SUM(total), 0) into v_total_vendas from pedido p
	where p.id_franquia = p_id_franquia 
	and extract(year from data_venda) = p_ano 
	and extract(month from data_venda) = p_mes 
	and status = 'Finalizado';
	
	
    RETURN v_total_vendas;
END;
$$ LANGUAGE plpgsql;