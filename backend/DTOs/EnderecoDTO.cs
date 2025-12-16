namespace backend.DTOs
{
    public class EnderecoDTO
    {
        public int Id { get; set; }
        public int ClienteId { get; set; }
        public string Tipo { get; set; } = string.Empty; // Residencial, Comercial, Cobrança, Entrega
        public string Logradouro { get; set; } = string.Empty;
        public string Numero { get; set; } = string.Empty;
        public string? Complemento { get; set; }
        public string Bairro { get; set; } = string.Empty;
        public string Cidade { get; set; } = string.Empty;
        public string UF { get; set; } = string.Empty;
        public string CEP { get; set; } = string.Empty;
        public bool Principal { get; set; }
    }
}
