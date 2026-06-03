create or replace function fn_impedir_modificacao_item()
returns trigger as $$
declare
    v_status varchar(50);
    v_id_pedido int;
begin
    
    if tg_op = 'DELETE' then
        v_id_pedido := old.id_pedido;
    else
        v_id_pedido := new.id_pedido;
    end if;

    select status into v_status 
    from pedido 
    where id_pedido = v_id_pedido;

  
    if v_status = 'Finalizado' then
        raise exception 'Não é permitido adicionar, alterar ou remover itens de um pedido que já possui o status Finalizado.';
    end if;

    if tg_op = 'DELETE' then
        return old;
    else
        return new;
    end if;
end;
$$ language plpgsql;


create trigger trg_impedir_modificacao_item
before insert or update or delete on item_pedido
for each row
execute function fn_impedir_modificacao_item();