using backend.Interfaces;
using backend.Context;
using backend.DTOs;
using backend.Common;
using System.Data;
using Dapper;

namespace backend.Repositories
{
    // =========================================================================
    // REPOSITORY DE MATERIAIS - Acessa o banco de dados
    // =========================================================================
    // Este repository é responsável por fazer todas as operações de banco
    // relacionadas a materiais (produtos/insumos da marcenaria)
    // =========================================================================
    
    public class MaterialRepository : IMaterialRepository
    {
        // Contexto do Dapper para criar conexões com o banco
        private readonly DapperContext _context;

        // Construtor - recebe o contexto
        public MaterialRepository(DapperContext context)
        {
            _context = context;
        }

        // =====================================================================
        // LISTAR TODOS OS MATERIAIS - Com paginação e filtro
        // =====================================================================
        public async Task<MaterialListResult> ListarTodos(ListParameters parameters)
        {
            // Cria conexão com o banco
            using var connection = _context.CreateConnection();
            
            // ========================================================
            // PASSO 1: Contar quantos materiais existem no total
            // ========================================================
            // Precisamos saber o total para calcular quantas páginas existem
            
            var sqlContagem = @"
                SELECT COUNT(*) 
                FROM Materiais m
                WHERE m.Ativo = 1
                    AND (@SearchTerm IS NULL OR @SearchTerm = '' OR 
                         m.Nome LIKE '%' + @SearchTerm + '%' OR 
                         m.Categoria LIKE '%' + @SearchTerm + '%' OR 
                         m.Descricao LIKE '%' + @SearchTerm + '%')";
            
            var totalMateriais = await connection.ExecuteScalarAsync<int>(
                sqlContagem, 
                new { SearchTerm = parameters.SearchTerm });
            
            // ========================================================
            // PASSO 2: Buscar apenas os materiais da página atual
            // ========================================================
            // OFFSET pula os registros das páginas anteriores
            // FETCH pega só a quantidade de registros desta página
            
            var offset = (parameters.Page - 1) * parameters.PageSize;
            
            var sqlBusca = @"
                SELECT 
                    m.Id, 
                    m.Nome, 
                    m.Descricao, 
                    m.Categoria, 
                    m.PrecoUnitario,
                    m.UnidadeMedida, 
                    m.QuantidadeEstoque, 
                    m.EstoqueMinimo, 
                    m.EstoqueMaximo,
                    m.Localizacao, 
                    m.Ativo, 
                    m.DataCriacao, 
                    m.DataAlteracao
                FROM Materiais m
                WHERE m.Ativo = 1
                    AND (@SearchTerm IS NULL OR @SearchTerm = '' OR 
                         m.Nome LIKE '%' + @SearchTerm + '%' OR 
                         m.Categoria LIKE '%' + @SearchTerm + '%' OR 
                         m.Descricao LIKE '%' + @SearchTerm + '%')
                ORDER BY m.Nome
                OFFSET @Offset ROWS
                FETCH NEXT @PageSize ROWS ONLY";
            
            var materiais = await connection.QueryAsync<MaterialDTO>(
                sqlBusca,
                new 
                { 
                    SearchTerm = parameters.SearchTerm, 
                    Offset = offset, 
                    PageSize = parameters.PageSize 
                });
            
            // ========================================================
            // PASSO 3: Montar o resultado com informações de paginação
            // ========================================================
            
            // Calcula quantas páginas existem no total
            var totalPaginas = (int)Math.Ceiling((double)totalMateriais / parameters.PageSize);
            
            // Monta o resultado
            var resultado = new MaterialListResult
            {
                Items = materiais.ToList(), // Lista de materiais desta página
                TotalItems = totalMateriais, // Total de materiais no banco
                TotalPages = totalPaginas, // Total de páginas
                CurrentPage = parameters.Page, // Página atual
                PageSize = parameters.PageSize, // Tamanho da página
                HasPreviousPage = parameters.Page > 1, // Tem página anterior?
                HasNextPage = parameters.Page < totalPaginas // Tem próxima página?
            };
            
            return resultado;
        }

        // =====================================================================
        // OBTER MATERIAL POR ID
        // =====================================================================
        public async Task<MaterialDTO?> ObterPorId(int id)
        {
            // Cria conexão com o banco
            using var connection = _context.CreateConnection();
            
            // SQL para buscar o material
            var sql = @"
                SELECT 
                    Id, 
                    Nome, 
                    Descricao, 
                    Categoria, 
                    PrecoUnitario,
                    UnidadeMedida, 
                    QuantidadeEstoque, 
                    EstoqueMinimo, 
                    EstoqueMaximo,
                    Localizacao, 
                    Ativo, 
                    DataCriacao, 
                    DataAlteracao
                FROM Materiais
                WHERE Id = @Id AND Ativo = 1";
            
            // Busca o material
            var material = await connection.QueryFirstOrDefaultAsync<MaterialDTO>(
                sql, 
                new { Id = id });
            
            // Retorna o material (ou null se não encontrou)
            return material;
        }

        // =====================================================================
        // CRIAR NOVO MATERIAL
        // =====================================================================
        public async Task<CreateResult> Criar(MaterialDTO material)
        {
            try
            {
                // Cria conexão com o banco
                using var connection = _context.CreateConnection();
                
                // ========================================================
                // Preparar os parâmetros para chamar a stored procedure
                // ========================================================
                var parametros = new DynamicParameters();
                
                // Ação: C = Create (criar)
                parametros.Add("@Acao", "C", DbType.String);
                
                // Dados do material
                parametros.Add("@Nome", material.Nome, DbType.String);
                parametros.Add("@Descricao", material.Descricao, DbType.String);
                parametros.Add("@Categoria", material.Categoria, DbType.String);
                parametros.Add("@PrecoUnitario", material.PrecoUnitario, DbType.Decimal);
                parametros.Add("@UnidadeMedida", material.UnidadeMedida, DbType.String);
                parametros.Add("@QuantidadeEstoque", material.QuantidadeEstoque, DbType.Decimal);
                parametros.Add("@EstoqueMinimo", material.EstoqueMinimo, DbType.Decimal);
                parametros.Add("@EstoqueMaximo", material.EstoqueMaximo, DbType.Decimal);
                parametros.Add("@Localizacao", material.Localizacao, DbType.String);
                
                // Parâmetros de saída (a procedure retorna estes valores)
                parametros.Add("@Return_Code", dbType: DbType.Int32, direction: ParameterDirection.Output);
                parametros.Add("@Error", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);
                parametros.Add("@Id", dbType: DbType.Int32, direction: ParameterDirection.Output);
                
                // ========================================================
                // Executar a stored procedure
                // ========================================================
                await connection.ExecuteAsync(
                    "st_Gerenciar_Material",
                    parametros,
                    commandType: CommandType.StoredProcedure);
                
                // ========================================================
                // Ler os valores de retorno
                // ========================================================
                var returnCode = parametros.Get<int>("@Return_Code");
                var errorMessage = parametros.Get<string>("@Error") ?? "";
                var idGerado = parametros.Get<int?>("@Id");
                
                // ========================================================
                // Verificar o código de retorno e montar o resultado
                // ========================================================
                
                // Return_Code = 0: Sucesso!
                if (returnCode == 0)
                {
                    return CreateResult.CreateSuccess(
                        idGerado ?? 0,
                        "Material cadastrado com sucesso");
                }
                
                // Return_Code = 2: Erro de validação (ex: estoque mínimo > máximo)
                if (returnCode == 2)
                {
                    return CreateResult.CreateValidationError(errorMessage);
                }
                
                // Return_Code = 1 ou outro: Erro do banco de dados
                return CreateResult.CreateError(errorMessage);
            }
            catch (Exception ex)
            {
                // Se deu algum erro inesperado (conexão, etc)
                return CreateResult.CreateError("Erro ao criar material: " + ex.Message);
            }
        }

        // =====================================================================
        // ATUALIZAR MATERIAL EXISTENTE
        // =====================================================================
        public async Task<OperationResult> Atualizar(MaterialDTO material)
        {
            try
            {
                // Cria conexão com o banco
                using var connection = _context.CreateConnection();
                
                // ========================================================
                // Preparar os parâmetros para chamar a stored procedure
                // ========================================================
                var parametros = new DynamicParameters();
                
                // Ação: U = Update (atualizar)
                parametros.Add("@Acao", "U", DbType.String);
                
                // ID do material a atualizar
                parametros.Add("@Id", material.Id, DbType.Int32);
                
                // Novos dados do material
                parametros.Add("@Nome", material.Nome, DbType.String);
                parametros.Add("@Descricao", material.Descricao, DbType.String);
                parametros.Add("@Categoria", material.Categoria, DbType.String);
                parametros.Add("@PrecoUnitario", material.PrecoUnitario, DbType.Decimal);
                parametros.Add("@UnidadeMedida", material.UnidadeMedida, DbType.String);
                parametros.Add("@EstoqueMinimo", material.EstoqueMinimo, DbType.Decimal);
                parametros.Add("@EstoqueMaximo", material.EstoqueMaximo, DbType.Decimal);
                parametros.Add("@Localizacao", material.Localizacao, DbType.String);
                
                // Parâmetros de saída
                parametros.Add("@Return_Code", dbType: DbType.Int32, direction: ParameterDirection.Output);
                parametros.Add("@Error", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);
                
                // ========================================================
                // Executar a stored procedure
                // ========================================================
                await connection.ExecuteAsync(
                    "st_Gerenciar_Material",
                    parametros,
                    commandType: CommandType.StoredProcedure);
                
                // ========================================================
                // Ler os valores de retorno e montar resultado
                // ========================================================
                var returnCode = parametros.Get<int>("@Return_Code");
                var errorMessage = parametros.Get<string>("@Error") ?? "";
                
                // Return_Code = 0: Sucesso!
                if (returnCode == 0)
                {
                    return OperationResult.CreateSuccess("Material atualizado com sucesso");
                }
                
                // Return_Code = 2: Erro de validação
                if (returnCode == 2)
                {
                    return OperationResult.CreateValidationError(errorMessage);
                }
                
                // Return_Code = 3: Não encontrou o material
                if (returnCode == 3)
                {
                    return OperationResult.CreateNotFound("Material não encontrado");
                }
                
                // Outro código: Erro do banco
                return OperationResult.CreateError(errorMessage);
            }
            catch (Exception ex)
            {
                // Erro inesperado
                return OperationResult.CreateError("Erro ao atualizar material: " + ex.Message);
            }
        }

        // =====================================================================
        // DELETAR MATERIAL (soft delete - marca como inativo)
        // =====================================================================
        public async Task<OperationResult> Deletar(int id)
        {
            try
            {
                // Cria conexão com o banco
                using var connection = _context.CreateConnection();
                
                // ========================================================
                // Preparar os parâmetros para chamar a stored procedure
                // ========================================================
                var parametros = new DynamicParameters();
                
                // Ação: D = Delete (deletar)
                parametros.Add("@Acao", "D", DbType.String);
                
                // ID do material a deletar
                parametros.Add("@Id", id, DbType.Int32);
                
                // Parâmetros de saída
                parametros.Add("@Return_Code", dbType: DbType.Int32, direction: ParameterDirection.Output);
                parametros.Add("@Error", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);
                
                // ========================================================
                // Executar a stored procedure
                // ========================================================
                await connection.ExecuteAsync(
                    "st_Gerenciar_Material",
                    parametros,
                    commandType: CommandType.StoredProcedure);
                
                // ========================================================
                // Ler os valores de retorno e montar resultado
                // ========================================================
                var returnCode = parametros.Get<int>("@Return_Code");
                var errorMessage = parametros.Get<string>("@Error") ?? "";
                
                // Return_Code = 0: Sucesso!
                if (returnCode == 0)
                {
                    return OperationResult.CreateSuccess("Material deletado com sucesso");
                }
                
                // Return_Code = 3: Não encontrou o material
                if (returnCode == 3)
                {
                    return OperationResult.CreateNotFound("Material não encontrado");
                }
                
                // Outro código: Erro do banco
                return OperationResult.CreateError(errorMessage);
            }
            catch (Exception ex)
            {
                // Erro inesperado
                return OperationResult.CreateError("Erro ao deletar material: " + ex.Message);
            }
        }
    }
}