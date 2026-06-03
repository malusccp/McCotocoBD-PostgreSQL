create or replace function fn_verificar_estoque(p_id_pedido int, p_id_franquia int)
returns void as $$
declare
    v_id_ingrediente int;
    v_qtd_final_necessaria int;
    v_qtd_estoque int;
begin
   
    for v_id_ingrediente, v_qtd_final_necessaria in 
        select * from fn_obter_ingredientes_necessarios(p_id_pedido)
    loop
    
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