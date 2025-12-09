namespace backend.DTOs
{
    public class MaterialDTO
    {
        public int Id {get; set;}
        public string Nome {get; set;} = string.Empty;
        public string Categoria {get; set;} = string.Empty;
        public decimal PrecoUnitario {get; set;}
        public string UnidadeMedida {get; set;} = string.Empty;
        public bool Ativo {get; set;}
        public DateTime DataCriacao {get; set;}
        public DateTime? DataAlteracao {get; set;}
    }
}