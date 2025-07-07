REVOKE ALL ON cupom FROM PUBLIC;

GRANT SELECT ON cupom TO grupo_clientes;
GRANT SELECT, INSERT, UPDATE ON cupom TO grupo_funcionarios;

