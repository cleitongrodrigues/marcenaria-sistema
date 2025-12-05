CREATE PROCEDURE st_Gerenciar_Cliente @Acao        CHAR(1)      = 'C', -- 'C', 'U', 'D'
                                      @Id          INTEGER      = NULL,
                                      @Nome        VARCHAR(50)  = NULL,
                                      @CPF         VARCHAR(14)  = NULL,
                                      @Telefone    VARCHAR(20)  = NULL,
                                      @Logradouro  VARCHAR(100) = NULL,
                                      @Numero      VARCHAR(20)  = NULL,
                                      @Bairro      VARCHAR(50)  = NULL,
                                      @Cidade      VARCHAR(50)  = NULL,
                                      @UF          CHAR(2)      = NULL,
                                      @CEP         VARCHAR(9)   = NULL,
                                      @Complemento VARCHAR(50)  = NULL,
                                      @Return_Code SMALLINT     = 0  OUTPUT,
                                      @Error       VARCHAR(255) = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
      SET @Acao       = UPPER(TRIM(@Acao));
      SET @Nome       = TRIM(@Nome);
      SET @CPF        = TRIM(@CPF);
      SET @Telefone   = TRIM(@Telefone);
      SET @Logradouro = TRIM(@Logradouro);
      SET @Bairro     = TRIM(@Bairro);
      SET @Cidade     = TRIM(@Cidade);
      SET @UF         = UPPER(TRIM(@UF));

      SELECT @Return_Code = 0,
             @Error       = '';

      IF (ISNULL(@Acao, '')) NOT IN ('C', 'U', 'D')
      BEGIN
        SELECT @Return_Code = 2,
               @Error       = 'st_Gerenciar_Cliente: Ação inválida.';
        RAISERROR(@Error, 16, 1);
      END

      IF (@Acao IN ('U','D')) AND (@Id IS NULL)
      BEGIN
      SELECT @Return_Code = 2,
             @Error       = 'st_Gerenciar_Cliente: ID Obrigatório para a ação (' + @Acao + ')';
      RAISERROR(@Error, 16, 1);
      END

      IF (@Acao IN ('C', 'U'))
      BEGIN
        IF (ISNULL(@Nome, '') = '') OR (LEN(@Nome) < 3) OR (ISNULL(@Telefone, '') = '')
        BEGIN
            SELECT @Return_Code = 2,
                   @Error       = 'st_Gerenciar_Cliente: Nome e Telefone são obrigatórios.';
            RAISERROR(@Error, 16, 1);
        END

        IF (ISNULL(@Logradouro, '') = '') OR (ISNULL(@Numero, '') = '') OR (ISNULL(@Bairro, '') = '') OR (ISNULL(@Cidade, '') = '') OR
           (ISNULL(@UF, '') = '') OR (ISNULL(@CEP, '') = '')
        BEGIN
          SELECT @Return_Code = 2,
                 @Error       = 'st_Gerenciar_Cliente: Endereço incompleto.';
          RAISERROR(@Error, 16, 1);
        END

        IF (ISNULL(@CPF, '') <> '')
        BEGIN
          IF EXISTS (SELECT 1
                     FROM dbo.Clientes WITH(NOLOCK)
                     WHERE CPF = @CPF
                       AND Id <> ISNULL(@Id, -1))
          BEGIN
              SELECT @Return_Code = 2,
                     @Error       = 'st_Gerenciar_Cliente: CPF já cadastrado.';
              RAISERROR(@Error, 16, 1);
          END
        END
        ELSE
        BEGIN
          IF EXISTS (SELECT 1
                     FROM dbo.Clientes WITH(NOLOCK)
                     WHERE Nome     = @Nome
                       AND Telefone = @Telefone
                       AND Id      <> ISNULL(@Id, -1))
          BEGIN
            SELECT @Return_Code = 2,
                   @Error       = 'st_Gerenciar_Cliente: Cliente duplicado (Nome + Telefone).';
            RAISERROR(@Error, 16, 1);
          END
        END
      END

      DECLARE @NovoId INTEGER;
      BEGIN TRANSACTION;

        IF @Acao = 'C'
        BEGIN
          INSERT INTO dbo.Clientes (Nome,
                                    CPF,
                                    Telefone,
                                    Ativo,
                                    DataCriacao,
                                    DataAlteracao)
          VALUES (@Nome,
                  @CPF,
                  @Telefone,
                  1,
                  GETDATE(),
                  NULL);

          SELECT @NovoId = SCOPE_IDENTITY();

          INSERT INTO dbo.Enderecos (ClienteId,
                                     Logradouro,
                                     Numero,
                                     Bairro,
                                     Cidade,
                                     UF,
                                     CEP,
                                     Complemento)
          VALUES (@NovoId,
                  @Logradouro,
                  @Numero,
                  @Bairro,
                  @Cidade,
                  @UF,
                  @CEP,
                  @Complemento);

          SELECT @NovoId AS IdGerado;
        END

        IF (@Acao = 'U')
        BEGIN
          UPDATE dbo.Clientes
          SET Nome          = @Nome,
              CPF           = @CPF,
              Telefone      = @Telefone,
              DataAlteracao = GETDATE()
          WHERE Id = @Id;

          IF EXISTS (SELECT 1
                     FROM dbo.Enderecos WITH(NOLOCK)
                     WHERE ClienteId = @Id)
          BEGIN
            UPDATE dbo.Enderecos
            SET Logradouro    = @Logradouro,
                Numero        = @Numero,
                Bairro        = @Bairro,
                Cidade        = @Cidade,
                UF            = @UF,
                CEP           = @CEP,
                Complemento   = @Complemento,
                DataAlteracao = GETDATE()
            WHERE ClienteId = @Id;
          END
          ELSE
          BEGIN
            INSERT INTO dbo.Enderecos (ClienteId,
                                       Logradouro,
                                       Numero,
                                       Bairro,
                                       Cidade,
                                       UF,
                                       CEP,
                                       Complemento)
              VALUES (@Id,
                      @Logradouro,
                      @Numero,
                      @Bairro,
                      @Cidade,
                      @UF,
                      @CEP,
                      @Complemento);
          END
        END

        IF (@Acao = 'D')
        BEGIN
          IF EXISTS (SELECT 1
                     FROM dbo.Clientes WITH(NOLOCK)
                     WHERE ID    = @Id
                       AND Ativo = 1)
          BEGIN
            UPDATE dbo.Clientes
            SET Ativo         = 0,
                DataAlteracao = GETDATE()
            WHERE Id = @Id;
          END
          ELSE
          BEGIN
            SELECT @Return_Code = 1,
                   @Error       = 'st_Gerenciar_Cliente: Cliente de ID ( ' + CAST(@Id AS VARCHAR(4)) + ' ) não encontrado.';
            RAISERROR(@Error, 16, 1);
          END
        END

      COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

      SELECT @Return_Code = CASE
                              WHEN @Return_Code = 0 THEN 1
                              ELSE 2
                            END,
             @Error       = @Error;
    END CATCH

    RETURN;
END