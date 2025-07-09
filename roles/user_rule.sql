ALTER TABLE cliente
ADD COLUMN login_pg VARCHAR(14) GENERATED ALWAYS AS (regexp_replace(cpf, '\D', '', 'g')) STORED;

ALTER TABLE cliente ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON cliente FROM PUBLIC;

GRANT SELECT, INSERT, UPDATE on cliente TO grupo_funcionarios;
GRANT SELECT on cliente TO grupo_clientes;

DROP POLICY IF EXISTS politica_acesso_clientes ON cliente;
CREATE POLICY politica_acesso_clientes
ON cliente
FOR SELECT
USING (
    -- Se for cliente: só pode ver e atualizar seus dados
    login_pg = current_user

    -- Se for funcionário: acesso total
    OR get_funcionario()
);