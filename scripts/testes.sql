SELECT
    *
FROM
    cliente;

SELECT
    fechar_venda (2);

SELECT
    *
FROM
    cupons_disponiveis_por_cliente
WHERE
    id_cliente = 1
    and id_cupom = 4;

SELECT
    resgatar_cupom ('123.456.789-01', 4);

SELECT
    *
FROM
    resgate_cupom
WHERE
    id_cliente = 1;

-- Teste de venda
SELECT
    *
FROM
    venda
    NATURAL JOIN item_venda
WHERE
    id_venda = 7;

SELECT
    abrir_venda ('123.456.789-01');

SELECT
    *
FROM
    produto;

SELECT
    registrar_item_venda (7, 'PRATO002', 2);

SELECT
    registrar_item_venda (7, 'BEB002', 2);

SELECT
    registrar_item_venda (7, 'BEB001', 2);

SELECT
    aplicar_cupom_venda (
        id_venda_p := 7,
        codigo_voucher_p := '6853b2e5',
        id_cliente_p := 1
    );

SELECT
    fechar_venda (7);


    select * from cliente
select * from venda
select * from item_venda
select * from cupom
select * from resgate_cupom
select * from categoria_programa
select * from produto;
select cadastrar_produto('CAMISA002','Camisa casual', 'Camisa casual',20.00,'Roupas', 50);
select cadastrar_categoria_programa(7,'Radiante', 8000)
select atualizar_categoria_programa(7, 'Radiante', 1000)
select excluir_categoria_programa(7)
select cadastrar_cliente('Thiago','000.000.000-00','Thiago@email.com','86988244789')
select atualizar_dados_cliente(1,'','Renan@email.com','86988218047')
select abrir_venda('123.456.789-01')
select abrir_venda('123.456.789-01')
select registrar_item_venda(5, 'PRATO002', 10)
select fechar_venda(5)
select resgatar_cupom('123.456.789-01',7)
select cadastrar_cupom(1,'Cupom 50%', 'Desconto 50%', 600, 60)
select excluir_cupom(18)
select atualizar_dados_cupom(17,null,'Cupom atualizado','',null,null,null)
select aplicar_cupom_venda('7', '090e0cf3', '1')

SELECT setval(
  pg_get_serial_sequence('produto', 'id_produto'),
  (SELECT MAX(id_produto) FROM produto)
);