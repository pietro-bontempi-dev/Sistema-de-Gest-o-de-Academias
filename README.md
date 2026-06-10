# 🏋️ Sistema de Gerenciamento de Academias de Rede

## 📌 Sobre o Projeto

Este projeto consiste no desenvolvimento de um **Banco de Dados Relacional** para um **Sistema de Gerenciamento de Academias de Rede**, permitindo o controle integrado das unidades da academia, alunos, funcionários, planos, matrículas, frequência e fichas de treino.

O objetivo é simular um cenário real de uma rede de academias, aplicando conceitos de **modelagem de dados**, **normalização**, **integridade referencial** e **programação em banco de dados**, utilizando o **MySQL** como Sistema Gerenciador de Banco de Dados (SGBD).

---

## 🎯 Objetivos do Projeto

- Modelar um banco de dados para uma rede de academias;
- Implementar tabelas com relacionamentos e restrições;
- Aplicar regras de negócio utilizando recursos avançados do MySQL;
- Desenvolver consultas otimizadas através de Views;
- Automatizar processos utilizando Triggers;
- Centralizar regras operacionais por meio de Stored Procedures;
- Demonstrar conhecimentos em modelagem relacional e SQL.

---

## 🛠 Tecnologias Utilizadas

- **MySQL 8.0+**
- SQL (DDL e DML)
- Git
- GitHub
- Markdown

---

# 📂 Estrutura do Projeto

```text
academia-rede/
│
├── README.md
├── scripts/
│   ├── 01_create_database.sql
│   ├── 02_create_tables.sql
│   ├── 03_functions.sql
│   ├── 04_procedures.sql
│   ├── 05_triggers.sql
│   ├── 06_views.sql
│   └── 07_inserts.sql
│
├── diagramas/
│   ├── DER.png
│   └── Modelo_Relacional.pdf
│
└── docs/
    └── Documentacao_Projeto.pdf
```

---

# 📋 Escopo do Sistema

O sistema permite gerenciar:

- Unidades da rede;
- Usuários do sistema;
- Funcionários;
- Alunos;
- Planos de academia;
- Matrículas;
- Controle de acesso (catracas);
- Fichas de treino;
- Histórico de alterações de matrícula.

---

# 🏢 Entidades do Sistema

## Unidades

Representa cada filial pertencente à rede de academias.

### Principais informações:

- Nome da unidade;
- CNPJ;
- Endereço;
- Cidade;
- Estado;
- Telefone.

---

## Usuários

Responsável pelo processo de autenticação no sistema.

### Perfis disponíveis:

- Administrador da Rede;
- Gerente;
- Professor;
- Recepcionista;
- Aluno.

---

## Funcionários

Armazena os dados dos colaboradores.

### Informações armazenadas:

- Nome;
- CPF;
- Cargo;
- Unidade de atuação;
- CREF (quando aplicável).

---

## Alunos

Armazena os dados cadastrais dos alunos.

### Informações armazenadas:

- Nome;
- CPF;
- Data de nascimento;
- Telefone;
- Unidade de origem.

---

## Planos

Representa os planos oferecidos pela academia.

### Tipos de acesso:

| Tipo | Descrição |
|--------|------------|
| Local | Permite treinar apenas na unidade de origem |
| Rede | Permite acesso a qualquer unidade da rede |

---

## Matrículas

Controla a relação entre alunos e planos.

### Status possíveis:

- Ativo;
- Inativo;
- Trancado.

---

## Check-ins

Responsável pelo registro das passagens dos alunos pelas catracas.

Permite auditoria e acompanhamento da frequência dos alunos.

---

## Fichas de Treino

Armazena os treinos prescritos pelos professores.

---

# 🔗 Modelo Relacional

## Relacionamentos

| Entidades | Cardinalidade |
|-----------|---------------|
| Usuários × Funcionários | 1:1 |
| Usuários × Alunos | 1:1 |
| Unidades × Funcionários | 1:N |
| Unidades × Alunos | 1:N |
| Alunos × Matrículas | 1:N |
| Planos × Matrículas | 1:N |
| Alunos × Check-ins | 1:N |
| Unidades × Check-ins | 1:N |
| Alunos × Fichas de Treino | 1:N |
| Funcionários × Fichas de Treino | 1:N |
| Matrículas × Histórico de Matrículas | 1:N |

---

## Relacionamento N:N Normalizado

Conceitualmente:

```text
Alunos ←→ Planos
```

Foi implementado através da tabela intermediária:

```text
Alunos (1) ← Matrículas → (1) Planos
```

---

# ⚙️ Regras de Negócio

## Controle de acesso à rede

Quando um aluno realiza um check-in, o sistema verifica:

1. Se existe matrícula cadastrada;
2. Se a matrícula está ativa;
3. Se o check-in ocorre na unidade de origem;
4. Caso seja em outra unidade, verifica se o plano é do tipo **rede**;
5. Se autorizado, registra o check-in.

---

## Professores devem possuir CREF

Todo funcionário cadastrado como professor deve possuir um número válido de CREF.

---

## Histórico de Matrículas

Toda alteração de status em uma matrícula é registrada automaticamente.

---

# 🧩 Objetos Programáveis

## Stored Function

### `fn_calcular_idade_aluno`

Calcula a idade atual de um aluno.

### Exemplo:

```sql
SELECT fn_calcular_idade_aluno(1);
```

---

## Stored Procedure

### `sp_realizar_checkin`

Responsável por executar toda a lógica de validação do acesso dos alunos às unidades.

### Exemplo:

```sql
CALL sp_realizar_checkin(1, 2);
```

---

# 🔔 Triggers

## `tr_validar_cref_professor`

Impede o cadastro de professores sem CREF.

---

## `tr_historico_status_matricula`

Registra automaticamente alterações no status das matrículas.

---

# 👁 Views

## `vw_alunos_ativos`

Retorna todos os alunos com matrícula ativa.

---

## `vw_frequencia_alunos`

Apresenta informações sobre frequência e último check-in dos alunos.

---

## `vw_funcionarios_unidade`

Lista os funcionários agrupados por unidade.

---

# 📊 Estrutura do Banco

## Principais tabelas

- unidades
- usuarios
- funcionarios
- alunos
- planos
- matriculas
- checkins
- fichas_treino
- historico_matriculas

---

# 🚀 Como Executar o Projeto

## 1. Clonar o repositório

```bash
git clone https://github.com/SEU-USUARIO/SEU-REPOSITORIO.git
```

---

## 2. Abrir o MySQL

Utilize uma das ferramentas abaixo:

- MySQL Workbench;
- DBeaver;
- phpMyAdmin;
- Linha de comando do MySQL.

---

## 3. Executar os scripts na ordem correta

```text
01_create_database.sql

02_create_tables.sql

03_functions.sql

04_procedures.sql

05_triggers.sql

06_views.sql

07_inserts.sql
```

---

# 🧪 Exemplos de Teste

## Consultar alunos ativos

```sql
SELECT * FROM vw_alunos_ativos;
```

---

## Consultar frequência dos alunos

```sql
SELECT * FROM vw_frequencia_alunos;
```

---

## Consultar funcionários por unidade

```sql
SELECT * FROM vw_funcionarios_unidade;
```

---

## Calcular idade de um aluno

```sql
SELECT fn_calcular_idade_aluno(1);
```

---

## Registrar check-in

```sql
CALL sp_realizar_checkin(2, 3);
```

---

## Testar histórico de matrícula

```sql
UPDATE matriculas
SET status = 'trancado'
WHERE id_matricula = 1;
```

---

## Consultar histórico

```sql
SELECT * FROM historico_matriculas;
```

---

# 📈 Possíveis Evoluções do Projeto

- Controle financeiro e pagamentos;
- Integração com aplicativos mobile;
- Agendamento de aulas coletivas;
- Controle de equipamentos e manutenção;
- Dashboard gerencial;
- Programa de indicação de alunos;
- Integração com reconhecimento facial nas catracas.

---

# 🎓 Contexto Acadêmico

Este projeto foi desenvolvido com fins educacionais para aplicação prática dos conteúdos relacionados a:

- Modelagem de Banco de Dados;
- SQL;
- Integridade Referencial;
- Programação em Banco de Dados;
- Automação de regras de negócio utilizando MySQL.

---

# 👨‍💻 Autor

**Pietro Zamperlini Bontempi**

- GitHub: https://github.com/SEU-USUARIO
- LinkedIn: https://linkedin.com/in/SEU-USUARIO

---

# 📄 Licença

Este projeto foi desenvolvido para fins acadêmicos e de aprendizado.

Sinta-se à vontade para utilizá-lo como referência em estudos, respeitando a atribuição ao autor original.

---
