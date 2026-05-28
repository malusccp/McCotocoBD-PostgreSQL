CREATE OR REPLACE FUNCTION fn_obter_meta_vigente(
    p_id_franquia INT, 
    OUT o_valor_meta FLOAT, 
    OUT o_porcentagem_bonus FLOAT
)
AS $$
BEGIN

	select valor_meta, porcentagem into o_valor_meta, o_porcentagem_bonus from meta m
	join meta_franquia mf on m.id_meta = mf.id_meta
	where mf.id_franquia = p_id_franquia and eh_vigente = true;

   
END;
$$ LANGUAGE plpgsql;