
CREATE OR REPLACE FUNCTION fn_trocar_cupom() RETURNS TRIGGER AS $$
BEGIN

    IF NEW.desconto_voucher IS NOT NULL and OLD.status = 'preparando' THEN
        -- Verifica se a venda já possui um cupom aplicado
        IF OLD.desconto_voucher IS NOT NULL THEN
            -- Se já possui, remove o cupom antigo
            UPDATE resgate_cupom
            SET status = 'pendente'
            WHERE codigo_voucher = OLD.desconto_voucher AND id_cliente = OLD.id_cliente;
        END IF;

        return NEW;
    END IF;

    return NEW;

END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER tg_trocar_cupom
BEFORE
UPDATE ON venda
FOR EACH ROW EXECUTE FUNCTION fn_trocar_cupom();


CREATE OR REPLACE FUNCTION fn_atualizar_valor_total() RETURNS TRIGGER AS $$
BEGIN
    -- Calcula o novo valor total da venda
    UPDATE venda
    SET valor_total = (SELECT SUM(subtotal) FROM item_venda WHERE id_venda = NEW.id_venda)
    WHERE id_venda = NEW.id_venda;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER tg_atualizar_valor_total AFTER
INSERT ON item_venda
FOR EACH ROW EXECUTE FUNCTION fn_atualizar_valor_total();


CREATE OR REPLACE FUNCTION fechar_venda(id_venda int) RETURNS void AS $$
DECLARE
    desconto_voucher text;
    desconto int;
BEGIN
    -- Verifica se a venda existe
    IF NOT EXISTS (SELECT 1 FROM venda WHERE id_venda = id_venda) THEN
        RAISE EXCEPTION 'Venda com ID % não encontrada', id_venda;
    END IF;

    -- Aplica o cupom, se houver
    SELECT desconto_voucher INTO desconto_voucher FROM venda WHERE id_venda = id_venda;
    IF desconto_voucher IS NOT NULL THEN
        SELECT cupom.desconto INTO desconto FROM resgate_cupom NATURAL JOIN cupom
        WHERE codigo_voucher = desconto_voucher;

        UPDATE venda
        SET valor_total = valor_total - (valor_total * desconto / 100)
        WHERE id_venda = id_venda;
    END IF;

    -- Atualiza o status da venda para 'finalizado'
    UPDATE venda
    SET status = 'finalizado'
    WHERE id_venda = id_venda;

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION cancelar_venda(id_venda int) RETURNS void AS $$
BEGIN
    -- Verifica se a venda existe
    IF NOT EXISTS (SELECT 1 FROM venda WHERE id_venda = id_venda) THEN
        RAISE EXCEPTION 'Venda com ID % não encontrada', id_venda;
    END IF;

    -- Reajusta o estoque dos produtos da venda
    UPDATE produto p
    SET estoque = estoque + iv.quantidade
    FROM item_venda iv
    WHERE iv.id_venda = id_venda AND iv.id_produto = p.id_produto;

    -- Atualiza o status da venda para 'cancelado'
    UPDATE venda
    SET status = 'cancelado'
    WHERE id_venda = id_venda;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION abrir_venda(cpf_cliente varchar(14)) RETURNS int AS $$
DECLARE
    id_venda int;
    id_cliente int;
BEGIN
    -- Verifica se o cliente existe
    SELECT ca.id_cliente INTO id_cliente FROM clientes_ativos ca WHERE cpf = cpf_cliente;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cliente com CPF % não encontrado', cpf_cliente;
    END IF;

    -- Cria uma nova venda com o status 'preparando'
    INSERT INTO venda (id_cliente, valor_total)
    VALUES (id_cliente, 0.00)
    RETURNING venda.id_venda INTO id_venda;

    return id_venda;
END;
$$ LANGUAGE plpgsql;


SELECT abrir_venda('123.456.789-01');


SELECT *
from produto;


SELECT registrar_item_venda(2, 'PRATO001', 2);


SELECT *
FROM venda
NATURAL JOIN item_venda
WHERE id_venda = 2;