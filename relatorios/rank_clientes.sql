
-- Relatório de clientes com maior pontuação

DROP FUNCTION IF EXISTS rank_clientes();
CREATE OR REPLACE FUNCTION rank_clientes() RETURNS TABLE(
    cpf VARCHAR(14),
    nome VARCHAR(100),
    pontos INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.cpf,
        c.nome,
        c.pontos
    FROM
        cliente c
    WHERE
        c.ativo = true
    ORDER BY
        c.pontos DESC;
END;
$$ LANGUAGE plpgsql;

-- Executa a função para obter o ranking de clientes

SELECT * FROM rank_clientes();