CREATE PROCEDURE st_Gerenciar_OrcamentoMaterial @Acao             CHAR(1)        = 'C', -- 'C', 'U', 'D'
                                                 @Id               INTEGER        = NULL,
                                                 @OrcamentoItemId  INTEGER        = NULL,
                                                 @MaterialId       INTEGER        = NULL,
                                                 @Quantidade       DECIMAL(10,4)  = NULL,
                                                 @Return_Code      SMALLINT       = 0  OUTPUT,
                                                 @Error            VARCHAR(255)   = '' OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    SET @Acao = UPPER(TRIM(@Acao));

    SELECT @Error       = '',
           @Return_Code = 0;

    IF (@Acao NOT IN ('C', 'U', 'D'))
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_OrcamentoMaterial: Ação inválida.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao = 'C') AND (ISNULL(@OrcamentoItemId, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_OrcamentoMaterial: ID do item obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao = 'C') AND (ISNULL(@MaterialId, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_OrcamentoMaterial: ID do material obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao IN ('U', 'D')) AND (ISNULL(@Id, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_OrcamentoMaterial: ID obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao IN ('C', 'U'))
    BEGIN
      IF (ISNULL(@Quantidade, 0) <= 0)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_OrcamentoMaterial: Quantidade deve ser maior que zero.';
        RAISERROR(@Error, 16, 1);
      END
    END

    IF (@Acao = 'C')
    BEGIN
      IF NOT EXISTS (SELECT 1
                     FROM dbo.OrcamentoItens WITH(NOLOCK)
                     WHERE Id = @OrcamentoItemId)
      BEGIN
        SELECT @Return_Code = 3,
               @Error       = 'st_Gerenciar_OrcamentoMaterial: Item do orçamento não encontrado.';
        RAISERROR(@Error, 16, 1);
      END

      IF NOT EXISTS (SELECT 1
                     FROM dbo.Materiais WITH(NOLOCK)
                     WHERE Id    = @MaterialId
                       AND Ativo = 1)
      BEGIN
        SELECT @Return_Code = 3,
               @Error       = 'st_Gerenciar_OrcamentoMaterial: Material não encontrado.';
        RAISERROR(@Error, 16, 1);
      END
    END

    IF (@Acao IN ('U', 'D'))
    BEGIN
      IF NOT EXISTS (SELECT 1
                     FROM dbo.OrcamentoItemMateriais WITH(NOLOCK)
                     WHERE Id = @Id)
      BEGIN
        SELECT @Return_Code = 3,
               @Error       = 'st_Gerenciar_OrcamentoMaterial: Registro não encontrado.';
        RAISERROR(@Error, 16, 1);
      END
    END

    DECLARE @OrcamentoPrincipalId INTEGER;
    DECLARE @PrecoAtual           DECIMAL(18,2);

    BEGIN TRANSACTION;

    IF (@Acao = 'C')
    BEGIN
      -- Busca o preço ATUAL do material e congela no momento do orçamento
      SELECT @PrecoAtual = PrecoUnitario
      FROM dbo.Materiais
      WHERE Id = @MaterialId;

      INSERT INTO dbo.OrcamentoItemMateriais (OrcamentoItemId,
                                              MaterialId,
                                              Quantidade,
                                              PrecoCustoNoMomento,
                                              DataRegistro)
      VALUES (@OrcamentoItemId,
              @MaterialId,
              @Quantidade,
              @PrecoAtual,
              GETDATE());

      SELECT SCOPE_IDENTITY() AS IdGerado;

      -- Descobre o Orçamento principal para recalcular totais
      SELECT @OrcamentoPrincipalId = OrcamentoId
      FROM dbo.OrcamentoItens
      WHERE Id = @OrcamentoItemId;
    END

    IF (@Acao = 'U')
    BEGIN
      UPDATE dbo.OrcamentoItemMateriais
      SET Quantidade = @Quantidade
      WHERE Id = @Id;

      -- Descobre o Orçamento principal para recalcular totais
      SELECT @OrcamentoPrincipalId = I.OrcamentoId
      FROM dbo.OrcamentoItens I
      INNER JOIN dbo.OrcamentoItemMateriais M ON M.OrcamentoItemId = I.Id
      WHERE M.Id = @Id;
    END

    IF (@Acao = 'D')
    BEGIN
      -- Descobre o Orçamento principal antes de deletar
      SELECT @OrcamentoPrincipalId = I.OrcamentoId
      FROM dbo.OrcamentoItens I
      INNER JOIN dbo.OrcamentoItemMateriais M ON M.OrcamentoItemId = I.Id
      WHERE M.Id = @Id;

      DELETE FROM dbo.OrcamentoItemMateriais WHERE Id = @Id;
    END

    -- Recalcula totais automaticamente
    IF (@OrcamentoPrincipalId IS NOT NULL)
    BEGIN
      EXEC st_Calcular_Totais @OrcamentoPrincipalId;
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