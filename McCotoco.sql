--================================================================================--
-- 				SCRIPT COMPLETO - BANCO DE DADOS MCCOTOCO
--================================================================================--
-- 	Versão final com organização, padronização e inclusão de restrições NOT NULL
-- 	para garantir a integridade e consistência dos dados.
--================================================================================--

--================================================================================--
-- 				1. CRIAÇÃO DAS TABELAS
--================================================================================--
CREATE TABLE categoria(
    id_categoria serial PRIMARY KEY,
    nome_cat varchar(50) NOT NULL
);

CREATE TABLE ingrediente(
    id_ingrediente serial PRIMARY KEY,
    nome_ingrediente varchar(50) NOT NULL
);

CREATE TABLE meta(
    id_meta serial PRIMARY KEY,
    valor_meta float NOT NULL,
    porcentagem float NOT NULL
);

CREATE TABLE franquia(
    id_franquia serial PRIMARY KEY,
    nome_franquia varchar(50) NOT NULL,
    endereco varchar(100) NOT NULL,
    cnpj varchar(14) NOT NULL
);

CREATE TABLE produto(
    id_produto serial PRIMARY KEY,
    preco_base float NOT NULL,
    nome_prod varchar(50),
    id_categoria int NOT NULL REFERENCES categoria(id_categoria)
);

CREATE TABLE funcionario(
    id_funcionario serial PRIMARY KEY,
    cpf varchar(11) NOT NULL,
    nome_funcionario varchar(100) NOT NULL,
    cargo varchar(50) NOT NULL,
    salario_base float NOT NULL,
    id_franquia int REFERENCES franquia(id_franquia)
);

CREATE TABLE pedido(
    id_pedido serial PRIMARY KEY,
    data_venda timestamp DEFAULT current_timestamp,
    status varchar(50) NOT NULL,
    total float,
    id_funcionario int REFERENCES funcionario(id_funcionario),
    id_franquia int REFERENCES franquia(id_franquia)
);

CREATE TABLE item_pedido(
    id_pedido int REFERENCES pedido(id_pedido),
    id_produto int REFERENCES produto(id_produto),
    preco_unitario float NOT NULL,
    quantidade int NOT NULL,
    PRIMARY KEY(id_pedido, id_produto)
);

CREATE TABLE item_combo(
    id_combo int REFERENCES produto(id_produto),
    id_produto int REFERENCES produto(id_produto),
    qtd_prod int NOT NULL,
    PRIMARY KEY(id_combo, id_produto)
);

CREATE TABLE receita_produto(
    id_produto int REFERENCES produto(id_produto),
    id_ingrediente int REFERENCES ingrediente(id_ingrediente),
    qtd_necessaria int NOT NULL,
    PRIMARY KEY(id_produto, id_ingrediente)
);

CREATE TABLE estoque_unid(
    id_franquia int REFERENCES franquia(id_franquia),
    id_ingrediente int REFERENCES ingrediente(id_ingrediente),
    qtd_atual int NOT NULL,
    PRIMARY KEY(id_franquia, id_ingrediente)
);

CREATE TABLE meta_franquia(
    id_meta_vigente serial PRIMARY KEY,
    id_meta int REFERENCES meta(id_meta),
    id_franquia int REFERENCES franquia(id_franquia),
    eh_vigente boolean NOT NULL DEFAULT TRUE
);

CREATE TABLE historico_bonus(
    id_historico serial PRIMARY KEY,
    id_funcionario int REFERENCES funcionario(id_funcionario),
    mes int NOT NULL,
    ano int NOT NULL,
    valor_bonus float NOT NULL,
    data_pagamento timestamp DEFAULT current_timestamp,
    UNIQUE(id_funcionario, mes, ano)
);

CREATE TABLE log_auditoria(
    id_log        serial PRIMARY KEY,
    nome_tabela   varchar(50) NOT NULL,
    operacao      varchar(10) NOT NULL,
    usuario       varchar(50) NOT NULL DEFAULT current_user,
    data_hora     timestamp   NOT NULL DEFAULT current_timestamp,
    dados_antigos jsonb,
    dados_novos   jsonb
);

--================================================================================--
-- 				1.1. VIEWS
--================================================================================--

CREATE OR REPLACE VIEW vw_consumo_ingrediente_pedido AS
SELECT
    pe.id_pedido,
    pe.id_franquia,
    pe.status,
    pe.data_venda,
    rp.id_ingrediente,
    (ip.quantidade * rp.qtd_necessaria) AS qtd_total
FROM pedido pe
JOIN item_pedido ip     ON ip.id_pedido  = pe.id_pedido
JOIN receita_produto rp ON ip.id_produto = rp.id_produto
UNION ALL
SELECT
    pe.id_pedido,
    pe.id_franquia,
    pe.status,
    pe.data_venda,
    rp.id_ingrediente,
    (ip.quantidade * ic.qtd_prod * rp.qtd_necessaria) AS qtd_total
FROM pedido pe
JOIN item_pedido ip     ON ip.id_pedido  = pe.id_pedido
JOIN item_combo ic      ON ip.id_produto = ic.id_combo
JOIN receita_produto rp ON ic.id_produto = rp.id_produto;

CREATE OR REPLACE VIEW vw_cardapio AS
SELECT
    p.id_produto,
    p.nome_prod,
    c.nome_cat AS categoria,
    p.preco_base
FROM produto p
JOIN categoria c ON p.id_categoria = c.id_categoria
ORDER BY c.nome_cat, p.nome_prod;

--================================================================================--
-- 				2. GATILHOS (TRIGGERS) E SUAS FUNÇÕES
--================================================================================--

------------------------------------------------------------------------------------
-- 2.1 Validação de nome do funcionário (sem números)
------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION validar_nome_funcionario()
RETURNS TRIGGER AS $$
BEGIN
    IF new.nome_funcionario ~ '.*\d.*' THEN
        RAISE EXCEPTION 'Não é permitido números dentro do nome do funcionário. Valor fornecido: "%".', new.nome_funcionario;
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_nomes_nao_numeros
BEFORE INSERT OR UPDATE ON funcionario
FOR EACH ROW
EXECUTE FUNCTION validar_nome_funcionario();

------------------------------------------------------------------------------------
-- 2.2 Validação de CPF único e formato (11 dígitos numéricos)
------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION checar_cpf_unico_funcionario()
RETURNS TRIGGER AS $$
BEGIN
    IF new.cpf !~ '^[0-9]{11}$' THEN
        RAISE EXCEPTION 'CPF inválido: deve conter exatamente 11 dígitos numéricos. Valor fornecido: "%".', new.cpf;
    END IF;
    IF EXISTS (
        SELECT 1 FROM funcionario
        WHERE cpf = new.cpf
          AND id_funcionario IS DISTINCT FROM new.id_funcionario
    ) THEN
        RAISE EXCEPTION 'Já existe um funcionário cadastrado com o CPF %.', new.cpf;
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_checar_cpf_unico_funcionario
BEFORE INSERT OR UPDATE ON funcionario
FOR EACH ROW
EXECUTE FUNCTION checar_cpf_unico_funcionario();

------------------------------------------------------------------------------------
-- 2.3 Validação de CNPJ único por franquia
------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION checar_cnpj_unico_franquia()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM franquia
        WHERE cnpj = new.cnpj
          AND id_franquia IS DISTINCT FROM new.id_franquia
    ) THEN
        RAISE EXCEPTION 'Já existe uma franquia cadastrada com o CNPJ %.', new.cnpj;
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_checar_cnpj_unico_franquia
BEFORE INSERT OR UPDATE ON franquia
FOR EACH ROW
EXECUTE FUNCTION checar_cnpj_unico_franquia();

------------------------------------------------------------------------------------
-- 2.4 Validação de valores positivos (preços, salários, metas e totais)
------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION checar_valores_positivos()
RETURNS TRIGGER AS $$
BEGIN
    IF tg_table_name = 'produto' THEN
        IF new.preco_base <= 0 THEN
            RAISE EXCEPTION 'O preço base do produto não pode ser negativo ou nulo. Valor fornecido: %.', new.preco_base;
        END IF;
    ELSIF tg_table_name = 'item_pedido' THEN
        IF new.preco_unitario <= 0 THEN
            RAISE EXCEPTION 'O preço unitário do item não pode ser negativo ou nulo. Valor fornecido: %.', new.preco_unitario;
        END IF;
        IF new.quantidade <= 0 THEN
            RAISE EXCEPTION 'A quantidade do item do pedido deve ser maior que zero. Valor fornecido: %.', new.quantidade;
        END IF;
    ELSIF tg_table_name = 'meta' THEN
        IF new.valor_meta <= 0 THEN
            RAISE EXCEPTION 'O valor da meta deve ser maior que zero. Valor fornecido: %.', new.valor_meta;
        END IF;
        IF new.porcentagem <= 0 THEN
            RAISE EXCEPTION 'A porcentagem de bônus da meta deve ser maior que zero. Valor fornecido: %.', new.porcentagem;
        END IF;
    ELSIF tg_table_name = 'funcionario' THEN
        IF new.salario_base <= 0 THEN
            RAISE EXCEPTION 'O salário base do funcionário não pode ser negativo ou nulo. Valor fornecido: %.', new.salario_base;
        END IF;
    ELSIF tg_table_name = 'pedido' THEN
        IF new.total <= 0 THEN
            RAISE EXCEPTION 'O valor total do pedido não pode ser negativo ou nulo. Valor fornecido: %.', new.total;
        END IF;
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_checar_preco_produto
BEFORE INSERT OR UPDATE ON produto
FOR EACH ROW
EXECUTE FUNCTION checar_valores_positivos();

CREATE TRIGGER trg_checar_preco_item_pedido
BEFORE INSERT OR UPDATE ON item_pedido
FOR EACH ROW
EXECUTE FUNCTION checar_valores_positivos();

CREATE TRIGGER trg_checar_salario_funcionario
BEFORE INSERT OR UPDATE ON funcionario
FOR EACH ROW
EXECUTE FUNCTION checar_valores_positivos();

CREATE TRIGGER trg_checar_total_pedido
BEFORE INSERT OR UPDATE ON pedido
FOR EACH ROW
EXECUTE FUNCTION checar_valores_positivos();

CREATE TRIGGER trg_checar_valores_meta
BEFORE INSERT OR UPDATE ON meta
FOR EACH ROW
EXECUTE FUNCTION checar_valores_positivos();

------------------------------------------------------------------------------------
-- 2.5 Validação de data do pedido (não permite data futura)
------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION validar_data_pedido()
RETURNS TRIGGER AS $$
BEGIN
    IF new.data_venda > current_timestamp THEN
        RAISE EXCEPTION 'A data da venda não pode ser no futuro. Valor fornecido: %', new.data_venda;
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_data_pedido
BEFORE INSERT OR UPDATE ON pedido
FOR EACH ROW
EXECUTE FUNCTION validar_data_pedido();

------------------------------------------------------------------------------------
-- 2.6 Validação do valor do status do pedido
------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION validar_valores_status()
RETURNS TRIGGER AS $$
BEGIN
    new.status := trim(new.status);
    IF trim(upper(new.status)) NOT IN ('EM ANDAMENTO', 'FINALIZADO', 'CANCELADO') THEN
        RAISE EXCEPTION 'A definição de Status da compra está diferente do padronizado. Valor fornecido: "%"', new.status;
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_status_pedido
BEFORE INSERT OR UPDATE ON pedido
FOR EACH ROW
EXECUTE FUNCTION validar_valores_status();

------------------------------------------------------------------------------------
-- 2.7 Bloqueio de transição de status inválida
--     (Cancelado e Finalizado não podem ter o status revertido)
------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION transicao_status()
RETURNS TRIGGER AS $$
BEGIN
    IF (trim(upper(OLD.status)) = 'CANCELADO') THEN
        RAISE EXCEPTION 'Operação negada. Não é possível alterar um pedido de CANCELADO para %.', new.status;
    END IF;
    IF (trim(upper(OLD.status)) = 'FINALIZADO') THEN
        RAISE EXCEPTION 'Operação negada. Não é possível alterar um pedido de FINALIZADO para %.', new.status;
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER validar_transicao_status
BEFORE UPDATE OF status ON pedido
FOR EACH ROW
EXECUTE FUNCTION transicao_status();

------------------------------------------------------------------------------------
-- 2.8 Validação de que o funcionário pertence à franquia do pedido
------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION validar_venda()
RETURNS TRIGGER AS $$
BEGIN
    IF ((SELECT id_franquia FROM funcionario WHERE id_funcionario = new.id_funcionario) IS DISTINCT FROM new.id_franquia) THEN
        RAISE EXCEPTION 'Essa venda não pode ser concluída, pois o funcionário que a fez não é dessa franquia.';
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER validacao_de_venda_pela_franquia_funcionario
BEFORE INSERT ON pedido
FOR EACH ROW
EXECUTE FUNCTION validar_venda();

------------------------------------------------------------------------------------
-- 2.9 Garante que só há uma meta vigente por franquia
------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION meta_vigente()
RETURNS TRIGGER AS $$
DECLARE
    mensagem_erro   TEXT;
    codigo_sqlstate TEXT;
BEGIN
    IF new.eh_vigente = TRUE THEN
        IF TG_OP = 'INSERT' THEN
            UPDATE meta_franquia
            SET eh_vigente = FALSE
            WHERE id_franquia = new.id_franquia AND eh_vigente = TRUE;
        ELSIF TG_OP = 'UPDATE' THEN
            UPDATE meta_franquia
            SET eh_vigente = FALSE
            WHERE id_franquia = new.id_franquia
              AND id_meta_vigente != new.id_meta_vigente
              AND eh_vigente = TRUE;
        END IF;
    END IF;
    RETURN new;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            mensagem_erro   = MESSAGE_TEXT,
            codigo_sqlstate = RETURNED_SQLSTATE;
        IF codigo_sqlstate = '42501' THEN
            RAISE EXCEPTION 'Acesso negado. O seu perfil não tem permissão para manipular as metas dessa franquia.';
        ELSE
            RAISE EXCEPTION 'Erro ao processar os dados da meta. (Erro: %)', SQLERRM;
        END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER atualizar_meta_vigente
BEFORE INSERT OR UPDATE ON meta_franquia
FOR EACH ROW
EXECUTE FUNCTION meta_vigente();

------------------------------------------------------------------------------------
-- 2.10 Recálculo automático do total do pedido ao modificar itens
------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_atualizar_total_pedido()
RETURNS TRIGGER AS $$
DECLARE
    v_id_pedido int;
    v_total     float;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_id_pedido := OLD.id_pedido;
    ELSE
        v_id_pedido := new.id_pedido;
    END IF;

    SELECT COALESCE(SUM(preco_unitario * quantidade), 0)
    INTO v_total
    FROM item_pedido
    WHERE id_pedido = v_id_pedido;

    IF EXISTS (SELECT 1 FROM pedido WHERE id_pedido = v_id_pedido) THEN
        UPDATE pedido SET total = v_total WHERE id_pedido = v_id_pedido;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_atualizar_total_pedido
AFTER INSERT OR UPDATE OR DELETE ON item_pedido
FOR EACH ROW
EXECUTE FUNCTION fn_atualizar_total_pedido();

------------------------------------------------------------------------------------
-- 2.11 Bloqueio de alteração de itens em pedido já finalizado
------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_impedir_modificacao_item()
RETURNS TRIGGER AS $$
DECLARE
    v_status    varchar(50);
    v_id_pedido int;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_id_pedido := OLD.id_pedido;
    ELSE
        v_id_pedido := new.id_pedido;
    END IF;

    SELECT status INTO v_status FROM pedido WHERE id_pedido = v_id_pedido;

    IF v_status = 'Finalizado' THEN
        RAISE EXCEPTION 'Não é permitido adicionar, alterar ou remover itens de um pedido que já possui o status Finalizado.';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN new;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_impedir_modificacao_item
BEFORE INSERT OR UPDATE OR DELETE ON item_pedido
FOR EACH ROW
EXECUTE FUNCTION fn_impedir_modificacao_item();

------------------------------------------------------------------------------------
-- 2.12 Baixa de estoque ao finalizar pedido
------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_baixar_estoque_pedido()
RETURNS TRIGGER AS $$
DECLARE
    v_id_ingrediente       int;
    v_qtd_final_necessaria int;
BEGIN
    PERFORM fn_verificar_estoque(new.id_pedido, new.id_franquia);

    FOR v_id_ingrediente, v_qtd_final_necessaria IN
        SELECT * FROM fn_obter_ingredientes_necessarios(new.id_pedido)
    LOOP
        UPDATE estoque_unid
        SET qtd_atual = qtd_atual - v_qtd_final_necessaria
        WHERE id_ingrediente = v_id_ingrediente AND id_franquia = new.id_franquia;
    END LOOP;

    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_baixar_estoque_pedido
AFTER UPDATE OF status ON pedido
FOR EACH ROW
WHEN (new.status = 'Finalizado' AND OLD.status != 'Finalizado')
EXECUTE FUNCTION fn_baixar_estoque_pedido();

------------------------------------------------------------------------------------
-- 2.13 Devolução de estoque ao reverter status de Finalizado
------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_devolver_estoque()
RETURNS TRIGGER AS $$
DECLARE
    v_id_ingrediente       int;
    v_qtd_final_necessaria int;
BEGIN
    FOR v_id_ingrediente, v_qtd_final_necessaria IN
        SELECT * FROM fn_obter_ingredientes_necessarios(new.id_pedido)
    LOOP
        UPDATE estoque_unid
        SET qtd_atual = qtd_atual + v_qtd_final_necessaria
        WHERE id_ingrediente = v_id_ingrediente AND id_franquia = new.id_franquia;
    END LOOP;

    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_devolver_estoque_pedido
AFTER UPDATE OF status ON pedido
FOR EACH ROW
WHEN (OLD.status = 'Finalizado' AND new.status != 'Finalizado')
EXECUTE FUNCTION fn_devolver_estoque();

------------------------------------------------------------------------------------
-- 2.14 Validação de estoque mínimo (impede estoque negativo)
------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION estoque_minimo()
RETURNS TRIGGER AS $$
BEGIN
    IF (new.qtd_atual < 0) THEN
        RAISE EXCEPTION 'Operação negada: o estoque do ingrediente % (franquia %) não pode ficar negativo. Valor resultante: %.',
            new.id_ingrediente, new.id_franquia, new.qtd_atual;
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER validar_estoque_minimo
BEFORE INSERT OR UPDATE OF qtd_atual ON estoque_unid
FOR EACH ROW
EXECUTE FUNCTION estoque_minimo();

------------------------------------------------------------------------------------
-- 2.15 Auditoria genérica (log de INSERT/UPDATE/DELETE nas tabelas críticas)
------------------------------------------------------------------------------------
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

--================================================================================--
-- 				3. FUNÇÕES
--================================================================================--

------------------------------------------------------------------------------------
-- 3.1. FUNÇÕES GENÉRICAS DE MANIPULAÇÃO DE DADOS
------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inserir(nome_tabela TEXT, valores JSONB)
RETURNS VOID AS $$
DECLARE
    mensagem_erro   text;
    codigo_sqlstate text;
BEGIN
    EXECUTE format('INSERT INTO %I SELECT * FROM jsonb_populate_record(NULL::%I, $1)', nome_tabela, nome_tabela)
    USING valores;
    RAISE NOTICE 'Dados inseridos com sucesso na tabela %!', nome_tabela;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            mensagem_erro   = MESSAGE_TEXT,
            codigo_sqlstate = RETURNED_SQLSTATE;
        IF codigo_sqlstate = '42501' THEN
            RAISE EXCEPTION 'Acesso negado. O seu perfil não tem permissão para inserir na tabela "%".', nome_tabela;
        ELSIF codigo_sqlstate = 'P0001' THEN
            RAISE EXCEPTION 'Erro ao inserir dados na tabela "%". %. Por favor, verifique os dados fornecidos.', nome_tabela, mensagem_erro;
        ELSE
            RAISE EXCEPTION 'Erro ao inserir dados na tabela "%". Por favor, verifique os dados fornecidos ou a estrutura da tabela. (Erro: %)', nome_tabela, SQLERRM;
        END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION deletar(
    nome_tabela TEXT,
    nome_coluna TEXT DEFAULT NULL,
    operador    TEXT DEFAULT NULL,
    valor       TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    mensagem_erro   text;
    codigo_sqlstate text;
BEGIN
    IF (nome_coluna IS NULL AND operador IS NULL AND valor IS NULL) THEN
        EXECUTE format('DELETE FROM %I', nome_tabela);
        RAISE NOTICE 'Todos os dados da tabela "%" foram deletados!', nome_tabela;
    ELSIF NOT (trim(upper(operador)) IN ('=', '>', '<', '>=', '<=', '<>', '!=', 'LIKE', 'ILIKE', 'IS NULL', 'IS NOT NULL')) THEN
        RAISE EXCEPTION 'Operador "%" inválido ou não permitido por motivos de segurança.', operador;
    ELSIF (trim(upper(operador)) IN ('IS NULL', 'IS NOT NULL')) THEN
        EXECUTE format('DELETE FROM %I WHERE %I %s', nome_tabela, nome_coluna, operador);
        RAISE NOTICE 'Todos os dados onde "% %" foram deletados.', nome_coluna, operador;
    ELSE
        EXECUTE format('DELETE FROM %I WHERE %I %s %L', nome_tabela, nome_coluna, operador, valor);
        RAISE NOTICE 'Todos os dados da tabela "%" foram deletados seguindo as seguintes condições: % % %', nome_tabela, nome_coluna, operador, valor;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            mensagem_erro   = MESSAGE_TEXT,
            codigo_sqlstate = RETURNED_SQLSTATE;
        IF codigo_sqlstate = '42501' THEN
            RAISE EXCEPTION 'Acesso negado. O seu perfil não tem permissão para deletar dados na tabela "%".', nome_tabela;
        ELSE
            RAISE EXCEPTION 'Erro ao deletar dados na tabela "%". Por favor, verifique os dados fornecidos ou as dependências entre as tabelas. (Erro: %)', nome_tabela, mensagem_erro;
        END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION atualizar(
    nome_tabela       TEXT,
    nome_coluna       TEXT,
    valor             TEXT,
    nome_coluna_where TEXT DEFAULT NULL,
    operador          TEXT DEFAULT NULL,
    valor_where       TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    mensagem_erro   text;
    codigo_sqlstate text;
BEGIN
    IF (nome_coluna_where IS NULL AND operador IS NULL AND valor_where IS NULL) THEN
        EXECUTE format('UPDATE %I SET %I = %L', nome_tabela, nome_coluna, valor);
        RAISE NOTICE 'Todos os dados da tabela "%" foram atualizados!', nome_tabela;
    ELSIF NOT (trim(upper(operador)) IN ('=', '>', '<', '>=', '<=', '<>', '!=', 'LIKE', 'ILIKE', 'IS NULL', 'IS NOT NULL')) THEN
        RAISE EXCEPTION 'Operador "%" inválido ou não permitido por motivos de segurança.', operador;
    ELSIF (trim(upper(operador)) IN ('IS NULL', 'IS NOT NULL')) THEN
        EXECUTE format('UPDATE %I SET %I = %L WHERE %I %s', nome_tabela, nome_coluna, valor, nome_coluna_where, operador);
        RAISE NOTICE 'Todos os dados onde "% %" foram atualizados.', nome_coluna_where, operador;
    ELSE
        EXECUTE format('UPDATE %I SET %I = %L WHERE %I %s %L', nome_tabela, nome_coluna, valor, nome_coluna_where, operador, valor_where);
        RAISE NOTICE 'Todos os dados da tabela "%" foram atualizados seguindo a condição: % % %', nome_tabela, nome_coluna_where, operador, valor_where;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            mensagem_erro   = MESSAGE_TEXT,
            codigo_sqlstate = RETURNED_SQLSTATE;
        IF codigo_sqlstate = '42501' THEN
            RAISE EXCEPTION 'Acesso negado. O seu perfil não tem permissão para atualizar dados na tabela "%".', nome_tabela;
        ELSE
            RAISE EXCEPTION 'Erro ao atualizar dados na tabela "%". (Erro: %)', nome_tabela, mensagem_erro;
        END IF;
END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------------------------------
-- 3.2. FUNÇÕES DE LÓGICA DE NEGÓCIO (OPERAÇÕES DE VENDA)
------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_obter_ingredientes_necessarios(p_id_pedido int)
RETURNS TABLE(id_ingrediente int, qtd_final_necessaria int) AS $$
BEGIN
    RETURN QUERY
    SELECT
        v.id_ingrediente,
        CAST(SUM(v.qtd_total) AS INT) AS qtd_final_necessaria
    FROM vw_consumo_ingrediente_pedido v
    WHERE v.id_pedido = p_id_pedido
    GROUP BY v.id_ingrediente;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_verificar_estoque(p_id_pedido int, p_id_franquia int)
RETURNS VOID AS $$
DECLARE
    v_id_ingrediente       int;
    v_qtd_final_necessaria int;
    v_qtd_estoque          int;
BEGIN
    FOR v_id_ingrediente, v_qtd_final_necessaria IN
        SELECT * FROM fn_obter_ingredientes_necessarios(p_id_pedido)
    LOOP
        SELECT qtd_atual INTO v_qtd_estoque
        FROM estoque_unid
        WHERE id_ingrediente = v_id_ingrediente AND id_franquia = p_id_franquia;

        IF v_qtd_estoque IS NULL OR v_qtd_final_necessaria > v_qtd_estoque THEN
            RAISE EXCEPTION 'Estoque insuficiente para o ingrediente %. Quantidade necessária: %, em estoque: %',
                v_id_ingrediente, v_qtd_final_necessaria, COALESCE(v_qtd_estoque, 0);
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calcular_valor_total(p_itens JSONB)
RETURNS FLOAT AS $$
DECLARE
    v_valor_total     float := 0;
    v_valor_calculado float;
    item              jsonb;
BEGIN
    FOR item IN SELECT * FROM jsonb_array_elements(p_itens)
    LOOP
        SELECT (preco_base * (item ->> 'qtd')::int)
        INTO v_valor_calculado
        FROM produto
        WHERE id_produto = (item ->> 'id_produto')::int;

        IF v_valor_calculado IS NULL THEN
            RAISE EXCEPTION 'Produto com ID % não foi encontrado no banco de dados.', (item ->> 'id_produto')::int;
        END IF;

        v_valor_total := v_valor_total + v_valor_calculado;
    END LOOP;

    RETURN v_valor_total;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION venda(
    p_id_funcionario int,
    p_id_franquia    int,
    p_itens          jsonb
)
RETURNS VOID AS $$
DECLARE
    v_id_pedido   int;
    v_preco_base  float;
    item          jsonb;
    v_valor_total float;
BEGIN
    v_valor_total := calcular_valor_total(p_itens);

    INSERT INTO pedido (status, total, id_funcionario, id_franquia)
    VALUES ('Em Andamento', v_valor_total, p_id_funcionario, p_id_franquia)
    RETURNING id_pedido INTO v_id_pedido;

    FOR item IN SELECT * FROM jsonb_array_elements(p_itens)
    LOOP
        SELECT preco_base INTO v_preco_base
        FROM produto
        WHERE id_produto = (item ->> 'id_produto')::int;

        INSERT INTO item_pedido (id_pedido, id_produto, preco_unitario, quantidade)
        VALUES (
            v_id_pedido,
            (item ->> 'id_produto')::int,
            v_preco_base,
            (item ->> 'qtd')::int
        );
    END LOOP;

    UPDATE pedido SET status = 'Finalizado' WHERE id_pedido = v_id_pedido;

    RAISE NOTICE 'Venda % finalizada com sucesso! Valor Total: R$ %', v_id_pedido, v_valor_total;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_obter_meta_vigente(
    p_id_franquia          INT,
    OUT o_valor_meta       FLOAT,
    OUT o_porcentagem_bonus FLOAT
)
AS $$
BEGIN
    SELECT valor_meta, porcentagem
    INTO o_valor_meta, o_porcentagem_bonus
    FROM meta m
    JOIN meta_franquia mf ON m.id_meta = mf.id_meta
    WHERE mf.id_franquia = p_id_franquia AND eh_vigente = TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_obter_vendas_franquia(p_id_franquia INT, p_mes INT, p_ano INT)
RETURNS FLOAT AS $$
DECLARE
    v_total_vendas FLOAT := 0;
BEGIN
    SELECT COALESCE(SUM(total), 0)
    INTO v_total_vendas
    FROM pedido p
    WHERE p.id_franquia = p_id_franquia
      AND EXTRACT(year  FROM data_venda) = p_ano
      AND EXTRACT(month FROM data_venda) = p_mes
      AND status = 'Finalizado';

    RETURN v_total_vendas;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_calcular_bonus_mensal(p_id_franquia INT, p_mes INT, p_ano INT)
RETURNS VOID AS $$
DECLARE
    v_total_vendido     float;
    v_valor_meta        float;
    v_porcentagem_bonus float;
BEGIN
    IF p_mes < 1 OR p_mes > 12 THEN
        RAISE EXCEPTION 'Mês inválido: %. Informe um valor entre 1 e 12.', p_mes;
    END IF;

    v_total_vendido := fn_obter_vendas_franquia(p_id_franquia, p_mes, p_ano);

    SELECT o_valor_meta, o_porcentagem_bonus
    INTO v_valor_meta, v_porcentagem_bonus
    FROM fn_obter_meta_vigente(p_id_franquia);

    IF v_valor_meta IS NULL THEN
        RAISE EXCEPTION 'Não há meta vigente cadastrada para a franquia %.', p_id_franquia;
    END IF;

    IF v_total_vendido >= v_valor_meta THEN
        INSERT INTO historico_bonus(id_funcionario, mes, ano, valor_bonus)
        SELECT id_funcionario, p_mes, p_ano, (salario_base * (v_porcentagem_bonus / 100.0))
        FROM funcionario
        WHERE id_franquia = p_id_franquia
        ON CONFLICT (id_funcionario, mes, ano) DO UPDATE SET
            valor_bonus    = EXCLUDED.valor_bonus,
            data_pagamento = CURRENT_TIMESTAMP;

        RAISE NOTICE 'Sucesso: Meta atingida! Bônus processado para a franquia % referente a %/%.', p_id_franquia, p_mes, p_ano;
    ELSE
        RAISE NOTICE 'Aviso: A franquia % não atingiu a meta em %/%. Vendas: R$ %, Meta: R$ %',
            p_id_franquia, p_mes, p_ano, v_total_vendido, v_valor_meta;
    END IF;
END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------------------------------
-- 3.3. FUNÇÕES DE CONSULTA E RELATÓRIO
------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_alerta_estoque(p_limite INT DEFAULT 10)
RETURNS TABLE(
    nome_franquia    varchar,
    nome_ingrediente varchar,
    qtd_atual        int
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.nome_franquia,
        i.nome_ingrediente,
        e.qtd_atual
    FROM estoque_unid e
    JOIN franquia    f ON e.id_franquia    = f.id_franquia
    JOIN ingrediente i ON e.id_ingrediente = i.id_ingrediente
    WHERE e.qtd_atual <= p_limite
    ORDER BY e.qtd_atual ASC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_desempenho_atendente(p_id_franquia INT)
RETURNS TABLE(
    id_funcionario   int,
    nome_funcionario varchar,
    qtd_pedidos      bigint,
    total_vendido    float,
    ticket_medio     float
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        fu.id_funcionario,
        fu.nome_funcionario,
        COUNT(p.id_pedido),
        COALESCE(SUM(p.total), 0),
        COALESCE(AVG(p.total), 0)
    FROM funcionario fu
    LEFT JOIN pedido p
           ON p.id_funcionario = fu.id_funcionario
          AND p.status = 'Finalizado'
    WHERE fu.id_franquia = p_id_franquia
    GROUP BY fu.id_funcionario, fu.nome_funcionario
    ORDER BY COALESCE(SUM(p.total), 0) DESC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_produto_mais_vendido(p_id_franquia INT)
RETURNS TABLE(id_produto int, nome_prod varchar, qtd_vendida int) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id_produto,
        p.nome_prod,
        CAST(SUM(ip.quantidade) AS int) AS qtd_vendida
    FROM item_pedido ip
    JOIN pedido  pe ON ip.id_pedido  = pe.id_pedido
    JOIN produto p  ON ip.id_produto = p.id_produto
    WHERE pe.id_franquia = p_id_franquia
      AND pe.status = 'Finalizado'
    GROUP BY p.id_produto, p.nome_prod
    ORDER BY qtd_vendida DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

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

CREATE OR REPLACE FUNCTION fn_relatorio_consumo_ingredientes(
    p_data_inicio timestamp,
    p_data_fim    timestamp
)
RETURNS TABLE(
    id_franquia      int,
    nome_franquia    varchar,
    id_ingrediente   int,
    nome_ingrediente varchar,
    qtd_consumida    bigint
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        v.id_franquia,
        f.nome_franquia,
        v.id_ingrediente,
        i.nome_ingrediente,
        CAST(SUM(v.qtd_total) AS bigint)
    FROM vw_consumo_ingrediente_pedido v
    JOIN ingrediente i ON i.id_ingrediente = v.id_ingrediente
    JOIN franquia    f ON f.id_franquia    = v.id_franquia
    WHERE v.status = 'Finalizado'
      AND v.data_venda BETWEEN p_data_inicio AND p_data_fim
    GROUP BY v.id_franquia, f.nome_franquia, v.id_ingrediente, i.nome_ingrediente
    ORDER BY v.id_franquia, SUM(v.qtd_total) DESC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_relatorio_faturamento_periodo(
    p_data_inicio timestamp,
    p_data_fim    timestamp
)
RETURNS TABLE(
    id_franquia   int,
    nome_franquia varchar,
    qtd_pedidos   bigint,
    faturamento   float
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.id_franquia,
        f.nome_franquia,
        COUNT(p.id_pedido),
        COALESCE(SUM(p.total), 0)
    FROM franquia f
    LEFT JOIN pedido p
           ON p.id_franquia = f.id_franquia
          AND p.status = 'Finalizado'
          AND p.data_venda BETWEEN p_data_inicio AND p_data_fim
    GROUP BY f.id_franquia, f.nome_franquia
    ORDER BY COALESCE(SUM(p.total), 0) DESC;
END;
$$ LANGUAGE plpgsql;