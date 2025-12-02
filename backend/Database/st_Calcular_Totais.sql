CREATE OR ALTER PROCEDURE st_Calcular_Totais
    @OrcamentoId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Atualiza o custo de cada ITEM (Filho) somando seus MATERIAIS (Netos)
    UPDATE I
    SET I.ValorCustoItem = ISNULL((
        SELECT SUM(M.Quantidade * M.PrecoCustoNoMomento)
        FROM OrcamentoItemMateriais M
        WHERE M.OrcamentoItemId = I.Id
    ), 0)
    FROM OrcamentoItens I
    WHERE I.OrcamentoId = @OrcamentoId;

    -- 2. Atualiza o CABEÇALHO (Pai) somando os Itens + Margem
    DECLARE @TotalCusto DECIMAL(18,2);
    DECLARE @Margem DECIMAL(5,2);

    -- Pega soma dos itens e a margem atual
    SELECT 
        @TotalCusto = ISNULL(SUM(ValorCustoItem), 0)
    FROM OrcamentoItens WHERE OrcamentoId = @OrcamentoId;

    SELECT @Margem = MargemLucro FROM Orcamentos WHERE Id = @OrcamentoId;

    -- Atualiza valores finais
    UPDATE Orcamentos
    SET 
        ValorTotalCusto = @TotalCusto,
        ValorFinalVenda = @TotalCusto + (@TotalCusto * (ISNULL(@Margem, 0) / 100)),
        DataAlteracao = GETDATE()
    WHERE Id = @OrcamentoId;
END
GO