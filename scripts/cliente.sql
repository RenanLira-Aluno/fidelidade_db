-- Trigger de validação de dados do cliente
CREATE
OR REPLACE FUNCTION validar_cliente () RETURNS TRIGGER AS $$
begin
	if NEW.email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' then
		raise exception 'email invalido';
	elsif NEW.telefone !~ '^\d{2}9\d{8}$' then
		raise exception 'telefone invalido';
	elsif NEW.cpf !~ '^\d{3}\.\d{3}\.\d{3}-\d{2}$' then
		raise exception 'cpf invalido';
	elsif NEW.nome !~ '^[A-Za-zÀ-ÖØ-öø-ÿ\s]+$' then
		raise exception 'nome invalido';
	end if;

	return NEW;
end;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validar_cliente_trigger BEFORE INSERT
OR
UPDATE ON cliente FOR EACH ROW
EXECUTE PROCEDURE validar_cliente ();

-- Trigger para gerar pontos para o cliente após a venda ser finalizada
CREATE
OR REPLACE FUNCTION fn_gerar_pontos_cliente () RETURNS TRIGGER AS $$
DECLARE
	pontos_gerados int;
	total_venda decimal(10, 2);
BEGIN

	SELECT valor_total INTO total_venda FROM venda WHERE id_venda = NEW.id_venda;

	pontos_gerados := floor(total_venda)::INTEGER;

	IF pontos_gerados > 0 THEN
		UPDATE cliente
		SET pontos = pontos + pontos_gerados
		WHERE id_cliente = NEW.id_cliente;

		RAISE NOTICE 'Pontos gerados: %', pontos_gerados;
	ELSE
		RAISE NOTICE 'Nenhum ponto gerado para a venda com valor total: %', total_venda;
	END IF;

	RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_gerar_pontos_cliente
AFTER
UPDATE ON venda FOR EACH ROW WHEN (
	OLD.status <> 'finalizado'
	and NEW.status = 'finalizado'
)
EXECUTE FUNCTION fn_gerar_pontos_cliente ();

-- Trigger para atualizar a categoria do cliente quando os pontos mudarem
CREATE
OR REPLACE FUNCTION fn_atualizar_categoria_cliente () RETURNS TRIGGER AS $$
DECLARE
	categoria_nova int;
BEGIN
	SELECT cod INTO categoria_nova FROM categoria_programa 
	WHERE pontos <= NEW.pontos
	ORDER BY pontos DESC
	LIMIT 1;

	IF categoria_nova = NEW.cod_categoria THEN
		RETURN NEW; -- Nenhuma mudança de categoria
	END IF;

	UPDATE cliente
	SET cod_categoria = categoria_nova
	WHERE id_cliente = NEW.id_cliente;

	return NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_atualizar_categoria_cliente
AFTER
UPDATE ON cliente FOR EACH ROW WHEN (OLD.pontos <> NEW.pontos)
EXECUTE FUNCTION fn_atualizar_categoria_cliente ();

-- Função para cadastrar cliente
CREATE
OR replace FUNCTION cadastrar_cliente (
	nome_p text,
	cpf_p text,
	email_p text,
	telefone_p text
) RETURNS void AS $$
DECLARE
	constraint_violada text;
	cpf_formatado text := regexp_replace(cpf_p, '[^0-9]', '', 'g');
BEGIN

	-- Verificar se o CPF está apenas desativado
	IF EXISTS (SELECT 1 FROM cliente WHERE cpf = cpf_formatado AND ativo = false) THEN
		UPDATE cliente
		SET ativo = true, nome = nome_p, email = email_p, telefone = telefone_p
		WHERE cpf = cpf_formatado;
		RETURN; -- Cliente reativado com sucesso
	END IF;

	-- Inserir cliente na tabela cliente
	insert into cliente (nome, cpf, email, telefone, cod_categoria) values
	(nome_p, cpf_p, email_p, telefone_p, 1);

	-- Criar usuario no banco postgres
	EXECUTE format('CREATE USER %I WITH PASSWORD %L', cpf_formatado, cpf_formatado);
exception
	when unique_violation then
		GET STACKED DIAGNOSTICS constraint_violada = CONSTRAINT_NAME;

		if constraint_violada = 'cpf_unique' then
			RAISE EXCEPTION 'cpf já cadastrado';
		elsif constraint_violada = 'email_unique' then
			RAISE EXCEPTION 'email já cadastrado';
		elsif constraint_violada = 'telefone_unique' then
			RAISE EXCEPTION 'telefone já cadastrado';
		else
			RAISE EXCEPTION 'Erro de dado duplicado. Constraint: %', constraint_violada;
		end if;
end;
$$ LANGUAGE plpgsql;

-- Função para atualizar dados do cliente
CREATE
OR REPLACE FUNCTION atualizar_dados_cliente (
	cliente_id int,
	nome_p TEXT DEFAULT NULL,
	email_p TEXT DEFAULT NULL,
	telefone_p TEXT DEFAULT NULL
) RETURNS void AS $$
DECLARE
	constraint_violada TEXT;
BEGIN
	UPDATE cliente
	SET
		nome = COALESCE(nome_p, nome),
		email = COALESCE(email_p, email),
		telefone = COALESCE(telefone_p, telefone)
	WHERE id_cliente = cliente_id and ativo = true;

	if NOT FOUND then
		RAISE EXCEPTION 'Cliente com id % não encontrado', cliente_id;
	end if;
exception
	when unique_violation then
		GET STACKED DIAGNOSTICS constraint_violada = CONSTRAINT_NAME;

		if constraint_violada = 'cpf_unique' then
			RAISE EXCEPTION 'cpf já cadastrado';
		elsif constraint_violada = 'email_unique' then
			RAISE EXCEPTION 'email já cadastrado';
		elsif constraint_violada = 'telefone_unique' then
			RAISE EXCEPTION 'telefone já cadastrado';
		else
			RAISE EXCEPTION 'Erro de dado duplicado. Constraint: %', constraint_violada;
		end if;
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Erro ao atualizar dados do cliente: %', SQLERRM;

END;
$$ LANGUAGE plpgsql;

-- Função para excluir cliente (marcar como inativo)
CREATE
OR REPLACE FUNCTION excluir_cliente (cpf_p TEXT) RETURNS void AS $$
BEGIN
	UPDATE cliente
	SET ativo = false
	WHERE cpf = cpf_p;

	IF NOT FOUND THEN
		RAISE EXCEPTION 'Cliente com CPF % não encontrado', cpf_p;
	END IF;

	EXECUTE format('DROP USER IF EXISTS %I', regexp_replace(cpf_p, '[^0-9]', '', 'g'));
END;
$$ LANGUAGE plpgsql;

-- views
CREATE OR REPLACE VIEW
	clientes_ativos AS
SELECT
	*
FROM
	cliente
WHERE
	ativo = true;

-- exemplo de uso da função cadastrar_cliente
SELECT
	cadastrar_cliente (
		'renan',
		'123.456.789-01',
		'renan@email.com',
		'86999168877'
	);

-- View para listar cupons disponíveis por client
DROP VIEW IF EXISTS cupons_disponiveis_por_cliente;

CREATE OR REPLACE VIEW
	cupons_disponiveis_por_cliente AS
SELECT
	cli.id_cliente,
	cli.cpf,
	cli.nome AS nome_cliente,
	cat.nome AS nome_categoria,
	cup.id_cupom,
	cup.nome AS nome_cupom,
	cup.descricao,
	cup.desconto,
	cup.pontos_necessarios,
	cli.pontos AS pontos_cliente
FROM
	cliente cli
	JOIN categoria_programa cat ON cli.cod_categoria = cat.cod
	JOIN cupom cup ON cup.cod_categoria = cat.cod
WHERE
	cup.disponivel = true
	AND cli.ativo = true;