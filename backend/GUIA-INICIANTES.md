# 📚 GUIA PARA INICIANTES - Sistema de Marcenaria

Este guia explica como o código do backend funciona de uma forma **fácil de entender** para quem está começando a programar.

---

## 🎯 O que é este sistema?

É uma API (Application Programming Interface) para gerenciar uma marcenaria. Ela permite:
- Cadastrar e gerenciar **clientes**
- Cadastrar e gerenciar **materiais** (madeiras, pregos, tintas, etc)
- Controlar estoque
- Gerenciar orçamentos e vendas

---

## 📂 Como o código está organizado?

```
backend/
├── Controllers/         ← Recebe as requisições HTTP (ex: GET, POST)
├── Services/           ← Aplica regras de negócio
├── Repositories/       ← Acessa o banco de dados
├── DTOs/              ← Objetos que trafegam dados entre camadas
├── Interfaces/        ← Contratos que definem o que cada classe deve fazer
├── Common/            ← Classes compartilhadas (ex: Result)
├── Context/           ← Configuração da conexão com banco
└── Database/          ← Scripts SQL (tabelas e procedures)
```

---

## 🔄 Fluxo de uma requisição

Quando o frontend (ou Postman) faz uma requisição, o caminho é:

```
1. Frontend                  (faz requisição)
    ↓
2. Controller               (recebe requisição HTTP)
    ↓
3. Service                  (aplica regras de negócio)
    ↓
4. Repository              (acessa o banco de dados)
    ↓
5. Banco SQL Server        (armazena/busca dados)
    ↓
6. Repository              (retorna dados)
    ↓
7. Service                 (retorna dados)
    ↓
8. Controller              (transforma em JSON e retorna HTTP)
    ↓
9. Frontend                (recebe resposta)
```

---

## 📝 Exemplo prático: Criar um cliente

### 1️⃣ Frontend envia requisição

```http
POST /api/Cliente
Content-Type: application/json

{
  "nome": "João Silva",
  "cpf": "123.456.789-00",
  "tipoPessoa": "F"
}
```

### 2️⃣ Controller recebe (`ClienteController.cs`)

```csharp
[HttpPost]
public async Task<IActionResult> Criar([FromBody] ClienteDTO cliente)
{
    // Chama o service
    var resultado = await _service.Criar(cliente);
    
    // Se deu certo, retorna HTTP 201 Created
    if (resultado.Success)
    {
        return CreatedAtAction(...);
    }
    
    // Se deu erro, retorna erro apropriado
    return RetornarErro(resultado.ErrorCode, resultado.Message);
}
```

**O que acontece aqui?**
- `[HttpPost]` → Define que este método responde a requisições POST
- `[FromBody]` → Os dados vêm no corpo da requisição (JSON)
- `await` → Espera a operação terminar (operação assíncrona)
- `IActionResult` → Tipo de retorno HTTP (200, 400, 404, etc)

### 3️⃣ Service aplica regras (`ClienteService.cs`)

```csharp
public async Task<CreateResult> Criar(ClienteDTO cliente)
{
    // REGRA 1: Limpar dados
    if (cliente.CPF != null)
    {
        cliente.CPF = cliente.CPF.Replace(".", "");
        cliente.CPF = cliente.CPF.Replace("-", "");
    }
    
    // REGRA 2: Validar dados
    if (string.IsNullOrWhiteSpace(cliente.Nome))
    {
        return CreateResult.CreateValidationError("Nome é obrigatório");
    }
    
    // REGRA 3: Validar CPF para pessoa física
    if (cliente.TipoPessoa == "F")
    {
        if (string.IsNullOrWhiteSpace(cliente.CPF))
        {
            return CreateResult.CreateValidationError("CPF é obrigatório para pessoa física");
        }
    }
    
    // Se passou por todas as validações, chama o repository
    return await _repository.Criar(cliente);
}
```

**O que acontece aqui?**
- Remove pontos e traços do CPF
- Valida se os dados obrigatórios foram preenchidos
- Aplica regras específicas (ex: CPF obrigatório para PF)
- Só depois de validar tudo, chama o repository

### 4️⃣ Repository acessa banco (`ClienteRepository.cs`)

```csharp
public async Task<CreateResult> Criar(ClienteDTO cliente)
{
    // Cria conexão com o banco
    using var connection = _context.CreateConnection();
    
    // Prepara os parâmetros para a stored procedure
    var parametros = new DynamicParameters();
    parametros.Add("@Acao", "I", DbType.String);
    parametros.Add("@Nome", cliente.Nome, DbType.String);
    parametros.Add("@CPF", cliente.CPF, DbType.String);
    // ... outros parâmetros
    
    // Parâmetros de saída (a procedure retorna estes valores)
    parametros.Add("@Return_Code", dbType: DbType.Int32, direction: ParameterDirection.Output);
    parametros.Add("@Error", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);
    parametros.Add("@Id", dbType: DbType.Int32, direction: ParameterDirection.Output);
    
    // Executa a stored procedure
    await connection.ExecuteAsync(
        "st_Gerenciar_Cliente",
        parametros,
        commandType: CommandType.StoredProcedure);
    
    // Lê os valores de retorno
    var returnCode = parametros.Get<int>("@Return_Code");
    var errorMessage = parametros.Get<string>("@Error") ?? "";
    var idGerado = parametros.Get<int?>("@Id");
    
    // Verifica o código de retorno
    if (returnCode == 0)
    {
        return CreateResult.CreateSuccess(idGerado ?? 0, "Cliente cadastrado com sucesso");
    }
    
    if (returnCode == 2)
    {
        return CreateResult.CreateValidationError(errorMessage);
    }
    
    return CreateResult.CreateError(errorMessage);
}
```

**O que acontece aqui?**
- Cria conexão com SQL Server
- Prepara parâmetros (inputs e outputs)
- Chama stored procedure `st_Gerenciar_Cliente`
- Lê o código de retorno da procedure
- Retorna sucesso ou erro apropriado

### 5️⃣ Stored Procedure no banco (`st_Gerenciar_Cliente`)

```sql
CREATE PROCEDURE st_Gerenciar_Cliente
    @Acao CHAR(1),              -- I = Insert, U = Update, D = Delete
    @Id INT = NULL,
    @Nome VARCHAR(100),
    @CPF VARCHAR(11),
    -- ... outros parâmetros
    @Return_Code INT OUTPUT,    -- 0 = sucesso, 1 = erro SQL, 2 = validação, 3 = não encontrado
    @Error VARCHAR(500) OUTPUT  -- Mensagem de erro
AS
BEGIN
    SET @Return_Code = 0;
    SET @Error = '';
    
    BEGIN TRY
        -- INSERT
        IF @Acao = 'I'
        BEGIN
            -- Valida se CPF já existe
            IF EXISTS (SELECT 1 FROM Clientes WHERE CPF = @CPF AND Ativo = 1)
            BEGIN
                SET @Return_Code = 2;
                SET @Error = 'CPF já cadastrado';
                RETURN;
            END
            
            -- Insere o cliente
            INSERT INTO Clientes (Nome, CPF, TipoPessoa, ...)
            VALUES (@Nome, @CPF, @TipoPessoa, ...);
            
            SET @Id = SCOPE_IDENTITY();  -- Pega o ID gerado
        END
        -- ... UPDATE e DELETE
    END TRY
    BEGIN CATCH
        SET @Return_Code = 1;
        SET @Error = ERROR_MESSAGE();
    END CATCH
END
```

**O que acontece aqui?**
- Procedure valida dados (ex: CPF duplicado)
- Faz INSERT/UPDATE/DELETE no banco
- Retorna código de sucesso ou erro
- Retorna ID gerado (no caso de INSERT)

---

## 📦 Classes importantes

### 1. DTO (Data Transfer Object)

**O que é?** Um objeto simples que carrega dados entre camadas.

```csharp
public class ClienteDTO
{
    public int? Id { get; set; }
    public string? Nome { get; set; }
    public string? CPF { get; set; }
    public string? TipoPessoa { get; set; }
    // ...
}
```

**Por que usar?**
- Organiza os dados em um único objeto
- Facilita passar muitos parâmetros de uma vez
- É fácil converter para JSON

### 2. CreateResult e OperationResult

**O que são?** Classes que representam o resultado de uma operação.

```csharp
public class CreateResult
{
    public bool Success { get; set; }         // Deu certo?
    public string Message { get; set; }       // Mensagem
    public int ErrorCode { get; set; }        // Código de erro (0, 1, 2, 3)
    public int GeneratedId { get; set; }      // ID gerado (só para criar)
}
```

**Por que usar?**
- Melhor que retornar `true/false` ou `null`
- Permite retornar dados + mensagem de erro
- Códigos de erro padronizados:
  - **0** = Sucesso
  - **1** = Erro do banco de dados (SQL)
  - **2** = Erro de validação (ex: CPF inválido)
  - **3** = Não encontrado

### 3. ListParameters

**O que é?** Parâmetros para paginação e filtro.

```csharp
public class ListParameters
{
    public int Page { get; set; } = 1;            // Página atual
    public int PageSize { get; set; } = 50;       // Itens por página
    public string? SearchTerm { get; set; }       // Termo de busca
}
```

**Por que usar?**
- Evita retornar 10.000 registros de uma vez
- Permite buscar por nome, CPF, etc
- Frontend pode navegar entre páginas

### 4. ClienteListResult / MaterialListResult

**O que é?** Resultado de uma listagem paginada.

```csharp
public class ClienteListResult
{
    public List<ClienteDTO> Items { get; set; }    // Lista de clientes desta página
    public int TotalItems { get; set; }            // Total de clientes no banco
    public int TotalPages { get; set; }            // Total de páginas
    public int CurrentPage { get; set; }           // Página atual
    public int PageSize { get; set; }              // Itens por página
    public bool HasPreviousPage { get; set; }      // Tem página anterior?
    public bool HasNextPage { get; set; }          // Tem próxima página?
}
```

**Por que usar?**
- Frontend sabe quantas páginas existem
- Frontend pode mostrar "Página 1 de 10"
- Frontend pode habilitar/desabilitar botões "Anterior" e "Próximo"

---

## 🔧 Conceitos importantes

### async/await

**O que é?** Forma de fazer operações que demoram sem travar o programa.

```csharp
// SEM async/await (trava o programa)
var cliente = BuscarCliente(id);  // Programa PARA aqui e espera

// COM async/await (não trava)
var cliente = await BuscarCliente(id);  // Programa pode fazer outras coisas enquanto espera
```

**Quando usar?**
- Acesso ao banco de dados (sempre é lento)
- Chamadas HTTP
- Leitura/escrita de arquivos

### using

**O que é?** Garante que recursos sejam liberados (ex: conexão com banco).

```csharp
using var connection = _context.CreateConnection();
// ... usa a conexão ...
// Quando terminar este bloco, a conexão é AUTOMATICAMENTE fechada
```

**Por que usar?**
- Evita deixar conexões abertas (vazamento de recursos)
- Mais simples que try/finally

### Dependency Injection

**O que é?** O framework "injeta" dependências automaticamente.

```csharp
public class ClienteController : ControllerBase
{
    private readonly IClienteService _service;
    
    // ASP.NET Core automaticamente passa o service correto aqui
    public ClienteController(IClienteService service)
    {
        _service = service;
    }
}
```

**Como configurar?** No `Program.cs`:

```csharp
builder.Services.AddScoped<IClienteService, ClienteService>();
builder.Services.AddScoped<IClienteRepository, ClienteRepository>();
```

**Por que usar?**
- Não precisa usar `new ClienteService()` manualmente
- Facilita trocar implementações (para testes, por exemplo)
- Gerencia o ciclo de vida dos objetos

---

## ➕ Como adicionar um novo endpoint?

Digamos que você quer criar um endpoint para **buscar clientes por CPF**.

### Passo 1: Adicione o método no Repository

```csharp
// IClienteRepository.cs
public interface IClienteRepository
{
    // ... métodos existentes ...
    Task<ClienteDTO?> ObterPorCPF(string cpf);  // ← NOVO
}

// ClienteRepository.cs
public async Task<ClienteDTO?> ObterPorCPF(string cpf)
{
    using var connection = _context.CreateConnection();
    
    var sql = @"
        SELECT Id, Nome, CPF, TipoPessoa, Email, DataCadastro
        FROM Clientes
        WHERE CPF = @CPF AND Ativo = 1";
    
    var cliente = await connection.QueryFirstOrDefaultAsync<ClienteDTO>(
        sql, 
        new { CPF = cpf });
    
    return cliente;
}
```

### Passo 2: Adicione o método no Service

```csharp
// IClienteService.cs
public interface IClienteService
{
    // ... métodos existentes ...
    Task<ClienteDTO?> ObterPorCPF(string cpf);  // ← NOVO
}

// ClienteService.cs
public async Task<ClienteDTO?> ObterPorCPF(string cpf)
{
    // Limpar o CPF (remover pontos e traços)
    if (cpf != null)
    {
        cpf = cpf.Replace(".", "");
        cpf = cpf.Replace("-", "");
    }
    
    // Chamar o repository
    return await _repository.ObterPorCPF(cpf);
}
```

### Passo 3: Adicione o endpoint no Controller

```csharp
// ClienteController.cs
[HttpGet("cpf/{cpf}")]  // ← Rota: /api/Cliente/cpf/12345678900
public async Task<IActionResult> ObterPorCPF(string cpf)
{
    // Busca o cliente
    var cliente = await _service.ObterPorCPF(cpf);
    
    // Se não encontrou, retorna 404
    if (cliente == null)
    {
        return NotFound(new { sucesso = false, mensagem = "Cliente não encontrado" });
    }
    
    // Se encontrou, retorna 200
    return Ok(new { sucesso = true, dados = cliente });
}
```

### Passo 4: Teste

No Postman ou navegador:
```http
GET http://localhost:5000/api/Cliente/cpf/12345678900
```

Resposta:
```json
{
  "sucesso": true,
  "dados": {
    "id": 123,
    "nome": "João Silva",
    "cpf": "12345678900",
    "tipoPessoa": "F"
  }
}
```

---

## 🛑 Códigos de erro HTTP

| Código | Nome | Quando usar |
|--------|------|-------------|
| **200** | OK | Operação bem-sucedida (GET, PUT, DELETE) |
| **201** | Created | Registro criado com sucesso (POST) |
| **400** | Bad Request | Dados inválidos (CPF errado, campo obrigatório vazio) |
| **404** | Not Found | Registro não encontrado |
| **500** | Internal Server Error | Erro no servidor (SQL, conexão, etc) |

---

## 💡 Dicas importantes

### 1. Use comentários para explicar O QUÊ e POR QUÊ, não COMO

```csharp
// ❌ RUIM (explica o óbvio)
// Remove os pontos
cpf = cpf.Replace(".", "");

// ✅ BOM (explica o motivo)
// Remove pontos e traços para padronizar o CPF no formato só números
cpf = cpf.Replace(".", "").Replace("-", "");
```

### 2. Um método deve fazer UMA coisa

```csharp
// ❌ RUIM (faz muitas coisas)
public async Task<CreateResult> CriarClienteEEnviarEmail(ClienteDTO cliente) { ... }

// ✅ BOM (responsabilidade única)
public async Task<CreateResult> Criar(ClienteDTO cliente) { ... }
public async Task EnviarEmailBoasVindas(int clienteId) { ... }
```

### 3. Valide no Service, não no Controller

```csharp
// ❌ RUIM (validação no Controller)
[HttpPost]
public async Task<IActionResult> Criar([FromBody] ClienteDTO cliente)
{
    if (string.IsNullOrWhiteSpace(cliente.Nome))
        return BadRequest("Nome é obrigatório");
    
    return await _service.Criar(cliente);
}

// ✅ BOM (validação no Service)
[HttpPost]
public async Task<IActionResult> Criar([FromBody] ClienteDTO cliente)
{
    var resultado = await _service.Criar(cliente);
    // Service já fez todas as validações
}
```

### 4. Use nomes descritivos

```csharp
// ❌ RUIM
var r = await _repo.Get(id);
var c = new CResult();

// ✅ BOM
var cliente = await _repository.ObterPorId(id);
var resultado = new CreateResult();
```

---

## 🎓 Para aprender mais

### Conceitos básicos
- **C# básico**: variáveis, if/else, loops, métodos
- **OOP**: classes, interfaces, herança
- **SQL**: SELECT, INSERT, UPDATE, DELETE, JOINs

### Conceitos intermediários
- **ASP.NET Core**: Controllers, Routing, Dependency Injection
- **Dapper**: Micro ORM para acessar banco de dados
- **async/await**: Programação assíncrona
- **REST API**: GET, POST, PUT, DELETE, códigos HTTP

### Conceitos avançados
- **Clean Architecture**: Separação em camadas
- **SOLID**: Princípios de design
- **Design Patterns**: Repository, Service, DTO
- **Stored Procedures**: Lógica no banco de dados

---

## 📞 Dúvidas frequentes

**P: Por que não usar Entity Framework?**
R: Entity Framework é mais complexo e "mágico". Dapper + Stored Procedures é mais explícito e você tem mais controle sobre o SQL.

**P: Por que separar em Controller/Service/Repository?**
R: Separação de responsabilidades. Se você precisar mudar o banco de dados, só muda o Repository. Se precisar mudar uma regra de negócio, só muda o Service.

**P: O que é "Ativo = 1"?**
R: É um "soft delete". Em vez de deletar o registro, só marca como inativo. Assim você mantém o histórico.

**P: Por que usar async/await?**
R: Banco de dados é lento. Com async/await, o servidor pode atender outras requisições enquanto espera o banco responder.

**P: Preciso aprender tudo isso de uma vez?**
R: Não! Comece entendendo o fluxo (Controller → Service → Repository). Depois vá aprofundando aos poucos.

---

## ✅ Resumo

1. **Controller** = Recebe requisições HTTP
2. **Service** = Aplica regras de negócio
3. **Repository** = Acessa o banco de dados
4. **DTO** = Objeto que carrega dados
5. **Result** = Retorno padronizado (sucesso/erro)
6. **Stored Procedure** = Código SQL no banco

**Fluxo:**
```
Frontend → Controller → Service → Repository → Banco SQL
                                               ↓
Frontend ← Controller ← Service ← Repository ← Dados
```

---

🎉 **Agora você está pronto para começar a desenvolver!**

Se tiver dúvidas, leia este guia novamente e analise o código existente. Tudo foi escrito de forma bem explícita para facilitar o entendimento.

Boa sorte! 🚀
