CREATE OR ALTER PROCEDURE st_Gerenciar_OrcamentoMaterial
    @Acao CHAR(1), -- 'C', 'U', 'D'
    @Id INT = NULL,
    @OrcamentoItemId INT = NULL,
    @MaterialId INT = NULL,
    @Quantidade DECIMAL(10,4) = NULL,
    -- Saída
    @Return_Code SMALLINT = 0 OUTPUT,
    @Error VARCHAR(1000) = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SELECT @Error = '', @Return_Code = 0;

    -- VALIDAÇÕES
    IF (@Acao = 'C')
    BEGIN
        IF (ISNULL(@OrcamentoItemId, 0) <= 0) OR (ISNULL(@MaterialId, 0) <= 0) OR (ISNULL(@Quantidade, 0) <= 0)
        BEGIN
            SELECT @Return_Code = 2, @Error = 'st_Gerenciar_OrcamentoMaterial: Item, Material e Quantidade (>0) são obrigatórios.';
            RAISERROR(@Error, 16, 1);
            RETURN;
        END
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Variável para guardar o ID do Orçamento Principal (Avô) para recalculo
        DECLARE @OrcamentoPrincipalId INT;

        IF @Acao = 'C'
        BEGIN
            -- 1. Busca o preço ATUAL do material
            DECLARE @PrecoAtual DECIMAL(18,2);
            SELECT @PrecoAtual = PrecoUnitario FROM Materiais WHERE Id = @MaterialId;

            IF @PrecoAtual IS NULL
            BEGIN
                RAISERROR('Material não encontrado para capturar preço.', 16, 1);
            END

            -- 2. Insere com o preço congelado
            INSERT INTO OrcamentoItemMateriais (OrcamentoItemId, MaterialId, Quantidade, PrecoCustoNoMomento, DataRegistro)
            VALUES (@OrcamentoItemId, @MaterialId, @Quantidade, @PrecoAtual, GETDATE());

            -- 3. Descobre quem é o Orçamento Pai para recalcular
            SELECT @OrcamentoPrincipalId = OrcamentoId FROM OrcamentoItens WHERE Id = @OrcamentoItemId;
        END

        ELSE IF @Acao = 'U'
        BEGIN
            -- Atualiza quantidade
            UPDATE OrcamentoItemMateriais
            SET Quantidade = @Quantidade
            WHERE Id = @Id;

            -- Descobre Pai para recalcular
            SELECT @OrcamentoPrincipalId = I.OrcamentoId 
            FROM OrcamentoItens I 
            JOIN OrcamentoItemMateriais M ON M.OrcamentoItemId = I.Id
            WHERE M.Id = @Id;
        END

        ELSE IF @Acao = 'D'
        BEGIN
            -- Descobre Pai antes de deletar
            SELECT @OrcamentoPrincipalId = I.OrcamentoId 
            FROM OrcamentoItens I 
            JOIN OrcamentoItemMateriais M ON M.OrcamentoItemId = I.Id
            WHERE M.Id = @Id;

            DELETE FROM OrcamentoItemMateriais WHERE Id = @Id;
        END

        -- RECALCULA TUDO AUTOMATICAMENTE
        IF @OrcamentoPrincipalId IS NOT NULL
        BEGIN
            EXEC st_Calcular_Totais @OrcamentoPrincipalId;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT @Return_Code = 1, @Error = 'st_Gerenciar_OrcamentoMaterial: ' + ERROR_MESSAGE();
        RAISERROR(@Error, 16, 1);
    END CATCH
    RETURN;
END
GO