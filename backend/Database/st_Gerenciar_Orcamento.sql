CREATE PROCEDURE st_Gerenciar_Orcamento @Acao        CHAR(1)       = 'C', -- 'C', 'U', 'D'
                                        @Id          INTEGER       = NULL,
                                        @ClienteId   INTEGER       = NULL,
                                        @MargemLucro DECIMAL(5,2)  = NULL,
                                        @Observacao  VARCHAR(1024) = NULL,
                                        @Situacao    VARCHAR(20)   = NULL, -- 'Em Aberto', 'Aprovado'
                                        @Return_Code SMALLINT      = 0  OUTPUT,
                                        @Error       VARCHAR(255)  = '' OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    SET @Acao       = UPPER(TRIM(@Acao));
    SET @Observacao = TRIM(@Observacao);
    SET @Situacao   = TRIM(@Situacao);

    SELECT @Error       = '',
           @Return_Code = 0;

    IF (@Acao NOT IN ('C', 'U', 'D'))
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Orcamento: Ação inválida.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao = 'C') AND (ISNULL(@ClienteId, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Orcamento: Cliente obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao IN ('U', 'D')) AND (ISNULL(@Id, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Orcamento: ID obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Situacao IS NOT NULL) AND (@Situacao NOT IN ('Em Aberto', 'Aprovado'))
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Orcamento: Situação inválida. Valores permitidos: Em Aberto, Aprovado.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@MargemLucro IS NOT NULL) AND (@MargemLucro < 0 OR @MargemLucro > 100)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Orcamento: Margem de lucro deve estar entre 0 e 100.';
      RAISERROR(@Error, 16, 1);
    END

    BEGIN TRANSACTION;

    IF (@Acao = 'C')
    BEGIN
	  IF NOT EXISTS (SELECT 1
	                 FROM dbo.Clientes
					 WHERE ID = @ClienteId)
	  BEGIN
	    SELECT @Return_Code = 3,
               @Error       = 'st_Gerenciar_Orcamento: Cliente não encontrado.';
        RAISERROR(@Error, 16, 1);
	  END

      INSERT INTO dbo.Orcamentos (ClienteId,
                                  Situacao,
                                  MargemLucro,
                                  ValorTotalCusto,
                                  ValorFinalVenda,
                                  Observacao,
                                  Ativo,
                                  DataCriacao,
                                  DataAlteracao)
      VALUES (@ClienteId,
              'Em Aberto',
              ISNULL(@MargemLucro, 50),
              0,
              0,
              NULLIF(@Observacao, ''),
              1,
              GETDATE(),
              NULL);

      SELECT SCOPE_IDENTITY() AS IdGerado;
    END

    IF @Acao = 'U'
    BEGIN
	  IF NOT EXISTS (SELECT 1
	                 FROM dbo.Orcamentos
					 WHERE ID    = @Id
					   AND Ativo = 1)
	  BEGIN
	    SELECT @Return_Code = 3,
               @Error       = 'st_Gerenciar_Orcamento: Orçamento não encontrado.';
        RAISERROR(@Error, 16, 1);
	  END

      UPDATE dbo.Orcamentos
      SET MargemLucro   = ISNULL(@MargemLucro, MargemLucro),
          Observacao    = ISNULL(NULLIF(@Observacao, ''), Observacao),
          Situacao      = ISNULL(@Situacao, Situacao),
          DataAlteracao = GETDATE()
      WHERE Id = @Id;

      EXEC st_Calcular_Totais @Id;
    END

    IF @Acao = 'D'
    BEGIN
	  IF NOT EXISTS (SELECT 1
	                 FROM dbo.Orcamentos
					 WHERE ID    = @Id
					   AND Ativo = 1)
	  BEGIN
	    SELECT @Return_Code = 3,
               @Error       = 'st_Gerenciar_Orcamento: Orçamento não encontrado.';
        RAISERROR(@Error, 16, 1);
	  END

      UPDATE Orcamentos
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