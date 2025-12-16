CREATE DATABASE MARCENARIA;
USE MARCENARIA;
GO

-- =============================================
-- 1. TABELA DE CLIENTES (PF/PJ)
-- =============================================
CREATE TABLE Clientes (
  Id                 INTEGER      PRIMARY KEY IDENTITY(1,1),
  TipoPessoa         CHAR(1)      NOT NULL CHECK (TipoPessoa IN ('F', 'J')), -- F=Física, J=Jurídica
  Nome               VARCHAR(100) NOT NULL, -- Nome completo (PF) ou Razão Social (PJ)
  NomeFantasia       VARCHAR(100) NULL,     -- Apenas para PJ
  CPF                VARCHAR(11)  NULL,     -- Apenas números, apenas PF
  CNPJ               VARCHAR(14)  NULL,     -- Apenas números, apenas PJ
  InscricaoEstadual  VARCHAR(20)  NULL,     -- Apenas PJ
  Email              VARCHAR(100) NULL,
  Observacao         VARCHAR(500) NULL,
  Ativo              BIT          DEFAULT 1 NOT NULL,
  DataCriacao        DATETIME     DEFAULT GETDATE(),
  DataAlteracao      DATETIME     DEFAULT NULL,
  CONSTRAINT CK_Cliente_Documento CHECK (
    (TipoPessoa = 'F' AND CPF IS NOT NULL AND CNPJ IS NULL) OR
    (TipoPessoa = 'J' AND CNPJ IS NOT NULL AND CPF IS NULL)
  )
);
CREATE NONCLUSTERED INDEX IX_Clientes_CPF  ON Clientes(CPF)  WHERE CPF IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Clientes_CNPJ ON Clientes(CNPJ) WHERE CNPJ IS NOT NULL;

-- =============================================
-- 2. TABELA DE TELEFONES (1:N com Cliente)
-- =============================================
CREATE TABLE Telefones (
  Id            INTEGER     PRIMARY KEY IDENTITY(1,1),
  ClienteId     INTEGER     NOT NULL,
  Tipo          VARCHAR(20) NOT NULL CHECK (Tipo IN ('Celular', 'Comercial', 'Residencial', 'WhatsApp')),
  Numero        VARCHAR(20) NOT NULL,
  Principal     BIT         DEFAULT 0 NOT NULL,
  DataCriacao   DATETIME    DEFAULT GETDATE(),
  DataAlteracao DATETIME    DEFAULT NULL,
  CONSTRAINT FK_Telefone_Cliente FOREIGN KEY (ClienteId) REFERENCES Clientes(Id)
);
CREATE NONCLUSTERED INDEX IX_Telefones_ClienteId ON Telefones(ClienteId);

-- =============================================
-- 3. TABELA DE ENDEREÇOS (1:N com Cliente)
-- =============================================
CREATE TABLE Enderecos (
  Id            INTEGER      PRIMARY KEY IDENTITY(1,1),
  ClienteId     INTEGER      NOT NULL,
  Tipo          VARCHAR(20)  NOT NULL CHECK (Tipo IN ('Residencial', 'Comercial', 'Cobrança', 'Entrega')),
  Logradouro    VARCHAR(150) NOT NULL,
  Numero        VARCHAR(10)  NOT NULL,
  Bairro        VARCHAR(100) NOT NULL,
  Cidade        VARCHAR(100) NOT NULL,
  UF            CHAR(2)      NOT NULL,
  CEP           VARCHAR(8)   NOT NULL,
  Complemento   VARCHAR(100) NULL,
  Principal     BIT          DEFAULT 0 NOT NULL,
  DataCriacao   DATETIME     DEFAULT GETDATE(),
  DataAlteracao DATETIME     DEFAULT NULL,
  CONSTRAINT FK_Endereco_Cliente FOREIGN KEY (ClienteId) REFERENCES Clientes(Id)
);
CREATE NONCLUSTERED INDEX IX_Enderecos_ClienteId ON Enderecos(ClienteId);

-- =============================================
-- 4. TABELA DE FORNECEDORES (PF/PJ)
-- =============================================
CREATE TABLE Fornecedores (
  Id                INTEGER      PRIMARY KEY IDENTITY(1,1),
  TipoPessoa        CHAR(1)      NOT NULL CHECK (TipoPessoa IN ('F', 'J')),
  Nome              VARCHAR(100) NOT NULL,
  NomeFantasia      VARCHAR(100) NULL,
  CPF               VARCHAR(11)  NULL,
  CNPJ              VARCHAR(14)  NULL,
  InscricaoEstadual VARCHAR(20)  NULL,
  Email             VARCHAR(100) NULL,
  Telefone          VARCHAR(20)  NOT NULL,
  Logradouro        VARCHAR(150) NULL,
  Numero            VARCHAR(10)  NULL,
  Bairro            VARCHAR(100) NULL,
  Cidade            VARCHAR(100) NULL,
  UF                CHAR(2)      NULL,
  CEP               VARCHAR(8)   NULL,
  Complemento       VARCHAR(100) NULL,
  Observacao        VARCHAR(500) NULL,
  Ativo             BIT          DEFAULT 1 NOT NULL,
  DataCriacao       DATETIME     DEFAULT GETDATE(),
  DataAlteracao     DATETIME     DEFAULT NULL,
  CONSTRAINT CK_Fornecedor_Documento CHECK (
    (TipoPessoa = 'F' AND CPF IS NOT NULL AND CNPJ IS NULL) OR
    (TipoPessoa = 'J' AND CNPJ IS NOT NULL AND CPF IS NULL)
  )
);
CREATE NONCLUSTERED INDEX IX_Fornecedores_CPF  ON Fornecedores(CPF)  WHERE CPF IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Fornecedores_CNPJ ON Fornecedores(CNPJ) WHERE CNPJ IS NOT NULL;

-- =============================================
-- 5. TABELA DE MATERIAIS (com Estoque)
-- =============================================
CREATE TABLE Materiais (
  Id                INTEGER        PRIMARY KEY IDENTITY(1,1),
  Nome              VARCHAR(100)   NOT NULL,
  Categoria         VARCHAR(50)    NULL,
  Descricao         VARCHAR(500)   NULL,
  PrecoUnitario     DECIMAL(18,2)  NOT NULL CHECK (PrecoUnitario >= 0),
  UnidadeMedida     VARCHAR(10)    NOT NULL,
  QuantidadeEstoque DECIMAL(10,4)  DEFAULT 0 NOT NULL CHECK (QuantidadeEstoque >= 0),
  EstoqueMinimo     DECIMAL(10,4)  DEFAULT 0 NULL,
  EstoqueMaximo     DECIMAL(10,4)  NULL,
  Localizacao       VARCHAR(50)    NULL,
  Ativo             BIT            DEFAULT 1 NOT NULL,
  DataCriacao       DATETIME       DEFAULT GETDATE(),
  DataAlteracao     DATETIME       DEFAULT NULL
);
CREATE NONCLUSTERED INDEX IX_Materiais_Categoria ON Materiais(Categoria);
CREATE NONCLUSTERED INDEX IX_Materiais_Estoque   ON Materiais(QuantidadeEstoque, EstoqueMinimo);

-- =============================================
-- 6. TABELA DE MOVIMENTAÇÕES DE ESTOQUE
-- =============================================
CREATE TABLE MovimentacoesEstoque (
  Id                 INTEGER       PRIMARY KEY IDENTITY(1,1),
  MaterialId         INTEGER       NOT NULL,
  TipoMovimento      VARCHAR(20)   NOT NULL CHECK (TipoMovimento IN ('Entrada', 'Saida', 'Ajuste', 'Perda')),
  OrigemDestino      VARCHAR(100)  NULL, -- Ex: 'Compra #123', 'Orçamento #456', 'Ajuste Manual'
  Quantidade         DECIMAL(10,4) NOT NULL,
  EstoqueAnterior    DECIMAL(10,4) NOT NULL,
  EstoqueAtual       DECIMAL(10,4) NOT NULL,
  ValorUnitario      DECIMAL(18,2) NULL,
  ValorTotal         DECIMAL(18,2) NULL,
  Observacao         VARCHAR(500)  NULL,
  UsuarioResponsavel VARCHAR(100)  NULL,
  DataMovimento      DATETIME      DEFAULT GETDATE(),
  CONSTRAINT FK_Movimentacao_Material FOREIGN KEY (MaterialId) REFERENCES Materiais(Id)
);
CREATE NONCLUSTERED INDEX IX_MovimentacoesEstoque_MaterialId ON MovimentacoesEstoque(MaterialId);
CREATE NONCLUSTERED INDEX IX_MovimentacoesEstoque_Data       ON MovimentacoesEstoque(DataMovimento);

-- =============================================
-- 7. TABELA DE COMPRAS (Entrada de Materiais)
-- =============================================
CREATE TABLE Compras (
  Id            INTEGER       PRIMARY KEY IDENTITY(1,1),
  FornecedorId  INTEGER       NOT NULL,
  NumeroNota    VARCHAR(50)   NULL,
  ValorTotal    DECIMAL(18,2) DEFAULT 0 NOT NULL,
  DataCompra    DATETIME      DEFAULT GETDATE(),
  DataEntrega   DATETIME      NULL,
  Situacao      VARCHAR(20)   DEFAULT 'Pendente' CHECK (Situacao IN ('Pendente', 'Recebida', 'Cancelada')),
  Observacao    VARCHAR(500)  NULL,
  DataCriacao   DATETIME      DEFAULT GETDATE(),
  DataAlteracao DATETIME      DEFAULT NULL,
  CONSTRAINT FK_Compra_Fornecedor FOREIGN KEY (FornecedorId) REFERENCES Fornecedores(Id)
);
CREATE NONCLUSTERED INDEX IX_Compras_FornecedorId ON Compras(FornecedorId);
CREATE NONCLUSTERED INDEX IX_Compras_DataCompra   ON Compras(DataCompra);

-- =============================================
-- 8. ITENS DA COMPRA
-- =============================================
CREATE TABLE CompraItens (
  Id            INTEGER       PRIMARY KEY IDENTITY(1,1),
  CompraId      INTEGER       NOT NULL,
  MaterialId    INTEGER       NOT NULL,
  Quantidade    DECIMAL(10,4) NOT NULL CHECK (Quantidade > 0),
  ValorUnitario DECIMAL(18,2) NOT NULL CHECK (ValorUnitario >= 0),
  ValorTotal    DECIMAL(18,2) NOT NULL CHECK (ValorTotal >= 0),
  CONSTRAINT FK_CompraItem_Compra   FOREIGN KEY (CompraId)   REFERENCES Compras(Id),
  CONSTRAINT FK_CompraItem_Material FOREIGN KEY (MaterialId) REFERENCES Materiais(Id)
);
CREATE NONCLUSTERED INDEX IX_CompraItens_CompraId   ON CompraItens(CompraId);
CREATE NONCLUSTERED INDEX IX_CompraItens_MaterialId ON CompraItens(MaterialId);

-- =============================================
-- 9. TABELA DE ORÇAMENTOS (Cabeçalho)
-- =============================================
CREATE TABLE Orcamentos (
  Id              INTEGER       PRIMARY KEY IDENTITY(1,1),
  ClienteId       INTEGER       NOT NULL,
  Situacao        VARCHAR(20)   DEFAULT 'Em Aberto' CHECK (Situacao IN ('Em Aberto', 'Aprovado', 'Em Producao', 'Concluido', 'Cancelado')),
  MargemLucro     DECIMAL(5,2)  DEFAULT 0 CHECK (MargemLucro >= 0),
  ValorTotalCusto DECIMAL(18,2) DEFAULT 0,
  ValorFinalVenda DECIMAL(18,2) DEFAULT 0,
  Observacao      VARCHAR(500)  NULL,
  DataAprovacao   DATETIME      NULL,
  Ativo           BIT           DEFAULT 1 NOT NULL,
  DataCriacao     DATETIME      DEFAULT GETDATE(),
  DataAlteracao   DATETIME      DEFAULT NULL,
  CONSTRAINT FK_Orcamento_Cliente FOREIGN KEY (ClienteId) REFERENCES Clientes(Id)
);
CREATE NONCLUSTERED INDEX IX_Orcamentos_ClienteId ON Orcamentos(ClienteId);
CREATE NONCLUSTERED INDEX IX_Orcamentos_Situacao  ON Orcamentos(Situacao);

-- =============================================
-- 10. ITENS DO ORÇAMENTO
-- =============================================
CREATE TABLE OrcamentoItens (
  Id             INTEGER       PRIMARY KEY IDENTITY(1,1),
  OrcamentoId    INTEGER       NOT NULL,
  NomeItem       VARCHAR(100)  NOT NULL,
  Ambiente       VARCHAR(50)   NULL,
  Largura        DECIMAL(10,2) NULL,
  Altura         DECIMAL(10,2) NULL,
  Profundidade   DECIMAL(10,2) NULL,
  ValorCustoItem DECIMAL(18,2) DEFAULT 0,
  CONSTRAINT FK_Item_Orcamento FOREIGN KEY (OrcamentoId) REFERENCES Orcamentos(Id)
);
CREATE NONCLUSTERED INDEX IX_OrcamentoItens_OrcamentoId ON OrcamentoItens(OrcamentoId);

-- =============================================
-- 11. MATERIAIS USADOS NO ITEM (N:N)
-- =============================================
CREATE TABLE OrcamentoItemMateriais (
  Id                  INTEGER       PRIMARY KEY IDENTITY(1,1),
  OrcamentoItemId     INTEGER       NOT NULL,
  MaterialId          INTEGER       NOT NULL,
  Quantidade          DECIMAL(10,4) NOT NULL CHECK (Quantidade > 0),
  PrecoCustoNoMomento DECIMAL(18,2) NOT NULL,
  DataRegistro        DATETIME      DEFAULT GETDATE(),
  CONSTRAINT FK_Consumo_Item     FOREIGN KEY (OrcamentoItemId) REFERENCES OrcamentoItens(Id),
  CONSTRAINT FK_Consumo_Material FOREIGN KEY (MaterialId)      REFERENCES Materiais(Id)
);
CREATE NONCLUSTERED INDEX IX_OrcamentoItemMateriais_OrcamentoItemId ON OrcamentoItemMateriais(OrcamentoItemId);

-- =============================================
-- 12. CONTAS A RECEBER
-- =============================================
CREATE TABLE ContasReceber (
  Id               INTEGER       PRIMARY KEY IDENTITY(1,1),
  OrcamentoId      INTEGER       NOT NULL,
  NumeroParcela    INTEGER       NOT NULL,
  TotalParcelas    INTEGER       NOT NULL,
  ValorParcela     DECIMAL(18,2) NOT NULL CHECK (ValorParcela > 0),
  DataVencimento   DATE          NOT NULL,
  DataPagamento    DATE          NULL,
  ValorPago        DECIMAL(18,2) NULL CHECK (ValorPago >= 0),
  FormaPagamento   VARCHAR(30)   NULL CHECK (FormaPagamento IN ('Dinheiro', 'PIX', 'Debito', 'Credito', 'Boleto', 'Transferencia')),
  Situacao         VARCHAR(20)   DEFAULT 'Aberta' CHECK (Situacao IN ('Aberta', 'Paga', 'Vencida', 'Cancelada')),
  Observacao       VARCHAR(500)  NULL,
  DataCriacao      DATETIME      DEFAULT GETDATE(),
  DataAlteracao    DATETIME      DEFAULT NULL,
  CONSTRAINT FK_ContaReceber_Orcamento FOREIGN KEY (OrcamentoId) REFERENCES Orcamentos(Id)
);
CREATE NONCLUSTERED INDEX IX_ContasReceber_OrcamentoId     ON ContasReceber(OrcamentoId);
CREATE NONCLUSTERED INDEX IX_ContasReceber_DataVencimento  ON ContasReceber(DataVencimento);
CREATE NONCLUSTERED INDEX IX_ContasReceber_Situacao        ON ContasReceber(Situacao);

-- =============================================
-- 13. CONTAS A PAGAR
-- =============================================
CREATE TABLE ContasPagar (
  Id               INTEGER       PRIMARY KEY IDENTITY(1,1),
  FornecedorId     INTEGER       NULL, -- Pode ser NULL para despesas gerais
  CompraId         INTEGER       NULL, -- Vincula com compra de material, se aplicável
  TipoDespesa      VARCHAR(50)   NOT NULL CHECK (TipoDespesa IN ('Compra Material', 'Aluguel', 'Energia', 'Agua', 'Telefone', 'Internet', 'Salario', 'Imposto', 'Manutencao', 'Outros')),
  Descricao        VARCHAR(200)  NOT NULL,
  ValorTotal       DECIMAL(18,2) NOT NULL CHECK (ValorTotal > 0),
  DataVencimento   DATE          NOT NULL,
  DataPagamento    DATE          NULL,
  ValorPago        DECIMAL(18,2) NULL CHECK (ValorPago >= 0),
  FormaPagamento   VARCHAR(30)   NULL CHECK (FormaPagamento IN ('Dinheiro', 'PIX', 'Debito', 'Credito', 'Boleto', 'Transferencia')),
  Situacao         VARCHAR(20)   DEFAULT 'Aberta' CHECK (Situacao IN ('Aberta', 'Paga', 'Vencida', 'Cancelada')),
  Observacao       VARCHAR(500)  NULL,
  DataCriacao      DATETIME      DEFAULT GETDATE(),
  DataAlteracao    DATETIME      DEFAULT NULL,
  CONSTRAINT FK_ContaPagar_Fornecedor FOREIGN KEY (FornecedorId) REFERENCES Fornecedores(Id),
  CONSTRAINT FK_ContaPagar_Compra     FOREIGN KEY (CompraId)     REFERENCES Compras(Id)
);
CREATE NONCLUSTERED INDEX IX_ContasPagar_FornecedorId    ON ContasPagar(FornecedorId);
CREATE NONCLUSTERED INDEX IX_ContasPagar_DataVencimento  ON ContasPagar(DataVencimento);
CREATE NONCLUSTERED INDEX IX_ContasPagar_Situacao        ON ContasPagar(Situacao);

-- =============================================
-- 14. TABELA DE NOTAS FISCAIS (Compras e Vendas)
-- =============================================
CREATE TABLE NotasFiscais (
  Id              INTEGER       PRIMARY KEY IDENTITY(1,1),
  TipoNota        VARCHAR(20)   NOT NULL CHECK (TipoNota IN ('Entrada', 'Saida')), -- Entrada=Compra, Saida=Venda
  CompraId        INTEGER       NULL, -- FK para Compras (quando TipoNota = 'Entrada')
  OrcamentoId     INTEGER       NULL, -- FK para Orcamentos (quando TipoNota = 'Saida')
  NumeroNota      VARCHAR(50)   NULL,
  Serie           VARCHAR(10)   NULL,
  ChaveAcesso     VARCHAR(44)   NULL, -- Chave de acesso NFe (44 dígitos)
  DataEmissao     DATE          NOT NULL,
  ValorTotal      DECIMAL(18,2) NOT NULL CHECK (ValorTotal >= 0),
  NomeArquivo     VARCHAR(255)  NOT NULL,
  CaminhoArquivo  VARCHAR(500)  NOT NULL, -- Caminho relativo ou absoluto do arquivo
  TipoArquivo     VARCHAR(10)   NOT NULL CHECK (TipoArquivo IN ('PDF', 'JPG', 'JPEG', 'PNG')),
  TamanhoBytes    BIGINT        NOT NULL CHECK (TamanhoBytes > 0),
  DataUpload      DATETIME      DEFAULT GETDATE(),
  UsuarioUpload   VARCHAR(100)  NULL,
  Observacao      VARCHAR(500)  NULL,
  Ativo           BIT           DEFAULT 1 NOT NULL,
  DataCriacao     DATETIME      DEFAULT GETDATE(),
  DataAlteracao   DATETIME      DEFAULT NULL,
  CONSTRAINT FK_NotaFiscal_Compra     FOREIGN KEY (CompraId)     REFERENCES Compras(Id),
  CONSTRAINT FK_NotaFiscal_Orcamento  FOREIGN KEY (OrcamentoId)  REFERENCES Orcamentos(Id),
  CONSTRAINT CK_NotaFiscal_Vinculo CHECK (
    (TipoNota = 'Entrada' AND CompraId IS NOT NULL AND OrcamentoId IS NULL) OR
    (TipoNota = 'Saida' AND OrcamentoId IS NOT NULL AND CompraId IS NULL)
  )
);
CREATE NONCLUSTERED INDEX IX_NotasFiscais_CompraId      ON NotasFiscais(CompraId);
CREATE NONCLUSTERED INDEX IX_NotasFiscais_OrcamentoId   ON NotasFiscais(OrcamentoId);
CREATE NONCLUSTERED INDEX IX_NotasFiscais_ChaveAcesso   ON NotasFiscais(ChaveAcesso) WHERE ChaveAcesso IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_NotasFiscais_DataEmissao   ON NotasFiscais(DataEmissao);
GO