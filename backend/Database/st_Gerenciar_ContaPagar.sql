CREATE PROCEDURE st_Gerenciar_ContaPagar @Acao           CHAR(1)       = 'C', -- 'C'=Criar, 'P'=Pagar, 'X'=Cancelar
                                        @Id             INTEGER       = NULL,
                                        @CompraId       INTEGER       = NULL,
                                        @FornecedorId   INTEGER       = NULL,
                                        @Descricao      VARCHAR(200)  = NULL,
                                        @Valor          DECIMAL(18,2) = NULL,
                                        @DataVencimento DATE          = NULL,
                                        @DataPagamento  DATE          = NULL,
                                        @ValorPago      DECIMAL(18,2) = NULL,
                                        @FormaPagamento VARCHAR(30)   = NULL,
                                        @Observacao     VARCHAR(500)  = NULL,
                                        @Return_Code    SMALLINT      = 0  OUTPUT,
                                        @Error          VARCHAR(255)  = '' OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    SET @Acao           = UPPER(TRIM(@Acao));
    SET @Descricao      = TRIM(@Descricao);
    SET @FormaPagamento = TRIM(@FormaPagamento);
    SET @Observacao     = TRIM(@Observacao);

    SELECT @Error       = '',
           @Return_Code = 0;

    IF (@Acao NOT IN ('C', 'P', 'X'))
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_ContaPagar: Ação inválida. Valores: C=Criar, P=Pagar, X=Cancelar.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao IN ('P', 'X')) AND (ISNULL(@Id, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_ContaPagar: ID obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao = 'C')
    BEGIN
      IF (LTRIM(RTRIM(ISNULL(@Descricao, ''))) = '')
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_ContaPagar: Descrição obrigatória.';
        RAISERROR(@Error, 16, 1);
      END

      IF (ISNULL(@Valor, 0) <= 0)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_ContaPagar: Valor deve ser maior que zero.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@DataVencimento IS NULL)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_ContaPagar: Data de vencimento obrigatória.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@CompraId IS NOT NULL)
      BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM dbo.Compras WITH(NOLOCK)
                       WHERE Id = @CompraId)
        BEGIN
          SELECT @Return_Code = 3,
                 @Error       = 'st_Gerenciar_ContaPagar: Compra não encontrada.';
          RAISERROR(@Error, 16, 1);
        END
      END

      IF (@FornecedorId IS NOT NULL)
      BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM dbo.Fornecedores WITH(NOLOCK)
                       WHERE Id    = @FornecedorId
                         AND Ativo = 1)
        BEGIN
          SELECT @Return_Code = 3,
                 @Error       = 'st_Gerenciar_ContaPagar: Fornecedor não encontrado.';
          RAISERROR(@Error, 16, 1);
        END
      END
    END

    IF (@Acao IN ('P', 'X'))
    BEGIN
      DECLARE @SituacaoAtual VARCHAR(20);

      SELECT @SituacaoAtual = Situacao
      FROM dbo.ContasPagar WITH(NOLOCK)
      WHERE Id = @Id;

      IF (@SituacaoAtual IS NULL)
      BEGIN
        SELECT @Return_Code = 3,
               @Error       = 'st_Gerenciar_ContaPagar: Conta não encontrada.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@Acao = 'P') AND (@SituacaoAtual = 'Paga')
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_ContaPagar: Conta já está paga.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@Acao = 'P') AND (@SituacaoAtual = 'Cancelada')
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_ContaPagar: Conta cancelada não pode ser paga.';
        RAISERROR(@Error, 16, 1);
      END
    END

    IF (@Acao = 'P')
    BEGIN
      IF (ISNULL(@ValorPago, 0) <= 0)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_ContaPagar: Valor pago deve ser maior que zero.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@FormaPagamento NOT IN ('Dinheiro', 'PIX', 'Debito', 'Credito', 'Boleto', 'Transferencia'))
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_ContaPagar: Forma de pagamento inválida.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@DataPagamento IS NULL)
        SET @DataPagamento = CAST(GETDATE() AS DATE);
    END

    BEGIN TRANSACTION;

    IF (@Acao = 'C')
    BEGIN
      INSERT INTO dbo.ContasPagar (CompraId,
                                   FornecedorId,
                                   Descricao,
                                   Valor,
                                   DataVencimento,
                                   FormaPagamento,
                                   Situacao,
                                   Observacao,
                                   DataCriacao)
      VALUES (NULLIF(@CompraId, 0),
              NULLIF(@FornecedorId, 0),
              @Descricao,
              @Valor,
              @DataVencimento,
              NULLIF(@FormaPagamento, ''),
              CASE 
                WHEN @DataVencimento < CAST(GETDATE() AS DATE) THEN 'Vencida'
                ELSE 'Aberta'
              END,
              NULLIF(@Observacao, ''),
              GETDATE());

      SELECT SCOPE_IDENTITY() AS IdGerado;
    END

    IF (@Acao = 'P')
    BEGIN
      UPDATE dbo.ContasPagar
      SET DataPagamento  = @DataPagamento,
          ValorPago      = @ValorPago,
          FormaPagamento = @FormaPagamento,
          Situacao       = 'Paga',
          DataAlteracao  = GETDATE()
      WHERE Id = @Id;
    END

    IF (@Acao = 'X')
    BEGIN
      UPDATE dbo.ContasPagar
      SET Situacao      = 'Cancelada',
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
