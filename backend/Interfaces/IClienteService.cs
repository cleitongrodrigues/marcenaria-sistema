using backend.DTOs;
using backend.Common;

namespace backend.Interfaces
{
    // =========================================================================
    // INTERFACE (CONTRATO) DO SERVIÇO DE CLIENTES
    // =========================================================================
    // Define quais métodos o ClienteService DEVE ter
    // Services ficam entre Controller e Repository
    // Eles aplicam REGRAS DE NEGÓCIO antes de chamar o banco
    // =========================================================================
    
    public interface IClienteService
    {
        // Listar clientes
        Task<ClienteListResult> ListarTodos(ListParameters parameters);
        
        // Obter um cliente por ID
        Task<ClienteComDetalhesDTO?> ObterPorId(int id);
        
        // Criar novo cliente
        Task<CreateResult> Criar(ClienteDTO cliente);
        
        // Atualizar cliente
        Task<OperationResult> Atualizar(ClienteDTO cliente);
        
        // Deletar cliente
        Task<OperationResult> Deletar(int id);
    }
}
