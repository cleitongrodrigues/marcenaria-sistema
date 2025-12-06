using backend.Context;
using backend.DTOs;
using backend.Interfaces;
using Dapper;
using System.Data;

namespace backend.Repositories
{
    public class ClienteRepository : IClienteRepository
    {
        private readonly DapperContext _context;

        public ClienteRepository(DapperContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<ClienteDTO>> ListarTodos()
        {
            var sql = "SELECT * FROM Clientes WHERE Ativo = 1 ORDER BY Nome";
            
            using (var connection = _context.CreateConnection())
            {
                return await connection.QueryAsync<ClienteDTO>(sql);
            }
        }

        public async Task<(int Id, string Error)> Criar(ClienteDTO cliente)
        {
            using (var connection = _context.CreateConnection())
            {
                try
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@Acao", "C");
                    parametros.Add("@Nome", cliente.Nome);
                    parametros.Add("@CPF", cliente.CPF);
                    parametros.Add("@Telefone", cliente.Telefone);
                    
                    // Endereço
                    parametros.Add("@Logradouro", cliente.Logradouro);
                    parametros.Add("@Numero", cliente.Numero);
                    parametros.Add("@Bairro", cliente.Bairro);
                    parametros.Add("@Cidade", cliente.Cidade);
                    parametros.Add("@UF", cliente.UF);
                    parametros.Add("@CEP", cliente.CEP);
                    parametros.Add("@Complemento", cliente.Complemento);

                    // Saídas - ajustado o tamanho para 255 conforme a procedure
                    parametros.Add("@Return_Code", dbType: DbType.Int16, direction: ParameterDirection.Output);
                    parametros.Add("@Error", dbType: DbType.String, size: 255, direction: ParameterDirection.Output);

                    var resultado = await connection.QueryFirstOrDefaultAsync<int?>("st_Gerenciar_Cliente", parametros, commandType: CommandType.StoredProcedure);

                    int returnCode = parametros.Get<short>("@Return_Code");
                    string errorMsg = parametros.Get<string>("@Error") ?? string.Empty;

                    // Se ReturnCode != 0, retorna o erro
                    if (returnCode != 0)
                        return (0, errorMsg);

                    // Se deu certo, retorna o ID e erro vazio
                    return (resultado ?? 0, string.Empty);
                }
                catch (Exception ex)
                {
                    // Captura erros de RAISERROR ou outras exceções SQL
                    return (0, ex.Message);
                }
            }
        }

        public async Task<(bool Sucesso, string Error)> Atualizar(ClienteDTO cliente)
        {
            using (var connection = _context.CreateConnection())
            {
                try
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@Acao", "U");
                    parametros.Add("@Id", cliente.Id);
                    parametros.Add("@Nome", cliente.Nome);
                    parametros.Add("@CPF", cliente.CPF);
                    parametros.Add("@Telefone", cliente.Telefone);
                    
                    // Endereço
                    parametros.Add("@Logradouro", cliente.Logradouro);
                    parametros.Add("@Numero", cliente.Numero);
                    parametros.Add("@Bairro", cliente.Bairro);
                    parametros.Add("@Cidade", cliente.Cidade);
                    parametros.Add("@UF", cliente.UF);
                    parametros.Add("@CEP", cliente.CEP);
                    parametros.Add("@Complemento", cliente.Complemento);

                    // Saídas
                    parametros.Add("@Return_Code", dbType: DbType.Int16, direction: ParameterDirection.Output);
                    parametros.Add("@Error", dbType: DbType.String, size: 255, direction: ParameterDirection.Output);

                    await connection.ExecuteAsync("st_Gerenciar_Cliente", parametros, commandType: CommandType.StoredProcedure);

                    int returnCode = parametros.Get<short>("@Return_Code");
                    string errorMsg = parametros.Get<string>("@Error") ?? string.Empty;

                    if (returnCode != 0)
                        return (false, errorMsg);

                    return (true, string.Empty);
                }
                catch (Exception ex)
                {
                    return (false, ex.Message);
                }
            }
        }

        public async Task<(bool Sucesso, string Error)> Deletar(int id)
        {
            using (var connection = _context.CreateConnection())
            {
                try
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@Acao", "D");
                    parametros.Add("@Id", id);

                    // Saídas
                    parametros.Add("@Return_Code", dbType: DbType.Int16, direction: ParameterDirection.Output);
                    parametros.Add("@Error", dbType: DbType.String, size: 255, direction: ParameterDirection.Output);

                    await connection.ExecuteAsync("st_Gerenciar_Cliente", parametros, commandType: CommandType.StoredProcedure);

                    int returnCode = parametros.Get<short>("@Return_Code");
                    string errorMsg = parametros.Get<string>("@Error") ?? string.Empty;

                    if (returnCode != 0)
                        return (false, errorMsg);

                    return (true, string.Empty);
                }
                catch (Exception ex)
                {
                    return (false, ex.Message);
                }
            }
        }
    }
}