namespace backend.DTOs
{
    public class ClienteDTO
    {
        public int Id { get; set; }
        public string TipoPessoa { get; set; } = "F"; // F=Física, J=Jurídica
        public string Nome { get; set; } = string.Empty; // Nome completo (PF) ou Razão Social (PJ)
        public string? NomeFantasia { get; set; }
        public string? CPF { get; set; } // Apenas PF
        public string? CNPJ { get; set; } // Apenas PJ
        public string? InscricaoEstadual { get; set; } // Apenas PJ
        public string? Email { get; set; }
        public string? Observacao { get; set; }
        public bool Ativo { get; set; } = true;
        public DateTime DataCriacao { get; set; }
        public DateTime? DataAlteracao { get; set; }
    }
}