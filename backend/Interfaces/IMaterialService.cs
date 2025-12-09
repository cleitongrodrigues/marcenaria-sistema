using backend.DTOs;

namespace backend.Interfaces
{
    public interface IMaterialService
    {
        Task<IEnumerable<MaterialDTO>> ListarTodos();
        Task<(int Id, string Error)> Criar(MaterialDTO material);
        Task<(bool Sucesso, string Error)> Atualizar(MaterialDTO material);
        Task<(bool Sucesso, string Error)> Deletar(int id);
    }
}