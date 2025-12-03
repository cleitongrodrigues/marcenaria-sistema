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

                // Saídas
                parametros.Add("@Return_Code", dbType: DbType.Int16, direction: ParameterDirection.Output);
                parametros.Add("@Error", dbType: DbType.String, size: 1000, direction: ParameterDirection.Output);

                var idGerado = await connection.QueryFirstOrDefaultAsync<int>("st_Gerenciar_Cliente", parametros, commandType: CommandType.StoredProcedure);

                int returnCode = parametros.Get<short>("@Return_Code");
                string errorMsg = parametros.Get<string>("@Error");

                // Se ReturnCode != 0, retorna o erro
                if (returnCode != 0)
                    return (0, errorMsg);

                // Se deu certo, retorna o ID e erro vazio
                return (idGerado, string.Empty);
            }
        }
    }
}