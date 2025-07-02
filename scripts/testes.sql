
SELECT * FROM cliente;

SELECT fechar_venda(2);


SELECT * FROM cupons_disponiveis_por_cliente WHERE id_cliente = 1 and id_cupom = 1;


-- Teste de venda
SELECT * FROM venda NATURAL JOIN item_venda WHERE id_venda = 6;


SELECT abrir_venda('123.456.789-01');
SELECT * FROM produto;
SELECT registrar_item_venda(6, 'PRATO002', 2);
SELECT registrar_item_venda(6, 'BEB002', 2);
SELECT registrar_item_venda(6, 'BEB001', 2);

SELECT fechar_venda(6);

