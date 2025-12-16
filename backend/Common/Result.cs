namespace backend.Common
{
    // =============================================================================
    // CLASSE SIMPLES PARA RETORNAR RESULTADOS DE OPERAÇÕES
    // =============================================================================
    // Em vez de usar "tuplas" confusas como (bool, string), usamos esta classe
    // que é muito mais fácil de entender
    // =============================================================================
    
    /// <summary>
    /// Retorno de operações que NÃO precisam devolver dados (Update, Delete)
    /// </summary>
    public class OperationResult
    {
        // Se a operação deu certo ou não
        public bool Success { get; set; }
        
        // Mensagem de erro (se houver) ou mensagem de sucesso
        public string Message { get; set; } = string.Empty;
        
        // Código que veio da procedure (0=sucesso, 1=erro SQL, 2=validação, 3=não encontrado)
        public int ErrorCode { get; set; }

        // =========================================================================
        // MÉTODOS AUXILIARES PARA CRIAR RESULTADOS DE FORMA FÁCIL
        // =========================================================================

        // Cria resultado de SUCESSO
        public static OperationResult CreateSuccess(string message = "Operação realizada com sucesso")
        {
            return new OperationResult 
            { 
                Success = true, 
                Message = message, 
                ErrorCode = 0 
            };
        }

        // Cria resultado de ERRO GENÉRICO (erro do SQL Server)
        public static OperationResult CreateError(string message)
        {
            return new OperationResult 
            { 
                Success = false, 
                Message = message, 
                ErrorCode = 1 
            };
        }

        // Cria resultado de VALIDAÇÃO (ex: CPF inválido)
        public static OperationResult CreateValidationError(string message)
        {
            return new OperationResult 
            { 
                Success = false, 
                Message = message, 
                ErrorCode = 2 
            };
        }

        // Cria resultado de NÃO ENCONTRADO (ex: cliente ID 999 não existe)
        public static OperationResult CreateNotFound(string message = "Registro não encontrado")
        {
            return new OperationResult 
            { 
                Success = false, 
                Message = message, 
                ErrorCode = 3 
            };
        }
    }

    // =============================================================================
    // CLASSE PARA OPERAÇÕES QUE DEVOLVEM UM NÚMERO (CREATE - retorna ID gerado)
    // =============================================================================
    
    /// <summary>
    /// Retorno de operações que devolvem um ID (Create)
    /// </summary>
    public class CreateResult
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public int ErrorCode { get; set; }
        
        // ID do registro criado (ex: 123)
        public int GeneratedId { get; set; }

        // Cria resultado de SUCESSO com ID gerado
        public static CreateResult CreateSuccess(int id, string message = "Registro criado com sucesso")
        {
            return new CreateResult 
            { 
                Success = true, 
                GeneratedId = id, 
                Message = message, 
                ErrorCode = 0 
            };
        }

        // Cria resultado de ERRO (ID sempre será 0)
        public static CreateResult CreateError(string message, int errorCode = 1)
        {
            return new CreateResult 
            { 
                Success = false, 
                GeneratedId = 0, 
                Message = message, 
                ErrorCode = errorCode 
            };
        }

        // Cria resultado de VALIDAÇÃO (ex: CPF inválido)
        public static CreateResult CreateValidationError(string message)
        {
            return new CreateResult 
            { 
                Success = false, 
                GeneratedId = 0, 
                Message = message, 
                ErrorCode = 2 
            };
        }

        // Cria resultado de NÃO ENCONTRADO
        public static CreateResult CreateNotFound(string message = "Registro não encontrado")
        {
            return new CreateResult 
            { 
                Success = false, 
                GeneratedId = 0, 
                Message = message, 
                ErrorCode = 3 
            };
        }
    }
}
