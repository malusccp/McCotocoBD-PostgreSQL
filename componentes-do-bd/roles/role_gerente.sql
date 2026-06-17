CREATE ROLE gerente;

GRANT atendente_caixa TO gerente;

GRANT SELECT, INSERT, UPDATE ON funcionario TO gerente;
GRANT USAGE, SELECT ON SEQUENCE funcionario_id_funcionario_seq TO gerente;

GRANT SELECT, INSERT, UPDATE ON estoque_unid TO gerente;

GRANT SELECT, INSERT, UPDATE ON meta, meta_franquia TO gerente;
GRANT USAGE, SELECT ON SEQUENCE meta_id_meta_seq, meta_franquia_id_meta_vigente_seq TO gerente;

GRANT EXECUTE ON FUNCTION inserir(TEXT, JSONB) TO gerente;
GRANT EXECUTE ON FUNCTION atualizar(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO gerente;
GRANT EXECUTE ON FUNCTION deletar(TEXT, TEXT, TEXT, TEXT) TO gerente;

GRANT SELECT ON franquia TO gerente;