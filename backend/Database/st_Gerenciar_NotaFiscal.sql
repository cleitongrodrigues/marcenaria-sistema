CREATE PROCEDURE st_Gerenciar_NotaFiscal @Acao           CHAR(1)       = 'C', -- 'C'=Criar, 'U'=Atualizar, 'D'=Deletar
                                          @Id             INTEGER       = NULL,
                                          @TipoNota       VARCHAR(20)   = NULL,
                                          @CompraId       INTEGER       = NULL,
                                          @OrcamentoId    INTEGER       = NULL,
                                          @NumeroNota     VARCHAR(50)   = NULL,
                                          @Serie          VARCHAR(10)   = NULL,
                                          @ChaveAcesso    VARCHAR(44)   = NULL,
                                          @DataEmissao    DATE          = NULL,
                                          @ValorTotal     DECIMAL(18,2) = NULL,
                                          @NomeArquivo    VARCHAR(255)  = NULL,
                                          @CaminhoArquivo VARCHAR(500)  = NULL,
                                          @TipoArquivo    VARCHAR(10)   = NULL,
                                          @TamanhoBytes   BIGINT        = NULL,
                                          @UsuarioUpload  VARCHAR(100)  = NULL,
                                          @Observacao     VARCHAR(500)  = NULL,
                                          @Return_Code    SMALLINT      = 0  OUTPUT,
                                          @Error          VARCHAR(255)  = '' OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    SET @Acao           = UPPER(TRIM(@Acao));
    SET @TipoNota       = TRIM(@TipoNota);
    SET @NumeroNota     = TRIM(@NumeroNota);
    SET @Serie          = TRIM(@Serie);
    SET @ChaveAcesso    = TRIM(@ChaveAcesso);
    SET @NomeArquivo    = TRIM(@NomeArquivo);
    SET @CaminhoArquivo = TRIM(@CaminhoArquivo);
    SET @TipoArquivo    = UPPER(TRIM(@TipoArquivo));
    SET @UsuarioUpload  = TRIM(@UsuarioUpload);
    SET @Observacao     = TRIM(@Observacao);

    SELECT @Error       = '',
           @Return_Code = 0;

    IF (@Acao NOT IN ('C', 'U', 'D'))
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_NotaFiscal: Ação inválida. Valores: C=Criar, U=Atualizar, D=Deletar.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao IN ('U', 'D')) AND (ISNULL(@Id, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_NotaFiscal: ID obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao = 'C')
    BEGIN
      IF (@TipoNota NOT IN ('Entrada', 'Saida'))
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_NotaFiscal: Tipo de nota inválido. Valores: Entrada, Saida.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@TipoNota = 'Entrada') AND (ISNULL(@CompraId, 0) <= 0)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_NotaFiscal: CompraId obrigatório para nota de entrada.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@TipoNota = 'Saida') AND (ISNULL(@OrcamentoId, 0) <= 0)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_NotaFiscal: OrcamentoId obrigatório para nota de saída.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@DataEmissao IS NULL)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_NotaFiscal: Data de emissão obrigatória.';
        RAISERROR(@Error, 16, 1);
      END

      IF (ISNULL(@ValorTotal, 0) < 0)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_NotaFiscal: Valor total inválido.';
        RAISERROR(@Error, 16, 1);
      END

      IF (LTRIM(RTRIM(ISNULL(@NomeArquivo, ''))) = '')
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_NotaFiscal: Nome do arquivo obrigatório.';
        RAISERROR(@Error, 16, 1);
      END

      IF (LTRIM(RTRIM(ISNULL(@CaminhoArquivo, ''))) = '')
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_NotaFiscal: Caminho do arquivo obrigatório.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@TipoArquivo NOT IN ('PDF', 'JPG', 'JPEG', 'PNG'))
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_NotaFiscal: Tipo de arquivo inválido. Valores: PDF, JPG, JPEG, PNG.';
        RAISERROR(@Error, 16, 1);
      END

      IF (ISNULL(@TamanhoBytes, 0) <= 0)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_NotaFiscal: Tamanho do arquivo obrigatório.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@TipoNota = 'Entrada')
      BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM dbo.Compras WITH(NOLOCK)
                       WHERE Id = @CompraId)
        BEGIN
          SELECT @Return_Code = 3,
                 @Error       = 'st_Gerenciar_NotaFiscal: Compra não encontrada.';
          RAISERROR(@Error, 16, 1);
        END
      END

      IF (@TipoNota = 'Saida')
      BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM dbo.Orcamentos WITH(NOLOCK)
                       WHERE Id    = @OrcamentoId
                         AND Ativo = 1)
        BEGIN
          SELECT @Return_Code = 3,
                 @Error       = 'st_Gerenciar_NotaFiscal: Orçamento não encontrado.';
          RAISERROR(@Error, 16, 1);
        END
      END

      IF (@ChaveAcesso IS NOT NULL) AND (LEN(@ChaveAcesso) <> 44)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_NotaFiscal: Chave de acesso NFe deve ter 44 dígitos.';
        RAISERROR(@Error, 16, 1);
      END
    END

    IF (@Acao IN ('U', 'D'))
    BEGIN
      IF NOT EXISTS (SELECT 1
                     FROM dbo.NotasFiscais WITH(NOLOCK)
                     WHERE Id    = @Id
                       AND Ativo = 1)
      BEGIN
        SELECT @Return_Code = 3,
               @Error       = 'st_Gerenciar_NotaFiscal: Nota fiscal não encontrada.';
        RAISERROR(@Error, 16, 1);
      END
    END

    BEGIN TRANSACTION;

    IF (@Acao = 'C')
    BEGIN
      INSERT INTO dbo.NotasFiscais (TipoNota,
                                    CompraId,
                                    OrcamentoId,
                                    NumeroNota,
                                    Serie,
                                    ChaveAcesso,
                                    DataEmissao,
                                    ValorTotal,
                                    NomeArquivo,
                                    CaminhoArquivo,
                                    TipoArquivo,
                                    TamanhoBytes,
                                    DataUpload,
                                    UsuarioUpload,
                                    Observacao)
      VALUES (@TipoNota,
              NULLIF(@CompraId, 0),
              NULLIF(@OrcamentoId, 0),
              NULLIF(@NumeroNota, ''),
              NULLIF(@Serie, ''),
              NULLIF(@ChaveAcesso, ''),
              @DataEmissao,
              @ValorTotal,
              @NomeArquivo,
              @CaminhoArquivo,
              @TipoArquivo,
              @TamanhoBytes,
              GETDATE(),
              NULLIF(@UsuarioUpload, ''),
              NULLIF(@Observacao, ''));

      SELECT SCOPE_IDENTITY() AS IdGerado;
    END

    IF (@Acao = 'U')
    BEGIN
      UPDATE dbo.NotasFiscais
      SET NumeroNota    = COALESCE(NULLIF(@NumeroNota, ''), NumeroNota),
          Serie         = COALESCE(NULLIF(@Serie, ''), Serie),
          ChaveAcesso   = COALESCE(NULLIF(@ChaveAcesso, ''), ChaveAcesso),
          DataEmissao   = COALESCE(@DataEmissao, DataEmissao),
          ValorTotal    = COALESCE(@ValorTotal, ValorTotal),
          Observacao    = COALESCE(NULLIF(@Observacao, ''), Observacao),
          DataAlteracao = GETDATE()
      WHERE Id = @Id;
    END

    IF (@Acao = 'D')
    BEGIN
      UPDATE dbo.NotasFiscais
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
