-- Uso de Vouchers em Vendas

-- Vendas que utilizaram desconto_voucher.

-- Correlação entre cupom resgatado e uso efetivo.
DROP FUNCTION IF EXISTS uso_vouchers();
CREATE OR REPLACE FUNCTION uso_vouchers()
RETURNS TABLE(
    id_venda INT,
    id_cliente INT,
    codigo_voucher VARCHAR,
    data_resgate TIMESTAMP,
    status_venda status_venda
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        v.id_venda,
        v.id_cliente,
        rc.codigo_voucher,
        rc.data_resgate,
        v.status
    FROM
        venda v
    JOIN
        resgate_cupom rc ON v.desconto_voucher = rc.codigo_voucher
    WHERE
        v.status = 'finalizado' AND
        rc.status = 'utilizado'
    ORDER BY
        v.id_venda;
END;
$$ LANGUAGE plpgsql;

REVOKE ALL ON FUNCTION uso_vouchers() FROM public;
GRANT EXECUTE ON FUNCTION uso_vouchers() TO relatorios;

SELECT * FROM uso_vouchers();