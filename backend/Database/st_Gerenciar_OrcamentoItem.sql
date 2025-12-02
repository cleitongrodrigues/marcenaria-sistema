CREATE OR ALTER PROCEDURE st_Gerenciar_OrcamentoItem
    @Acao CHAR(1), -- 'C', 'U', 'D'
    @Id INT = NULL,
    @OrcamentoId INT = NULL,
    @NomeItem VARCHAR(100) = NULL,
    @Ambiente VARCHAR(50) = NULL,
    @Largura DECIMAL(10,2) = NULL,
    @Altura DECIMAL(10,2) = NULL,
    @Profundidade DECIMAL(10,2) = NULL,
    -- Saída
    @Return_Code SMALLINT = 0 OUTPUT,
    @Error VARCHAR(1000) = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @NomeItem = TRIM(@NomeItem);

    SELECT @Error = '', @Return_Code = 0;

    -- VALIDAÇÕES
    IF (@Acao = 'C') AND (ISNULL(@OrcamentoId, 0) <= 0 OR ISNULL(@NomeItem, '') = '')
    BEGIN
        SELECT @Return_Code = 2, @Error = 'st_Gerenciar_OrcamentoItem: OrçamentoId e Nome do Item são obrigatórios.';
        RAISERROR(@Error, 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Acao = 'C'
        BEGIN
            INSERT INTO OrcamentoItens (OrcamentoId, NomeItem, Ambiente, Largura, Altura, Profundidade, ValorCustoItem)
            VALUES (@OrcamentoId, @NomeItem, @Ambiente, @Largura, @Altura, @Profundidade, 0);
            
            SELECT SCOPE_IDENTITY() AS IdGerado;
        END

        ELSE IF @Acao = 'U'
        BEGIN
            UPDATE OrcamentoItens
            SET NomeItem = @NomeItem, Ambiente = @Ambiente, 
                Largura = @Largura, Altura = @Altura, Profundidade = @Profundidade
            WHERE Id = @Id;
            -- Update de nome não muda preço, não precisa recalcular
        END

        ELSE IF @Acao = 'D'
        BEGIN
            -- Guarda o ID do Pai antes de deletar o Filho para poder recalcular
            DECLARE @IdPai INT;
            SELECT @IdPai = OrcamentoId FROM OrcamentoItens WHERE Id = @Id;

            DELETE FROM OrcamentoItens WHERE Id = @Id; -- Delete Físico (Itens não têm Soft Delete neste modelo simples)
            
            -- Recalcula o orçamento total (pois um móvel sumiu)
            EXEC st_Calcular_Totais @IdPai;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT @Return_Code = 1, @Error = 'st_Gerenciar_OrcamentoItem: ' + ERROR_MESSAGE();
        RAISERROR(@Error, 16, 1);
    END CATCH
    RETURN;
END
GO