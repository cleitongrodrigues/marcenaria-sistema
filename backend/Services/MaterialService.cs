using backend.DTOs;
using backend.Interfaces;

namespace backend.Services
{
    public class MaterialService : IMaterialService
    {
        private readonly IMaterialRepository _repository;
        private readonly ILogger<MaterialService> _logger;

        public MaterialService(IMaterialRepository repository, ILogger<MaterialService> logger)
        {
            _repository = repository;
            _logger = logger;
        }

        public async Task<IEnumerable<MaterialDTO>> ListarTodos()
        {
            _logger.LogInformation("Listando todos os materiais ativos.");

            var materiais = await  _repository.ListarTodos();

            _logger.LogInformation("Total de materiais encontrados: {Count}", materiais.Count());

            return materiais;
        }

        public async Task<(int Id, string Error)> Criar(MaterialDTO materiais)
        {
            _logger.LogInformation("Iniciando criação do material: {Nome}", materiais.Nome);

            var resultado = await _repository.Criar(materiais);

            return resultado;
        }

        public async Task<(bool Sucesso, string Error)> Atualizar(MaterialDTO materiais)
        {
            _logger.LogInformation("Iniciando atualização do material: {Nome}", materiais.Nome);

            var resultado = await _repository.Atualizar(materiais);

            return resultado;
        }

        public async Task<(bool Sucesso, string Error)> Deletar(int id)
        {
            _logger.LogInformation("Deletando material com ID: {id}", id);

            var resultado = await _repository.Deletar(id);

            return resultado;
        }
    }
}