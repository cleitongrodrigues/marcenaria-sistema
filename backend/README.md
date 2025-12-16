# 🪵 Sistema de Marcenaria - Backend

API REST para gerenciamento completo de uma marcenaria.

---

## 🎯 Sobre o Projeto

Sistema ERP para marcenarias com controle de:
- 👥 **Clientes** (PF e PJ)
- 📦 **Materiais** e estoque
- 💰 **Orçamentos** e vendas
- 💳 **Financeiro** (contas a pagar/receber)
- 📄 **Notas fiscais**
- 👷 **Fornecedores**

---

## 🛠️ Tecnologias

- **.NET 9.0** - Framework backend
- **ASP.NET Core** - Web API
- **Dapper** - Micro ORM
- **SQL Server** - Banco de dados
- **Stored Procedures** - Lógica de banco

---

## 📂 Estrutura do Código

```
backend/
├── Controllers/         ← Endpoints HTTP (GET, POST, PUT, DELETE)
├── Services/           ← Regras de negócio e validações
├── Repositories/       ← Acesso ao banco de dados
├── DTOs/              ← Objetos de transferência de dados
├── Interfaces/        ← Contratos das classes
├── Common/            ← Classes compartilhadas (Result, PagedResult)
├── Context/           ← Configuração do Dapper
└── Database/          ← Scripts SQL (tabelas e procedures)
```

---

## 🚀 Como Executar

### 1. Configurar o banco de dados

Execute os scripts SQL na ordem:
```sql
1. Database/Creates.sql              -- Cria as tabelas
2. Database/st_Gerenciar_Cliente.sql -- Procedures de cliente
3. Database/st_Gerenciar_Material.sql -- Procedures de material
-- ... outros scripts
```

### 2. Configurar a connection string

Edite `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=SEU_SERVIDOR;Database=MARCENARIA;Trusted_Connection=true;TrustServerCertificate=true"
  }
}
```

### 3. Executar o projeto

```powershell
cd backend
dotnet run
```

A API estará disponível em: `https://localhost:5001`

---

## 📚 Documentação para Iniciantes

**Se você é iniciante em programação**, leia o guia completo:

👉 **[GUIA-INICIANTES.md](GUIA-INICIANTES.md)**

Este guia explica:
- Como o código funciona (passo a passo)
- O que cada camada faz (Controller, Service, Repository)
- Conceitos importantes (async/await, DI, DTOs)
- Como adicionar novos endpoints
- Exemplos práticos e dicas

---

## 🔍 Endpoints Disponíveis

### Clientes

```http
GET    /api/Cliente?page=1&pageSize=50&searchTerm=silva
GET    /api/Cliente/{id}
POST   /api/Cliente
PUT    /api/Cliente/{id}
DELETE /api/Cliente/{id}
```

### Materiais

```http
GET    /api/Material?page=1&pageSize=50&searchTerm=madeira
GET    /api/Material/{id}
POST   /api/Material
PUT    /api/Material/{id}
DELETE /api/Material/{id}
```

---

## 📋 Exemplo de Uso

### Criar um cliente

**Requisição:**
```http
POST /api/Cliente
Content-Type: application/json

{
  "nome": "João Silva",
  "cpf": "123.456.789-00",
  "tipoPessoa": "F",
  "email": "joao@email.com",
  "telefones": [
    { "numero": "(11) 98765-4321", "tipo": "Celular" }
  ],
  "enderecos": [
    {
      "logradouro": "Rua das Flores",
      "numero": "123",
      "bairro": "Centro",
      "cidade": "São Paulo",
      "estado": "SP",
      "cep": "01234-567"
    }
  ]
}
```

**Resposta:**
```json
{
  "sucesso": true,
  "id": 45,
  "mensagem": "Cliente cadastrado com sucesso"
}
```

---

## 🎨 Filosofia do Código

Este projeto foi desenvolvido com foco em **clareza e facilidade de manutenção**:

✅ **Código explícito** - sem "mágica"  
✅ **Comentários extensos** - explicam o POR QUÊ  
✅ **Sintaxe simples** - fácil para iniciantes  
✅ **Sem abstrações complexas** - tudo visível  
✅ **Duplicação aceitável** - se ajuda no entendimento  

**Prioridade:** Um iniciante deve conseguir entender e modificar o código.

---

## 🗄️ Banco de Dados

### Tabelas principais

- **Clientes** - Dados de clientes (PF e PJ)
- **Telefones** - Telefones dos clientes
- **Enderecos** - Endereços dos clientes
- **Materiais** - Produtos e insumos
- **Fornecedores** - Fornecedores de materiais
- **MovimentacaoEstoque** - Histórico de entradas/saídas
- **Orcamentos** - Orçamentos de vendas
- **OrcamentoItens** - Itens (serviços) do orçamento
- **OrcamentoMateriais** - Materiais usados no orçamento
- **Compras** - Compras de fornecedores
- **ContasReceber** - Contas a receber de clientes
- **ContasPagar** - Contas a pagar para fornecedores
- **NotasFiscais** - Notas fiscais de entrada/saída

### Stored Procedures

Todas seguem o padrão:
- Parâmetro `@Acao` (I=Insert, U=Update, D=Delete)
- Retornam `@Return_Code` (0=sucesso, 1=erro SQL, 2=validação, 3=não encontrado)
- Retornam `@Error` (mensagem de erro)

---

## 🔧 Manutenção

### Como adicionar um novo módulo

1. Crie o DTO em `DTOs/`
2. Crie a interface do Repository em `Interfaces/`
3. Implemente o Repository em `Repositories/`
4. Crie a interface do Service em `Interfaces/`
5. Implemente o Service em `Services/`
6. Crie o Controller em `Controllers/`
7. Registre no `Program.cs` (Dependency Injection)

**Siga o padrão existente** de Cliente ou Material como exemplo.

---

## 📝 Convenções

### Nomenclatura
- **Classes**: PascalCase (`ClienteService`)
- **Métodos**: PascalCase (`ObterPorId`)
- **Variáveis**: camelCase (`var cliente`)
- **Parâmetros**: camelCase (`int id`)

### Comentários
- Use `===` para separar grandes seções
- Use `PASSO 1, 2, 3` para algoritmos
- Comente inline para linhas importantes
- Explique o POR QUÊ, não o COMO

### Códigos de erro
- **0** = Sucesso
- **1** = Erro SQL (try/catch)
- **2** = Erro de validação (CPF inválido, campo obrigatório)
- **3** = Não encontrado (registro não existe)

### HTTP Status
- **200 OK** - Sucesso em GET/PUT/DELETE
- **201 Created** - Sucesso em POST
- **400 Bad Request** - Validação falhou (ErrorCode 2)
- **404 Not Found** - Não encontrado (ErrorCode 3)
- **500 Internal Server Error** - Erro no servidor (ErrorCode 1)

---

## 🤝 Contribuindo

1. Clone o repositório
2. Leia o [GUIA-INICIANTES.md](GUIA-INICIANTES.md)
3. Siga os padrões existentes
4. Teste suas mudanças
5. Comente seu código

---

## 📞 Suporte

Para dúvidas sobre como o código funciona, consulte:
- [GUIA-INICIANTES.md](GUIA-INICIANTES.md) - Guia completo
- Comentários no código - Explicações detalhadas
- Stored procedures - Lógica do banco

---

## 📄 Licença

Este é um projeto educacional focado em clareza e facilidade de aprendizado.

---

🎉 **Desenvolvido com foco em simplicidade e clareza para iniciantes!**
