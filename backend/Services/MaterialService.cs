using backend.DTOs;
using backend.Interfaces;
using backend.Common;

namespace backend.Services
{
    // =========================================================================
    // SERVICE DE MATERIAIS - Aplica regras de negócio
    // =========================================================================
    // O Service fica entre o Controller e o Repository
    // Ele valida dados, limpa strings e aplica regras antes de salvar no banco
    // =========================================================================
    
    public class MaterialService : IMaterialService
    {
        // Repository para acessar o banco de dados
        private readonly IMaterialRepository _repository;
        
        // Logger para registrar logs (erros, informações, etc)
        private readonly ILogger<MaterialService> _logger;

        // Construtor - recebe o repository e o logger
        public MaterialService(IMaterialRepository repository, ILogger<MaterialService> logger)
        {
            _repository = repository;
            _logger = logger;
        }

        // =====================================================================
        // LISTAR TODOS OS MATERIAIS
        // =====================================================================
        public async Task<MaterialListResult> ListarTodos(ListParameters parameters)
        {
            // Registra no log que está listando
            _logger.LogInformation("Listando materiais - Página: " + parameters.Page);

            // Chama o repository para buscar no banco
            var resultado = await _repository.ListarTodos(parameters);

            // Registra no log o resultado
            _logger.LogInformation("Total de materiais encontrados: " + resultado.TotalItems);

            return resultado;
        }

        // =====================================================================
        // OBTER MATERIAL POR ID
        // =====================================================================
        public async Task<MaterialDTO?> ObterPorId(int id)
        {
            // Registra no log
            _logger.LogInformation("Buscando material ID: " + id);

            // Busca no banco
            var material = await _repository.ObterPorId(id);

            // Se não encontrou, registra no log
            if (material == null)
            {
                _logger.LogWarning("Material ID " + id + " não encontrado");
            }

            return material;
        }

        // =====================================================================
        // CRIAR NOVO MATERIAL
        // =====================================================================
        public async Task<CreateResult> Criar(MaterialDTO material)
        {
            // Registra no log
            _logger.LogInformation("Criando material: " + material.Nome);

            // ========================================================
            // REGRA DE NEGÓCIO 1: Limpar e padronizar os dados
            // ========================================================
            
            // Remove espaços extras do nome
            if (material.Nome != null)
            {
                material.Nome = material.Nome.Trim();
            }
            
            // Remove espaços extras da descrição
            if (material.Descricao != null)
            {
                material.Descricao = material.Descricao.Trim();
            }
            
            // Remove espaços extras da categoria
            if (material.Categoria != null)
            {
                material.Categoria = material.Categoria.Trim();
            }
            
            // Unidade de medida em maiúsculas (ex: KG, M, UN)
            if (material.UnidadeMedida != null)
            {
                material.UnidadeMedida = material.UnidadeMedida.Trim().ToUpper();
            }
            
            // Remove espaços extras da localização
            if (material.Localizacao != null)
            {
                material.Localizacao = material.Localizacao.Trim();
            }

            // ========================================================
            // REGRA DE NEGÓCIO 2: Validar dados obrigatórios
            // ========================================================
            
            // Nome é obrigatório
            if (string.IsNullOrWhiteSpace(material.Nome))
            {
                return CreateResult.CreateValidationError("Nome do material é obrigatório");
            }
            
            // Unidade de medida é obrigatória
            if (string.IsNullOrWhiteSpace(material.UnidadeMedida))
            {
                return CreateResult.CreateValidationError("Unidade de medida é obrigatória");
            }

            // ========================================================
            // REGRA DE NEGÓCIO 3: Validar estoque
            // ========================================================
            
            // Se informou estoque mínimo E estoque máximo
            if (material.EstoqueMinimo.HasValue && material.EstoqueMaximo.HasValue)
            {
                // Estoque mínimo não pode ser maior que máximo
                if (material.EstoqueMinimo.Value > material.EstoqueMaximo.Value)
                {
                    return CreateResult.CreateValidationError(
                        "Estoque mínimo não pode ser maior que estoque máximo");
                }
            }
            
            // Estoque não pode ser negativo
            if (material.QuantidadeEstoque < 0)
            {
                return CreateResult.CreateValidationError(
                    "Quantidade em estoque não pode ser negativa");
            }

            // ========================================================
            // CHAMA O REPOSITORY PARA SALVAR NO BANCO
            // ========================================================
            var resultado = await _repository.Criar(material);

            // Registra no log o resultado
            if (resultado.Success)
            {
                _logger.LogInformation("Material criado com sucesso - ID: " + resultado.GeneratedId);
            }
            else
            {
                _logger.LogError("Erro ao criar material: " + resultado.Message);
            }

            return resultado;
        }

        // =====================================================================
        // ATUALIZAR MATERIAL EXISTENTE
        // =====================================================================
        public async Task<OperationResult> Atualizar(MaterialDTO material)
        {
            // Registra no log
            _logger.LogInformation("Atualizando material ID: " + material.Id);

            // ========================================================
            // REGRA DE NEGÓCIO 1: Limpar e padronizar os dados
            // ========================================================
            
            if (material.Nome != null)
            {
                material.Nome = material.Nome.Trim();
            }
            
            if (material.Descricao != null)
            {
                material.Descricao = material.Descricao.Trim();
            }
            
            if (material.Categoria != null)
            {
                material.Categoria = material.Categoria.Trim();
            }
            
            if (material.UnidadeMedida != null)
            {
                material.UnidadeMedida = material.UnidadeMedida.Trim().ToUpper();
            }
            
            if (material.Localizacao != null)
            {
                material.Localizacao = material.Localizacao.Trim();
            }

            // ========================================================
            // REGRA DE NEGÓCIO 2: Validar dados obrigatórios
            // ========================================================
            
            if (string.IsNullOrWhiteSpace(material.Nome))
            {
                return OperationResult.CreateValidationError("Nome do material é obrigatório");
            }
            
            if (string.IsNullOrWhiteSpace(material.UnidadeMedida))
            {
                return OperationResult.CreateValidationError("Unidade de medida é obrigatória");
            }

            // ========================================================
            // REGRA DE NEGÓCIO 3: Validar estoque
            // ========================================================
            
            if (material.EstoqueMinimo.HasValue && material.EstoqueMaximo.HasValue)
            {
                if (material.EstoqueMinimo.Value > material.EstoqueMaximo.Value)
                {
                    return OperationResult.CreateValidationError(
                        "Estoque mínimo não pode ser maior que estoque máximo");
                }
            }
            
            if (material.QuantidadeEstoque < 0)
            {
                return OperationResult.CreateValidationError(
                    "Quantidade em estoque não pode ser negativa");
            }

            // ========================================================
            // CHAMA O REPOSITORY PARA ATUALIZAR NO BANCO
            // ========================================================
            var resultado = await _repository.Atualizar(material);

            // Registra no log
            if (resultado.Success)
            {
                _logger.LogInformation("Material ID " + material.Id + " atualizado com sucesso");
            }
            else
            {
                _logger.LogError("Erro ao atualizar material ID " + material.Id + ": " + resultado.Message);
            }

            return resultado;
        }

        // =====================================================================
        // DELETAR MATERIAL (soft delete)
        // =====================================================================
        public async Task<OperationResult> Deletar(int id)
        {
            // Registra no log
            _logger.LogInformation("Deletando material ID: " + id);

            // Chama o repository para deletar
            var resultado = await _repository.Deletar(id);

            // Registra no log
            if (resultado.Success)
            {
                _logger.LogInformation("Material ID " + id + " deletado com sucesso");
            }
            else
            {
                _logger.LogError("Erro ao deletar material ID " + id + ": " + resultado.Message);
            }

            return resultado;
        }
    }
}