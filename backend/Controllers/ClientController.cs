using backend.DTOs;
using backend.Interfaces; // Usamos a Interface agora
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ClienteController : ControllerBase
    {
        // Injetamos a Interface, não o DapperContext direto
        private readonly IClienteRepository _repository;

        public ClienteController(IClienteRepository repository)
        {
            _repository = repository;
        }

        [HttpGet]
        public async Task<IActionResult> Listar()
        {
            // O controller apenas delega a tarefa
            var clientes = await _repository.ListarTodos();
            return Ok(clientes);
        }

        [HttpPost]
        public async Task<IActionResult> Criar([FromBody] ClienteDTO cliente)
        {
            // Chama o repositório e recebe a Tupla (Id, Error)
            var resultado = await _repository.Criar(cliente);

            // Verifica se veio erro na string de erro
            if (!string.IsNullOrEmpty(resultado.Error))
            {
                return BadRequest(new { mensagem = resultado.Error });
            }

            return Ok(new { id = resultado.Id, mensagem = "Cliente cadastrado com sucesso!" });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Atualizar(int id, [FromBody] ClienteDTO cliente)
        {
            // Garante que o ID da URL seja usado
            cliente.Id = id;

            var resultado = await _repository.Atualizar(cliente);

            if (!resultado.Sucesso)
            {
                return BadRequest(new { mensagem = resultado.Error });
            }

            return Ok(new { mensagem = "Cliente atualizado com sucesso!" });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Deletar(int id)
        {
            var resultado = await _repository.Deletar(id);

            if (!resultado.Sucesso)
            {
                return BadRequest(new { mensagem = resultado.Error });
            }

            return Ok(new { mensagem = "Cliente removido com sucesso!" });
        }
    }
}