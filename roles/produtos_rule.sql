REVOKE ALL ON produto FROM PUBLIC;

GRANT SELECT ON produto TO grupo_clientes;
GRANT SELECT, INSERT, UPDATE ON produto TO grupo_funcionarios;