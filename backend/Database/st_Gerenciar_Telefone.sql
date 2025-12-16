CREATE PROCEDURE st_Gerenciar_Telefone @Acao        CHAR(1)     = 'C', -- 'C', 'U', 'D'
                                       @Id          INTEGER     = NULL,
                                       @ClienteId   INTEGER     = NULL,
                                       @Tipo        VARCHAR(20) = NULL,
                                       @Numero      VARCHAR(20) = NULL,
                                       @Principal   BIT         = 0,
                                       @Return_Code SMALLINT    = 0  OUTPUT,
                                       @Error       VARCHAR(255) = '' OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    SET @Acao   = UPPER(TRIM(@Acao));
    SET @Tipo   = TRIM(@Tipo);
    SET @Numero = TRIM(@Numero);

    SELECT @Error       = '',
           @Return_Code = 0;

    IF ISNULL(@Acao, '') NOT IN ('C', 'U', 'D')
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Telefone: Ação inválida.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao = 'C') AND (ISNULL(@ClienteId, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Telefone: ID do cliente obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao IN ('U', 'D')) AND (ISNULL(@Id, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Telefone: ID obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao IN ('C', 'U'))
    BEGIN
      IF (ISNULL(@Numero, '') = '')
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Telefone: Número obrigatório.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@Tipo NOT IN ('Celular', 'Comercial', 'Residencial', 'WhatsApp'))
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Telefone: Tipo inválido. Valores: Celular, Comercial, Residencial, WhatsApp.';
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
               @Error       = 'st_Gerenciar_Telefone: Cliente não encontrado.';
        RAISERROR(@Error, 16, 1);
      END
    END

    IF (@Acao IN ('U', 'D'))
    BEGIN
      IF NOT EXISTS (SELECT 1
                     FROM dbo.Telefones WITH(NOLOCK)
                     WHERE Id = @Id)
      BEGIN
        SELECT @Return_Code = 3,
               @Error       = 'st_Gerenciar_Telefone: Telefone não encontrado.';
        RAISERROR(@Error, 16, 1);
      END
    END

    BEGIN TRANSACTION;

    IF (@Acao = 'C')
    BEGIN
      -- Se marcar como principal, remove o principal anterior
      IF (@Principal = 1)
      BEGIN
        UPDATE dbo.Telefones
        SET Principal = 0
        WHERE ClienteId = @ClienteId;
      END

      INSERT INTO dbo.Telefones (ClienteId,
                                 Tipo,
                                 Numero,
                                 Principal,
                                 DataCriacao,
                                 DataAlteracao)
      VALUES (@ClienteId,
              @Tipo,
              @Numero,
              @Principal,
              GETDATE(),
              NULL);

      SELECT SCOPE_IDENTITY() AS IdGerado;
    END

    IF (@Acao = 'U')
    BEGIN
      DECLARE @ClienteIdExistente INTEGER;

      SELECT @ClienteIdExistente = ClienteId
      FROM dbo.Telefones
      WHERE Id = @Id;

      -- Se marcar como principal, remove o principal anterior
      IF (@Principal = 1)
      BEGIN
        UPDATE dbo.Telefones
        SET Principal = 0
        WHERE ClienteId = @ClienteIdExistente
          AND Id       <> @Id;
      END

      UPDATE dbo.Telefones
      SET Tipo          = @Tipo,
          Numero        = @Numero,
          Principal     = @Principal,
          DataAlteracao = GETDATE()
      WHERE Id = @Id;
    END

    IF (@Acao = 'D')
    BEGIN
      DELETE FROM dbo.Telefones WHERE Id = @Id;
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
