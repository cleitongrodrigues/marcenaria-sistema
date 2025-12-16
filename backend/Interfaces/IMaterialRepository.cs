using backend.DTOs;
using backend.Common;

namespace backend.Interfaces
{
    // =========================================================================
    // INTERFACE DO REPOSITORY DE MATERIAIS
    // =========================================================================
    // Esta interface define o "contrato" que o MaterialRepository deve seguir
    // Ela diz QUAIS métodos devem existir, mas não diz COMO funcionam
    // =========================================================================
    
    public interface IMaterialRepository
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