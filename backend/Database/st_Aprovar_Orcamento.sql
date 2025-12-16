CREATE PROCEDURE st_Aprovar_Orcamento @OrcamentoId        INTEGER      = NULL,
                                      @FormaPagamento     VARCHAR(30)  = 'Dinheiro',
                                      @NumeroParcelas     INTEGER      = 1,
                                      @DataPrimeiraParcela DATE         = NULL,
                                      @UsuarioResponsavel VARCHAR(100) = NULL,
                                      @Return_Code        SMALLINT     = 0  OUTPUT,
                                      @Error              VARCHAR(255) = '' OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    SET @FormaPagamento     = TRIM(@FormaPagamento);
    SET @UsuarioResponsavel = TRIM(@UsuarioResponsavel);

    SELECT @Error       = '',
           @Return_Code = 0;

    IF (ISNULL(@OrcamentoId, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Aprovar_Orcamento: ID do orçamento obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@FormaPagamento NOT IN ('Dinheiro', 'PIX', 'Debito', 'Credito', 'Boleto', 'Transferencia'))
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Aprovar_Orcamento: Forma de pagamento inválida.';
      RAISERROR(@Error, 16, 1);
    END

    IF (ISNULL(@NumeroParcelas, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Aprovar_Orcamento: Número de parcelas deve ser maior que zero.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@DataPrimeiraParcela IS NULL)
      SET @DataPrimeiraParcela = CAST(GETDATE() AS DATE);

    DECLARE @SituacaoAtual VARCHAR(20);
    DECLARE @ValorTotal    DECIMAL(18,2);

    -- Valida se orçamento existe e está ativo
    SELECT @SituacaoAtual = Situacao,
           @ValorTotal    = ValorFinalVenda
    FROM dbo.Orcamentos WITH(NOLOCK)
    WHERE Id    = @OrcamentoId
      AND Ativo = 1;

    IF (@SituacaoAtual IS NULL)
    BEGIN
      SELECT @Return_Code = 3,
             @Error       = 'st_Aprovar_Orcamento: Orçamento não encontrado.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@SituacaoAtual <> 'Em Aberto')
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Aprovar_Orcamento: Orçamento não está em aberto. Situação atual: ' + @SituacaoAtual + '.';
      RAISERROR(@Error, 16, 1);
    END

    BEGIN TRANSACTION;

    -- 1. VALIDAR ESTOQUE DISPONÍVEL
    DECLARE @MaterialId       INTEGER;
    DECLARE @QuantidadeNecessaria DECIMAL(10,4);
    DECLARE @QuantidadeDisponivel DECIMAL(10,4);
    DECLARE @NomeMaterial     VARCHAR(100);

    DECLARE cur_materiais CURSOR FOR
      SELECT M.Id,
             M.Nome,
             SUM(OIM.Quantidade) AS QtdNecessaria,
             M.QuantidadeEstoque
      FROM dbo.OrcamentoItens OI
      INNER JOIN dbo.OrcamentoItemMateriais OIM ON OIM.OrcamentoItemId = OI.Id
      INNER JOIN dbo.Materiais M ON M.Id = OIM.MaterialId
      WHERE OI.OrcamentoId = @OrcamentoId
      GROUP BY M.Id, M.Nome, M.QuantidadeEstoque;

    OPEN cur_materiais;
    FETCH NEXT FROM cur_materiais INTO @MaterialId, @NomeMaterial, @QuantidadeNecessaria, @QuantidadeDisponivel;

    WHILE @@FETCH_STATUS = 0
    BEGIN
      IF (@QuantidadeDisponivel < @QuantidadeNecessaria)
      BEGIN
        CLOSE cur_materiais;
        DEALLOCATE cur_materiais;

        SELECT @Return_Code = 2,
               @Error       = 'st_Aprovar_Orcamento: Estoque insuficiente para ' + @NomeMaterial + 
                              '. Necessário: ' + CAST(@QuantidadeNecessaria AS VARCHAR(20)) + 
                              ', Disponível: ' + CAST(@QuantidadeDisponivel AS VARCHAR(20)) + '.';
        RAISERROR(@Error, 16, 1);
      END

      FETCH NEXT FROM cur_materiais INTO @MaterialId, @NomeMaterial, @QuantidadeNecessaria, @QuantidadeDisponivel;
    END

    CLOSE cur_materiais;
    DEALLOCATE cur_materiais;

    -- 2. BAIXAR ESTOQUE (chamando st_Movimentar_Estoque para cada material)
    DECLARE @ReturnCodeMov SMALLINT;
    DECLARE @ErrorMov      VARCHAR(255);
    DECLARE @OrigemDestino VARCHAR(100);

    SET @OrigemDestino = 'Orçamento #' + CAST(@OrcamentoId AS VARCHAR(10));

    DECLARE cur_baixa CURSOR FOR
      SELECT M.Id,
             SUM(OIM.Quantidade) AS QtdNecessaria
      FROM dbo.OrcamentoItens OI
      INNER JOIN dbo.OrcamentoItemMateriais OIM ON OIM.OrcamentoItemId = OI.Id
      INNER JOIN dbo.Materiais M ON M.Id = OIM.MaterialId
      WHERE OI.OrcamentoId = @OrcamentoId
      GROUP BY M.Id;

    OPEN cur_baixa;
    FETCH NEXT FROM cur_baixa INTO @MaterialId, @QuantidadeNecessaria;

    WHILE @@FETCH_STATUS = 0
    BEGIN
      EXEC st_Movimentar_Estoque 
        @MaterialId         = @MaterialId,
        @TipoMovimento      = 'Saida',
        @Quantidade         = @QuantidadeNecessaria,
        @OrigemDestino      = @OrigemDestino,
        @Observacao         = 'Baixa automática por aprovação de orçamento',
        @UsuarioResponsavel = @UsuarioResponsavel,
        @Return_Code        = @ReturnCodeMov OUTPUT,
        @Error              = @ErrorMov OUTPUT;

      IF (@ReturnCodeMov <> 0)
      BEGIN
        CLOSE cur_baixa;
        DEALLOCATE cur_baixa;
        RAISERROR(@ErrorMov, 16, 1);
      END

      FETCH NEXT FROM cur_baixa INTO @MaterialId, @QuantidadeNecessaria;
    END

    CLOSE cur_baixa;
    DEALLOCATE cur_baixa;

    -- 3. GERAR CONTAS A RECEBER (parcelas)
    DECLARE @ValorParcela     DECIMAL(18,2);
    DECLARE @DataVencimento   DATE;
    DECLARE @Parcela          INTEGER;

    SET @ValorParcela = @ValorTotal / @NumeroParcelas;

    SET @Parcela = 1;
    WHILE (@Parcela <= @NumeroParcelas)
    BEGIN
      SET @DataVencimento = DATEADD(MONTH, @Parcela - 1, @DataPrimeiraParcela);

      INSERT INTO dbo.ContasReceber (OrcamentoId,
                                     NumeroParcela,
                                     TotalParcelas,
                                     ValorParcela,
                                     DataVencimento,
                                     FormaPagamento,
                                     Situacao,
                                     DataCriacao)
      VALUES (@OrcamentoId,
              @Parcela,
              @NumeroParcelas,
              @ValorParcela,
              @DataVencimento,
              @FormaPagamento,
              'Aberta',
              GETDATE());

      SET @Parcela = @Parcela + 1;
    END

    -- 4. ATUALIZAR SITUAÇÃO DO ORÇAMENTO
    UPDATE dbo.Orcamentos
    SET Situacao      = 'Aprovado',
        DataAprovacao = GETDATE(),
        DataAlteracao = GETDATE()
    WHERE Id = @OrcamentoId;

    COMMIT TRANSACTION;

    SELECT @Return_Code = 0,
           @Error       = 'Orçamento aprovado com sucesso. Estoque baixado e parcelas geradas.';
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SELECT @Return_Code = CASE WHEN @Return_Code > 0 THEN @Return_Code ELSE ERROR_NUMBER() END,
           @Error       = COALESCE(NULLIF(@Error, ''), ERROR_MESSAGE());
    RAISERROR(@Error, 16, 1);
  END CATCH

  RETURN;
END
