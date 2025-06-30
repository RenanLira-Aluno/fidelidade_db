CREATE TABLE categoria_programa (
	cod int PRIMARY KEY,
	nome varchar(140) NOT NULL,
	pontos int NOT NULL
);

CREATE TABLE cliente (
	id_cliente serial PRIMARY KEY,
	cod_categoria int REFERENCES categoria_programa(cod) NOT NULL,
	nome varchar(100) NOT NULL,
	cpf varchar(14) NOT NULL,
	email varchar(100),
	telefone varchar(20) NOT NULL,
	data_cadastro timestamp DEFAULT(now()),
	ativo bool DEFAULT(true),
	pontos int NOT NULL DEFAULT(0)
);

ALTER TABLE cliente ADD CONSTRAINT cpf_unique UNIQUE (cpf);
ALTER TABLE cliente ADD CONSTRAINT email_unique UNIQUE (email);
ALTER TABLE cliente ADD CONSTRAINT telefone_unique UNIQUE (telefone);


CREATE TABLE cupom (
	id_cupom serial PRIMARY KEY,
	cod_categoria int REFERENCES categoria_programa(cod) NOT NULL,
	nome varchar(100) NOT NULL,
	descricao text,
	pontos_necessarios int NOT NULL,
	desconto int,
	disponivel bool DEFAULT(true)
);

CREATE TYPE status_resgate AS ENUM ('pendente', 'aprovado', 'utilizado');

CREATE TABLE resgate_cupom (
	id_resgate serial PRIMARY KEY,
	id_cliente serial REFERENCES cliente(id_cliente) NOT NULL,
	id_cupom serial REFERENCES cupom(id_cupom) NOT NULL,
	status status_resgate DEFAULT('pendente') NOT NULL,
	data_resgate timestamp DEFAULT(now()),
	codigo_voucher varchar(8) NOT NULL
);

CREATE TABLE produto(
	id_produto int PRIMARY KEY,
	codigo varchar(50) NOT NULL,
	nome varchar(100) NOT NULL,
	descricao text,
	preco decimal(10, 2) NOT NULL,
	categoria varchar(50) NOT NULL,
	estoque int NOT NULL 
);


CREATE TYPE status_venda AS ENUM ('preparando', 'cancelado', 'finalizado');

CREATE TABLE venda(
	id_venda serial PRIMARY KEY,
	desconto_voucher varchar(8),
	data_venda timestamp DEFAULT(now()),
	id_cliente int REFERENCES cliente(id_cliente),
	valor_total decimal(10, 2) NOT NULL,
	status status_venda DEFAULT('preparando')
);

CREATE TABLE item_venda(
	id_item int PRIMARY KEY,
	id_venda serial REFERENCES venda(id_venda) NOT NULL,
	id_produto int REFERENCES produto(id_produto) NOT NULL,
	quantidade int NOT NULL,
	preco decimal(10, 2) NOT NULL,
	subtotal decimal(10, 2) NOT NULL
);



-- CATEGORIAS

INSERT INTO categoria_programa VALUES
(1, 'bronze', 0),
(2, 'prata', 100),
(3, 'ouro', 400),
(4, 'platina', 1000),
(5, 'diamante', 2500),
(6, 'elite', 4000)
;

-- PRODUTOS
INSERT INTO produto (id_produto, codigo, nome, descricao, preco, categoria, estoque) VALUES
(1, 'PRATO001', 'Feijoada Completa', 'Feijoada servida com arroz, couve, farofa e laranja.', 34.90, 'Prato Principal', 50),
(2, 'PRATO002', 'Lasanha à Bolonhesa', 'Lasanha com carne moída, molho de tomate e queijo gratinado.', 29.90, 'Prato Principal', 40),
(3, 'PRATO003', 'Salada Caesar', 'Alface americana, frango grelhado, croutons e molho Caesar.', 22.50, 'Entrada', 30),
(4, 'BEB001', 'Suco Natural de Laranja', 'Suco feito na hora com laranjas frescas.', 8.90, 'Bebida', 100),
(5, 'BEB002', 'Refrigerante Lata', 'Escolha entre Coca-Cola, Guaraná ou Fanta.', 6.00, 'Bebida', 200),
(6, 'SOB001', 'Pudim de Leite', 'Clássico pudim de leite condensado com calda de caramelo.', 9.50, 'Sobremesa', 25),
(7, 'SOB002', 'Brownie com Sorvete', 'Brownie de chocolate servido com bola de sorvete de creme.', 14.00, 'Sobremesa', 20),
(8, 'PRATO004', 'Frango Grelhado com Legumes', 'Peito de frango grelhado acompanhado de legumes salteados.', 27.00, 'Prato Principal', 35),
(9, 'ENT001', 'Cesta de Pães', 'Pães variados servidos com manteiga e geleia.', 12.00, 'Entrada', 15),
(10, 'BEB003', 'Cerveja Long Neck', 'Cerveja gelada disponível em várias marcas.', 9.90, 'Bebida', 60);



CREATE OR REPLACE FUNCTION inserir(nome_tabela TEXT, VARIADIC valores anyarray) RETURNS void AS $$
DECLARE
	message_error TEXT;
BEGIN
	if nome_tabela = 'cliente' THEN
		SELECT cadastrar_cliente(
			nome_p     := valores[1],
			cpf_p      := valores[2],
			email_p    := valores[3],
			telefone_p := valores[4]
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

