CREATE DATABASE academia_rede;
USE academia_rede;

CREATE TABLE unidades (
    id_unidade INT AUTO_INCREMENT PRIMARY KEY,
    nome_fantasia VARCHAR(100) NOT NULL,
    cnpj VARCHAR(18) UNIQUE NOT NULL,
    endereco VARCHAR(200) NOT NULL,
    cidade VARCHAR(100) NOT NULL,
    estado VARCHAR(2) NOT NULL,
    telefone VARCHAR(20)
);

CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(150) UNIQUE NOT NULL,
    senha VARCHAR(255) NOT NULL,
    tipo_perfil ENUM(
        'admin_rede',
        'gerente',
        'professor',
        'recepcionista',
        'aluno'
    ) NOT NULL,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE funcionarios (
    id_funcionario INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT UNIQUE NOT NULL,
    id_unidade_alocada INT NOT NULL,
    nome VARCHAR(150) NOT NULL,
    cpf VARCHAR(14) UNIQUE NOT NULL,
    cref VARCHAR(20),
    cargo VARCHAR(50) NOT NULL,

    FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario),

    FOREIGN KEY (id_unidade_alocada)
        REFERENCES unidades(id_unidade)
);

CREATE TABLE alunos (
    id_aluno INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT UNIQUE NOT NULL,
    id_unidade_origem INT NOT NULL,
    nome VARCHAR(150) NOT NULL,
    cpf VARCHAR(14) UNIQUE NOT NULL,
    data_nascimento DATE NOT NULL,
    telefone VARCHAR(20),

    FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario),

    FOREIGN KEY (id_unidade_origem)
        REFERENCES unidades(id_unidade)
);

CREATE TABLE planos (
    id_plano INT AUTO_INCREMENT PRIMARY KEY,
    nome_plano VARCHAR(100) NOT NULL,
    preco_mensal DECIMAL(10,2) NOT NULL,

    tipo_acesso ENUM(
        'local',
        'rede'
    ) NOT NULL
);

CREATE TABLE matriculas (
    id_matricula INT AUTO_INCREMENT PRIMARY KEY,
    id_aluno INT NOT NULL,
    id_plano INT NOT NULL,
    data_inicio DATE NOT NULL,

    status ENUM(
        'ativo',
        'inativo',
        'trancado'
    ) NOT NULL,

    FOREIGN KEY (id_aluno)
        REFERENCES alunos(id_aluno),

    FOREIGN KEY (id_plano)
        REFERENCES planos(id_plano)
);

CREATE TABLE checkins (
    id_checkin INT AUTO_INCREMENT PRIMARY KEY,
    id_aluno INT NOT NULL,
    id_unidade INT NOT NULL,
    data_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_aluno)
        REFERENCES alunos(id_aluno),

    FOREIGN KEY (id_unidade)
        REFERENCES unidades(id_unidade)
);

CREATE TABLE fichas_treino (
    id_ficha INT AUTO_INCREMENT PRIMARY KEY,
    id_aluno INT NOT NULL,
    id_professor INT NOT NULL,
    data_criacao DATE NOT NULL,
    objetivo VARCHAR(100),

    FOREIGN KEY (id_aluno)
        REFERENCES alunos(id_aluno),

    FOREIGN KEY (id_professor)
        REFERENCES funcionarios(id_funcionario)
);

CREATE TABLE historico_matriculas (
    id_historico INT AUTO_INCREMENT PRIMARY KEY,
    id_matricula INT NOT NULL,
    status_anterior VARCHAR(20),
    status_novo VARCHAR(20),
    data_alteracao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_matricula)
        REFERENCES matriculas(id_matricula)
);


/* Stored Function - Função para calcular a idade do aluno*/
DELIMITER $$

CREATE FUNCTION fn_calcular_idade_aluno(
    p_id_aluno INT
)
RETURNS INT
DETERMINISTIC

BEGIN
    DECLARE v_data_nascimento DATE;
    DECLARE v_idade INT;

    SELECT data_nascimento
    INTO v_data_nascimento
    FROM alunos
    WHERE id_aluno = p_id_aluno;

    SET v_idade = TIMESTAMPDIFF(YEAR, v_data_nascimento, CURDATE());

    RETURN v_idade;
END $$

DELIMITER ;

/* Stored Procedure - Procedure para realizar o check-in do aluno*/
DELIMITER $$

CREATE PROCEDURE sp_realizar_checkin(
    IN p_id_aluno INT,
    IN p_id_unidade INT
)
BEGIN

    DECLARE v_status VARCHAR(20);
    DECLARE v_tipo_acesso VARCHAR(20);
    DECLARE v_unidade_origem INT;

    SELECT m.status,
           p.tipo_acesso,
           a.id_unidade_origem
    INTO v_status,
         v_tipo_acesso,
         v_unidade_origem
    FROM matriculas m
    INNER JOIN planos p
        ON m.id_plano = p.id_plano
    INNER JOIN alunos a
        ON m.id_aluno = a.id_aluno
    WHERE a.id_aluno = p_id_aluno
    ORDER BY m.id_matricula DESC
    LIMIT 1;

    IF v_status IS NULL THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Aluno não possui matrícula cadastrada.';

    ELSEIF v_status <> 'ativo' THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Matrícula inativa ou trancada.';

    ELSEIF p_id_unidade = v_unidade_origem THEN

        INSERT INTO checkins(id_aluno, id_unidade)
        VALUES (p_id_aluno, p_id_unidade);

    ELSEIF v_tipo_acesso = 'rede' THEN

        INSERT INTO checkins(id_aluno, id_unidade)
        VALUES (p_id_aluno, p_id_unidade);

    ELSE

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Plano não permite acesso em outras unidades.';

    END IF;

END $$

DELIMITER ;

/* Trigger - Validar CREF dos professores*/
DELIMITER $$

CREATE TRIGGER tr_validar_cref_professor
BEFORE INSERT
ON funcionarios
FOR EACH ROW

BEGIN

    IF LOWER(NEW.cargo) = 'professor'
       AND (NEW.cref IS NULL OR NEW.cref = '') THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Professores devem possuir CREF cadastrado.';

    END IF;

END $$

DELIMITER ;


/* Trigger - Registrar alterações de status da matrícula*/
DELIMITER $$

CREATE TRIGGER tr_historico_status_matricula
AFTER UPDATE
ON matriculas
FOR EACH ROW

BEGIN

    IF OLD.status <> NEW.status THEN

        INSERT INTO historico_matriculas(
            id_matricula,
            status_anterior,
            status_novo
        )
        VALUES (
            NEW.id_matricula,
            OLD.status,
            NEW.status
        );

    END IF;

END $$

DELIMITER ;


/* View 1 – Alunos ativos */
CREATE VIEW vw_alunos_ativos AS

SELECT
    a.id_aluno,
    a.nome,
    a.cpf,
    u.nome_fantasia AS unidade_origem,
    p.nome_plano,
    m.data_inicio
FROM alunos a
INNER JOIN matriculas m
    ON a.id_aluno = m.id_aluno
INNER JOIN planos p
    ON m.id_plano = p.id_plano
INNER JOIN unidades u
    ON a.id_unidade_origem = u.id_unidade
WHERE m.status = 'ativo';


/* View 2 – Frequencia Alunos */
CREATE VIEW vw_frequencia_alunos AS

SELECT
    a.id_aluno,
    a.nome,
    COUNT(c.id_checkin) AS total_checkins,
    MAX(c.data_hora) AS ultimo_checkin
FROM alunos a
LEFT JOIN checkins c
    ON a.id_aluno = c.id_aluno
GROUP BY
    a.id_aluno,
    a.nome;

/* View 3 – Funcionários por unidade */    
CREATE VIEW vw_funcionarios_unidade AS

SELECT
    u.nome_fantasia AS unidade,
    f.nome AS funcionario,
    f.cargo,
    f.cref
FROM funcionarios f
INNER JOIN unidades u
    ON f.id_unidade_alocada = u.id_unidade;




/* Lista com inserts para testes e validações */

INSERT INTO unidades (
    nome_fantasia, cnpj, endereco, cidade, estado, telefone
) VALUES
('Academia FitLife Centro', '12.345.678/0001-01', 'Rua A, 100', 'Santo André', 'SP', '(11) 4000-1001'),
('Academia FitLife Jardim', '12.345.678/0002-92', 'Rua B, 200', 'Santo André', 'SP', '(11) 4000-1002'),
('Academia FitLife Norte', '12.345.678/0003-73', 'Rua C, 300', 'São Bernardo do Campo', 'SP', '(11) 4000-1003'),
('Academia FitLife Sul', '12.345.678/0004-54', 'Rua D, 400', 'São Caetano do Sul', 'SP', '(11) 4000-1004');

INSERT INTO usuarios (email, senha, tipo_perfil) VALUES
('admin@fitlife.com', '123456', 'admin_rede'),
('gerente.centro@fitlife.com', '123456', 'gerente'),
('prof.maria@fitlife.com', '123456', 'professor'),
('prof.joao@fitlife.com', '123456', 'professor'),
('recep.centro@fitlife.com', '123456', 'recepcionista'),
('gerente.norte@fitlife.com', '123456', 'gerente'),
('prof.pedro@fitlife.com', '123456', 'professor'),
('recep.norte@fitlife.com', '123456', 'recepcionista');

INSERT INTO funcionarios (
    id_usuario, id_unidade_alocada, nome, cpf, cref, cargo
) VALUES
(1, 1, 'Carlos Alberto', '111.111.111-11', NULL, 'Administrador'),
(2, 1, 'Fernanda Souza', '222.222.222-22', NULL, 'Gerente'),
(3, 1, 'Maria Oliveira', '333.333.333-33', 'CREF12345', 'Professor'),
(4, 2, 'João Pereira', '444.444.444-44', 'CREF23456', 'Professor'),
(5, 1, 'Juliana Costa', '555.555.555-55', NULL, 'Recepcionista'),
(6, 3, 'Roberto Lima', '666.666.666-66', NULL, 'Gerente'),
(7, 3, 'Pedro Martins', '777.777.777-77', 'CREF34567', 'Professor'),
(8, 3, 'Ana Clara', '888.888.888-88', NULL, 'Recepcionista');

INSERT INTO planos (
    nome_plano, preco_mensal, tipo_acesso
) VALUES
('Plano Básico', 89.90, 'local'),
('Plano Premium', 129.90, 'rede'),
('Plano Black', 169.90, 'rede'),
('Plano Estudante', 69.90, 'local');

INSERT INTO usuarios (email, senha, tipo_perfil) VALUES
('aluno01@email.com','123456','aluno'),
('aluno02@email.com','123456','aluno'),
('aluno03@email.com','123456','aluno'),
('aluno04@email.com','123456','aluno'),
('aluno05@email.com','123456','aluno'),
('aluno06@email.com','123456','aluno'),
('aluno07@email.com','123456','aluno'),
('aluno08@email.com','123456','aluno'),
('aluno09@email.com','123456','aluno'),
('aluno10@email.com','123456','aluno'),
('aluno11@email.com','123456','aluno'),
('aluno12@email.com','123456','aluno'),
('aluno13@email.com','123456','aluno'),
('aluno14@email.com','123456','aluno'),
('aluno15@email.com','123456','aluno'),
('aluno16@email.com','123456','aluno'),
('aluno17@email.com','123456','aluno'),
('aluno18@email.com','123456','aluno'),
('aluno19@email.com','123456','aluno'),
('aluno20@email.com','123456','aluno');

INSERT INTO alunos (
    id_usuario, id_unidade_origem, nome, cpf,
    data_nascimento, telefone
) VALUES
(9,1,'Lucas Ferreira','101.101.101-01','1998-03-12','11999990001'),
(10,1,'Gabriel Santos','102.102.102-02','2000-06-20','11999990002'),
(11,1,'Beatriz Lima','103.103.103-03','1995-08-15','11999990003'),
(12,2,'Amanda Costa','104.104.104-04','2001-02-11','11999990004'),
(13,2,'Rafael Martins','105.105.105-05','1997-09-23','11999990005'),
(14,2,'Mariana Alves','106.106.106-06','1999-05-19','11999990006'),
(15,3,'Thiago Souza','107.107.107-07','1994-07-30','11999990007'),
(16,3,'Camila Rocha','108.108.108-08','2002-04-08','11999990008'),
(17,3,'Felipe Gomes','109.109.109-09','1996-11-10','11999990009'),
(18,4,'Larissa Nunes','110.110.110-10','2000-12-18','11999990010'),
(19,4,'Gustavo Silva','111.111.111-12','1993-10-14','11999990011'),
(20,4,'Patricia Melo','112.112.112-13','1998-01-25','11999990012'),
(21,1,'Eduardo Pinto','113.113.113-14','2001-09-05','11999990013'),
(22,2,'Vanessa Cruz','114.114.114-15','1997-02-02','11999990014'),
(23,3,'Daniel Ribeiro','115.115.115-16','1995-06-17','11999990015'),
(24,4,'Bruna Fernandes','116.116.116-17','2003-03-09','11999990016'),
(25,1,'Caio Carvalho','117.117.117-18','1992-12-11','11999990017'),
(26,2,'Isabela Freitas','118.118.118-19','2000-08-28','11999990018'),
(27,3,'Leonardo Araujo','119.119.119-20','1999-04-04','11999990019'),
(28,4,'Renata Moraes','120.120.120-21','1996-07-21','11999990020');

INSERT INTO matriculas (
    id_aluno, id_plano, data_inicio, status
) VALUES
(1,1,'2025-01-10','ativo'),
(2,2,'2025-02-15','ativo'),
(3,3,'2025-03-01','ativo'),
(4,4,'2025-01-20','ativo'),
(5,2,'2025-02-10','ativo'),
(6,1,'2025-04-05','trancado'),
(7,3,'2025-01-12','ativo'),
(8,2,'2025-03-22','ativo'),
(9,1,'2025-02-18','ativo'),
(10,4,'2025-01-08','inativo'),
(11,3,'2025-05-02','ativo'),
(12,2,'2025-04-14','ativo'),
(13,1,'2025-03-11','ativo'),
(14,4,'2025-02-07','ativo'),
(15,2,'2025-01-25','ativo'),
(16,3,'2025-03-17','ativo'),
(17,1,'2025-04-01','ativo'),
(18,2,'2025-05-10','ativo'),
(19,4,'2025-02-28','ativo'),
(20,3,'2025-03-03','ativo');

INSERT INTO checkins (
    id_aluno, id_unidade, data_hora
) VALUES
(1,1,'2026-06-01 08:00:00'),
(2,2,'2026-06-01 18:30:00'),
(3,1,'2026-06-02 07:45:00'),
(3,3,'2026-06-04 19:00:00'),
(5,2,'2026-06-02 20:00:00'),
(7,3,'2026-06-03 06:30:00'),
(8,4,'2026-06-03 18:00:00'),
(11,1,'2026-06-05 08:15:00'),
(15,3,'2026-06-05 19:20:00'),
(20,4,'2026-06-06 10:00:00');

INSERT INTO fichas_treino (
    id_aluno, id_professor, data_criacao, objetivo
) VALUES
(1,3,'2026-05-01','Hipertrofia'),
(2,3,'2026-05-02','Emagrecimento'),
(3,4,'2026-05-03','Condicionamento físico'),
(4,4,'2026-05-04','Hipertrofia'),
(5,7,'2026-05-05','Emagrecimento'),
(7,7,'2026-05-06','Hipertrofia'),
(8,3,'2026-05-07','Resistência'),
(11,4,'2026-05-08','Hipertrofia'),
(15,7,'2026-05-09','Emagrecimento'),
(20,3,'2026-05-10','Condicionamento físico');


/* Consultas testes */
SELECT * FROM vw_alunos_ativos;
SELECT * FROM vw_frequencia_alunos;
SELECT * FROM vw_funcionarios_unidade;
SELECT fn_calcular_idade_aluno(1);
CALL sp_realizar_checkin(2, 3);


/* Teste Trigger */

UPDATE matriculas
SET status = 'trancado'
WHERE id_matricula = 1;