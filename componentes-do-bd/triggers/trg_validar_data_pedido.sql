create or replace function validar_data_pedido()
returns trigger as $$
 begin

 if new.data_venda > current_timestamp then
 	raise exception 'A data da venda não pode ser no futuro. Valor fornecido: %', new.data_venda;
    end if;

	return new;

	end;

$$ language plpgsql;

create trigger trg_validar_data_pedido
before insert or update on pedido
for each row
execute function validar_data_pedido();