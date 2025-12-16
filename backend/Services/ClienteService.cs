using backend.DTOs;
using backend.Interfaces;
using backend.Common;

namespace backend.Services
{
    // =========================================================================
    // SERVIÇO DE CLIENTES - Regras de negócio
    // =========================================================================
    // O Service fica entre o Controller e o Repository
    // Ele aplica REGRAS DE NEGÓCIO antes de salvar no banco
    // Exemplo: validar CPF, normalizar dados, etc.
    // =========================================================================
    
    public class ClienteService : IClienteService
    {
        // Repository para acessar o banco
        private readonly IClienteRepository _repository;
        
        // Logger para registrar o que está acontecendo (útil para debugar)
        private readonly ILogger<ClienteService> _logger;

        // Construtor - recebe as dependências
        public ClienteService(IClienteRepository repository, ILogger<ClienteService> logger)
        {
            _repository = repository;
            _logger = logger;
        }

        // =====================================================================
        // LISTAR TODOS OS CLIENTES
        // =====================================================================
        public async Task<ClienteListResult> ListarTodos(ListParameters parameters)
        {
            // Registra no log que está listando
            _logger.LogInformation($"Listando clientes - Página {parameters.Page}, Busca: {parameters.SearchTerm}");
            
            // Simplesmente chama o repository (não tem regra de negócio aqui)
            var resultado = await _repository.ListarTodos(parameters);
            
            // Registra quantos clientes foram encontrados
            _logger.LogInformation($"Encontrados {resultado.TotalItems} clientes");
            
            return resultado;
        }

        // =====================================================================
        // OBTER UM CLIENTE POR ID
        // =====================================================================
        public async Task<ClienteComDetalhesDTO?> ObterPorId(int id)
        {
            _logger.LogInformation($"Buscando cliente ID: {id}");
            
            // Busca o cliente no banco
            var cliente = await _repository.ObterPorId(id);
            
            if (cliente == null)
            {
                _logger.LogWarning($"Cliente ID {id} não encontrado");
            }
            
            return cliente;
        }

        // =====================================================================
        // CRIAR NOVO CLIENTE (COM VALIDAÇÕES)
        // =====================================================================
        public async Task<CreateResult> Criar(ClienteDTO cliente)
        {
            _logger.LogInformation($"Criando cliente: {cliente.Nome}");
            
            // =================================================================
            // REGRA DE NEGÓCIO 1: Limpar e padronizar os dados
            // =================================================================
            
            // TipoPessoa sempre em maiúscula (F ou J)
            if (cliente.TipoPessoa != null)
                cliente.TipoPessoa = cliente.TipoPessoa.ToUpper().Trim();
            else
                cliente.TipoPessoa = "F"; // Padrão: Pessoa Física
            
            // Nome sem espaços nas pontas
            if (cliente.Nome != null)
                cliente.Nome = cliente.Nome.Trim();
            
            // Email sempre em minúscula
            if (cliente.Email != null)
                cliente.Email = cliente.Email.Trim().ToLower();
            
            // CPF: remover pontos e traços (guardar só números)
            if (!string.IsNullOrEmpty(cliente.CPF))
            {
                cliente.CPF = cliente.CPF.Replace(".", "");
                cliente.CPF = cliente.CPF.Replace("-", "");
                cliente.CPF = cliente.CPF.Trim();
            }
            
            // CNPJ: remover pontos, traços e barra
            if (!string.IsNullOrEmpty(cliente.CNPJ))
            {
                cliente.CNPJ = cliente.CNPJ.Replace(".", "");
                cliente.CNPJ = cliente.CNPJ.Replace("-", "");
                cliente.CNPJ = cliente.CNPJ.Replace("/", "");
                cliente.CNPJ = cliente.CNPJ.Trim();
            }
            
            // =================================================================
            // REGRA DE NEGÓCIO 2: Validar dados obrigatórios
            // =================================================================
            
            // Se for Pessoa Física, CPF é obrigatório
            if (cliente.TipoPessoa == "F" && string.IsNullOrEmpty(cliente.CPF))
            {
                _logger.LogWarning("Tentou criar Pessoa Física sem CPF");
                return CreateResult.CreateError("CPF é obrigatório para Pessoa Física", 2);
            }
            
            // Se for Pessoa Jurídica, CNPJ é obrigatório
            if (cliente.TipoPessoa == "J" && string.IsNullOrEmpty(cliente.CNPJ))
            {
                _logger.LogWarning("Tentou criar Pessoa Jurídica sem CNPJ");
                return CreateResult.CreateError("CNPJ é obrigatório para Pessoa Jurídica", 2);
            }
            
            // =================================================================
            // CHAMA O REPOSITORY PARA SALVAR NO BANCO
            // =================================================================
            var resultado = await _repository.Criar(cliente);
            
            // Registra no log o resultado
            if (resultado.Success)
                _logger.LogInformation($"Cliente criado com sucesso! ID: {resultado.GeneratedId}");
            else
                _logger.LogError($"Erro ao criar cliente: {resultado.Message}");
            
            return resultado;
        }

        // =====================================================================
        // ATUALIZAR CLIENTE EXISTENTE
        // =====================================================================
        public async Task<OperationResult> Atualizar(ClienteDTO cliente)
        {
            _logger.LogInformation($"Atualizando cliente ID: {cliente.Id}");
            
            // =================================================================
            // Limpar e padronizar os dados (mesma lógica do Criar)
            // =================================================================
            if (cliente.TipoPessoa != null)
                cliente.TipoPessoa = cliente.TipoPessoa.ToUpper().Trim();
            else
                cliente.TipoPessoa = "F";
            
            if (cliente.Nome != null)
                cliente.Nome = cliente.Nome.Trim();
            
            if (cliente.Email != null)
                cliente.Email = cliente.Email.Trim().ToLower();
            
            if (!string.IsNullOrEmpty(cliente.CPF))
            {
                cliente.CPF = cliente.CPF.Replace(".", "");
                cliente.CPF = cliente.CPF.Replace("-", "");
                cliente.CPF = cliente.CPF.Trim();
            }
            
            if (!string.IsNullOrEmpty(cliente.CNPJ))
            {
                cliente.CNPJ = cliente.CNPJ.Replace(".", "");
                cliente.CNPJ = cliente.CNPJ.Replace("-", "");
                cliente.CNPJ = cliente.CNPJ.Replace("/", "");
                cliente.CNPJ = cliente.CNPJ.Trim();
            }
            
            // =================================================================
            // Chamar o repository para atualizar no banco
            // =================================================================
            var resultado = await _repository.Atualizar(cliente);
            
            if (resultado.Success)
                _logger.LogInformation($"Cliente ID {cliente.Id} atualizado com sucesso");
            else
                _logger.LogError($"Erro ao atualizar cliente {cliente.Id}: {resultado.Message}");
            
            return resultado;
        }

        // =====================================================================
        // DELETAR CLIENTE (SOFT DELETE)
        // =====================================================================
        public async Task<OperationResult> Deletar(int id)
        {
            _logger.LogInformation($"Deletando cliente ID: {id}");
            
            // Simplesmente chama o repository (não tem regra de negócio aqui)
            var resultado = await _repository.Deletar(id);
            
            if (resultado.Success)
                _logger.LogInformation($"Cliente ID {id} deletado (soft delete)");
            else
                _logger.LogError($"Erro ao deletar cliente {id}: {resultado.Message}");
            
            return resultado;
        }
    }
}
