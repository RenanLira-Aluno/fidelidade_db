REVOKE ALL ON item_venda FROM PUBLIC;

GRANT SELECT ON item_venda TO grupo_clientes;
GRANT SELECT, INSERT, DELETE ON item_venda TO grupo_funcionarios;