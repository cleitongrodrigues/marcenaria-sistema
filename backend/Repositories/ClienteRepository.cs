using backend.Context;
using backend.DTOs;
using backend.Interfaces;
using backend.Common;
using Dapper;
using System.Data;

namespace backend.Repositories
{
    // =========================================================================
    // REPOSITÓRIO DE CLIENTES - Conversa com o banco de dados
    // =========================================================================
    // Este arquivo é responsável por TODAS as operações de banco relacionadas
    // a clientes: listar, criar, atualizar, deletar
    // =========================================================================
    
    public class ClienteRepository : IClienteRepository
    {
        // Guarda a conexão com o banco de dados
        private readonly DapperContext _context;

        // Construtor - recebe a conexão quando a classe é criada
        public ClienteRepository(DapperContext context)
        {
            _context = context;
        }

        // =====================================================================
        // LISTAR TODOS OS CLIENTES (COM PAGINAÇÃO)
        // =====================================================================
        public async Task<ClienteListResult> ListarTodos(ListParameters parameters)
        {
            // Valida os parâmetros (não deixa pedir mais de 100 itens, etc)
            parameters.Validate();

            // Abre conexão com o banco
            using (var connection = _context.CreateConnection())
            {
                // ============================================================
                // PASSO 1: Contar quantos clientes existem no total
                // ============================================================
                var sqlCount = "SELECT COUNT(*) FROM Clientes WHERE Ativo = 1";
                
                // Se o usuário digitou algo para buscar (ex: "Silva")
                if (!string.IsNullOrEmpty(parameters.SearchTerm))
                {
                    sqlCount += " AND (Nome LIKE @SearchTerm OR CPF LIKE @SearchTerm OR CNPJ LIKE @SearchTerm OR Email LIKE @SearchTerm)";
                }

                // Executa a query de contagem
                var totalClientes = await connection.ExecuteScalarAsync<int>(
                    sqlCount, 
                    new { SearchTerm = $"%{parameters.SearchTerm}%" }
                );

                // ============================================================
                // PASSO 2: Buscar apenas os clientes da página atual
                // ============================================================
                // Ex: Se está na página 2 e mostra 50 por vez, pula os primeiros 50
                var sqlClientes = @"
                    SELECT Id, TipoPessoa, Nome, NomeFantasia, CPF, CNPJ, 
                           InscricaoEstadual, Email, Observacao, Ativo, 
                           DataCriacao, DataAlteracao
                    FROM Clientes 
                    WHERE Ativo = 1";

                // Adiciona filtro de busca se necessário
                if (!string.IsNullOrEmpty(parameters.SearchTerm))
                {
                    sqlClientes += " AND (Nome LIKE @SearchTerm OR CPF LIKE @SearchTerm OR CNPJ LIKE @SearchTerm OR Email LIKE @SearchTerm)";
                }

                // Adiciona paginação (OFFSET = quantos pular, FETCH = quantos pegar)
                sqlClientes += @"
                    ORDER BY Nome
                    OFFSET @QuantosPular ROWS
                    FETCH NEXT @QuantosPegar ROWS ONLY";

                // Calcula quantos registros pular
                // Ex: Página 2 com 50 itens = pular os primeiros 50 (1 * 50)
                int quantosPular = (parameters.Page - 1) * parameters.PageSize;

                // Executa a query e pega os clientes
                var clientes = await connection.QueryAsync<ClienteDTO>(
                    sqlClientes,
                    new 
                    { 
                        SearchTerm = $"%{parameters.SearchTerm}%",
                        QuantosPular = quantosPular,
                        QuantosPegar = parameters.PageSize
                    }
                );

                // ============================================================
                // PASSO 3: Montar o resultado com informações de paginação
                // ============================================================
                var totalPaginas = (int)Math.Ceiling(totalClientes / (double)parameters.PageSize);

                return new ClienteListResult
                {
                    Items = clientes.ToList(),
                    TotalItems = totalClientes,
                    TotalPages = totalPaginas,
                    CurrentPage = parameters.Page,
                    PageSize = parameters.PageSize,
                    HasPreviousPage = parameters.Page > 1,
                    HasNextPage = parameters.Page < totalPaginas
                };
            }
        }

        // =====================================================================
        // OBTER UM CLIENTE POR ID (COM TELEFONES E ENDEREÇOS)
        // =====================================================================
        public async Task<ClienteComDetalhesDTO?> ObterPorId(int id)
        {
            using (var connection = _context.CreateConnection())
            {
                // ============================================================
                // PASSO 1: Buscar o cliente
                // ============================================================
                var sqlCliente = @"
                    SELECT Id, TipoPessoa, Nome, NomeFantasia, CPF, CNPJ, 
                           InscricaoEstadual, Email, Observacao, Ativo, 
                           DataCriacao, DataAlteracao
                    FROM Clientes 
                    WHERE Id = @Id AND Ativo = 1";

                var cliente = await connection.QueryFirstOrDefaultAsync<ClienteComDetalhesDTO>(
                    sqlCliente, 
                    new { Id = id }
                );

                // Se não encontrou o cliente, retorna null
                if (cliente == null)
                {
                    return null;
                }

                // ============================================================
                // PASSO 2: Buscar os telefones deste cliente
                // ============================================================
                var sqlTelefones = "SELECT * FROM Telefones WHERE ClienteId = @ClienteId";
                var telefones = await connection.QueryAsync<TelefoneDTO>(
                    sqlTelefones, 
                    new { ClienteId = id }
                );
                cliente.Telefones = telefones.ToList();

                // ============================================================
                // PASSO 3: Buscar os endereços deste cliente
                // ============================================================
                var sqlEnderecos = "SELECT * FROM Enderecos WHERE ClienteId = @ClienteId";
                var enderecos = await connection.QueryAsync<EnderecoDTO>(
                    sqlEnderecos, 
                    new { ClienteId = id }
                );
                cliente.Enderecos = enderecos.ToList();

                // Retorna o cliente completo com telefones e endereços
                return cliente;
            }
        }

        // =====================================================================
        // CRIAR NOVO CLIENTE
        // =====================================================================
        public async Task<CreateResult> Criar(ClienteDTO cliente)
        {
            using (var connection = _context.CreateConnection())
            {
                try
                {
                    // ========================================================
                    // Preparar os parâmetros para chamar a stored procedure
                    // ========================================================
                    var parametros = new DynamicParameters();
                    
                    // Parâmetros de entrada (dados do cliente)
                    parametros.Add("@Acao", "C"); // C = Criar
                    parametros.Add("@TipoPessoa", cliente.TipoPessoa);
                    parametros.Add("@Nome", cliente.Nome);
                    parametros.Add("@NomeFantasia", cliente.NomeFantasia);
                    parametros.Add("@CPF", cliente.CPF);
                    parametros.Add("@CNPJ", cliente.CNPJ);
                    parametros.Add("@InscricaoEstadual", cliente.InscricaoEstadual);
                    parametros.Add("@Email", cliente.Email);
                    parametros.Add("@Observacao", cliente.Observacao);

                    // Parâmetros de saída (a procedure vai preencher estes valores)
                    parametros.Add("@Return_Code", dbType: DbType.Int16, direction: ParameterDirection.Output);
                    parametros.Add("@Error", dbType: DbType.String, size: 255, direction: ParameterDirection.Output);

                    // ========================================================
                    // Executar a stored procedure
                    // ========================================================
                    var idGerado = await connection.QueryFirstOrDefaultAsync<int?>(
                        "st_Gerenciar_Cliente", 
                        parametros, 
                        commandType: CommandType.StoredProcedure
                    );

                    // ========================================================
                    // Pegar os valores de retorno da procedure
                    // ========================================================
                    int returnCode = parametros.Get<short>("@Return_Code");
                    string errorMessage = parametros.Get<string>("@Error") ?? string.Empty;

                    // ========================================================
                    // Verificar se deu erro
                    // ========================================================
                    // Se returnCode for diferente de 0, deu erro
                    if (returnCode != 0)
                    {
                        return CreateResult.CreateError(errorMessage, returnCode);
                    }

                    // ========================================================
                    // Sucesso! Retornar o ID gerado
                    // ========================================================
                    return CreateResult.CreateSuccess(idGerado ?? 0, "Cliente criado com sucesso");
                }
                catch (Exception ex)
                {
                    // Se der erro de conexão ou qualquer outro erro inesperado
                    return CreateResult.CreateError($"Erro ao criar cliente: {ex.Message}");
                }
            }
        }

        // =====================================================================
        // ATUALIZAR CLIENTE EXISTENTE
        // =====================================================================
        public async Task<OperationResult> Atualizar(ClienteDTO cliente)
        {
            using (var connection = _context.CreateConnection())
            {
                try
                {
                    var parametros = new DynamicParameters();
                    
                    // Parâmetros de entrada
                    parametros.Add("@Acao", "U"); // U = Update (atualizar)
                    parametros.Add("@Id", cliente.Id);
                    parametros.Add("@TipoPessoa", cliente.TipoPessoa);
                    parametros.Add("@Nome", cliente.Nome);
                    parametros.Add("@NomeFantasia", cliente.NomeFantasia);
                    parametros.Add("@CPF", cliente.CPF);
                    parametros.Add("@CNPJ", cliente.CNPJ);
                    parametros.Add("@InscricaoEstadual", cliente.InscricaoEstadual);
                    parametros.Add("@Email", cliente.Email);
                    parametros.Add("@Observacao", cliente.Observacao);

                    // Parâmetros de saída
                    parametros.Add("@Return_Code", dbType: DbType.Int16, direction: ParameterDirection.Output);
                    parametros.Add("@Error", dbType: DbType.String, size: 255, direction: ParameterDirection.Output);

                    // Executar a procedure
                    await connection.ExecuteAsync(
                        "st_Gerenciar_Cliente", 
                        parametros, 
                        commandType: CommandType.StoredProcedure
                    );

                    // Pegar valores de retorno
                    int returnCode = parametros.Get<short>("@Return_Code");
                    string errorMessage = parametros.Get<string>("@Error") ?? string.Empty;

                    // Verificar se deu erro
                    if (returnCode != 0)
                    {
                        // Verificar o tipo de erro
                        if (returnCode == 2)
                            return OperationResult.CreateValidationError(errorMessage);
                        if (returnCode == 3)
                            return OperationResult.CreateNotFound(errorMessage);
                        
                        return OperationResult.CreateError(errorMessage);
                    }

                    // Sucesso!
                    return OperationResult.CreateSuccess("Cliente atualizado com sucesso");
                }
                catch (Exception ex)
                {
                    return OperationResult.CreateError($"Erro ao atualizar cliente: {ex.Message}");
                }
            }
        }

        // =====================================================================
        // DELETAR CLIENTE (SOFT DELETE - só marca como inativo)
        // =====================================================================
        public async Task<OperationResult> Deletar(int id)
        {
            using (var connection = _context.CreateConnection())
            {
                try
                {
                    var parametros = new DynamicParameters();
                    
                    // Parâmetros de entrada
                    parametros.Add("@Acao", "D"); // D = Delete (deletar)
                    parametros.Add("@Id", id);

                    // Parâmetros de saída
                    parametros.Add("@Return_Code", dbType: DbType.Int16, direction: ParameterDirection.Output);
                    parametros.Add("@Error", dbType: DbType.String, size: 255, direction: ParameterDirection.Output);

                    // Executar a procedure
                    await connection.ExecuteAsync(
                        "st_Gerenciar_Cliente", 
                        parametros, 
                        commandType: CommandType.StoredProcedure
                    );

                    // Pegar valores de retorno
                    int returnCode = parametros.Get<short>("@Return_Code");
                    string errorMessage = parametros.Get<string>("@Error") ?? string.Empty;

                    // Verificar se deu erro
                    if (returnCode != 0)
                    {
                        if (returnCode == 3)
                            return OperationResult.CreateNotFound("Cliente não encontrado");
                        
                        return OperationResult.CreateError(errorMessage);
                    }

                    // Sucesso!
                    return OperationResult.CreateSuccess("Cliente removido com sucesso");
                }
                catch (Exception ex)
                {
                    return OperationResult.CreateError($"Erro ao deletar cliente: {ex.Message}");
                }
            }
        }
    }
}