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


--View para exibir somente categorias ativas

CREATE OR REPLACE VIEW categorias_ativas AS
SELECT *
FROM categoria_programa
WHERE ativo = true;