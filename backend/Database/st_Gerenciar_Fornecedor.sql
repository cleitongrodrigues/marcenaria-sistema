CREATE PROCEDURE st_Gerenciar_Fornecedor @Acao              CHAR(1)      = 'C', -- 'C', 'U', 'D'
                                         @Id                INTEGER      = NULL,
                                         @TipoPessoa        CHAR(1)      = 'F', -- 'F'=Física, 'J'=Jurídica
                                         @Nome              VARCHAR(100) = NULL,
                                         @NomeFantasia      VARCHAR(100) = NULL,
                                         @CPF               VARCHAR(11)  = NULL,
                                         @CNPJ              VARCHAR(14)  = NULL,
                                         @InscricaoEstadual VARCHAR(20)  = NULL,
                                         @Email             VARCHAR(100) = NULL,
                                         @Telefone          VARCHAR(20)  = NULL,
                                         @Logradouro        VARCHAR(150) = NULL,
                                         @Numero            VARCHAR(10)  = NULL,
                                         @Bairro            VARCHAR(100) = NULL,
                                         @Cidade            VARCHAR(100) = NULL,
                                         @UF                CHAR(2)      = NULL,
                                         @CEP               VARCHAR(8)   = NULL,
                                         @Complemento       VARCHAR(100) = NULL,
                                         @Observacao        VARCHAR(500) = NULL,
                                         @Return_Code       SMALLINT     = 0  OUTPUT,
                                         @Error             VARCHAR(255) = '' OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    SET @Acao              = UPPER(TRIM(@Acao));
    SET @TipoPessoa        = UPPER(TRIM(@TipoPessoa));
    SET @Nome              = TRIM(@Nome);
    SET @NomeFantasia      = TRIM(@NomeFantasia);
    SET @CPF               = REPLACE(REPLACE(@CPF, '.', ''), '-', '');
    SET @CNPJ              = REPLACE(REPLACE(REPLACE(@CNPJ, '.', ''), '/', ''), '-', '');
    SET @InscricaoEstadual = TRIM(@InscricaoEstadual);
    SET @Email             = TRIM(@Email);
    SET @Telefone          = TRIM(@Telefone);
    SET @Logradouro        = TRIM(@Logradouro);
    SET @Numero            = TRIM(@Numero);
    SET @Bairro            = TRIM(@Bairro);
    SET @Cidade            = TRIM(@Cidade);
    SET @UF                = UPPER(TRIM(@UF));
    SET @CEP               = REPLACE(@CEP, '-', '');
    SET @Complemento       = TRIM(@Complemento);
    SET @Observacao        = TRIM(@Observacao);

    SELECT @Error       = '',
           @Return_Code = 0;

    IF ISNULL(@Acao, '') NOT IN ('C', 'U', 'D')
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Fornecedor: Ação inválida.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao IN ('U', 'D')) AND (ISNULL(@Id, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Fornecedor: ID obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao IN ('U', 'D'))
    BEGIN
      IF NOT EXISTS (SELECT 1
                     FROM dbo.Fornecedores WITH(NOLOCK)
                     WHERE Id    = @Id
                       AND Ativo = 1)
      BEGIN
        SELECT @Return_Code = 3,
               @Error       = 'st_Gerenciar_Fornecedor: Fornecedor não encontrado.';
        RAISERROR(@Error, 16, 1);
      END
    END

    IF (@Acao IN ('C', 'U'))
    BEGIN
      IF (@TipoPessoa NOT IN ('F', 'J'))
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Fornecedor: Tipo de pessoa inválido. Valores: F=Física, J=Jurídica.';
        RAISERROR(@Error, 16, 1);
      END

      IF (ISNULL(@Nome, '') = '') OR (LEN(@Nome) < 3)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Fornecedor: Nome obrigatório (mínimo 3 caracteres).';
        RAISERROR(@Error, 16, 1);
      END

      IF (ISNULL(@Telefone, '') = '')
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Fornecedor: Telefone obrigatório.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@TipoPessoa = 'F')
      BEGIN
        IF (ISNULL(@CPF, '') = '') OR (LEN(@CPF) <> 11) OR (@CPF NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
        BEGIN
          SELECT @Return_Code = 2,
                 @Error       = 'st_Gerenciar_Fornecedor: CPF inválido. Deve conter 11 dígitos numéricos.';
          RAISERROR(@Error, 16, 1);
        END

        IF EXISTS (SELECT 1
                   FROM dbo.Fornecedores WITH(NOLOCK)
                   WHERE CPF   = @CPF
                     AND Ativo = 1
                     AND Id   <> ISNULL(@Id, -1))
        BEGIN
          SELECT @Return_Code = 2,
                 @Error       = 'st_Gerenciar_Fornecedor: CPF já cadastrado.';
          RAISERROR(@Error, 16, 1);
        END
      END

      IF (@TipoPessoa = 'J')
      BEGIN
        IF (ISNULL(@CNPJ, '') = '') OR (LEN(@CNPJ) <> 14) OR (@CNPJ NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
        BEGIN
          SELECT @Return_Code = 2,
                 @Error       = 'st_Gerenciar_Fornecedor: CNPJ inválido. Deve conter 14 dígitos numéricos.';
          RAISERROR(@Error, 16, 1);
        END

        IF EXISTS (SELECT 1
                   FROM dbo.Fornecedores WITH(NOLOCK)
                   WHERE CNPJ  = @CNPJ
                     AND Ativo = 1
                     AND Id   <> ISNULL(@Id, -1))
        BEGIN
          SELECT @Return_Code = 2,
                 @Error       = 'st_Gerenciar_Fornecedor: CNPJ já cadastrado.';
          RAISERROR(@Error, 16, 1);
        END
      END

      IF (@Email IS NOT NULL) AND (@Email NOT LIKE '%_@__%.__%')
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Fornecedor: E-mail inválido.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@UF IS NOT NULL) AND (@UF NOT IN ('AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'))
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Fornecedor: UF inválida.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@CEP IS NOT NULL) AND (LEN(@CEP) <> 8 OR @CEP NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Fornecedor: CEP inválido. Deve conter 8 dígitos.';
        RAISERROR(@Error, 16, 1);
      END
    END

    BEGIN TRANSACTION;

    IF (@Acao = 'C')
    BEGIN
      INSERT INTO dbo.Fornecedores (TipoPessoa,
                                    Nome,
                                    NomeFantasia,
                                    CPF,
                                    CNPJ,
                                    InscricaoEstadual,
                                    Email,
                                    Telefone,
                                    Logradouro,
                                    Numero,
                                    Bairro,
                                    Cidade,
                                    UF,
                                    CEP,
                                    Complemento,
                                    Observacao,
                                    Ativo,
                                    DataCriacao,
                                    DataAlteracao)
      VALUES (@TipoPessoa,
              @Nome,
              NULLIF(@NomeFantasia, ''),
              CASE WHEN @TipoPessoa = 'F' THEN @CPF ELSE NULL END,
              CASE WHEN @TipoPessoa = 'J' THEN @CNPJ ELSE NULL END,
              NULLIF(@InscricaoEstadual, ''),
              NULLIF(@Email, ''),
              @Telefone,
              NULLIF(@Logradouro, ''),
              NULLIF(@Numero, ''),
              NULLIF(@Bairro, ''),
              NULLIF(@Cidade, ''),
              NULLIF(@UF, ''),
              NULLIF(@CEP, ''),
              NULLIF(@Complemento, ''),
              NULLIF(@Observacao, ''),
              1,
              GETDATE(),
              NULL);

      SELECT SCOPE_IDENTITY() AS IdGerado;
    END

    IF (@Acao = 'U')
    BEGIN
      UPDATE dbo.Fornecedores
      SET TipoPessoa        = @TipoPessoa,
          Nome              = @Nome,
          NomeFantasia      = NULLIF(@NomeFantasia, ''),
          CPF               = CASE WHEN @TipoPessoa = 'F' THEN @CPF ELSE NULL END,
          CNPJ              = CASE WHEN @TipoPessoa = 'J' THEN @CNPJ ELSE NULL END,
          InscricaoEstadual = NULLIF(@InscricaoEstadual, ''),
          Email             = NULLIF(@Email, ''),
          Telefone          = @Telefone,
          Logradouro        = NULLIF(@Logradouro, ''),
          Numero            = NULLIF(@Numero, ''),
          Bairro            = NULLIF(@Bairro, ''),
          Cidade            = NULLIF(@Cidade, ''),
          UF                = NULLIF(@UF, ''),
          CEP               = NULLIF(@CEP, ''),
          Complemento       = NULLIF(@Complemento, ''),
          Observacao        = NULLIF(@Observacao, ''),
          DataAlteracao     = GETDATE()
      WHERE Id = @Id;
    END

    IF (@Acao = 'D')
    BEGIN
      UPDATE dbo.Fornecedores
      SET Ativo         = 0,
          DataAlteracao = GETDATE()
      WHERE Id = @Id;
    END

    COMMIT TRANSACTION;

    SELECT @Return_Code = 0,
           @Error       = '';
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SELECT @Return_Code = CASE WHEN @Return_Code > 0 THEN @Return_Code ELSE ERROR_NUMBER() END,
           @Error       = COALESCE(NULLIF(@Error, ''), ERROR_MESSAGE());
    RAISERROR(@Error, 16, 1);
  END CATCH

  RETURN;
END
