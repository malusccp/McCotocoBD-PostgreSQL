create or replace function checar_cpf_unico_funcionario()
returns trigger as $$
begin
    if exists (
        select 1
        from funcionario
        where cpf = new.cpf
        and id_funcionario is distinct from new.id_funcionario  
    ) then
       
        raise exception 'Já existe um funcionário cadastrado com o cpf %.', new.cpf;
    end if;

    return new;
end;
$$ language plpgsql;

create or replace trigger trg_checar_cpf_unico_funcionario
before insert or update on funcionario
for each row
execute function checar_cpf_unico_funcionario();