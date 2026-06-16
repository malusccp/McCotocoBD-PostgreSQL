CREATE OR REPLACE FUNCTION fn_auditoria_generica()
RETURNS TRIGGER
SECURITY DEFINER
AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO log_auditoria(nome_tabela, operacao, dados_novos)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(NEW));
        RETURN NEW;

    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO log_auditoria(nome_tabela, operacao, dados_antigos, dados_novos)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO log_auditoria(nome_tabela, operacao, dados_antigos)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD));
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER trg_auditar_funcionario
AFTER INSERT OR UPDATE OR DELETE ON funcionario
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_generica();

CREATE OR REPLACE TRIGGER trg_auditar_franquia
AFTER INSERT OR UPDATE OR DELETE ON franquia
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_generica();

CREATE OR REPLACE TRIGGER trg_auditar_produto
AFTER INSERT OR UPDATE OR DELETE ON produto
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_generica();

CREATE OR REPLACE TRIGGER trg_auditar_pedido
AFTER INSERT OR UPDATE OR DELETE ON pedido
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_generica();

CREATE OR REPLACE TRIGGER trg_auditar_item_pedido
AFTER INSERT OR UPDATE OR DELETE ON item_pedido
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_generica();

CREATE OR REPLACE TRIGGER trg_auditar_estoque_unid
AFTER INSERT OR UPDATE OR DELETE ON estoque_unid
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_generica();

CREATE OR REPLACE TRIGGER trg_auditar_meta_franquia
AFTER INSERT OR UPDATE OR DELETE ON meta_franquia
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_generica();

CREATE OR REPLACE TRIGGER trg_auditar_historico_bonus
AFTER INSERT OR UPDATE OR DELETE ON historico_bonus
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_generica();
