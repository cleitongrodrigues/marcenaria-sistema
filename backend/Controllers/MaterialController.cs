using backend.DTOs;
using backend.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]

    public class MaterialController : ControllerBase
    {
        private readonly IMaterialService _service;

        public MaterialController(IMaterialService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<IActionResult> Listar()
        {
            var materiais = await _service.ListarTodos();
            return Ok(materiais);
        }

        [HttpPost]
        public async Task<IActionResult> Criar([FromBody] MaterialDTO material)
        {
            var resultado = await _service.Criar(material);

            if (!string.IsNullOrEmpty(resultado.Error))
            {
                return BadRequest(new {mensagem = resultado.Error});
            }

            return Ok(new {id = resultado.Id, mensagem = "Material cadastrado com sucesso!"});
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Atualizar(int id, [FromBody] MaterialDTO material)
        {
            material.Id = id;

            var resultado = await _service.Atualizar(material);

            if (!resultado.Sucesso)
            {
                return BadRequest(new {mensagem = resultado.Error});
            }

            return Ok(new {mensagem = "Material atualizado com sucesso!"});
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Deletar(int id)
        {
            var resultado = await _service.Deletar(id);

            if (!resultado.Sucesso)
            {
                return BadRequest(new {mensagem = resultado.Error});
            }

            return Ok(new {mensagem = "Material removido com sucesso!"});
        }

    }
}