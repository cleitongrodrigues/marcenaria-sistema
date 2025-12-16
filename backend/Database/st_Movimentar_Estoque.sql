CREATE PROCEDURE st_Movimentar_Estoque @MaterialId         INTEGER        = NULL,
                                       @TipoMovimento      VARCHAR(20)    = NULL, -- 'Entrada', 'Saida', 'Ajuste', 'Perda'
                                       @Quantidade         DECIMAL(10,4)  = NULL,
                                       @OrigemDestino      VARCHAR(100)   = NULL,
                                       @ValorUnitario      DECIMAL(18,2)  = NULL,
                                       @Observacao         VARCHAR(500)   = NULL,
                                       @UsuarioResponsavel VARCHAR(100)   = NULL,
                                       @Return_Code        SMALLINT       = 0  OUTPUT,
                                       @Error              VARCHAR(255)   = '' OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    SET @TipoMovimento      = TRIM(@TipoMovimento);
    SET @OrigemDestino      = TRIM(@OrigemDestino);
    SET @Observacao         = TRIM(@Observacao);
    SET @UsuarioResponsavel = TRIM(@UsuarioResponsavel);

    SELECT @Error       = '',
           @Return_Code = 0;

    IF (ISNULL(@MaterialId, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Movimentar_Estoque: ID do material obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@TipoMovimento NOT IN ('Entrada', 'Saida', 'Ajuste', 'Perda'))
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Movimentar_Estoque: Tipo de movimento inválido. Valores: Entrada, Saida, Ajuste, Perda.';
      RAISERROR(@Error, 16, 1);
    END

    IF (ISNULL(@Quantidade, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Movimentar_Estoque: Quantidade deve ser maior que zero.';
      RAISERROR(@Error, 16, 1);
    END

    IF NOT EXISTS (SELECT 1
                   FROM dbo.Materiais WITH(NOLOCK)
                   WHERE Id    = @MaterialId
                     AND Ativo = 1)
    BEGIN
      SELECT @Return_Code = 3,
             @Error       = 'st_Movimentar_Estoque: Material não encontrado.';
      RAISERROR(@Error, 16, 1);
    END

    DECLARE @EstoqueAnterior DECIMAL(10,4);
    DECLARE @EstoqueAtual    DECIMAL(10,4);
    DECLARE @ValorTotal      DECIMAL(18,2);

    BEGIN TRANSACTION;

    -- Captura estoque atual
    SELECT @EstoqueAnterior = QuantidadeEstoque
    FROM dbo.Materiais
    WHERE Id = @MaterialId;

    -- Calcula novo estoque
    IF (@TipoMovimento IN ('Entrada', 'Ajuste'))
    BEGIN
      SET @EstoqueAtual = @EstoqueAnterior + @Quantidade;
    END
    ELSE IF (@TipoMovimento IN ('Saida', 'Perda'))
    BEGIN
      SET @EstoqueAtual = @EstoqueAnterior - @Quantidade;

      -- Validação: não pode ficar negativo
      IF (@EstoqueAtual < 0)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Movimentar_Estoque: Estoque insuficiente. Disponível: ' + 
                              CAST(@EstoqueAnterior AS VARCHAR(20)) + ', Solicitado: ' + 
                              CAST(@Quantidade AS VARCHAR(20)) + '.';
        RAISERROR(@Error, 16, 1);
      END
    END

    -- Calcula valor total
    SET @ValorTotal = ISNULL(@ValorUnitario, 0) * @Quantidade;

    -- Atualiza estoque do material
    UPDATE dbo.Materiais
    SET QuantidadeEstoque = @EstoqueAtual,
        DataAlteracao     = GETDATE()
    WHERE Id = @MaterialId;

    -- Registra movimentação
    INSERT INTO dbo.MovimentacoesEstoque (MaterialId,
                                          TipoMovimento,
                                          OrigemDestino,
                                          Quantidade,
                                          EstoqueAnterior,
                                          EstoqueAtual,
                                          ValorUnitario,
                                          ValorTotal,
                                          Observacao,
                                          UsuarioResponsavel,
                                          DataMovimento)
    VALUES (@MaterialId,
            @TipoMovimento,
            NULLIF(@OrigemDestino, ''),
            @Quantidade,
            @EstoqueAnterior,
            @EstoqueAtual,
            @ValorUnitario,
            @ValorTotal,
            NULLIF(@Observacao, ''),
            NULLIF(@UsuarioResponsavel, ''),
            GETDATE());

    COMMIT TRANSACTION;

    -- Retorna informações da movimentação
    SELECT SCOPE_IDENTITY() AS IdMovimentacao,
           @EstoqueAtual    AS EstoqueAtual;

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
