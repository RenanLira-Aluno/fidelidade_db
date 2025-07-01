CREATE OR REPLACE FUNCTION fn_atualizar_estoque()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE produto
    SET estoque = estoque - NEW.quantidade
    WHERE id_produto = NEW.id_produto;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_atualizar_estoque
AFTER INSERT ON item_venda
FOR EACH ROW
EXECUTE FUNCTION fn_atualizar_estoque();
