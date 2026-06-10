CREATE OR REPLACE FUNCTION meta_vigente ()
RETURNS TRIGGER
AS $$
DECLARE 
    mensagem_erro TEXT;
    codigo_sqlstate TEXT;
BEGIN

    IF NEW.eh_vigente = TRUE THEN

        IF TG_OP = 'INSERT' THEN

            UPDATE meta_franquia 
            SET eh_vigente = FALSE 
            WHERE id_franquia = NEW.id_franquia AND eh_vigente = TRUE;

        ELSIF TG_OP = 'UPDATE' THEN
          
            UPDATE meta_franquia 
            SET eh_vigente = FALSE 
            WHERE id_franquia = NEW.id_franquia 
              AND id_meta_vigente != NEW.id_meta_vigente 
              AND eh_vigente = TRUE;
        END IF;

    END IF;

    RETURN NEW;
    
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            mensagem_erro = MESSAGE_TEXT,
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