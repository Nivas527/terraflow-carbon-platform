using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace CarbonFootprint.Api.Models;

public class User
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [JsonIgnore]
    public ICollection<DailyEmission> DailyEmissions { get; set; } = new List<DailyEmission>();
}
