namespace backend.DTOs
{
    public class TelefoneDTO
    {
        public int Id { get; set; }
        public int ClienteId { get; set; }
        public string Tipo { get; set; } = string.Empty; // Celular, Comercial, Residencial, WhatsApp
        public string Numero { get; set; } = string.Empty;
        public bool Principal { get; set; }
    }
}
