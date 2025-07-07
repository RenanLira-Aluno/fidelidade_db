REVOKE ALL ON resgate_cupom
FROM
    PUBLIC;

GRANT SELECT, INSERT, DELETE ON resgate_cupom TO grupo_clientes;

GRANT ALL ON venda TO grupo_funcionarios;

ALTER TABLE resgate_cupom ENABLE ROW LEVEL SECURITY;

CREATE POLICY politica_acesso_resgate_cupom
ON venda
FOR SELECT
USING (
    -- Se for funcionário: acesso total
    current_user IN (SELECT login_pg FROM funcionario)
    
    -- Se for cliente: só vê seus cupons resgatados
    OR id_cliente = (
        SELECT id_cliente FROM cliente WHERE login_pg = current_user
    )
);