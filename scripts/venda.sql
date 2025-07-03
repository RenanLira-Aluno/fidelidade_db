
-- Trigger para verificar se já existe uma venda em andamento para o cliente

CREATE OR REPLACE FUNCTION fn_verificar_venda_em_andamento() RETURNS TRIGGER AS $$
BEGIN

    -- Verifica se já existe uma venda em andamento para o cliente
    IF EXISTS (
        SELECT 1 FROM venda
        WHERE id_cliente = NEW.id_cliente
        AND status = 'preparando'
        AND id_venda <> NEW.id_venda -- Ignora a venda atual
    ) THEN
        RAISE EXCEPTION 'Já existe uma venda em andamento para o cliente com ID %', NEW.id_cliente;
    END IF;

END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER tg_verificar_venda_em_andamento
BEFORE
INSERT ON venda
FOR EACH ROW EXECUTE FUNCTION fn_verificar_venda_em_andamento();

-- Trigger para trocar cupom de desconto em uma venda

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

-- Trigger para atualizar o valor total da venda após inserção de item

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

-- Função para fechar a venda e aplicar cupom de desconto, se houver

CREATE OR REPLACE FUNCTION fechar_venda(id_v int) RETURNS void AS $$
DECLARE
    desconto_voucher text;
    desconto int;
BEGIN
    -- Verifica se a venda existe
    IF NOT EXISTS (SELECT 1 FROM venda WHERE id_venda = id_v and status = 'preparando') THEN
        RAISE EXCEPTION 'Venda com ID % não encontrada', id_v;
    END IF;

    -- Aplica o cupom, se houver
    SELECT v.desconto_voucher INTO desconto_voucher FROM venda v WHERE v.id_venda = id_v;
    IF desconto_voucher IS NOT NULL THEN
        SELECT cupom.desconto INTO desconto FROM resgate_cupom NATURAL JOIN cupom
        WHERE codigo_voucher = desconto_voucher;

        UPDATE venda v
        SET valor_total = valor_total - (valor_total * desconto / 100)
        WHERE v.id_venda = id_v;

        -- Atualiza o status do cupom para 'utilizado'
        UPDATE resgate_cupom
        SET status = 'utilizado'
        WHERE codigo_voucher = desconto_voucher;
    END IF;

    -- Atualiza o status da venda para 'finalizado'
    UPDATE venda v
    SET status = 'finalizado'
    WHERE v.id_venda = id_v;

END;
$$ LANGUAGE plpgsql;

-- Função para cancelar uma venda e reajustar o estoque dos produtos

CREATE OR REPLACE FUNCTION cancelar_venda(id_venda int) RETURNS void AS $$
BEGIN
    -- Verifica se a venda existe
    IF NOT EXISTS (SELECT 1 FROM venda WHERE id_venda = id_venda and status = 'preparando') THEN
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

-- Função para abrir uma nova venda

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