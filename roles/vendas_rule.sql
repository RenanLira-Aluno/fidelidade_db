
REVOKE ALL ON venda FROM PUBLIC;

GRANT SELECT ON venda TO grupo_clientes;
GRANT SELECT, INSERT, UPDATE ON venda TO grupo_funcionarios;

ALTER TABLE venda ENABLE ROW LEVEL SECURITY;

CREATE POLICY politica_acesso_vendas
ON venda
FOR SELECT
USING (
    -- Se for funcionário: acesso total
    current_user IN (SELECT login_pg FROM funcionario)
    
    -- Se for cliente: só vê suas compras
    OR id_cliente = (
        SELECT id_cliente FROM cliente WHERE login_pg = current_user
    )
);
