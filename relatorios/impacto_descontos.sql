-- Impacto de Descontos no Valor Total das Vendas
-- Comparação entre vendas com e sem desconto_voucher.
DROP FUNCTION IF EXISTS impacto_descontos ();

CREATE
OR REPLACE FUNCTION impacto_descontos () RETURNS TABLE (
    tipo_venda TEXT,
    total_vendas DECIMAL,
    total_descontos DECIMAL(10, 2),
    quantidade_vendas BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        CASE
            WHEN v.desconto_voucher IS NOT NULL THEN 'Com Desconto'
            ELSE 'Sem Desconto'
        END AS tipo_venda,
        SUM(v.valor_total) AS total_vendas,
        SUM((v.valor_total * COALESCE(c.desconto, 0)) / 100)::DECIMAL(10, 2) AS total_descontos,
        COUNT(v.id_venda) AS quantidade_vendas
    FROM
        venda v
    LEFT JOIN
        resgate_cupom rc ON v.desconto_voucher = rc.codigo_voucher
    INNER JOIN
        cupom c ON rc.id_cupom = c.id_cupom
    GROUP BY
        tipo_venda
    ORDER BY
        tipo_venda
    ;
    
END;
$$ LANGUAGE plpgsql;

REVOKE ALL ON FUNCTION impacto_descontos() FROM public;
GRANT EXECUTE ON FUNCTION impacto_descontos() TO relatorios;


SELECT
    *
FROM
    impacto_descontos ();