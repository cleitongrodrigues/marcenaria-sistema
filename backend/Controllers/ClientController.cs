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
    }
}