CREATE OR REPLACE FUNCTION transicao_status()
RETURNS TRIGGER 
AS $$
BEGIN 
 
    IF (trim(upper(OLD.status)) = 'CANCELADO') THEN 
        RAISE EXCEPTION 'O status do pedido % não pode ser mudado para "%", pois já está cancelado.', OLD.id_pedido, NEW.status;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER validar_transicao_status
BEFORE UPDATE OF status ON pedido 
FOR EACH ROW
EXECUTE FUNCTION transicao_status();