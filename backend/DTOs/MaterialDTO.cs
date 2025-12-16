namespace backend.DTOs
{
    public class MaterialDTO
    {
        public int Id { get; set; }
        public string Nome { get; set; } = string.Empty;
        public string? Descricao { get; set; }
        public string Categoria { get; set; } = string.Empty;
        public decimal PrecoUnitario { get; set; }
        public string UnidadeMedida { get; set; } = string.Empty;
        public decimal QuantidadeEstoque { get; set; }
        public decimal? EstoqueMinimo { get; set; }
        public decimal? EstoqueMaximo { get; set; }
        public string? Localizacao { get; set; }
        public bool Ativo { get; set; } = true;
        public DateTime DataCriacao { get; set; }
        public DateTime? DataAlteracao { get; set; }
    }
}