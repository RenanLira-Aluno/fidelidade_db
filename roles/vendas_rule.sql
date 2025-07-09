
REVOKE ALL ON venda FROM PUBLIC;

GRANT SELECT ON venda TO grupo_clientes;
GRANT SELECT, INSERT, UPDATE ON venda TO grupo_funcionarios;

ALTER TABLE venda ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS politica_acesso_vendas ON venda;
CREATE POLICY politica_acesso_vendas
ON venda
FOR SELECT
USING (
    -- Se for cliente: só vê suas compras
    id_cliente = (
        SELECT id_cliente FROM cliente WHERE login_pg = current_user
    )
    -- Se for funcionário: acesso total
    OR get_funcionario()
);
