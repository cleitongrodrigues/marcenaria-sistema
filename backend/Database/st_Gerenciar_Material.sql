CREATE PROCEDURE st_Gerenciar_Material @Acao              CHAR(1)        = 'C', -- 'C', 'U', 'D'
                                       @Id                INTEGER        = NULL,
                                       @Nome              VARCHAR(100)   = NULL,
                                       @Categoria         VARCHAR(50)    = NULL,
                                       @Descricao         VARCHAR(500)   = NULL,
                                       @PrecoUnitario     DECIMAL(18,2)  = NULL,
                                       @UnidadeMedida     VARCHAR(10)    = NULL,
                                       @QuantidadeEstoque DECIMAL(10,4)  = 0,
                                       @EstoqueMinimo     DECIMAL(10,4)  = NULL,
                                       @EstoqueMaximo     DECIMAL(10,4)  = NULL,
                                       @Localizacao       VARCHAR(50)    = NULL,
                                       @Return_Code       SMALLINT       = 0 OUTPUT,
                                       @Error             VARCHAR(255)   = '' OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    SET @Acao          = UPPER(TRIM(@Acao));
    SET @Nome          = TRIM(@Nome);
    SET @Categoria     = TRIM(@Categoria);
    SET @Descricao     = TRIM(@Descricao);
    SET @UnidadeMedida = TRIM(@UnidadeMedida);
    SET @Localizacao   = TRIM(@Localizacao);

    SELECT @Error       = '',
           @Return_Code = 0;

    IF ISNULL(@Acao, '') NOT IN ('C', 'U', 'D')
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Material: Ação inválida.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao IN ('U', 'D')) AND (ISNULL(@Id, 0) <= 0)
    BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Material: ID obrigatório.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao IN ('C', 'U'))
    BEGIN
      IF (ISNULL(@Nome, '') = '') OR (LEN(@Nome) < 2)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Material: Nome do material obrigatório.';
        RAISERROR(@Error, 16, 1);
      END

      IF (ISNULL(@PrecoUnitario, -1) < 0)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Material: Preço não pode ser negativo.';
        RAISERROR(@Error, 16, 1);
      END

      IF (ISNULL(@UnidadeMedida, '') = '') OR (@UnidadeMedida NOT IN ('m', 'm2', 'm3', 'un', 'chapa', 'pc', 'kg', 'l'))
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Material: Unidade de medida inválida. Valores: m, m2, m3, un, chapa, pc, kg, l.';
        RAISERROR(@Error, 16, 1);
      END

      IF (ISNULL(@QuantidadeEstoque, 0) < 0)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Material: Quantidade em estoque não pode ser negativa.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@EstoqueMinimo IS NOT NULL) AND (@EstoqueMinimo < 0)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Material: Estoque mínimo não pode ser negativo.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@EstoqueMaximo IS NOT NULL) AND (@EstoqueMaximo < 0)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Material: Estoque máximo não pode ser negativo.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@EstoqueMinimo IS NOT NULL) AND (@EstoqueMaximo IS NOT NULL) AND (@EstoqueMinimo > @EstoqueMaximo)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Material: Estoque mínimo não pode ser maior que o máximo.';
        RAISERROR(@Error, 16, 1);
      END
    END

    IF (@Acao IN ('C', 'U'))
    BEGIN
      IF EXISTS (SELECT 1
                 FROM dbo.Materiais WITH(NOLOCK)
                 WHERE Nome      = @Nome
                   AND Categoria = ISNULL(@Categoria, '')
                   AND Ativo     = 1
                   AND Id       <> ISNULL(@Id, -1))
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Material: Material já cadastrado nesta categoria.';
        RAISERROR(@Error, 16, 1);
      END
    END

    IF (@Acao IN ('U', 'D'))
    BEGIN
      IF NOT EXISTS (SELECT 1
                     FROM dbo.Materiais WITH(NOLOCK)
                     WHERE Id    = @Id
                       AND Ativo = 1)
      BEGIN
        SELECT @Return_Code = 3,
               @Error       = 'st_Gerenciar_Material: Material não encontrado.';
        RAISERROR(@Error, 16, 1);
      END
    END

    BEGIN TRANSACTION;

    IF (@Acao = 'C')
    BEGIN
      INSERT INTO dbo.Materiais (Nome,
                                 Categoria,
                                 Descricao,
                                 PrecoUnitario,
                                 UnidadeMedida,
                                 QuantidadeEstoque,
                                 EstoqueMinimo,
                                 EstoqueMaximo,
                                 Localizacao,
                                 Ativo,
                                 DataCriacao,
                                 DataAlteracao)
      VALUES (@Nome,
              NULLIF(@Categoria, ''),
              NULLIF(@Descricao, ''),
              @PrecoUnitario,
              @UnidadeMedida,
              @QuantidadeEstoque,
              @EstoqueMinimo,
              @EstoqueMaximo,
              NULLIF(@Localizacao, ''),
              1,
              GETDATE(),
              NULL);

      SELECT SCOPE_IDENTITY() AS IdGerado;
    END

    IF (@Acao = 'U')
    BEGIN
      UPDATE dbo.Materiais
      SET Nome              = @Nome,
          Categoria         = NULLIF(@Categoria, ''),
          Descricao         = NULLIF(@Descricao, ''),
          PrecoUnitario     = @PrecoUnitario,
          UnidadeMedida     = @UnidadeMedida,
          EstoqueMinimo     = @EstoqueMinimo,
          EstoqueMaximo     = @EstoqueMaximo,
          Localizacao       = NULLIF(@Localizacao, ''),
          DataAlteracao     = GETDATE()
      WHERE Id = @Id;
      -- Nota: QuantidadeEstoque NÃO é alterada aqui, use st_Movimentar_Estoque
    END

    IF (@Acao = 'D')
    BEGIN
      UPDATE dbo.Materiais
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