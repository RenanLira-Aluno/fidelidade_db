ALTER TABLE cliente
ADD COLUMN login_pg VARCHAR(14) GENERATED ALWAYS AS (replace(cpf, '.', '')) STORED;