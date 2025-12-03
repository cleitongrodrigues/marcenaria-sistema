using backend.DTOs;

namespace backend.Interfaces
{
    public interface IClienteRepository
    {
        // Contrato: Quem implementar isso, tem que saber listar e criar clientes
        Task<IEnumerable<ClienteDTO>> ListarTodos();
        Task<(int Id, string Error)> Criar(ClienteDTO cliente);
    }
}