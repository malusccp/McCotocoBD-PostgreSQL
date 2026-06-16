CREATE OR REPLACE FUNCTION transicao_status()
RETURNS TRIGGER 
AS $$
BEGIN 
 
    IF (trim(upper(OLD.status)) = 'CANCELADO') THEN 
        RAISE EXCEPTION 'Operação negada. Não é possível alterar um pedido de CANCELADO para %.', NEW.status;
    END IF; 
    
    IF (trim(upper(OLD.status)) = 'FINALIZADO') THEN 
    	RAISE EXCEPTION 'Operação negada. Não é possível alterar um pedido de FINALIZADO para %.', NEW.status;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER validar_transicao_status
BEFORE UPDATE OF status ON pedido 
FOR EACH ROW
EXECUTE FUNCTION transicao_status();