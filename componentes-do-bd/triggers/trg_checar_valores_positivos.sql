create or replace function checar_valores_positivos()
returns trigger as $$
begin
  
    if tg_table_name = 'produto' then
        if new.preco_base <= 0 then
            raise exception 'O preço base do produto não pode ser negativo. valor fornecido: %.', new.preco_base;
        end if;
        
    elsif tg_table_name = 'item_pedido' then
        if new.preco_unitario <= 0 then
            raise exception 'O preço unitário do item não pode ser negativo. valor fornecido: %.', new.preco_unitario;
        end if;

    elsif tg_table_name = 'funcionario' then
        if new.salario_base <= 0 then
            raise exception 'O salário base do funcionário não pode ser negativo. valor fornecido: %.', new.salario_base;
        end if;

    elsif tg_table_name = 'pedido' then
        if new.total <= 0 then
            raise exception 'O valor total do pedido não pode ser negativo. valor fornecido: %.', new.total;
        end if;
    end if;

    return new;
end;
$$ language plpgsql;

-- trg para tabela produto
create trigger trg_checar_preco_produto
before insert or update on produto
for each row
execute function checar_valores_positivos();

-- trg para tabela item_pedido
create trigger trg_checar_preco_item_pedido
before insert or update on item_pedido
for each row
execute function checar_valores_positivos();

-- trg para tabela funcionario
create trigger trg_checar_salario_funcionario
before insert or update on funcionario
for each row
execute function checar_valores_positivos();

-- trg para tabela pedido
create trigger trg_checar_total_pedido
before insert or update on pedido
for each row
execute function checar_valores_positivos();