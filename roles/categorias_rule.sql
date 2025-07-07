REVOKE ALL ON categoria_programa FROM PUBLIC;

GRANT SELECT ON categoria_programa TO grupo_clientes;
GRANT SELECT, INSERT, UPDATE ON categoria_programa TO grupo_funcionarios;