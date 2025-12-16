using backend.DTOs;
using backend.Common;

namespace backend.Interfaces
{
    // =========================================================================
    // INTERFACE (CONTRATO) DO REPOSITÓRIO DE CLIENTES
    // =========================================================================
    // Define quais métodos o ClienteRepository DEVE ter
    // Isso facilita fazer testes e trocar implementações no futuro
    // =========================================================================
    
    public interface IClienteRepository
    {
        // Listar clientes com paginação
        Task<ClienteListResult> ListarTodos(ListParameters parameters);
        
        // Buscar um cliente específico por ID (com telefones e endereços)
        Task<ClienteComDetalhesDTO?> ObterPorId(int id);
        
        // Criar novo cliente (retorna o ID gerado)
        Task<CreateResult> Criar(ClienteDTO cliente);
        
        // Atualizar cliente existente
        Task<OperationResult> Atualizar(ClienteDTO cliente);
        
        // Deletar cliente (soft delete)
        Task<OperationResult> Deletar(int id);
    }
}