CREATE PROCEDURE st_Gerenciar_Material @Acao          CHAR(1)       = 'C', -- 'C', 'U', 'D'
                                       @Id            INTEGER       = NULL,
                                       @Nome          VARCHAR(100)  = NULL,
                                       @Categoria     VARCHAR(50)   = NULL,
                                       @PrecoUnitario DECIMAL(18,2) = NULL,
                                       @UnidadeMedida VARCHAR(10)   = NULL,
                                       @Return_Code   SMALLINT      = 0  OUTPUT, 
                                       @Error         VARCHAR(255) = '' OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    SET @Acao = UPPER(TRIM(@Acao));
    SET @Nome = TRIM(@Nome);
    SET @Categoria = TRIM(@Categoria);
    SET @UnidadeMedida = TRIM(@UnidadeMedida);

    SELECT @Error       = '', 
        @Return_Code = 0;

    IF (ISNULL(@Acao, '') = '') OR (@Acao NOT IN ('C', 'U', 'D'))
    BEGIN
      SELECT @Return_Code = 2, 
          @Error       = 'st_Gerenciar_Material: Ação inválida.';
      RAISERROR(@Error, 16, 1);
    END

    IF (@Acao IN ('C', 'U'))
    BEGIN
      IF (ISNULL(@Nome, '') = '') OR (LEN(@Nome) < 2)
      BEGIN
        SELECT @Return_Code = 2, 
            @Error       = 'st_Gerenciar_Material: Nome do material é obrigatório.';
        RAISERROR(@Error, 16, 1);
      END

      IF (ISNULL(@PrecoUnitario, -1) < 0)
      BEGIN
        SELECT @Return_Code = 2, 
           @Error       = 'st_Gerenciar_Material: O preço não pode ser negativo.';
        RAISERROR(@Error, 16, 1);
      END

      IF (ISNULL(@UnidadeMedida, '') = '')
      BEGIN
        SELECT @Return_Code = 2, 
           @Error       = 'st_Gerenciar_Material: Unidade de Medida (m, m2, un, chapa) é obrigatória.';
        RAISERROR(@Error, 16, 1);
      END
    END

    IF (@Acao IN ('C', 'U'))
    BEGIN
      IF EXISTS (SELECT 1
                 FROM dbo.Materiais WITH(NOLOCK)
                 WHERE Nome      = @Nome
                   AND Categoria = @Categoria -- Permite "Puxador" (Ferragem) e "Puxador" (Outro), mas não 2 Ferragens iguais
                   AND Ativo     = 1
                   AND Id       <> ISNULL(@Id, -1))
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Material: Já existe este Material cadastrado nesta Categoria.';
        RAISERROR(@Error, 16, 1);
      END
    END

    IF (@Acao IN ('U', 'D'))
    BEGIN
      IF (ISNULL(@Id, 0) <= 0) OR NOT EXISTS (SELECT 1
                                              FROM dbo.Materiais WITH(NOLOCK)
                                              WHERE Id = @Id)
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Material: Material não encontrado.';
        RAISERROR(@Error, 16, 1);
      END
    END

    BEGIN TRANSACTION;

    IF (@Acao = 'C')
    BEGIN
      INSERT INTO dbo.Materiais (Nome,
                                 Categoria,
                                 PrecoUnitario,
                                 UnidadeMedida,
                                 Ativo,
                                 DataCriacao,
                                 DataAlteracao)

      VALUES (@Nome,
              @Categoria,
              @PrecoUnitario,
              @UnidadeMedida,
              1,
              GETDATE(),
              NULL);

      SELECT SCOPE_IDENTITY() AS IdGerado;
    END

    IF @Acao = 'U'
    BEGIN
      UPDATE dbo.Materiais
      SET Nome          = @Nome,
          Categoria     = @Categoria,
          PrecoUnitario = @PrecoUnitario,
          UnidadeMedida = @UnidadeMedida,
          DataAlteracao = GETDATE()
      WHERE Id = @Id
        AND (Nome          <> @Nome          OR
             Categoria     <> @Categoria     OR
             PrecoUnitario <> @PrecoUnitario OR
             UnidadeMedida <> @UnidadeMedida);
    END

    IF @Acao = 'D'
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

    SELECT @Error       = @Error,
           @Return_Code = CASE
                            WHEN @Return_Code = 0 THEN 1
                            ELSE 2
                          END; 
  END CATCH

  RETURN;
END