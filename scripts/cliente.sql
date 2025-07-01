
CREATE OR REPLACE FUNCTION validar_cliente() RETURNS TRIGGER AS $$
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


CREATE TRIGGER validar_cliente_trigger
BEFORE
INSERT
OR
UPDATE ON cliente
FOR EACH ROW EXECUTE PROCEDURE validar_cliente();


CREATE OR replace FUNCTION cadastrar_cliente(nome_p text, cpf_p text, email_p text, telefone_p text) RETURNS void AS $$
DECLARE
	constraint_violada text;
BEGIN
	insert into cliente (nome, cpf, email, telefone, cod_categoria) values
	(nome_p, cpf_p, email_p, telefone_p, 1);
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


CREATE OR REPLACE FUNCTION atualizar_dados_cliente(cliente_id int, nome_p TEXT DEFAULT NULL, email_p TEXT DEFAULT NULL, telefone_p TEXT DEFAULT NULL) RETURNS void AS $$
DECLARE
	constraint_violada TEXT;
BEGIN
	UPDATE cliente
	SET
		nome = COALESCE(nome_p, nome),
		email = COALESCE(email_p, email),
		telefone = COALESCE(telefone_p, telefone)
	WHERE id_cliente = cliente_id;

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


CREATE OR REPLACE FUNCTION excluir_cliente(cpf_p TEXT) RETURNS void AS $$
BEGIN
	UPDATE cliente
	SET ativo = false
	WHERE cpf = cpf_p;

	IF NOT FOUND THEN
		RAISE EXCEPTION 'Cliente com CPF % não encontrado', cpf_p;
	END IF;
END;
$$ LANGUAGE plpgsql;

-- views

CREATE OR REPLACE VIEW clientes_ativos AS
SELECT * FROM cliente
WHERE ativo = true;

-- exemplo de uso da função cadastrar_cliente

SELECT cadastrar_cliente('renan', '123.456.789-01', 'renan@email.com', '86999168877');


SELECT atualizar_dados_cliente(1, 'Renan Silva', NULL, '86999168877');


SELECT * FROM clientes_ativos;