create or replace function validar_valores_status()
returns trigger as $$
begin
	new.status := trim(new.status);

	if trim(upper(new.status)) not in ('EM ANDAMENTO','FINALIZADO','CANCELADO') then
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