namespace backend.DTOs
{
    public class ClienteDTO
    {
        public int Id { get; set; }
        public string Nome { get; set; } = string.Empty;
        public string? CPF { get; set; }
        public string Telefone { get; set; } = string.Empty;
        
        // Dados de Endereço
        public string Logradouro { get; set; } = string.Empty;
        public int Numero { get; set; }
        public string Bairro { get; set; } = string.Empty;
        public string Cidade { get; set; } = string.Empty;
        public string UF { get; set; } = string.Empty;
        public string? CEP { get; set; }
        public string? Complemento { get; set; }
    }
}