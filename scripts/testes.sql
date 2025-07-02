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