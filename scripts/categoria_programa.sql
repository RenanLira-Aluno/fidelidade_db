--Alter Table para adicionar coluna ativo

ALTER TABLE categoria_programa
ADD COLUMN ativo BOOLEAN DEFAULT true;

--Função para excluir uma categoria do programa

CREATE OR REPLACE FUNCTION excluir_categoria_programa(cod_p INT)
RETURNS void AS $$
BEGIN
    UPDATE categoria_programa
    SET ativo = false
    WHERE cod = cod_p;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Categoria com código % não encontrada.', cod_p;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para atualizar uma categoria do programa
CREATE OR REPLACE FUNCTION atualizar_categoria_programa(
    cod_p INT,
    nome_p VARCHAR,
    descricao_p TEXT
) RETURNS void AS $$
BEGIN
    -- Verifica se a categoria existe
    IF NOT EXISTS (SELECT 1 FROM categoria_programa WHERE cod = cod_p) THEN
        RAISE EXCEPTION 'Categoria com código % não encontrada.', cod_p;
    END IF;
    
    -- Atualiza a categoria
    UPDATE categoria_programa
    SET nome = COALESCE(nome_p, nome),
        descricao = COALESCE(descricao_p, descricao)
    WHERE cod = cod_p;

END;
$$ LANGUAGE plpgsql;

--View para categorias ativas

CREATE OR REPLACE VIEW categorias_ativas AS
SELECT *
FROM categoria_programa
WHERE ativo = true;