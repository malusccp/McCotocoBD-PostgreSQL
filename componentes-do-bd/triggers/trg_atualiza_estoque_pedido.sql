create or replace function fn_baixar_estoque_pedido()
returns trigger as $$
declare
	v_id_ingrediente int;
    v_qtd_final_necessaria int;

begin
    

	if new.status = 'Finalizado' and old.status != 'Finalizado' then

	perform fn_verificar_estoque(new.id_pedido, new.id_franquia);

    for v_id_ingrediente, v_qtd_final_necessaria in (
        
        select 
            id_ingrediente,
            sum(qtd_total) as qtd_final_necessaria
        from (
            
            select 
                rp.id_ingrediente,
                (ip.quantidade * rp.qtd_necessaria) as qtd_total
            from item_pedido ip
            join receita_produto rp on ip.id_produto = rp.id_produto
            where ip.id_pedido = new.id_pedido
            
            union all
            
            select 
                rp.id_ingrediente,
                (ip.quantidade * ic.qtd_prod * rp.qtd_necessaria) as qtd_total
            from item_pedido ip
            join item_combo ic on ip.id_produto = ic.id_combo
            join receita_produto rp on ic.id_produto = rp.id_produto
            where ip.id_pedido = new.id_pedido 
            
        ) as ingredientes_necessarios
        group by id_ingrediente
        
    ) loop
    
   		update estoque_unid set qtd_atual = qtd_atual - v_qtd_final_necessaria
		where id_ingrediente = v_id_ingrediente and new.id_franquia = id_franquia;
        
    end loop;
	

	end if;
    
    return new;
end;
$$ language plpgsql;


create trigger trg_atualiza_estoque_pedido
after update of status on pedido
for each row
execute function fn_baixar_estoque_pedido();




