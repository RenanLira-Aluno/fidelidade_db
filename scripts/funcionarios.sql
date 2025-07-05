
CREATE OR REPLACE FUNCTION cadastrar_funcionario (
    login_p TEXT,
    cargo cargo
) RETURNS void AS $$
BEGIN

    -- Verifica se o login já existe
    IF EXISTS (SELECT 1 FROM funcionario WHERE login = login_p) THEN
        RAISE EXCEPTION 'Login % já está em uso', login_p;
    END IF;

    -- Insere o novo funcionário
    INSERT INTO funcionario (login, cargo)
    VALUES (login_p, cargo);

    -- Cria o usuário no banco de dados PostgreSQL
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', login_p, login_p);
    
    -- Concede privilégios ao usuário
    EXECUTE format('GRANT grupo_funcionarios TO %I', login_p);

END;
$$ LANGUAGE plpgsql;