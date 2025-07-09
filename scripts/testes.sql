-- CLIENTES

SELECT inserir('cliente', 'João da Silva', '123.456.789-00', 'joao@email.com', '11999999999');


SELECT inserir('cliente', 'Maria Oliveira', '987.654.321-00', 'maria@email.com', '11988888888');


SELECT inserir('cliente', 'Carlos Lima', '111.222.333-44', 'carlos@email.com', '11977777777');


SELECT excluir_cliente('123.456.789-00');


SELECT excluir_cliente('987.654.321-00');


SELECT excluir_cliente('111.222.333-44');

-- PRODUTOS

SELECT inserir('produto', 'PROD001', 'Arroz 5kg', 'Arroz branco tipo 1 pacote 5kg', '22.90', 'Alimentos', '100');


SELECT inserir('produto', 'PROD002', 'Feijão 1kg', 'Feijão carioca tipo 1 pacote 1kg', '7.80', 'Alimentos', '200');


SELECT inserir('produto', 'PROD003', 'Detergente', 'Detergente neutro 500ml', '2.50', 'Limpeza', '300');


SELECT *
from abrir_venda('123.456.789-00');


SELECT registrar_item_venda(id_venda_p := 2, cod_produto := 'PROD002', quantidade := 2);
SELECT registrar_item_venda(id_venda_p := 2, cod_produto := 'PROD001', quantidade := 1);


SELECT fechar_venda(2);


SELECT *
from abrir_venda('987.654.321-00');

SELECT registrar_item_venda(id_venda_p := 3, cod_produto := 'PROD001', quantidade := 5);
SELECT registrar_item_venda(id_venda_p := 3, cod_produto := 'PROD001', quantidade := 5);

SELECT fechar_venda(3);


-- RESGATE DE CUPOM (clientes usando cupons)

SELECT inserir('resgate_cupom', '123.456.789-00', '1');


SELECT inserir('resgate_cupom', '987.654.321-00', '2');

-- FUNCIONÁRIOS (essa tabela não tem função genérica, então será populada diretamente)

SELECT cadastrar_funcionario(login_p := 'vendedor01', cargo := 'vendedor');
SELECT cadastrar_funcionario(login_p := 'gerente01', cargo := 'gerente');
SELECT cadastrar_funcionario(login_p := 'admin01', cargo := 'administrador');
