CREATE PROCEDURE st_Calcular_Totais @OrcamentoId  INTEGER      = NULL,
                                    @Return_Code  SMALLINT     = 0  OUTPUT,
                                    @Error        VARCHAR(255) = '' OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    SELECT @Error       = '',
           @Return_Code = 0;

    IF (ISNULL(@OrcamentoId, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Calcular_Totais: ID do orçamento obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF NOT EXISTS (SELECT 1
                   FROM dbo.Orcamentos WITH(NOLOCK)
                   WHERE Id    = @OrcamentoId
                     AND Ativo = 1)
    BEGIN
      SELECT @Return_Code = 3,
             @Error       = 'st_Calcular_Totais: Orçamento não encontrado.';
      RAISERROR(@Error, 16, 1);
    END

    DECLARE @TotalCusto DECIMAL(18,2) = 0.00,
            @Margem     DECIMAL(5,2)  = 0.00;

    BEGIN TRANSACTION;

    UPDATE I
    SET I.ValorCustoItem = ISNULL((SELECT SUM(M.Quantidade * M.PrecoCustoNoMomento)
                                   FROM dbo.OrcamentoItemMateriais M
                                   WHERE M.OrcamentoItemId = I.Id), 0)
    FROM dbo.OrcamentoItens I
    WHERE I.OrcamentoId = @OrcamentoId;

    SELECT @TotalCusto = ISNULL(SUM(ValorCustoItem), 0)
    FROM dbo.OrcamentoItens
    WHERE OrcamentoId = @OrcamentoId;

    SELECT @Margem = MargemLucro
    FROM dbo.Orcamentos
    WHERE Id = @OrcamentoId;

    UPDATE dbo.Orcamentos
    SET ValorTotalCusto = @TotalCusto,
        ValorFinalVenda = @TotalCusto + (@TotalCusto * (ISNULL(@Margem, 0) / 100)),
        DataAlteracao   = GETDATE()
    WHERE Id = @OrcamentoId;

    COMMIT TRANSACTION;

    SELECT @Return_Code = 0,
           @Error       = '';
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SELECT @Return_Code = CASE 
	                        WHEN @Return_Code > 0 THEN @Return_Code 
							ELSE ERROR_NUMBER() 
						  END,
           @Error       = COALESCE(NULLIF(@Error, ''), ERROR_MESSAGE());
    RAISERROR(@Error, 16, 1);
  END CATCH

  RETURN;
END