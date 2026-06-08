using Microsoft.EntityFrameworkCore;
using CarbonFootprint.Api.Data;
using CarbonFootprint.Api.Services;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

// Add DbContext targeting MySQL
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? "server=localhost;database=carbon_footprint;user=root;password=root";
var serverVersion = new MySqlServerVersion(new Version(8, 0, 30));

builder.Services.AddDbContext<CarbonDbContext>(options =>
    options.UseMySql(connectionString, serverVersion));

// Register Carbon Calculator Service
builder.Services.AddScoped<ICarbonCalculatorService, CarbonCalculatorService>();

// Add controllers with JSON settings
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
        options.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
    });

// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
// builder.Services.AddOpenApi();

// Enable CORS for Flutter Web local development
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

var app = builder.Build();

// Auto-create/seed database on startup
using (var scope = app.Services.CreateScope())
{
    try
    {
        var db = scope.ServiceProvider.GetRequiredService<CarbonDbContext>();
        db.Database.EnsureCreated();
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Database initialization failed: {ex.Message}");
    }
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    // app.MapOpenApi();
}

app.UseCors("AllowFlutter");

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
