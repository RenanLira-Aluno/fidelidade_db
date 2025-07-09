CREATE ROLE grupo_clientes;
CREATE ROLE grupo_funcionarios;
CREATE ROLE relatorios;


CREATE OR REPLACE FUNCTION get_funcionario() RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM funcionario WHERE login_pg = current_user
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;