namespace backend.DTOs
{
    /// <summary>
    /// DTO completo com relacionamentos (usado em GET)
    /// </summary>
    public class ClienteComDetalhesDTO
    {
        public int Id { get; set; }
        public string TipoPessoa { get; set; } = "F";
        public string Nome { get; set; } = string.Empty;
        public string? NomeFantasia { get; set; }
        public string? CPF { get; set; }
        public string? CNPJ { get; set; }
        public string? InscricaoEstadual { get; set; }
        public string? Email { get; set; }
        public string? Observacao { get; set; }
        public bool Ativo { get; set; }
        public DateTime DataCriacao { get; set; }
        public DateTime? DataAlteracao { get; set; }

        // Relacionamentos
        public List<TelefoneDTO> Telefones { get; set; } = new();
        public List<EnderecoDTO> Enderecos { get; set; } = new();
    }
}
