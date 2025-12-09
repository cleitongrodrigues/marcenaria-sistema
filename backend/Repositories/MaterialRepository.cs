using backend.Interfaces;
using backend.Context;
using backend.DTOs;
using System.Data;
using Dapper;

namespace backend.Repositories
{
    public class MaterialRepository : IMaterialRepository
    {
        private readonly DapperContext _context;
        public MaterialRepository(DapperContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<MaterialDTO>> ListarTodos()
        {
            var sql = "SELECT * FROM dbo.Materiais WHERE Ativo = 1 ORDER BY Nome";

            using (var connection = _context.CreateConnection())
            {
                return await connection.QueryAsync<MaterialDTO>(sql);
            }            
        }

        public async Task<(int Id, string Error)> Criar(MaterialDTO material)
        {
            using (var connection = _context.CreateConnection())
            {
                try
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@Acao", "C");
                    parametros.Add("@Nome", material.Nome);
                    parametros.Add("@Categoria", material.Categoria);
                    parametros.Add("@PrecoUnitario", material.PrecoUnitario);
                    parametros.Add("@UnidadeMedida", material.UnidadeMedida);
                    parametros.Add("@Return_Code", dbType: DbType.Int16, direction: ParameterDirection.Output);
                    parametros.Add("@Error", dbType: DbType.String, size: 255, direction: ParameterDirection.Output);

                    var resultado = await connection.QueryFirstOrDefaultAsync<int?>("st_Gerenciar_Material", parametros, commandType: CommandType.StoredProcedure);

                    int returnCode = parametros.Get<short>("@Return_Code");
                    string errorMsg = parametros.Get<string>("@Error") ?? string.Empty;

                    if (returnCode != 0)
                        return (0, errorMsg);
                    
                    return (resultado ?? 0, string.Empty);
                }
                catch (Exception ex)
                {
                    return (0, ex.Message);
                }
            }
        }

        public async Task<(bool Sucesso, string Error)> Atualizar(MaterialDTO material)
        {
            using (var connection = _context.CreateConnection())
            {
                try
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@Acao", "U");
                    parametros.Add("@Id", material.Id);
                    parametros.Add("@Nome", material.Nome);
                    parametros.Add("@Categoria", material.Categoria);
                    parametros.Add("@PrecoUnitario", material.PrecoUnitario);
                    parametros.Add("@UnidadeMedida", material.UnidadeMedida);
                    parametros.Add("@Return_Code", dbType: DbType.Int16, direction: ParameterDirection.Output);
                    parametros.Add("@Error", dbType: DbType.String, size: 255, direction: ParameterDirection.Output);

                    var resultado = await connection.ExecuteAsync("st_Gerenciar_Material", parametros, commandType: CommandType.StoredProcedure);

                    int returnCode = parametros.Get<short>("@Return_Code");
                    string errorMsg = parametros.Get<string>("@Error") ?? string.Empty;

                    if (returnCode != 0)
                    {
                        return (false, errorMsg);
                    }

                    return (true, string.Empty);                    
                } catch (Exception ex)
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
                    parametros.Add("@Return_Code", dbType: DbType.Int16, direction: ParameterDirection.Output);
                    parametros.Add("@Error", dbType: DbType.String, size: 255, direction: ParameterDirection.Output);

                    await connection.ExecuteAsync("st_Gerenciar_Material", parametros, commandType: CommandType.StoredProcedure);

                    int returnCode = parametros.Get<short>("@Return_Code");
                    string errorMsg = parametros.Get<string>("@Error") ?? string.Empty;

                    if (returnCode != 0)
                    {
                        return (false, errorMsg);
                    }


                    return (true, string.Empty);
                } catch (Exception ex)
                {
                    return (false, ex.Message);
                }
            }
        }
    }
}