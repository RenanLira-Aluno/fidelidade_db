CREATE TABLE
	categoria_programa (
		cod int PRIMARY KEY,
		nome varchar(140) NOT NULL,
		pontos int NOT NULL
	);

CREATE TABLE
	cliente (
		id_cliente serial PRIMARY KEY,
		cod_categoria int REFERENCES categoria_programa (cod) NOT NULL,
		nome varchar(100) NOT NULL,
		cpf varchar(14) NOT NULL,
		email varchar(100),
		telefone varchar(20) NOT NULL,
		data_cadastro timestamp DEFAULT (now()),
		ativo bool DEFAULT (true),
		pontos int NOT NULL DEFAULT (0)
	);

ALTER TABLE cliente
ADD CONSTRAINT cpf_unique UNIQUE (cpf);

ALTER TABLE cliente
ADD CONSTRAINT email_unique UNIQUE (email);

ALTER TABLE cliente
ADD CONSTRAINT telefone_unique UNIQUE (telefone);

CREATE TABLE
	cupom (
		id_cupom serial PRIMARY KEY,
		cod_categoria int REFERENCES categoria_programa (cod) NOT NULL,
		nome varchar(100) NOT NULL,
		descricao text,
		pontos_necessarios int NOT NULL,
		desconto int,
		disponivel bool DEFAULT (true)
	);

CREATE TYPE status_resgate AS ENUM('pendente', 'aprovado', 'utilizado');

CREATE TABLE
	resgate_cupom (
		id_resgate serial PRIMARY KEY,
		id_cliente serial REFERENCES cliente (id_cliente) NOT NULL,
		id_cupom serial REFERENCES cupom (id_cupom) NOT NULL,
		status status_resgate DEFAULT ('pendente') NOT NULL,
		data_resgate timestamp DEFAULT (now()),
		codigo_voucher varchar(8) NOT NULL
	);

ALTER TABLE resgate_cupom
ADD COLUMN data_expiracao timestamp DEFAULT (now() + interval '30 days') NOT NULL;

ALTER TABLE resgate_cupom
ADD CONSTRAINT codigo_voucher_unique UNIQUE (codigo_voucher);

CREATE TABLE
	produto (
		id_produto serial PRIMARY KEY,
		codigo varchar(50) NOT NULL,
		nome varchar(100) NOT NULL,
		descricao text,
		preco decimal(10, 2) NOT NULL,
		categoria varchar(50) NOT NULL,
		estoque int NOT NULL
	);

ALTER TABLE produto
ADD CONSTRAINT codigo_unique UNIQUE (codigo);

CREATE TYPE status_venda AS ENUM('preparando', 'cancelado', 'finalizado');

CREATE TABLE
	venda (
		id_venda serial PRIMARY KEY,
		desconto_voucher varchar(8),
		data_venda timestamp DEFAULT (now()),
		id_cliente int REFERENCES cliente (id_cliente),
		valor_total decimal(10, 2) NOT NULL,
		status status_venda DEFAULT ('preparando')
	);

CREATE TABLE
	item_venda (
		id_item serial PRIMARY KEY,
		id_venda serial REFERENCES venda (id_venda) NOT NULL,
		id_produto serial REFERENCES produto (id_produto) NOT NULL,
		quantidade int NOT NULL,
		preco decimal(10, 2) NOT NULL,
		subtotal decimal(10, 2) NOT NULL
	);

-- CATEGORIAS
INSERT INTO
	categoria_programa
VALUES
	(1, 'bronze', 0),
	(2, 'prata', 100),
	(3, 'ouro', 400),
	(4, 'platina', 1000),
	(5, 'diamante', 2500),
	(6, 'elite', 4000);

-- PRODUTOS
INSERT INTO
	produto (
		id_produto,
		codigo,
		nome,
		descricao,
		preco,
		categoria,
		estoque
	)
VALUES
	(
		1,
		'PRATO001',
		'Feijoada Completa',
		'Feijoada servida com arroz, couve, farofa e laranja.',
		34.90,
		'Prato Principal',
		50
	),
	(
		2,
		'PRATO002',
		'Lasanha à Bolonhesa',
		'Lasanha com carne moída, molho de tomate e queijo gratinado.',
		29.90,
		'Prato Principal',
		40
	),
	(
		3,
		'PRATO003',
		'Salada Caesar',
		'Alface americana, frango grelhado, croutons e molho Caesar.',
		22.50,
		'Entrada',
		30
	),
	(
		4,
		'BEB001',
		'Suco Natural de Laranja',
		'Suco feito na hora com laranjas frescas.',
		8.90,
		'Bebida',
		100
	),
	(
		5,
		'BEB002',
		'Refrigerante Lata',
		'Escolha entre Coca-Cola, Guaraná ou Fanta.',
		6.00,
		'Bebida',
		200
	),
	(
		6,
		'SOB001',
		'Pudim de Leite',
		'Clássico pudim de leite condensado com calda de caramelo.',
		9.50,
		'Sobremesa',
		25
	),
	(
		7,
		'SOB002',
		'Brownie com Sorvete',
		'Brownie de chocolate servido com bola de sorvete de creme.',
		14.00,
		'Sobremesa',
		20
	),
	(
		8,
		'PRATO004',
		'Frango Grelhado com Legumes',
		'Peito de frango grelhado acompanhado de legumes salteados.',
		27.00,
		'Prato Principal',
		35
	),
	(
		9,
		'ENT001',
		'Cesta de Pães',
		'Pães variados servidos com manteiga e geleia.',
		12.00,
		'Entrada',
		15
	),
	(
		10,
		'BEB003',
		'Cerveja Long Neck',
		'Cerveja gelada disponível em várias marcas.',
		9.90,
		'Bebida',
		60
	);

-- Função genérica de inserção
CREATE
OR REPLACE FUNCTION inserir (nome_tabela TEXT, VARIADIC valores text[]) RETURNS void AS $$
DECLARE
    message_error TEXT;
BEGIN
    IF nome_tabela = 'cliente' THEN
        PERFORM cadastrar_cliente(
            nome_p     := valores[1],
            cpf_p      := valores[2],
            email_p    := valores[3],
            telefone_p := valores[4]
        );

    ELSIF nome_tabela = 'venda' THEN
        PERFORM abrir_venda(
            cpf_cliente := valores[1]
        );

    ELSIF nome_tabela = 'item_venda' THEN
        PERFORM registrar_item_venda(
            id_venda    := valores[1]::INT,
            cod_produto := valores[2],
            quantidade  := valores[3]::INT
        );

    ELSIF nome_tabela = 'produto' THEN
        PERFORM cadastrar_produto(
            id_produto_p := valores[1]::INT,
            codigo_p     := valores[2],
            nome_p       := valores[3],
            descricao_p  := valores[4],
            preco_p      := valores[5]::DECIMAL,
            categoria_p  := valores[6],
            estoque_p    := valores[7]::INT
        );

    ELSE
        RAISE EXCEPTION 'Tabela % não implementada para inserção', nome_tabela;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS message_error = MESSAGE_TEXT;
        RAISE EXCEPTION 'Erro ao inserir na tabela %: %', nome_tabela, message_error;
END;
$$ LANGUAGE plpgsql;

--Função genérica remover
CREATE OR REPLACE FUNCTION remover(nome_tabela TEXT, VARIADIC valores TEXT[])
RETURNS void AS $$
DECLARE
    message_error TEXT;
BEGIN
    IF nome_tabela = 'cliente' THEN
        PERFORM excluir_cliente(
            cpf_p := valores[1]
        );

    ELSIF nome_tabela = 'produto' THEN
        PERFORM excluir_produto(
            codigo_p := valores[1]
        );

    ELSIF nome_tabela = 'categoria_programa' THEN
        PERFORM excluir_categoria_programa(
            cod_p := valores[1]::INT
        );

    ELSIF nome_tabela = 'venda' THEN
        PERFORM cancelar_venda(
            id_venda := valores[1]::INT
        );

    ELSIF nome_tabela = 'cupom' THEN
        PERFORM excluir_cupom(
            id_cupom_p := valores[1]::INT
        );

    ELSE
        RAISE EXCEPTION 'Remoção lógica não implementada para a tabela %', nome_tabela;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS message_error = MESSAGE_TEXT;
        RAISE EXCEPTION 'Erro ao remover da tabela %: %', nome_tabela, message_error;
END;
$$ LANGUAGE plpgsql;

-- Função genérica de atualização
CREATE
OR REPLACE FUNCTION atualizar (nome_tabela TEXT, VARIADIC valores TEXT[]) RETURNS void AS $$
DECLARE
	message_error TEXT;
BEGIN
	IF nome_tabela = 'cliente' THEN
		PERFORM atualizar_dados_cliente(
			cliente_id := valores[1]::INT,
			nome_p     := valores[2],
			email_p    := valores[3],
			telefone_p := valores[4]
		);

	ELSIF nome_tabela = 'produto' THEN
		PERFORM atualizar_produto(
			codigo_p     := valores[1],
			nome_p       := valores[2],
			descricao_p  := valores[3],
			preco_p      := valores[4]::DECIMAL,
			categoria_p  := valores[5],
			estoque_p    := valores[6]::INT
		)
	ELSIF nome_tabela = 'categoria_programa' THEN
		PERFORM atualizar_categoria_programa(
			cod_p     := valores[1]::INT,
			nome_p    := valores[2],
			descricao_p := valores[3]
		);
	ELSE
		RAISE EXCEPTION 'Atualização não implementada para a tabela %', nome_tabela;
	END IF;

END;
$$ LANGUAGE plpgsql;