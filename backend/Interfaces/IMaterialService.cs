using backend.DTOs;
using backend.Common;

namespace backend.Interfaces
{
    // =========================================================================
    // INTERFACE DO SERVICE DE MATERIAIS
    // =========================================================================
    // Esta interface define o "contrato" que o MaterialService deve seguir
    // O Service fica entre o Controller e o Repository
    // Ele aplica as regras de negócio antes de salvar no banco
    // =========================================================================
    
    public interface IMaterialService
    {
        // Listar todos os materiais (com paginação e filtro)
        Task<MaterialListResult> ListarTodos(ListParameters parameters);
        
        // Buscar um material específico por ID
        Task<MaterialDTO?> ObterPorId(int id);
        
        // Criar um novo material (retorna o ID gerado)
        Task<CreateResult> Criar(MaterialDTO material);
        
        // Atualizar um material existente
        Task<OperationResult> Atualizar(MaterialDTO material);
        
        // Deletar um material (soft delete)
        Task<OperationResult> Deletar(int id);
    }
}