CREATE DATABASE MARCENARIA;
USE MARCENARIA;
GO

CREATE TABLE Clientes (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Nome VARCHAR(100) NOT NULL,
    CPF VARCHAR(14) UNIQUE NOT NULL, -- Ex: 111.222.333-44
    Telefone VARCHAR(20) NOT NULL,
    Ativo BIT DEFAULT 1 NOT NULL, -- 1 = Visível, 0 = Lixeira
    DataCriacao DATETIME DEFAULT GETDATE(),
    DataAlteracao DATETIME DEFAULT NULL
);
CREATE NONCLUSTERED INDEX IX_Clientes_CPF ON Clientes(CPF);

CREATE TABLE Enderecos (
    Id INT PRIMARY KEY IDENTITY(1,1),
    ClienteId INT NOT NULL,
    Logradouro VARCHAR(150) NOT NULL,
    Numero INTEGER NOT NULL,
    Bairro VARCHAR(100) NOT NULL,
    Cidade VARCHAR(100) NOT NULL,
    UF CHAR(2) NOT NULL,
    CEP VARCHAR(9),
    Complemento VARCHAR(100),
    DataCriacao DATETIME DEFAULT GETDATE(),
    DataAlteracao DATETIME DEFAULT NULL,    
    CONSTRAINT FK_Endereco_Cliente FOREIGN KEY (ClienteId) REFERENCES Clientes(Id)
);

CREATE TABLE Materiais (
    Id            INTEGER        PRIMARY KEY IDENTITY(1,1),
    Nome          VARCHAR(100)   NOT NULL,
    Categoria     VARCHAR(50)    NOT NULL, 
    PrecoUnitario DECIMAL(18, 2) NOT NULL CHECK (PrecoUnitario >= 0),
    UnidadeMedida VARCHAR(10)    NOT NULL,     
    Ativo         BIT            DEFAULT 1 NOT NULL,
    DataCriacao   DATETIME       DEFAULT GETDATE(),
    DataAlteracao DATETIME       DEFAULT NULL
);
CREATE NONCLUSTERED INDEX IX_Materiais_Categoria ON Materiais(Categoria);

-- =============================================
-- 3. TABELA DE ORÇAMENTOS (Cabeçalho)
-- =============================================
CREATE TABLE Orcamentos (
    Id INT PRIMARY KEY IDENTITY(1,1),
    ClienteId INT NOT NULL,
    
    Status VARCHAR(20) DEFAULT 'Em Aberto', -- Controle do fluxo (Aberto -> Aprovado)
    MargemLucro DECIMAL(5, 2) DEFAULT 0 CHECK (MargemLucro >= 0), 
    ValorTotalCusto DECIMAL(18, 2) DEFAULT 0,
    ValorFinalVenda DECIMAL(18, 2) DEFAULT 0,
    Observacao VARCHAR(500),
    OR_Status VARCHAR(20) DEFAULT 'Em Aberto', -- Controle do fluxo (Aberto -> Aprovado)    
    Ativo BIT DEFAULT 1 NOT NULL, -- Se o cliente cancelar, você apenas inativa aqui
    DataCriacao DATETIME DEFAULT GETDATE(),
    DataAlteracao DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Orcamento_Cliente FOREIGN KEY (ClienteId) REFERENCES Clientes(Id)
);
CREATE NONCLUSTERED INDEX IX_Orcamentos_ClienteId ON Orcamentos(ClienteId);

-- =============================================
-- 4. ITENS DO ORÇAMENTO (Filhos do Orçamento)
-- =============================================
CREATE TABLE OrcamentoItens (
    Id INT PRIMARY KEY IDENTITY(1,1),
    OrcamentoId INT NOT NULL,
    
    NomeItem VARCHAR(100) NOT NULL,
    Ambiente VARCHAR(50), 
    Largura DECIMAL(10,2),
    Altura DECIMAL(10,2),
    Profundidade DECIMAL(10,2),
    ValorCustoItem DECIMAL(18, 2) DEFAULT 0,

    -- NOTA: Itens não precisam de "Ativo" pois vivem dentro do Orçamento.
    -- Se o Orçamento for inativado (soft delete), os itens somem da tela automaticamente.
    -- Se tentar deletar o Orçamento fisicamente, o banco BLOQUEIA.
    CONSTRAINT FK_Item_Orcamento FOREIGN KEY (OrcamentoId) REFERENCES Orcamentos(Id)
);
CREATE NONCLUSTERED INDEX IX_OrcamentoItens_OrcamentoId ON OrcamentoItens(OrcamentoId);

-- =============================================
-- 5. MATERIAIS USADOS NO ITEM (N:N)
-- =============================================
CREATE TABLE OrcamentoItemMateriais (
    Id INT PRIMARY KEY IDENTITY(1,1),
    OrcamentoItemId INT NOT NULL,
    MaterialId INT NOT NULL,
    
    Quantidade DECIMAL(10, 4) NOT NULL CHECK (Quantidade > 0),
    PrecoCustoNoMomento DECIMAL(18, 2) NOT NULL, -- Cópia de segurança do preço
    DataRegistro DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_Consumo_Item FOREIGN KEY (OrcamentoItemId) REFERENCES OrcamentoItens(Id),
    CONSTRAINT FK_Consumo_Material FOREIGN KEY (MaterialId) REFERENCES Materiais(Id)
);
CREATE NONCLUSTERED INDEX IX_OrcamentoItemMateriais_OrcamentoItemId ON OrcamentoItemMateriais(OrcamentoItemId);
GO

-- ==============================================================================
-- 1. LIMPEZA TOTAL (RESET) - ORDEM CORRETA
-- ==============================================================================
-- Removemos primeiro quem tem a chave estrangeira (Filhos)
DROP PROCEDURE IF EXISTS st_Gerenciar_Cliente;
DROP TABLE IF EXISTS OrcamentoItemMateriais; -- Nível 3 (Neto)
DROP TABLE IF EXISTS OrcamentoItens;         -- Nível 2 (Filho)
DROP TABLE IF EXISTS Orcamentos;             -- Nível 1 (Filho do Cliente)
DROP TABLE IF EXISTS Enderecos;              -- Nível 1 (Filho do Cliente - NOVO)
DROP TABLE IF EXISTS Clientes;               -- Nível 0 (Pai)
-- Materiais pode ficar ou ser recriada (vou recriar para garantir)
DROP TABLE IF EXISTS Materiais; 
GO