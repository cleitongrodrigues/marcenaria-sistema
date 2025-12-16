CREATE PROCEDURE st_Gerenciar_Compra @Acao               CHAR(1)      = 'C', -- 'C'=Criar, 'R'=Receber, 'X'=Cancelar
                                     @CompraId           INTEGER      = NULL,
                                     @FornecedorId       INTEGER      = NULL,
                                     @NumeroNota         VARCHAR(50)  = NULL,
                                     @DataCompra         DATETIME     = NULL,
                                     @DataEntrega        DATETIME     = NULL,
                                     @Observacao         VARCHAR(500) = NULL,
                                     @UsuarioResponsavel VARCHAR(100) = NULL,
                                     @Return_Code        SMALLINT     = 0  OUTPUT,
                                     @Error              VARCHAR(255) = '' OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    SET @Acao               = UPPER(TRIM(@Acao));
    SET @NumeroNota         = TRIM(@NumeroNota);
    SET @Observacao         = TRIM(@Observacao);
    SET @UsuarioResponsavel = TRIM(@UsuarioResponsavel);

    SELECT @Error       = '',
           @Return_Code = 0;

    IF (@Acao NOT IN ('C', 'R', 'X'))
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Compra: Ação inválida. Valores: C=Criar, R=Receber, X=Cancelar.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao = 'C') AND (ISNULL(@FornecedorId, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Compra: ID do fornecedor obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao IN ('R', 'X')) AND (ISNULL(@CompraId, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Compra: ID da compra obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@DataCompra IS NULL)
      SET @DataCompra = GETDATE();

    IF (@Acao = 'C')
    BEGIN
      IF NOT EXISTS (SELECT 1
                     FROM dbo.Fornecedores WITH(NOLOCK)
                     WHERE Id    = @FornecedorId
                       AND Ativo = 1)
      BEGIN
        SELECT @Return_Code = 3,
               @Error       = 'st_Gerenciar_Compra: Fornecedor não encontrado.';
        RAISERROR(@Error, 16, 1);
      END
    END

    IF (@Acao IN ('R', 'X'))
    BEGIN
      DECLARE @SituacaoAtual VARCHAR(20);

      SELECT @SituacaoAtual = Situacao
      FROM dbo.Compras WITH(NOLOCK)
      WHERE Id = @CompraId;

      IF (@SituacaoAtual IS NULL)
      BEGIN
        SELECT @Return_Code = 3,
               @Error       = 'st_Gerenciar_Compra: Compra não encontrada.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@Acao = 'R') AND (@SituacaoAtual <> 'Pendente')
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Compra: Compra não está pendente. Situação: ' + @SituacaoAtual + '.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@Acao = 'X') AND (@SituacaoAtual = 'Recebida')
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Compra: Não é possível cancelar compra já recebida.';
        RAISERROR(@Error, 16, 1);
      END
    END

    BEGIN TRANSACTION;

    IF (@Acao = 'C')
    BEGIN
      -- Criar cabeçalho da compra
      INSERT INTO dbo.Compras (FornecedorId,
                               NumeroNota,
                               ValorTotal,
                               DataCompra,
                               DataEntrega,
                               Situacao,
                               Observacao,
                               DataCriacao,
                               DataAlteracao)
      VALUES (@FornecedorId,
              NULLIF(@NumeroNota, ''),
              0, -- Será calculado após inserir itens
              @DataCompra,
              @DataEntrega,
              'Pendente',
              NULLIF(@Observacao, ''),
              GETDATE(),
              NULL);

      SELECT SCOPE_IDENTITY() AS CompraIdGerada;
    END

    IF (@Acao = 'R')
    BEGIN
      -- Receber compra: dar entrada no estoque de todos os itens
      DECLARE @MaterialId    INTEGER;
      DECLARE @Quantidade    DECIMAL(10,4);
      DECLARE @ValorUnitario DECIMAL(18,2);
      DECLARE @OrigemDestino VARCHAR(100);
      DECLARE @ReturnCodeMov SMALLINT;
      DECLARE @ErrorMov      VARCHAR(255);

      SET @OrigemDestino = 'Compra #' + CAST(@CompraId AS VARCHAR(10));

      DECLARE cur_itens CURSOR FOR
        SELECT MaterialId, Quantidade, ValorUnitario
        FROM dbo.CompraItens
        WHERE CompraId = @CompraId;

      OPEN cur_itens;
      FETCH NEXT FROM cur_itens INTO @MaterialId, @Quantidade, @ValorUnitario;

      WHILE @@FETCH_STATUS = 0
      BEGIN
        -- Dar entrada no estoque chamando st_Movimentar_Estoque
        EXEC st_Movimentar_Estoque
          @MaterialId         = @MaterialId,
          @TipoMovimento      = 'Entrada',
          @Quantidade         = @Quantidade,
          @OrigemDestino      = @OrigemDestino,
          @ValorUnitario      = @ValorUnitario,
          @Observacao         = 'Entrada por recebimento de compra',
          @UsuarioResponsavel = @UsuarioResponsavel,
          @Return_Code        = @ReturnCodeMov OUTPUT,
          @Error              = @ErrorMov OUTPUT;

        IF (@ReturnCodeMov <> 0)
        BEGIN
          CLOSE cur_itens;
          DEALLOCATE cur_itens;
          RAISERROR(@ErrorMov, 16, 1);
        END

        FETCH NEXT FROM cur_itens INTO @MaterialId, @Quantidade, @ValorUnitario;
      END

      CLOSE cur_itens;
      DEALLOCATE cur_itens;

      -- Atualizar situação da compra
      UPDATE dbo.Compras
      SET Situacao      = 'Recebida',
          DataEntrega   = ISNULL(@DataEntrega, GETDATE()),
          DataAlteracao = GETDATE()
      WHERE Id = @CompraId;
    END

    IF (@Acao = 'X')
    BEGIN
      -- Cancelar compra
      UPDATE dbo.Compras
      SET Situacao      = 'Cancelada',
          DataAlteracao = GETDATE()
      WHERE Id = @CompraId;
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
