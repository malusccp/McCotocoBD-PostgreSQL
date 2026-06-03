create or replace function fn_baixar_estoque_pedido()
returns trigger as $$
declare
    v_id_ingrediente int;
    v_qtd_final_necessaria int;
begin
    perform fn_verificar_estoque(new.id_pedido, new.id_franquia);

    for v_id_ingrediente, v_qtd_final_necessaria in 
        select * from fn_obter_ingredientes_necessarios(new.id_pedido)
    loop
        update estoque_unid 
        set qtd_atual = qtd_atual - v_qtd_final_necessaria
        where id_ingrediente = v_id_ingrediente and id_franquia = new.id_franquia;
    end loop;
    
    return new;
end;
$$ language plpgsql;


create trigger trg_baixar_estoque_pedido
after update of status ON pedido
for each row
when (new.status = 'Finalizado' AND OLD.status != 'Finalizado') 
EXECUTE FUNCTION fn_baixar_estoque_pedido();



