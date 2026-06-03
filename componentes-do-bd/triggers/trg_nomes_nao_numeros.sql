create or replace function validar_nome_funcionario()
returns trigger as $$
begin
    if new.nome_funcionario ~ '.*\d.*' then
        raise exception 'Não é permitido números dentro do nome do funcionário. valor fornecido: "%".', new.nome_funcionario;
    end if;

    return new;
end;
$$ language plpgsql;

create trigger trg_nomes_nao_numeros
before insert or update on funcionario
for each row
execute function validar_nome_funcionario();