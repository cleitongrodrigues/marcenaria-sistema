using backend.DTOs;
using backend.Interfaces;
using backend.Common;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers
{
    // =========================================================================
    // CONTROLLER DE CLIENTES - Recebe as requisições HTTP
    // =========================================================================
    // Este é o "portão de entrada" da API
    // Quando o frontend chama GET /api/Cliente, cai aqui
    // =========================================================================
    
    [Route("api/[controller]")] // Define a rota: /api/Cliente
    [ApiController] // Marca como controller de API
    public class ClienteController : ControllerBase
    {
        // Service para aplicar regras de negócio
        private readonly IClienteService _service;

        // Construtor - recebe o service
        public ClienteController(IClienteService service)
        {
            _service = service;
        }

        // =====================================================================
        // GET /api/Cliente?page=1&pageSize=50&searchTerm=Silva
        // =====================================================================
        // Lista clientes com paginação e filtro
        // =====================================================================
        [HttpGet]
        public async Task<IActionResult> Listar([FromQuery] ListParameters parameters)
        {
            // Chama o service para buscar os clientes
            var resultado = await _service.ListarTodos(parameters);
            
            // Retorna HTTP 200 OK com a lista
            return Ok(resultado);
        }

        // =====================================================================
        // GET /api/Cliente/123
        // =====================================================================
        // Busca um cliente específico por ID (com telefones e endereços)
        // =====================================================================
        [HttpGet("{id}")]
        public async Task<IActionResult> ObterPorId(int id)
        {
            // Busca o cliente
            var cliente = await _service.ObterPorId(id);
            
            // Se não encontrou, retorna HTTP 404 Not Found
            if (cliente == null)
            {
                return NotFound(new 
                { 
                    sucesso = false, 
                    mensagem = "Cliente não encontrado" 
                });
            }
            
            // Se encontrou, retorna HTTP 200 OK com os dados
            return Ok(new 
            { 
                sucesso = true, 
                dados = cliente 
            });
        }

        // =====================================================================
        // POST /api/Cliente
        // =====================================================================
        // Cria um novo cliente
        // =====================================================================
        [HttpPost]
        public async Task<IActionResult> Criar([FromBody] ClienteDTO cliente)
        {
            // Chama o service para criar
            var resultado = await _service.Criar(cliente);
            
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
        // PUT /api/Cliente/123
        // =====================================================================
        // Atualiza um cliente existente
        // =====================================================================
        [HttpPut("{id}")]
        public async Task<IActionResult> Atualizar(int id, [FromBody] ClienteDTO cliente)
        {
            // Garante que o ID do body seja o mesmo da URL
            cliente.Id = id;
            
            // Chama o service para atualizar
            var resultado = await _service.Atualizar(cliente);
            
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
        // DELETE /api/Cliente/123
        // =====================================================================
        // Deleta um cliente (soft delete - só marca como inativo)
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
            
            // ErrorCode 2 = Erro de validação (ex: CPF inválido)
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
