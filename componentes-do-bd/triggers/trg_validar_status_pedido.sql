create or replace function validar_valores_status()
returns trigger as $$
begin
	if new.status not in ('Em Andamento','Finalizado','Cancelado') then
		raise exception 'A definição de Status da compra está diferente do padronizado. Valor fornecido: "%"', new.status;
	end if;

    return new;
end;
$$
language plpgsql;

create trigger trg_validar_status_pedido
before insert or update on pedido
for each row
execute function validar_valores_status();