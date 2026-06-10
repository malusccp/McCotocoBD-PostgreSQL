CREATE OR REPLACE FUNCTION validar_venda()
RETURNS TRIGGER
AS $$
BEGIN
	IF ((SELECT id_franquia FROM funcionario WHERE id_funcionario = NEW.id_funcionario) IS DISTINCT FROM NEW.id_franquia) THEN
		RAISE EXCEPTION 'Essa venda não pode ser concluída, pois o funcionário que a fez não é dessa franquia.';
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER validacao_de_venda_pela_franquia_funcionario
BEFORE INSERT ON pedido
FOR EACH ROW
EXECUTE FUNCTION validar_venda();