CREATE OR ALTER PROCEDURE st_Gerenciar_Orcamento
    @Acao CHAR(1), -- 'C', 'U', 'D'
    @Id INT = NULL,
    @ClienteId INT = NULL,
    @MargemLucro DECIMAL(5,2) = NULL,
    @Observacao VARCHAR(500) = NULL,
    @Status VARCHAR(20) = NULL, -- 'Em Aberto', 'Aprovado'
    -- Saída
    @Return_Code SMALLINT = 0 OUTPUT,
    @Error VARCHAR(1000) = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Observacao = TRIM(@Observacao);
    SELECT @Error = '', @Return_Code = 0;

    -- VALIDAÇÕES
    IF ISNULL(@Acao, '') NOT IN ('C', 'U', 'D')
    BEGIN
        SELECT @Return_Code = 2, @Error = 'st_Gerenciar_Orcamento: Ação inválida.';
        RAISERROR(@Error, 16, 1);
        RETURN;
    END

    IF (@Acao = 'C') AND (ISNULL(@ClienteId, 0) <= 0)
    BEGIN
        SELECT @Return_Code = 2, @Error = 'st_Gerenciar_Orcamento: Cliente obrigatório.';
        RAISERROR(@Error, 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Acao = 'C'
        BEGIN
            -- Cria orçamento zerado
            INSERT INTO Orcamentos (ClienteId, Status, MargemLucro, ValorTotalCusto, ValorFinalVenda, Observacao, Ativo, DataCriacao, DataAlteracao)
            VALUES (@ClienteId, 'Em Aberto', ISNULL(@MargemLucro, 50), 0, 0, @Observacao, 1, GETDATE(), GETDATE());
            
            SELECT SCOPE_IDENTITY() AS IdGerado;
        END

        ELSE IF @Acao = 'U'
        BEGIN
            UPDATE Orcamentos
            SET MargemLucro = ISNULL(@MargemLucro, MargemLucro),
                Observacao = ISNULL(@Observacao, Observacao),
                Status = ISNULL(@Status, Status),
                DataAlteracao = GETDATE()
            WHERE Id = @Id;

            -- Se mudou a margem, recalcula o preço final
            EXEC st_Calcular_Totais @Id;
        END

        ELSE IF @Acao = 'D'
        BEGIN
            UPDATE Orcamentos SET Ativo = 0, DataAlteracao = GETDATE() WHERE Id = @Id;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT @Return_Code = 1, @Error = 'st_Gerenciar_Orcamento: ' + ERROR_MESSAGE();
        RAISERROR(@Error, 16, 1);
    END CATCH
    RETURN;
END
GO