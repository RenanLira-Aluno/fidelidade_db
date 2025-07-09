DROP FUNCTION IF EXISTS cupons_mais_utilizados();


CREATE OR REPLACE FUNCTION cupons_mais_utilizados() RETURNS TABLE(id_cupom INT, nome_cupom VARCHAR(100), quantidade_utilizacoes BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id_cupom,
        c.nome AS nome_cupom,
        COUNT(*) AS quantidade_utilizacoes
    FROM
        resgate_cupom rc
    JOIN
        cupom c ON rc.id_cupom = c.id_cupom
    WHERE
        rc.status = 'utilizado'
    GROUP BY
        c.nome, c.id_cupom
    ORDER BY
        quantidade_utilizacoes DESC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

REVOKE ALL ON FUNCTION cupons_mais_utilizados() FROM public;
GRANT EXECUTE ON FUNCTION cupons_mais_utilizados() TO relatorios;

-- Executa a função para obter os cupons mais utilizados

SELECT *
FROM cupons_mais_utilizados();