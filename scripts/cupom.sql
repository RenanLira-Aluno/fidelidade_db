-- Trigger para verificar se o cliente já possui um cupom de desconto pendente
CREATE
OR REPLACE FUNCTION verificar_cupom_pendente () RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM resgate_cupom
        WHERE id_cliente = NEW.id_cliente
        AND status IN ('pendente', 'aprovado')
    ) THEN
        RAISE EXCEPTION 'Cliente com ID % já possui um cupom de desconto pendente', NEW.id_cliente;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_verificar_cupom_pendente BEFORE INSERT ON resgate_cupom FOR EACH ROW
EXECUTE FUNCTION verificar_cupom_pendente ();

-- Função para aplicar cupom de desconto em uma venda
CREATE
OR REPLACE FUNCTION aplicar_cupom_venda (
    id_venda_p int,
    codigo_voucher_p text,
    id_cliente_p int
) RETURNS void AS $$
BEGIN

    IF NOT EXISTS (SELECT id_resgate FROM resgate_cupom
    WHERE codigo_voucher = codigo_voucher_p AND id_cliente = id_cliente_p AND status = 'pendente') THEN
        RAISE EXCEPTION 'Voucher % não encontrado ou já utilizado', codigo_voucher_p;
    END IF;

    -- Atualiza o status do cupom para 'aprovado'
    UPDATE resgate_cupom
    SET status = 'aprovado'
    WHERE codigo_voucher = codigo_voucher_p AND id_cliente = id_cliente_p;

    -- Atualiza a venda com o desconto aplicado
    UPDATE venda
    SET desconto_voucher = codigo_voucher_p
    WHERE venda.id_venda = id_venda_p;

END;
$$ LANGUAGE plpgsql;

-- Função para resgatar cupom de desconto
CREATE
OR REPLACE FUNCTION resgatar_cupom (cpf_cliente_p text, id_cupom_p int) RETURNS void AS $$
DECLARE
    cliente_cupom cupons_disponiveis_por_cliente%ROWTYPE;
BEGIN

    SELECT * INTO cliente_cupom
    FROM cupons_disponiveis_por_cliente
    WHERE cpf = cpf_cliente_p AND id_cupom = id_cupom_p;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cupom com ID % não disponível para o cliente com CPF %', id_cupom_p, cpf_cliente_p;
    END IF;

    -- Verifica se o cliente tem pontos suficientes
    IF cliente_cupom.pontos_cliente <= cliente_cupom.pontos_necessarios THEN
        RAISE EXCEPTION 'Cliente com CPF % não possui pontos suficientes para resgatar o cupom', cpf_cliente_p;
    END IF;

    -- Insere o resgate do cupom
    INSERT INTO resgate_cupom (id_cliente, id_cupom, codigo_voucher)
    VALUES (cliente_cupom.id_cliente, cliente_cupom.id_cupom,
            substring(md5(random()::text), 1, 8));

    -- Atualiza os pontos do cliente
    UPDATE cliente
    SET pontos = pontos - cliente_cupom.pontos_necessarios
    WHERE cpf = cpf_cliente_p;

END;
$$ LANGUAGE plpgsql;

-- Inserts de cupons
INSERT INTO
    cupom (
        cod_categoria,
        nome,
        descricao,
        pontos_necessarios,
        desconto
    )
VALUES
    (
        1,
        'Desconto 5%',
        'Cupom de 5% em qualquer produto.',
        15,
        5
    ),
    (
        1,
        'Desconto 10%',
        'Cupom de 10% em qualquer produto.',
        30,
        10
    );

INSERT INTO
    cupom (
        cod_categoria,
        nome,
        descricao,
        pontos_necessarios,
        desconto
    )
VALUES
    (
        2,
        'Desconto 5%',
        'Cupom de 5% em qualquer produto.',
        12,
        5
    ),
    (
        2,
        'Desconto 10%',
        'Cupom de 10% em qualquer produto.',
        25,
        10
    ),
    (
        2,
        'Desconto 12%',
        'Desconto especial para membros prata.',
        35,
        12
    );

INSERT INTO
    cupom (
        cod_categoria,
        nome,
        descricao,
        pontos_necessarios,
        desconto
    )
VALUES
    (
        3,
        'Desconto 10%',
        'Cupom de 10% em qualquer produto.',
        20,
        10
    ),
    (
        3,
        'Desconto 15%',
        'Melhor condição para ouro.',
        35,
        15
    ),
    (
        3,
        'Desconto 18%',
        'Cupom premium para categoria ouro.',
        48,
        18
    );

INSERT INTO
    cupom (
        cod_categoria,
        nome,
        descricao,
        pontos_necessarios,
        desconto
    )
VALUES
    (
        4,
        'Desconto 12%',
        'Desconto padrão da categoria.',
        20,
        12
    ),
    (
        4,
        'Desconto 18%',
        'Cupom especial para membros platina.',
        36,
        18
    ),
    (
        4,
        'Desconto 20%',
        'Desconto agressivo para compras maiores.',
        45,
        20
    );

INSERT INTO
    cupom (
        cod_categoria,
        nome,
        descricao,
        pontos_necessarios,
        desconto
    )
VALUES
    (
        5,
        'Desconto 15%',
        'Condição exclusiva para clientes fiéis.',
        25,
        15
    ),
    (
        5,
        'Desconto 20%',
        'Economize mais com seu status diamante.',
        38,
        20
    ),
    (
        5,
        'Desconto 25%',
        'Cupom VIP com desconto máximo.',
        50,
        25
    );

INSERT INTO
    cupom (
        cod_categoria,
        nome,
        descricao,
        pontos_necessarios,
        desconto
    )
VALUES
    (
        6,
        'Desconto 20%',
        'Desconto para clientes elite.',
        30,
        20
    ),
    (
        6,
        'Desconto 25%',
        'Condição especial para elite.',
        45,
        25
    ),
    (
        6,
        'Desconto 30%',
        'Máximo benefício para clientes mais leais.',
        60,
        30
    );


--Função para cadastrar cupom

CREATE OR REPLACE FUNCTION cadastrar_cupom(
    cod_categoria_p INT,
    nome_p TEXT,
    descricao_p TEXT,
    pontos_necessarios_p INT,
    desconto_p INT,
    disponivel_p BOOLEAN DEFAULT true
)
RETURNS void AS $$
BEGIN
    -- Verifica se a categoria existe
    IF NOT EXISTS (
        SELECT 1 FROM categoria_programa WHERE cod = cod_categoria_p
    ) THEN
        RAISE EXCEPTION 'Categoria de código % não encontrada.', cod_categoria_p;
    END IF;

    -- Verifica se o desconto é válido
    IF desconto_p < 0 OR desconto_p > 100 THEN
        RAISE EXCEPTION 'Desconto deve estar entre 0 e 100.';
    END IF;

    -- Verifica se os pontos são positivos
    IF pontos_necessarios_p < 0 THEN
        RAISE EXCEPTION 'Pontos necessários não podem ser negativos.';
    END IF;

    -- Insere o cupom
    INSERT INTO cupom (
        cod_categoria, nome, descricao,
        pontos_necessarios, desconto, disponivel
    )
    VALUES (
        cod_categoria_p, nome_p, descricao_p,
        pontos_necessarios_p, desconto_p, disponivel_p
    );
END;
$$ LANGUAGE plpgsql;

--Função para excluir cupom

CREATE OR REPLACE FUNCTION excluir_cupom(id_cupom_p INT)
RETURNS void AS $$
BEGIN
    UPDATE cupom
    SET disponivel = false
    WHERE id_cupom = id_cupom_p;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cupom com ID % não encontrado.', id_cupom_p;
    END IF;
END;
$$ LANGUAGE plpgsql;

--Função para atualizar cupom


CREATE OR REPLACE FUNCTION atualizar_dados_cupom(
    id_cupom_p INT,
    cod_categoria_p INT DEFAULT NULL,
    nome_p TEXT DEFAULT NULL,
    descricao_p TEXT DEFAULT NULL,
    pontos_necessarios_p INT DEFAULT NULL,
    desconto_p INT DEFAULT NULL,
    disponivel_p BOOLEAN DEFAULT NULL
) RETURNS void AS $$
BEGIN
    -- Atualiza os dados do cupom com valores informados (ou mantém os atuais)
    UPDATE cupom
    SET
        cod_categoria       = COALESCE(cod_categoria_p, cod_categoria),
        nome                = COALESCE(nome_p, nome),
        descricao           = COALESCE(descricao_p, descricao),
        pontos_necessarios  = COALESCE(pontos_necessarios_p, pontos_necessarios),
        desconto            = COALESCE(desconto_p, desconto),
        disponivel          = COALESCE(disponivel_p, disponivel)
    WHERE id_cupom = id_cupom_p;

    -- Verifica se o cupom foi encontrado
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cupom com ID % não encontrado.', id_cupom_p;
    END IF;

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Código de categoria informado não existe.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao atualizar dados do cupom: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;


--View de cupons disponiveis

CREATE OR REPLACE VIEW cupons_disponiveis AS
SELECT * FROM CUPOM WHERE disponivel = true;


--Função excluir resgate cupom

CREATE OR REPLACE FUNCTION excluir_resgate_cupom(codigo_voucher_p TEXT)
RETURNS void AS $$
DECLARE
    status_resgate_atual status_resgate;
BEGIN
    -- Busca o status do resgate
    SELECT status INTO status_resgate_atual
    FROM resgate_cupom
    WHERE codigo_voucher = codigo_voucher_p;

    -- Verifica se existe
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Resgate com código % não encontrado.', codigo_voucher_p;
    END IF;

    -- Só permite deletar se for pendente ou expirado
    IF status_resgate_atual = 'pendente' THEN
        DELETE FROM resgate_cupom
        WHERE codigo_voucher = codigo_voucher_p;
    ELSE
        RAISE EXCEPTION 'Não é permitido excluir resgates com status %.', status_resgate_atual;
    END IF;
END;
$$ LANGUAGE plpgsql;