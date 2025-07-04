DROP FUNCTION IF EXISTS cupons_em_vendas ();

CREATE
OR REPLACE FUNCTION cupons_em_vendas () RETURNS TABLE (
    id_cupom INT,
    nome_cupom VARCHAR,
    valor_desconto INT,
    percentual_utilizado DECIMAL,
    quantidade_utilizada BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id_cupom,
        c.nome,
        c.desconto AS valor_desconto,
        (COUNT(rc.id_resgate) * 100.0) / SUM(COUNT(rc.id_resgate)),
        COUNT(rc.id_resgate)
    FROM
        cupom c
    LEFT JOIN
        (SELECT * FROM resgate_cupom r WHERE r.status = 'utilizado') rc ON c.id_cupom = rc.id_cupom
    GROUP BY
        c.id_cupom,
        c.nome,
        c.desconto
    ;
END;
$$ LANGUAGE plpgsql;

SELECT
    *
FROM
    cupons_em_vendas ();

