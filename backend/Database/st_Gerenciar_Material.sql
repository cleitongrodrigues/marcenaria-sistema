CREATE OR ALTER PROCEDURE st_Gerenciar_Material
    @Acao CHAR(1), -- 'C', 'U', 'D'
    @Id INT = NULL,
    @Nome VARCHAR(100) = NULL,
    @Categoria VARCHAR(50) = NULL,
    @PrecoUnitario DECIMAL(18,2) = NULL,
    @UnidadeMedida VARCHAR(10) = NULL,
    -- Saída
    @Return_Code SMALLINT = 0 OUTPUT, 
    @Error VARCHAR(1000) = '' OUTPUT
AS
BEGIN
    -- 1. CONFIGURAÇÕES
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 2. HIGIENE (TRIM)
    SET @Nome = TRIM(@Nome);
    SET @Categoria = TRIM(@Categoria);
    SET @UnidadeMedida = TRIM(@UnidadeMedida);

    SELECT @Error = '', @Return_Code = 0;

    -- =========================================================================
    -- 3. VALIDAÇÕES (FAIL FAST)
    -- =========================================================================

    IF ISNULL(@Acao, '') NOT IN ('C', 'U', 'D')
    BEGIN
        SELECT @Return_Code = 2, @Error = 'st_Gerenciar_Material: Ação inválida.';
        RAISERROR(@Error, 16, 1);
        RETURN;
    END

    -- Validação de Campos Obrigatórios (C/U)
    IF (@Acao IN ('C', 'U'))
    BEGIN
        IF (ISNULL(@Nome, '') = '') OR (LEN(@Nome) < 2)
        BEGIN
            SELECT @Return_Code = 2, @Error = 'st_Gerenciar_Material: Nome do material é obrigatório.';
            RAISERROR(@Error, 16, 1);
            RETURN;
        END

        IF (ISNULL(@PrecoUnitario, -1) < 0)
        BEGIN
            SELECT @Return_Code = 2, @Error = 'st_Gerenciar_Material: O preço não pode ser negativo.';
            RAISERROR(@Error, 16, 1);
            RETURN;
        END

        IF (ISNULL(@UnidadeMedida, '') = '')
        BEGIN
            SELECT @Return_Code = 2, @Error = 'st_Gerenciar_Material: Unidade de Medida (m, m2, un, chapa) é obrigatória.';
            RAISERROR(@Error, 16, 1);
            RETURN;
        END
    END

    -- Validação de Duplicidade (Nome exato na mesma categoria)
    IF (@Acao IN ('C', 'U'))
    BEGIN
        IF EXISTS (
            SELECT 1 FROM Materiais 
            WHERE Nome = @Nome 
              AND Categoria = @Categoria -- Permite "Puxador" (Ferragem) e "Puxador" (Outro), mas não 2 Ferragens iguais
              AND Ativo = 1 
              AND Id <> ISNULL(@Id, -1)
        )
        BEGIN
            SELECT @Return_Code = 2, @Error = 'st_Gerenciar_Material: Já existe este Material cadastrado nesta Categoria.';
            RAISERROR(@Error, 16, 1);
            RETURN;
        END
    END

    -- Validação de ID (U/D)
    IF (@Acao IN ('U', 'D'))
    BEGIN
        IF (ISNULL(@Id, 0) <= 0) OR NOT EXISTS (SELECT 1 FROM Materiais WHERE Id = @Id)
        BEGIN
            SELECT @Return_Code = 2, @Error = 'st_Gerenciar_Material: Material não encontrado.';
            RAISERROR(@Error, 16, 1);
            RETURN;
        END
    END

    -- =========================================================================
    -- 4. EXECUÇÃO
    -- =========================================================================
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Acao = 'C'
        BEGIN
            INSERT INTO Materiais (Nome, Categoria, PrecoUnitario, UnidadeMedida, Ativo, DataCriacao, DataAlteracao)
            VALUES (@Nome, @Categoria, @PrecoUnitario, @UnidadeMedida, 1, GETDATE(), GETDATE());
            
            SELECT SCOPE_IDENTITY() AS IdGerado;
        END

        ELSE IF @Acao = 'U'
        BEGIN
            UPDATE Materiais
            SET Nome = @Nome,
                Categoria = @Categoria,
                PrecoUnitario = @PrecoUnitario,
                UnidadeMedida = @UnidadeMedida,
                DataAlteracao = GETDATE()
            WHERE Id = @Id
              AND ( -- Otimização
                  Nome <> @Nome OR
                  Categoria <> @Categoria OR
                  PrecoUnitario <> @PrecoUnitario OR
                  UnidadeMedida <> @UnidadeMedida
              );
        END

        ELSE IF @Acao = 'D'
        BEGIN
            UPDATE Materiais SET Ativo = 0, DataAlteracao = GETDATE() WHERE Id = @Id;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT @Return_Code = 1, @Error = 'st_Gerenciar_Material: Erro SQL - ' + ERROR_MESSAGE();
        RAISERROR(@Error, 16, 1);
    END CATCH

    RETURN;
END
GO