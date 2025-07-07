ALTER TABLE cliente
ADD COLUMN login_pg VARCHAR(14) GENERATED ALWAYS AS (replace(cpf, '.', '')) STORED;

ALTER TABLE cliente ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON cliente FROM PUBLIC;

GRANT SELECT, INSERT, UPDATE on cliente TO grupo_funcionarios;
GRANT SELECT on cliente TO grupo_clientes;

CREATE POLICY politica_acesso_clientes
ON cliente
FOR SELECT
USING (
    -- Se for funcionário: acesso total
    current_user IN (SELECT login_pg FROM funcionario)
    
    -- Se for cliente: só pode ver e atualizar seus dados
    OR login_pg = current_user
)