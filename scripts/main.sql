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

CREATE TYPE cargo AS ENUM('vendedor', 'gerente', 'administrador');

CREATE TABLE
	funcionario (
		login_pg varchar(50) PRIMARY KEY,
		cargo cargo NOT NULL
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



-- Função genérica de inserção
CREATE
OR REPLACE FUNCTION inserir (nome_tabela TEXT, VARIADIC valores TEXT[]) RETURNS void AS $$
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
            codigo_p     := valores[1],
            nome_p       := valores[2],
            descricao_p  := valores[3],
            preco_p      := valores[4]::DECIMAL,
            categoria_p  := valores[5],
            estoque_p    := valores[6]::INT
        );

    ELSIF nome_tabela = 'cupom' THEN
        PERFORM cadastrar_cupom(
            cod_categoria_p        := valores[1]::INT,
            nome_p                 := valores[2],
            descricao_p            := valores[3],
            pontos_necessarios_p   := valores[4]::INT,
            desconto_p             := valores[5]::INT,
            disponivel_p           := COALESCE(valores[6]::BOOLEAN, true)
        );

    ELSIF nome_tabela = 'resgate_cupom' THEN
        PERFORM resgatar_cupom(
            cpf_cliente_p := valores[1],
            id_cupom_p    := valores[2]::INT
        );

    ELSIF nome_tabela = 'categoria_programa' THEN
        PERFORM cadastrar_categoria_programa(
            cod_p     := valores[1]::INT,
            nome_p    := valores[2],
            pontos_p  := valores[3]::INT
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
CREATE
OR REPLACE FUNCTION remover (nome_tabela TEXT, VARIADIC valores TEXT[]) RETURNS void AS $$
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

    ELSIF nome_tabela = 'item_venda' THEN
        PERFORM remover_item_venda(
            valores[1]::INT
        );

    ELSIF nome_tabela = 'resgate_cupom' THEN
        PERFORM excluir_resgate_cupom(
            codigo_voucher_p := valores[1]
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
        );

    ELSIF nome_tabela = 'categoria_programa' THEN
        PERFORM atualizar_categoria_programa(
            cod_p        := valores[1]::INT,
            nome_p       := valores[2],
            descricao_p  := valores[3]
        );

    ELSIF nome_tabela = 'cupom' THEN
        PERFORM atualizar_dados_cupom(
            id_cupom_p             := valores[1]::INT,
            cod_categoria_p        := NULLIF(valores[2], '')::INT,
            nome_p                 := valores[3],
            descricao_p            := valores[4],
            pontos_necessarios_p   := NULLIF(valores[5], '')::INT,
            desconto_p             := NULLIF(valores[6], '')::INT,
            disponivel_p           := NULLIF(valores[7], '')::BOOLEAN
        );

    ELSE
        RAISE EXCEPTION 'Atualização não implementada para a tabela %', nome_tabela;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS message_error = MESSAGE_TEXT;
        RAISE EXCEPTION 'Erro ao atualizar a tabela %: %', nome_tabela, message_error;
END;
$$ LANGUAGE plpgsql;