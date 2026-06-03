create or replace function validar_franquia_funcionario()
returns trigger as $$

begin
	if exists (select 1 from funcionario f
	where f.id_franquia != new.id_franquia and new.id_funcionario = f.id_funcionario
	) then
	raise exception 'O funcionário não trabalha na franquia inserida';
	end if;
	
	return new;

	end;
	

$$ language plpgsql;

create trigger trg_validar_franquia_funcionario
before insert or update on pedido
for each row
execute function validar_franquia_funcionario();