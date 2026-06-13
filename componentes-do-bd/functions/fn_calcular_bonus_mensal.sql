create or replace function fn_calcular_bonus_mensal(p_id_franquia int, p_mes int, p_ano int)
returns void as $$
declare
v_total_vendido float;
v_valor_meta FLOAT;
v_porcentagem_bonus FLOAT;

begin

	v_total_vendido := fn_obter_vendas_franquia(p_id_franquia, p_mes, p_ano);

	select o_valor_meta, o_porcentagem_bonus into v_valor_meta, v_porcentagem_bonus from
	fn_obter_meta_vigente(p_id_franquia);

	if v_valor_meta is null then
        RAISE EXCEPTION 'Não há meta vigente cadastrada para a franquia %.', p_id_franquia;
    END IF;

	if v_total_vendido >= v_valor_meta then 

		insert into historico_bonus(id_funcionario, mes, ano, valor_bonus)
		select id_funcionario, p_mes, p_ano, (salario_base * (v_porcentagem_bonus / 100.0)) from funcionario
		where id_franquia = p_id_franquia
		on conflict (id_funcionario, mes, ano)
			do update set 
            valor_bonus = EXCLUDED.valor_bonus, 
            data_pagamento = CURRENT_TIMESTAMP;

		raise notice 'Sucesso: Meta atingida! Bônus processado para a franquia % referente a %/%.', p_id_franquia, p_mes, p_ano;

	else
        raise notice 'Aviso: A franquia % não atingiu a meta em %/%. Vendas: R$ %, Meta: R$ %', 
            p_id_franquia, p_mes, p_ano, v_total_vendas, v_valor_meta;
    end if;

	end;

$$ language plpgsql;