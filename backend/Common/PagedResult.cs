namespace backend.Common
{
    // =============================================================================
    // PAGINAÇÃO SIMPLES - Para não retornar 10.000 registros de uma vez
    // =============================================================================
    // Exemplo: Em vez de retornar todos os clientes, retorna 50 por vez
    // =============================================================================
    
    /// <summary>
    /// Parâmetros que o usuário envia para filtrar/paginar a lista
    /// Exemplo: ?page=2&pageSize=50&search=Silva
    /// </summary>
    public class ListParameters
    {
        // Qual página o usuário quer ver (começa em 1)
        public int Page { get; set; } = 1;
        
        // Quantos itens por página (máximo 100)
        public int PageSize { get; set; } = 50;
        
        // Termo de busca (opcional) - ex: "Silva" para buscar clientes com nome Silva
        public string SearchTerm { get; set; } = string.Empty;

        // Validação: não deixa pedir mais de 100 itens por vez
        public void Validate()
        {
            if (PageSize > 100)
                PageSize = 100;
            
            if (PageSize < 1)
                PageSize = 50;
            
            if (Page < 1)
                Page = 1;
        }
    }

    // =============================================================================
    // RESULTADO PAGINADO - O que volta para o frontend
    // =============================================================================
    
    /// <summary>
    /// Lista paginada de clientes (ou qualquer outra coisa)
    /// </summary>
    public class ClienteListResult
    {
        // Lista com os 50 clientes da página atual
        public List<DTOs.ClienteDTO> Items { get; set; } = new();
        
        // Total de clientes no banco (ex: 500)
        public int TotalItems { get; set; }
        
        // Total de páginas (ex: se tem 500 clientes e mostra 50 por vez = 10 páginas)
        public int TotalPages { get; set; }
        
        // Página atual (ex: 2)
        public int CurrentPage { get; set; }
        
        // Itens por página (ex: 50)
        public int PageSize { get; set; }
        
        // Tem página anterior? (se estiver na página 1, não tem)
        public bool HasPreviousPage { get; set; }
        
        // Tem próxima página? (se estiver na última, não tem)
        public bool HasNextPage { get; set; }
    }

    /// <summary>
    /// Lista paginada de materiais
    /// </summary>
    public class MaterialListResult
    {
        public List<DTOs.MaterialDTO> Items { get; set; } = new();
        public int TotalItems { get; set; }
        public int TotalPages { get; set; }
        public int CurrentPage { get; set; }
        public int PageSize { get; set; }
        public bool HasPreviousPage { get; set; }
        public bool HasNextPage { get; set; }
    }
}
