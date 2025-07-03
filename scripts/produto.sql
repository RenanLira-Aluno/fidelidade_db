CREATE OR REPLACE FUNCTION fn_atualizar_estoque() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Verifica se o estoque é suficiente
        IF (SELECT estoque FROM produto WHERE id_produto = NEW.id_produto) < NEW.quantidade THEN
            RAISE EXCEPTION 'Estoque insuficiente para o produto com ID %', NEW.id_produto;
        END IF;

        -- Atualiza o estoque do produto
        UPDATE produto
        SET estoque = estoque - NEW.quantidade
        WHERE id_produto = NEW.id_produto;
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        UPDATE produto
        SET estoque = estoque + OLD.quantidade
        WHERE id_produto = OLD.id_produto;

        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER tg_atualizar_estoque AFTER
INSERT
OR
DELETE ON item_venda
FOR EACH ROW EXECUTE FUNCTION fn_atualizar_estoque();


CREATE OR REPLACE FUNCTION registrar_item_venda(id_venda_p int, cod_produto text, quantidade int) RETURNS void AS $$
DECLARE
    subtotal decimal(10, 2);
    produto produto%ROWTYPE;
BEGIN
    -- Verifica se o produto existe
    select * into produto from produto where codigo = cod_produto;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Produto com código % não encontrado', cod_produto;
    END IF;

    -- Calcula o subtotal
    subtotal := quantidade * produto.preco;
    if NOT EXISTS (select 1 from venda v where v.id_venda = id_venda_p and status = 'preparando') then
        RAISE EXCEPTION 'Venda com ID % não está disponivel', id_venda_p;
    END IF;

    -- Insere o item na tabela item_venda
    INSERT INTO item_venda (id_venda, id_produto, quantidade, preco, subtotal)
    VALUES (id_venda_p, produto.id_produto, quantidade, produto.preco, subtotal);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION remover_item_venda(id_item int) RETURNS void AS $$
BEGIN

    -- Verifica se o item existe
    IF NOT EXISTS (SELECT 1 FROM item_venda WHERE id_item = id_item) THEN
        RAISE EXCEPTION 'Item de venda com ID % não encontrado', id_item;
    END IF;

    -- Remove o item da tabela item_venda
    DELETE FROM item_venda WHERE id_item = id_item;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cadastrar_produto(
    id_produto_p INT,
    codigo_p VARCHAR,
    nome_p VARCHAR,
    descricao_p TEXT,
    preco_p DECIMAL,
    categoria_p VARCHAR,
    estoque_p INT
) RETURNS void AS $$
DECLARE
    constraint_violada TEXT;
BEGIN
    -- Validação de estoque negativo
    IF estoque_p < 0 THEN
        RAISE EXCEPTION 'O estoque não pode ser negativo';
    END IF;

    INSERT INTO produto (codigo, nome, descricao, preco, categoria, estoque)
    VALUES (codigo_p, nome_p, descricao_p, preco_p, categoria_p, estoque_p);

EXCEPTION
    WHEN unique_violation THEN
        GET STACKED DIAGNOSTICS constraint_violada = CONSTRAINT_NAME;

        IF constraint_violada = 'codigo_unique' THEN
            RAISE EXCEPTION 'Código do produto já cadastrado';
        ELSE
            RAISE EXCEPTION 'Violação de dado único. Constraint: %', constraint_violada;
        END IF;
END;
$$ LANGUAGE plpgsql;

--Função excluir produto

CREATE OR REPLACE FUNCTION excluir_produto(codigo_p TEXT)
RETURNS void AS $$
BEGIN
    UPDATE produto
    SET disponivel = false
    WHERE codigo = codigo_p;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Produto com código % não encontrado', codigo_p;
    END IF;
END;
$$ LANGUAGE plpgsql;

select excluir_produto('PROD001')

--Adicionando coluna disponivel em produto

ALTER TABLE produto
ADD COLUMN disponivel BOOLEAN DEFAULT true;

--View produtos disponiveis

CREATE OR REPLACE VIEW produtos_disponiveis AS
SELECT *
FROM produto
WHERE disponivel = true;

select * from produtos_disponiveis
