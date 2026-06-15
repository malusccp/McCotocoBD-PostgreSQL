CREATE OR REPLACE FUNCTION estoque_minimo()
RETURNS TRIGGER
AS $$
BEGIN
	IF (NEW.qtd_atual < 0) THEN 
	RAISE EXCEPTION  'ATENÇÃO! Não pode dar baixa no ingrediente de id "%", pois não tem a quantidade suficiente!', NEW.id_ingrediente;
	ELSIF (NEW.qtd_atual <= 10) THEN 
	RAISE NOTICE 'ATENÇÃO! A quantidade de ingredientes de id "%" da franquia de id "%" precisa ser atualizado. Quantidade em estoque atualmente: %', NEW.id_ingrediente,
	NEW.id_franquia, NEW.qtd_atual;
	
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER validar_estoque_minimo
BEFORE UPDATE OF qtd_atual ON estoque_unid
FOR EACH ROW
EXECUTE FUNCTION estoque_minimo();