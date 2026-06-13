create role atendente_caixa;
GRANT SELECT ON produto, categoria, item_combo, ingrediente, receita_produto TO atendente_caixa;
GRANT SELECT, INSERT, UPDATE ON pedido, item_pedido TO atendente_caixa;
GRANT USAGE, SELECT ON SEQUENCE pedido_id_pedido_seq TO atendente_caixa;
GRANT EXECUTE ON FUNCTION venda(int, int, jsonb) TO atendente_caixa;
GRANT EXECUTE ON FUNCTION calcular_valor_total(jsonb) TO atendente_caixa;