create or replace function fn_devolver_estoque()
returns trigger as $$
declare
    v_id_ingrediente int;
    v_qtd_final_necessaria int;
begin
    for v_id_ingrediente, v_qtd_final_necessaria in 
        select * from fn_obter_ingredientes_necessarios(new.id_pedido)
    loop
       
        update estoque_unid 
        set qtd_atual = qtd_atual + v_qtd_final_necessaria
        where id_ingrediente = v_id_ingrediente and id_franquia = new.id_franquia;
    end loop;
    
    return new;
end;
$$ language plpgsql;

create trigger trg_devolver_estoque_pedido
after update of status on pedido
for each row
when (old.status = 'Finalizado' and new.status != 'Finalizado') 
execute function fn_devolver_estoque();
