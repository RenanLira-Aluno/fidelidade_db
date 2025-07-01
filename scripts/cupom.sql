CREATE OR REPLACE FUNCTION aplicar_cupom_venda(id_venda int, codigo_voucher text, id_cliente int) RETURNS void AS $$
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