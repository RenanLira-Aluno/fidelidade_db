
CREATE OR REPLACE FUNCTION cadastrar_funcionario (
    login_p TEXT,
    cargo cargo
) RETURNS void AS $$
BEGIN

    -- Verifica se o login já existe
    IF EXISTS (SELECT 1 FROM funcionario WHERE login_pg = login_p) THEN
        RAISE EXCEPTION 'Login % já está em uso', login_p;
    END IF;

    -- Insere o novo funcionário
    INSERT INTO funcionario (login_pg, cargo)
    VALUES (login_p, cargo);

    -- Cria o usuário no banco de dados PostgreSQL
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', login_p, login_p);
    
    -- Concede privilégios ao usuário
    EXECUTE format('GRANT grupo_funcionarios TO %I', login_p);

    IF cargo = 'gerente' or cargo = 'administrador' THEN
        EXECUTE format('GRANT relatorios TO %I', login_p);
    END IF;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION excluir_funcionario (
    login_p TEXT
) RETURNS void AS $$
BEGIN
    -- Verifica se o funcionário existe
    IF NOT EXISTS (SELECT 1 FROM funcionario WHERE login_pg = login_p) THEN
        RAISE EXCEPTION 'Funcionário com login % não encontrado', login_p;
    END IF;

    -- Exclui o funcionário
    DELETE FROM funcionario WHERE login_pg = login_p;

    -- Exclui o usuário do banco de dados PostgreSQL
    EXECUTE format('DROP USER IF EXISTS %I', login_p);
END;
$$ LANGUAGE plpgsql;