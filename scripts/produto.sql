-- Trigger para atualizar o estoque após inserção ou remoção de item de venda

CREATE OR REPLACE FUNCTION fn_atualizar_estoque()
RETURNS TRIGGER AS $$
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

        -- Se o estoque zerar, tornar o produto indisponível
        UPDATE produto
        SET disponivel = false
        WHERE id_produto = NEW.id_produto AND estoque = 0;

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        -- Repor o estoque ao excluir item da venda
        UPDATE produto
        SET estoque = estoque + OLD.quantidade
        WHERE id_produto = OLD.id_produto;

        -- Se o estoque ficar maior que zero, tornar o produto disponível
        UPDATE produto
        SET disponivel = true
        WHERE id_produto = OLD.id_produto AND estoque > 0;

        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualizar o estoque após inserção ou remoção de item de venda

CREATE TRIGGER tg_atualizar_estoque AFTER
INSERT
OR
DELETE ON item_venda
FOR EACH ROW EXECUTE FUNCTION fn_atualizar_estoque();

-- função de inserir item de venda

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

-- Função para remover item de venda

CREATE OR REPLACE FUNCTION remover_item_venda(id_item_p INT)
RETURNS void AS $$
BEGIN
    -- Verifica se o item existe
    IF NOT EXISTS (SELECT 1 FROM item_venda WHERE id_item = id_item_p) THEN
        RAISE EXCEPTION 'Item de venda com ID % não encontrado', id_item_p;
    END IF;

    -- Remove o item da tabela item_venda
    DELETE FROM item_venda WHERE id_item = id_item_p;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS remover_item_venda(INT);


-- Função para cadastrar produto

CREATE OR REPLACE FUNCTION cadastrar_produto(
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

-- Função para atualizar produto

CREATE OR REPLACE FUNCTION atualizar_produto(
    codigo_p VARCHAR,
    nome_p VARCHAR,
    descricao_p TEXT,
    preco_p DECIMAL,
    categoria_p VARCHAR,
    estoque_p INT
) RETURNS void AS $$
DECLARE
    estoque_novo INT;
BEGIN
    -- Verifica se o produto existe
    IF NOT EXISTS (SELECT 1 FROM produto WHERE codigo = codigo_p) THEN
        RAISE EXCEPTION 'Produto com código % não encontrado.', codigo_p;
    END IF;

    -- Validação de estoque negativo (se informado)
    IF estoque_p IS NOT NULL AND estoque_p < 0 THEN
        RAISE EXCEPTION 'O estoque não pode ser negativo.';
    END IF;

    -- Calcula o novo estoque com COALESCE
    SELECT COALESCE(estoque_p, estoque) INTO estoque_novo
    FROM produto
    WHERE codigo = codigo_p;

    -- Atualiza o produto
    UPDATE produto
    SET
        nome        = COALESCE(nome_p, nome),
        descricao   = COALESCE(descricao_p, descricao),
        preco       = COALESCE(preco_p, preco),
        categoria   = COALESCE(categoria_p, categoria),
        estoque     = estoque_novo,
        disponivel  = CASE
                        WHEN disponivel = false AND estoque_novo > 0 THEN true
                        ELSE disponivel
                      END
    WHERE codigo = codigo_p;
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

--Adicionando coluna disponivel em produto

ALTER TABLE produto
ADD COLUMN disponivel BOOLEAN DEFAULT true;

--View produtos disponiveis

CREATE OR REPLACE VIEW produtos_disponiveis AS
SELECT *
FROM produto
WHERE disponivel = true;

select * from produtos_disponiveis;
