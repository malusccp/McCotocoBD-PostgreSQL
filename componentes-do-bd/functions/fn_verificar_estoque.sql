create or replace function fn_verificar_estoque(p_id_pedido int, p_id_franquia int)
returns void as $$
declare

    v_id_ingrediente int;
    v_qtd_final_necessaria int;
    v_qtd_estoque int;
begin
   
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
            where ip.id_pedido = p_id_pedido
            
            union all
            
            
            select 
                rp.id_ingrediente,
                (ip.quantidade * ic.qtd_prod * rp.qtd_necessaria) as qtd_total
            from item_pedido ip
            join item_combo ic on ip.id_produto = ic.id_combo
            join receita_produto rp on ic.id_produto = rp.id_produto
            where ip.id_pedido = p_id_pedido
            
        ) as ingredientes_necessarios
        group by id_ingrediente
        
    ) loop
    
        select qtd_atual into v_qtd_estoque 
        from estoque_unid 
        where id_ingrediente = v_id_ingrediente and id_franquia = p_id_franquia;
        
        if v_qtd_estoque is null or v_qtd_final_necessaria > v_qtd_estoque then
            
 
            raise exception 'Estoque insuficiente para o ingrediente %. quantidade necessária: %, em estoque: %', 
                v_id_ingrediente, v_qtd_final_necessaria, coalesce(v_qtd_estoque, 0);
                
        end if;
        
    end loop;
end;
$$ language plpgsql;