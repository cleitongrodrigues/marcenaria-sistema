using backend.DTOs;
using backend.Interfaces;
using backend.Common;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers
{
    // =========================================================================
    // CONTROLLER DE MATERIAIS - Recebe as requisições HTTP
    // =========================================================================
    // Este é o "portão de entrada" da API para materiais
    // Quando o frontend chama GET /api/Material, cai aqui
    // =========================================================================
    
    [Route("api/[controller]")] // Define a rota: /api/Material
    [ApiController] // Marca como controller de API
    public class MaterialController : ControllerBase
    {
        // Service para aplicar regras de negócio
        private readonly IMaterialService _service;

        // Construtor - recebe o service
        public MaterialController(IMaterialService service)
        {
            _service = service;
        }

        // =====================================================================
        // GET /api/Material?page=1&pageSize=50&searchTerm=madeira
        // =====================================================================
        // Lista materiais com paginação e filtro
        // =====================================================================
        [HttpGet]
        public async Task<IActionResult> Listar([FromQuery] ListParameters parameters)
        {
            // Chama o service para buscar os materiais
            var resultado = await _service.ListarTodos(parameters);
            
            // Retorna HTTP 200 OK com a lista
            return Ok(resultado);
        }

        // =====================================================================
        // GET /api/Material/123
        // =====================================================================
        // Busca um material específico por ID
        // =====================================================================
        [HttpGet("{id}")]
        public async Task<IActionResult> ObterPorId(int id)
        {
            // Busca o material
            var material = await _service.ObterPorId(id);
            
            // Se não encontrou, retorna HTTP 404 Not Found
            if (material == null)
            {
                return NotFound(new 
                { 
                    sucesso = false, 
                    mensagem = "Material não encontrado" 
                });
            }
            
            // Se encontrou, retorna HTTP 200 OK com os dados
            return Ok(new 
            { 
                sucesso = true, 
                dados = material 
            });
        }

        // =====================================================================
        // POST /api/Material
        // =====================================================================
        // Cria um novo material
        // =====================================================================
        [HttpPost]
        public async Task<IActionResult> Criar([FromBody] MaterialDTO material)
        {
            // Chama o service para criar
            var resultado = await _service.Criar(material);
            
            // Se deu certo, retorna HTTP 201 Created
            if (resultado.Success)
            {
                return CreatedAtAction(
                    nameof(ObterPorId), // Nome do método que busca por ID
                    new { id = resultado.GeneratedId }, // Parâmetros para o método
                    new 
                    { 
                        sucesso = true, 
                        id = resultado.GeneratedId, 
                        mensagem = resultado.Message 
                    }
                );
            }
            
            // Se deu erro, retorna o erro apropriado
            return RetornarErro(resultado.ErrorCode, resultado.Message);
        }

        // =====================================================================
        // PUT /api/Material/123
        // =====================================================================
        // Atualiza um material existente
        // =====================================================================
        [HttpPut("{id}")]
        public async Task<IActionResult> Atualizar(int id, [FromBody] MaterialDTO material)
        {
            // Garante que o ID do body seja o mesmo da URL
            material.Id = id;
            
            // Chama o service para atualizar
            var resultado = await _service.Atualizar(material);
            
            // Se deu certo, retorna HTTP 200 OK
            if (resultado.Success)
            {
                return Ok(new 
                { 
                    sucesso = true, 
                    mensagem = resultado.Message 
                });
            }
            
            // Se deu erro, retorna o erro apropriado
            return RetornarErro(resultado.ErrorCode, resultado.Message);
        }

        // =====================================================================
        // DELETE /api/Material/123
        // =====================================================================
        // Deleta um material (soft delete - só marca como inativo)
        // =====================================================================
        [HttpDelete("{id}")]
        public async Task<IActionResult> Deletar(int id)
        {
            // Chama o service para deletar
            var resultado = await _service.Deletar(id);
            
            // Se deu certo, retorna HTTP 200 OK
            if (resultado.Success)
            {
                return Ok(new 
                { 
                    sucesso = true, 
                    mensagem = resultado.Message 
                });
            }
            
            // Se deu erro, retorna o erro apropriado
            return RetornarErro(resultado.ErrorCode, resultado.Message);
        }

        // =====================================================================
        // MÉTODO AUXILIAR: Retornar erro com HTTP status correto
        // =====================================================================
        private IActionResult RetornarErro(int errorCode, string mensagem)
        {
            // ErrorCode 0 = Sucesso (não deveria cair aqui)
            if (errorCode == 0)
            {
                return Ok(new { sucesso = true, mensagem });
            }
            
            // ErrorCode 2 = Erro de validação (ex: estoque mínimo > máximo)
            // Retorna HTTP 400 Bad Request
            if (errorCode == 2)
            {
                return BadRequest(new { sucesso = false, mensagem });
            }
            
            // ErrorCode 3 = Não encontrado
            // Retorna HTTP 404 Not Found
            if (errorCode == 3)
            {
                return NotFound(new { sucesso = false, mensagem });
            }
            
            // ErrorCode 1 ou qualquer outro = Erro do servidor (SQL, etc)
            // Retorna HTTP 500 Internal Server Error
            return StatusCode(500, new { sucesso = false, mensagem });
        }
    }
}