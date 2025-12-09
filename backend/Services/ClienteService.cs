using backend.DTOs;
using backend.Interfaces;

namespace backend.Services
{
    public class ClienteService : IClienteService
    {
        private readonly IClienteRepository _repository;
        private readonly ILogger<ClienteService> _logger;

        public ClienteService(IClienteRepository repository, ILogger<ClienteService> logger)
        {
            _repository = repository;
            _logger = logger;
        }

        public async Task<IEnumerable<ClienteDTO>> ListarTodos()
        {
            _logger.LogInformation("Listando todos os clientes ativos");
            
            var clientes = await _repository.ListarTodos();
            
            _logger.LogInformation("Total de clientes encontrados: {Count}", clientes.Count());
            
            return clientes;
        }

        public async Task<(int Id, string Error)> Criar(ClienteDTO cliente)
        {
            _logger.LogInformation("Iniciando criação de cliente: {Nome}", cliente.Nome);
            
            // REGRA DE NEGÓCIO 1: Normalizar dados antes de salvar
            cliente.Nome = cliente.Nome?.Trim().ToUpper();
            cliente.CPF = cliente.CPF?.Replace(".", "").Replace("-", "").Trim();
            cliente.Telefone = cliente.Telefone?.Replace("(", "").Replace(")", "").Replace("-", "").Replace(" ", "").Trim();
            cliente.UF = cliente.UF?.ToUpper();
            cliente.CEP = cliente.CEP?.Replace("-", "").Trim();
            
            // REGRA DE NEGÓCIO 2: Validar CPF (básico - apenas formato)
            if (!string.IsNullOrEmpty(cliente.CPF) && cliente.CPF.Length != 11)
            {
                _logger.LogWarning("CPF inválido fornecido: {CPF}", cliente.CPF);
                return (0, "CPF deve conter 11 dígitos (apenas números)");
            }
            
            // REGRA DE NEGÓCIO 3: Validar UF
            var ufsValidas = new[] { "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA", 
                                     "MT", "MS", "MG", "PA", "PB", "PR", "PE", "PI", "RJ", "RN", 
                                     "RS", "RO", "RR", "SC", "SP", "SE", "TO" };
            if (!ufsValidas.Contains(cliente.UF))
            {
                _logger.LogWarning("UF inválida fornecida: {UF}", cliente.UF);
                return (0, "UF inválida. Informe uma sigla válida (ex: SP, RJ, MG)");
            }
            
            var resultado = await _repository.Criar(cliente);
            
            if (string.IsNullOrEmpty(resultado.Error))
            {
                _logger.LogInformation("Cliente criado com sucesso. ID: {Id}, Nome: {Nome}", resultado.Id, cliente.Nome);
                
                // REGRA DE NEGÓCIO 4: Aqui você poderia enviar email, notificar CRM, etc.
                // await _emailService.EnviarBoasVindas(cliente.Email);
            }
            else
            {
                _logger.LogError("Erro ao criar cliente {Nome}: {Error}", cliente.Nome, resultado.Error);
            }
            
            return resultado;
        }

        public async Task<(bool Sucesso, string Error)> Atualizar(ClienteDTO cliente)
        {
            _logger.LogInformation("Iniciando atualização do cliente ID: {Id}", cliente.Id);
            
            // REGRA DE NEGÓCIO: Normalizar dados antes de atualizar (mesma lógica do Criar)
            cliente.Nome = cliente.Nome?.Trim().ToUpper();
            cliente.CPF = cliente.CPF?.Replace(".", "").Replace("-", "").Trim();
            cliente.Telefone = cliente.Telefone?.Replace("(", "").Replace(")", "").Replace("-", "").Replace(" ", "").Trim();
            cliente.UF = cliente.UF?.ToUpper();
            cliente.CEP = cliente.CEP?.Replace("-", "").Trim();
            
            // REGRA DE NEGÓCIO: Validar CPF
            if (!string.IsNullOrEmpty(cliente.CPF) && cliente.CPF.Length != 11)
            {
                return (false, "CPF deve conter 11 dígitos (apenas números)");
            }
            
            // REGRA DE NEGÓCIO: Validar UF
            var ufsValidas = new[] { "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA", 
                                     "MT", "MS", "MG", "PA", "PB", "PR", "PE", "PI", "RJ", "RN", 
                                     "RS", "RO", "RR", "SC", "SP", "SE", "TO" };
            if (!ufsValidas.Contains(cliente.UF))
            {
                return (false, "UF inválida. Informe uma sigla válida (ex: SP, RJ, MG)");
            }
            
            var resultado = await _repository.Atualizar(cliente);
            
            if (resultado.Sucesso)
            {
                _logger.LogInformation("Cliente ID {Id} atualizado com sucesso", cliente.Id);
                
                // REGRA DE NEGÓCIO: Registrar auditoria, notificar mudanças, etc.
            }
            else
            {
                _logger.LogError("Erro ao atualizar cliente ID {Id}: {Error}", cliente.Id, resultado.Error);
            }
            
            return resultado;
        }

        public async Task<(bool Sucesso, string Error)> Deletar(int id)
        {
            _logger.LogInformation("Iniciando exclusão do cliente ID: {Id}", id);
            
            // REGRA DE NEGÓCIO: Aqui você poderia verificar se cliente tem orçamentos ativos
            // var temOrcamentosAtivos = await _orcamentoRepository.ClienteTemOrcamentosAtivos(id);
            // if (temOrcamentosAtivos)
            // {
            //     return (false, "Não é possível excluir cliente com orçamentos ativos");
            // }
            
            var resultado = await _repository.Deletar(id);
            
            if (resultado.Sucesso)
            {
                _logger.LogInformation("Cliente ID {Id} excluído com sucesso", id);
                
                // REGRA DE NEGÓCIO: Notificar sistemas externos, arquivar dados, etc.
            }
            else
            {
                _logger.LogError("Erro ao excluir cliente ID {Id}: {Error}", id, resultado.Error);
            }
            
            return resultado;
        }
    }
}
