CREATE PROCEDURE st_Gerenciar_OrcamentoItem @Acao          CHAR(1)       = 'C', -- 'C', 'U', 'D'
                                            @Id            INTEGER       = NULL,
                                            @OrcamentoId   INTEGER       = NULL,
                                            @NomeItem      VARCHAR(100)  = NULL,
                                            @Ambiente      VARCHAR(50)   = NULL,
                                            @Largura       DECIMAL(10,2) = NULL,
                                            @Altura        DECIMAL(10,2) = NULL,
                                            @Profundidade  DECIMAL(10,2) = NULL,
                                            @Return_Code   SMALLINT      = 0  OUTPUT,
                                            @Error         VARCHAR(255)  = '' OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    SET @Acao      = UPPER(TRIM(@Acao));
    SET @NomeItem  = TRIM(@NomeItem);
    SET @Ambiente  = TRIM(@Ambiente);

    SELECT @Error       = '',
           @Return_Code = 0;

    IF (@Acao NOT IN ('C', 'U', 'D'))
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_OrcamentoItem: Ação inválida.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao = 'C') AND (ISNULL(@OrcamentoId, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_OrcamentoItem: ID do orçamento obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao IN ('U', 'D')) AND (ISNULL(@Id, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_OrcamentoItem: ID obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao IN ('C', 'U'))
    BEGIN
      IF (ISNULL(@NomeItem, '') = '') OR (LEN(@NomeItem) < 2)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_OrcamentoItem: Nome do item obrigatório.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@Largura IS NOT NULL) AND (@Largura < 0)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_OrcamentoItem: Largura não pode ser negativa.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@Altura IS NOT NULL) AND (@Altura < 0)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_OrcamentoItem: Altura não pode ser negativa.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@Profundidade IS NOT NULL) AND (@Profundidade < 0)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_OrcamentoItem: Profundidade não pode ser negativa.';
        RAISERROR(@Error, 16, 1);
      END
    END

    IF (@Acao = 'C')
    BEGIN
      IF NOT EXISTS (SELECT 1
                     FROM dbo.Orcamentos WITH(NOLOCK)
                     WHERE Id    = @OrcamentoId
                       AND Ativo = 1)
      BEGIN
        SELECT @Return_Code = 3,
               @Error       = 'st_Gerenciar_OrcamentoItem: Orçamento não encontrado.';
        RAISERROR(@Error, 16, 1);
      END
    END

    IF (@Acao IN ('U', 'D'))
    BEGIN
      IF NOT EXISTS (SELECT 1
                     FROM dbo.OrcamentoItens WITH(NOLOCK)
                     WHERE Id = @Id)
      BEGIN
        SELECT @Return_Code = 3,
               @Error       = 'st_Gerenciar_OrcamentoItem: Item não encontrado.';
        RAISERROR(@Error, 16, 1);
      END
    END

    DECLARE @IdPai INTEGER;

    BEGIN TRANSACTION;

    IF (@Acao = 'C')
    BEGIN
      INSERT INTO dbo.OrcamentoItens (OrcamentoId,
                                      NomeItem,
                                      Ambiente,
                                      Largura,
                                      Altura,
                                      Profundidade,
                                      ValorCustoItem)
      VALUES (@OrcamentoId,
              @NomeItem,
              NULLIF(@Ambiente, ''),
              @Largura,
              @Altura,
              @Profundidade,
              0);

      SELECT SCOPE_IDENTITY() AS IdGerado;
    END

    IF (@Acao = 'U')
    BEGIN
      UPDATE dbo.OrcamentoItens
      SET NomeItem     = @NomeItem,
          Ambiente     = NULLIF(@Ambiente, ''),
          Largura      = @Largura,
          Altura       = @Altura,
          Profundidade = @Profundidade
      WHERE Id = @Id;
    END

    IF (@Acao = 'D')
    BEGIN
      SELECT @IdPai = OrcamentoId
      FROM dbo.OrcamentoItens
      WHERE Id = @Id;

      DELETE FROM dbo.OrcamentoItens WHERE Id = @Id;

      -- Recalcula totais do orçamento
      EXEC st_Calcular_Totais @IdPai;
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