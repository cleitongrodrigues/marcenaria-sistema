CREATE PROCEDURE st_Gerenciar_Endereco @Acao        CHAR(1)      = 'C', -- 'C', 'U', 'D'
                                       @Id          INTEGER      = NULL,
                                       @ClienteId   INTEGER      = NULL,
                                       @Tipo        VARCHAR(20)  = NULL,
                                       @Logradouro  VARCHAR(150) = NULL,
                                       @Numero      VARCHAR(10)  = NULL,
                                       @Bairro      VARCHAR(100) = NULL,
                                       @Cidade      VARCHAR(100) = NULL,
                                       @UF          CHAR(2)      = NULL,
                                       @CEP         VARCHAR(8)   = NULL,
                                       @Complemento VARCHAR(100) = NULL,
                                       @Principal   BIT          = 0,
                                       @Return_Code SMALLINT     = 0  OUTPUT,
                                       @Error       VARCHAR(255) = '' OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    SET @Acao        = UPPER(TRIM(@Acao));
    SET @Tipo        = TRIM(@Tipo);
    SET @Logradouro  = TRIM(@Logradouro);
    SET @Numero      = TRIM(@Numero);
    SET @Bairro      = TRIM(@Bairro);
    SET @Cidade      = TRIM(@Cidade);
    SET @UF          = UPPER(TRIM(@UF));
    SET @CEP         = REPLACE(@CEP, '-', '');
    SET @Complemento = TRIM(@Complemento);

    SELECT @Error       = '',
           @Return_Code = 0;

    IF ISNULL(@Acao, '') NOT IN ('C', 'U', 'D')
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Endereco: Ação inválida.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao = 'C') AND (ISNULL(@ClienteId, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Endereco: ID do cliente obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao IN ('U', 'D')) AND (ISNULL(@Id, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Endereco: ID obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao IN ('C', 'U'))
    BEGIN
      IF (@Tipo NOT IN ('Residencial', 'Comercial', 'Cobrança', 'Entrega'))
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Endereco: Tipo inválido. Valores: Residencial, Comercial, Cobrança, Entrega.';
        RAISERROR(@Error, 16, 1);
      END

      IF (ISNULL(@Logradouro, '') = '') OR (ISNULL(@Numero, '') = '') OR
         (ISNULL(@Bairro, '') = '') OR (ISNULL(@Cidade, '') = '') OR
         (ISNULL(@UF, '') = '') OR (ISNULL(@CEP, '') = '')
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Endereco: Endereço incompleto (Logradouro, Número, Bairro, Cidade, UF, CEP obrigatórios).';
        RAISERROR(@Error, 16, 1);
      END

      IF (@UF NOT IN ('AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'))
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Endereco: UF inválida.';
        RAISERROR(@Error, 16, 1);
      END

      IF (LEN(@CEP) <> 8 OR @CEP NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Endereco: CEP inválido. Deve conter 8 dígitos.';
        RAISERROR(@Error, 16, 1);
      END
    END

    IF (@Acao = 'C')
    BEGIN
      IF NOT EXISTS (SELECT 1
                     FROM dbo.Clientes WITH(NOLOCK)
                     WHERE Id    = @ClienteId
                       AND Ativo = 1)
      BEGIN
        SELECT @Return_Code = 3,
               @Error       = 'st_Gerenciar_Endereco: Cliente não encontrado.';
        RAISERROR(@Error, 16, 1);
      END
    END

    IF (@Acao IN ('U', 'D'))
    BEGIN
      IF NOT EXISTS (SELECT 1
                     FROM dbo.Enderecos WITH(NOLOCK)
                     WHERE Id = @Id)
      BEGIN
        SELECT @Return_Code = 3,
               @Error       = 'st_Gerenciar_Endereco: Endereço não encontrado.';
        RAISERROR(@Error, 16, 1);
      END
    END

    BEGIN TRANSACTION;

    IF (@Acao = 'C')
    BEGIN
      -- Se marcar como principal, remove o principal anterior
      IF (@Principal = 1)
      BEGIN
        UPDATE dbo.Enderecos
        SET Principal = 0
        WHERE ClienteId = @ClienteId;
      END

      INSERT INTO dbo.Enderecos (ClienteId,
                                 Tipo,
                                 Logradouro,
                                 Numero,
                                 Bairro,
                                 Cidade,
                                 UF,
                                 CEP,
                                 Complemento,
                                 Principal,
                                 DataCriacao,
                                 DataAlteracao)
      VALUES (@ClienteId,
              @Tipo,
              @Logradouro,
              @Numero,
              @Bairro,
              @Cidade,
              @UF,
              @CEP,
              NULLIF(@Complemento, ''),
              @Principal,
              GETDATE(),
              NULL);

      SELECT SCOPE_IDENTITY() AS IdGerado;
    END

    IF (@Acao = 'U')
    BEGIN
      DECLARE @ClienteIdExistente INTEGER;

      SELECT @ClienteIdExistente = ClienteId
      FROM dbo.Enderecos
      WHERE Id = @Id;

      -- Se marcar como principal, remove o principal anterior
      IF (@Principal = 1)
      BEGIN
        UPDATE dbo.Enderecos
        SET Principal = 0
        WHERE ClienteId = @ClienteIdExistente
          AND Id       <> @Id;
      END

      UPDATE dbo.Enderecos
      SET Tipo          = @Tipo,
          Logradouro    = @Logradouro,
          Numero        = @Numero,
          Bairro        = @Bairro,
          Cidade        = @Cidade,
          UF            = @UF,
          CEP           = @CEP,
          Complemento   = NULLIF(@Complemento, ''),
          Principal     = @Principal,
          DataAlteracao = GETDATE()
      WHERE Id = @Id;
    END

    IF (@Acao = 'D')
    BEGIN
      DELETE FROM dbo.Enderecos WHERE Id = @Id;
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
