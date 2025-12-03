using backend.Context;
using backend.Repositories;
using backend.Interfaces;

var builder = WebApplication.CreateBuilder(args);

// Adiciona o DapperContext (Conexão com Banco)
builder.Services.AddSingleton<DapperContext>();
builder.Services.AddScoped<IClienteRepository, ClienteRepository>();

// Adiciona Controllers
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configura o Swagger (Documentação da API)
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();