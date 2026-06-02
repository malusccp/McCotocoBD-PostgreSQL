create or replace function fn_atualizar_total_pedido()
returns trigger as $$
declare
    v_id_pedido int;
    v_total float;
begin
    if tg_op = 'DELETE' then
        v_id_pedido := old.id_pedido;
    else
        v_id_pedido := new.id_pedido;
    end if;

    select coalesce(sum(preco_unitario * quantidade), 0)
    into v_total
    from item_pedido
    where id_pedido = v_id_pedido;

    update pedido
    set total = v_total
    where id_pedido = v_id_pedido;

    return null; 
end;
$$ language plpgsql;

create trigger trg_atualizar_total_pedido
after insert or update or delete on item_pedido
for each row
execute function fn_atualizar_total_pedido();