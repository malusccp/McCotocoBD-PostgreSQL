create or replace function checar_cnpj_unico_franquia()
returns trigger as $$
 begin

	if exists( select 1 from franquia
	where cnpj = new.cnpj and 
	id_franquia is distinct 
	from new.id_franquia
	) then
		RAISE EXCEPTION 'Já existe um franquia cadastrado com o CNPJ %.', NEW.CNPJ;

	end if;

	return new;

	end;
	
$$ language plpgsql;

create trigger trg_checar_cnpj_unico_franquia
before insert or update on franquia
for each row
execute function checar_cnpj_unico_franquia();

