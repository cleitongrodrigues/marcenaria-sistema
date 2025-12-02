CREATE OR ALTER PROCEDURE st_Gerenciar_Cliente
    @Acao CHAR(1), -- 'C', 'U', 'D'
    @Id INT = NULL,
    -- Dados Pessoais
    @Nome VARCHAR(100) = NULL,
    @CPF VARCHAR(14) = NULL,
    @Telefone VARCHAR(20) = NULL,
    -- Dados de Endereço
    @Logradouro VARCHAR(150) = NULL,
    @Numero VARCHAR(20) = NULL,
    @Bairro VARCHAR(100) = NULL,
    @Cidade VARCHAR(100) = NULL,
    @UF CHAR(2) = NULL,
    @CEP VARCHAR(9) = NULL,
    @Complemento VARCHAR(100) = NULL,
    -- Saída
    @Return_Code SMALLINT = 0 OUTPUT, 
    @Error VARCHAR(1000) = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Limpeza
    SET @Nome = TRIM(@Nome);
    SET @CPF = TRIM(@CPF);
    SET @Telefone = TRIM(@Telefone);
    SET @Logradouro = TRIM(@Logradouro);
    SET @Bairro = TRIM(@Bairro);
    SET @Cidade = TRIM(@Cidade);
    SET @UF = UPPER(TRIM(@UF));

    SELECT @Error = '', @Return_Code = 0;

    -- Validações
    IF ISNULL(@Acao, '') NOT IN ('C', 'U', 'D')
    BEGIN
        SELECT @Return_Code = 2, @Error = 'st_Gerenciar_Cliente: Ação inválida.';
        RAISERROR(@Error, 16, 1);
        RETURN;
    END

    IF (@Acao IN ('C', 'U'))
    BEGIN
        IF (ISNULL(@Nome, '') = '') OR (LEN(@Nome) < 3) OR (ISNULL(@Telefone, '') = '')
        BEGIN
            SELECT @Return_Code = 2, @Error = 'st_Gerenciar_Cliente: Nome e Telefone são obrigatórios.';
            RAISERROR(@Error, 16, 1);
            RETURN;
        END
        IF (ISNULL(@Logradouro, '') = '') OR (ISNULL(@Bairro, '') = '') OR (ISNULL(@Cidade, '') = '')
        BEGIN
            SELECT @Return_Code = 2, @Error = 'st_Gerenciar_Cliente: Endereço incompleto.';
            RAISERROR(@Error, 16, 1);
            RETURN;
        END
        
        -- Validação Duplicidade
        IF (@CPF IS NOT NULL AND @CPF <> '')
        BEGIN
            IF EXISTS (SELECT 1 FROM Clientes WHERE CPF = @CPF AND Ativo = 1 AND Id <> ISNULL(@Id, -1))
            BEGIN
                SELECT @Return_Code = 2, @Error = 'st_Gerenciar_Cliente: CPF já cadastrado.';
                RAISERROR(@Error, 16, 1);
                RETURN;
            END
        END
        ELSE
        BEGIN
            IF EXISTS (SELECT 1 FROM Clientes WHERE Nome = @Nome AND Telefone = @Telefone AND Ativo = 1 AND Id <> ISNULL(@Id, -1))
            BEGIN
                SELECT @Return_Code = 2, @Error = 'st_Gerenciar_Cliente: Cliente duplicado (Nome + Telefone).';
                RAISERROR(@Error, 16, 1);
                RETURN;
            END
        END
    END

    -- Execução
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Acao = 'C'
        BEGIN
            INSERT INTO Clientes (Nome, CPF, Telefone, Ativo, DataCriacao, DataAlteracao)
            VALUES (@Nome, @CPF, @Telefone, 1, GETDATE(), GETDATE());
            
            DECLARE @NovoId INT = SCOPE_IDENTITY();

            INSERT INTO Enderecos (ClienteId, Logradouro, Numero, Bairro, Cidade, UF, CEP, Complemento)
            VALUES (@NovoId, @Logradouro, @Numero, @Bairro, @Cidade, @UF, @CEP, @Complemento);

            SELECT @NovoId AS IdGerado;
        END

        ELSE IF @Acao = 'U'
        BEGIN
            UPDATE Clientes SET Nome = @Nome, CPF = @CPF, Telefone = @Telefone, DataAlteracao = GETDATE() WHERE Id = @Id;

            IF EXISTS (SELECT 1 FROM Enderecos WHERE ClienteId = @Id)
                UPDATE Enderecos SET Logradouro = @Logradouro, Numero = @Numero, Bairro = @Bairro, Cidade = @Cidade, UF = @UF, CEP = @CEP, Complemento = @Complemento, DataAlteracao = GETDATE() WHERE ClienteId = @Id;
            ELSE
                INSERT INTO Enderecos (ClienteId, Logradouro, Numero, Bairro, Cidade, UF, CEP, Complemento) VALUES (@Id, @Logradouro, @Numero, @Bairro, @Cidade, @UF, @CEP, @Complemento);
        END

        ELSE IF @Acao = 'D'
        BEGIN
            UPDATE Clientes SET Ativo = 0, DataAlteracao = GETDATE() WHERE Id = @Id;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT @Return_Code = 1, @Error = 'st_Gerenciar_Cliente: Erro SQL - ' + ERROR_MESSAGE();
        RAISERROR(@Error, 16, 1);
    END CATCH
    RETURN;
END
GO