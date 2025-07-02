CREATE
OR REPLACE FUNCTION aplicar_cupom_venda (id_venda int, codigo_voucher text, id_cliente int) RETURNS void AS $$
BEGIN
    SELECT id_resgate FROM resgate_cupom
    WHERE codigo_voucher = desconto_voucher AND id_cliente = id_cliente AND status = 'pendente';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Voucher % não encontrado ou já utilizado', desconto_voucher;
    END IF;

    -- Atualiza o status do cupom para 'aprovado'
    UPDATE resgate_cupom
    SET status = 'aprovado'
    WHERE codigo_voucher = codigo_voucher AND id_cliente = id_cliente;

    -- Atualiza a venda com o desconto aplicado
    UPDATE venda
    SET desconto_voucher = codigo_voucher
    WHERE venda.id_venda = id_venda;

END;
$$ LANGUAGE plpgsql;

CREATE
OR REPLACE FUNCTION resgatar_cupom (cpf_cliente_p int, id_cupom_p int) RETURNS void AS $$
DECLARE
    cliente_row cliente%ROWTYPE;
    cupom_row cupom%ROWTYPE;
BEGIN

    -- Verifica se o cliente existe
    SELECT * INTO cliente_row FROM cliente WHERE cpf = cpf_cliente_p;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cliente com ID % não encontrado', cpf_cliente_p;
    END IF;

    -- Verifica se o cupom existe e está disponivel
    SELECT * INTO cupom_row FROM cupom WHERE id_cupom = id_cupom_p AND disponivel = true AND cod = cliente_row.cod_categoria;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cupom com ID % não encontrado ou indisponível', id_cupom_p;
    END IF;

    -- Verifica se o cliente tem pontos suficientes
    IF cliente_row.pontos <= cupom_row.pontos_necessarios THEN
        RAISE EXCEPTION 'Cliente com CPF % não possui pontos suficientes para resgatar o cupom', cpf_cliente_p;
    END IF;


    -- Insere o resgate do cupom
    INSERT INTO resgate_cupom (id_cliente, id_cupom, codigo_voucher)
    VALUES (cliente_row.id_cliente, cupom_row.id_cupom,
            substring(md5(random()::text), 1, 8));


END;
$$ LANGUAGE plpgsql;