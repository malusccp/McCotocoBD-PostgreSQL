
CREATE OR REPLACE FUNCTION fn_ranking_funcionarios_vendas(
    p_data_inicio timestamp,
    p_data_fim    timestamp
)
RETURNS TABLE(
    posicao          bigint,
    id_funcionario   int,
    nome_funcionario varchar,
    nome_franquia    varchar,
    total_vendido    float
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        RANK() OVER (ORDER BY COALESCE(SUM(p.total), 0) DESC),
        fu.id_funcionario,
        fu.nome_funcionario,
        f.nome_franquia,
        COALESCE(SUM(p.total), 0)
    FROM funcionario fu
    LEFT JOIN franquia f
        ON f.id_franquia = fu.id_franquia
    LEFT JOIN pedido p
        ON p.id_funcionario = fu.id_funcionario
        AND p.status = 'Finalizado'
        AND p.data_venda BETWEEN p_data_inicio AND p_data_fim
    GROUP BY fu.id_funcionario, fu.nome_funcionario, f.nome_franquia
    ORDER BY COALESCE(SUM(p.total), 0) DESC;
END;
$$ LANGUAGE plpgsql;


