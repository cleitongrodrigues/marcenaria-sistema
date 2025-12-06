using backend.DTOs;

namespace backend.Interfaces
{
    public interface IClienteRepository
    {
        Task<IEnumerable<ClienteDTO>> ListarTodos();
        Task<(int Id, string Error)> Criar(ClienteDTO cliente);
        Task<(bool Sucesso, string Error)> Atualizar(ClienteDTO cliente);
        Task<(bool Sucesso, string Error)> Deletar(int id);
    }
}