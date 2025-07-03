DROP FUNCTION IF EXISTS cupons_mais_utilizados();
CREATE OR REPLACE FUNCTION cupons_mais_utilizados()
RETURNS TABLE(
    codigo_voucher VARCHAR(20),
    nome_cupom VARCHAR(100),
    quantidade_utilizacoes BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        rc.codigo_voucher,
        c.nome AS nome_cupom,
        COUNT(*) AS quantidade_utilizacoes
    FROM
        resgate_cupom rc
    JOIN
        cupom c ON rc.id_cupom = c.id_cupom
    WHERE
        rc.status = 'utilizado'
    GROUP BY
        rc.codigo_voucher, c.nome
    ORDER BY    
        quantidade_utilizacoes DESC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;


-- Executa a função para obter os cupons mais utilizados
SELECT * FROM cupons_mais_utilizados();