using backend.DTOs;
using backend.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ClienteController : ControllerBase
    {
        private readonly IClienteService _service;

        public ClienteController(IClienteService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<IActionResult> Listar()
        {
            var clientes = await _service.ListarTodos();
            return Ok(clientes);
        }

        [HttpPost]
        public async Task<IActionResult> Criar([FromBody] ClienteDTO cliente)
        {
            var resultado = await _service.Criar(cliente);

            if (!string.IsNullOrEmpty(resultado.Error))
            {
                return BadRequest(new { mensagem = resultado.Error });
            }

            return Ok(new { id = resultado.Id, mensagem = "Cliente cadastrado com sucesso!" });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Atualizar(int id, [FromBody] ClienteDTO cliente)
        {
            cliente.Id = id;
            var resultado = await _service.Atualizar(cliente);

            if (!resultado.Sucesso)
            {
                return BadRequest(new { mensagem = resultado.Error });
            }

            return Ok(new { mensagem = "Cliente atualizado com sucesso!" });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Deletar(int id)
        {
            var resultado = await _service.Deletar(id);

            if (!resultado.Sucesso)
            {
                return BadRequest(new { mensagem = resultado.Error });
            }

            return Ok(new { mensagem = "Cliente removido com sucesso!" });
        }
    }
}
