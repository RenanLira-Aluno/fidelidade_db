REVOKE ALL ON resgate_cupom
FROM
    PUBLIC;

GRANT SELECT, INSERT, DELETE ON resgate_cupom TO grupo_clientes;

GRANT ALL ON venda TO grupo_funcionarios;

ALTER TABLE resgate_cupom ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS politica_acesso_resgate_cupom ON resgate_cupom;
CREATE POLICY politica_acesso_resgate_cupom
ON resgate_cupom
FOR SELECT
USING (
    -- Se for cliente: só vê seus cupons resgatados
    id_cliente = (
        SELECT id_cliente FROM cliente WHERE login_pg = current_user
    )

    -- Se for funcionário: acesso total
    OR get_funcionario()
);

DROP POLICY IF EXISTS politica_inserir_resgate_cupom ON resgate_cupom;
CREATE POLICY politica_inserir_resgate_cupom
ON resgate_cupom
FOR INSERT
WITH CHECK (
    -- Se for cliente: só pode inserir resgates para si mesmo
    id_cliente = (
        SELECT id_cliente FROM cliente WHERE login_pg = current_user
    )
    -- Se for funcionário: pode inserir qualquer resgate
    OR get_funcionario()
);