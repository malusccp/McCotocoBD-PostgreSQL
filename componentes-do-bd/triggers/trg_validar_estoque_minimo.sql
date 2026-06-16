CREATE OR REPLACE FUNCTION estoque_minimo()
RETURNS TRIGGER
AS $$
BEGIN
	IF (NEW.qtd_atual < 0) THEN
	RAISE EXCEPTION 'Operação negada: o estoque do ingrediente % (franquia %) não pode ficar negativo. Valor resultante: %.',
		NEW.id_ingrediente, NEW.id_franquia, NEW.qtd_atual;
	END IF;

	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER validar_estoque_minimo
BEFORE INSERT OR UPDATE OF qtd_atual ON estoque_unid
FOR EACH ROW
EXECUTE FUNCTION estoque_minimo();