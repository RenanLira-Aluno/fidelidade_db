
CREATE OR REPLACE FUNCTION validar_cliente() RETURNS TRIGGER AS $$
begin
	if NEW.email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' then
		raise exception 'email invalido';
	elsif NEW.telefone !~ '^\d{2}9\d{8}$' then
		raise exception 'telefone invalido';
	end if;

	return NEW;
end;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validar_trigger BEFORE INSERT ON cliente
FOR EACH ROW EXECUTE PROCEDURE validar_cliente();


CREATE OR replace FUNCTION cadastrar_cliente(nome_p text, cpf_p text, email_p text, telefone_p text) 
RETURNS void AS $$
BEGIN
	insert into cliente (nome, cpf, email, telefone, cod_categoria) values
	(nome_p, cpf_p, email_p, telefone_p, 1);
exception
	when unique_violation then
		raise exception 'um dado já existe';
end;
$$ LANGUAGE plpgsql;

-- exemplo de uso da função cadastrar_cliente
SELECT cadastrar_cliente('renan', '12345678900', 'renan@email.com', '86999168877');

