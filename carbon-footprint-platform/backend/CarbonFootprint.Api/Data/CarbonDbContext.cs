using Microsoft.EntityFrameworkCore;
using CarbonFootprint.Api.Models;
using System;

namespace CarbonFootprint.Api.Data;

public class CarbonDbContext : DbContext
{
    public CarbonDbContext(DbContextOptions<CarbonDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<DailyEmission> DailyEmissions => Set<DailyEmission>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure User entity
        modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("Users");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Email).IsRequired().HasMaxLength(100);
            entity.HasIndex(e => e.Email).IsUnique();
        });

        // Configure DailyEmission entity
        modelBuilder.Entity<DailyEmission>(entity =>
        {
            entity.ToTable("DailyEmissions");
            entity.HasKey(e => e.Id);
            
            entity.HasOne(d => d.User)
                  .WithMany(p => p.DailyEmissions)
                  .HasForeignKey(d => d.UserId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.Property(e => e.TransportVehicleType).HasMaxLength(50);
            entity.Property(e => e.TransportFuelType).HasMaxLength(50);
            entity.Property(e => e.WasteType).HasMaxLength(50);
        });

        // Seed data for Demo User
        modelBuilder.Entity<User>().HasData(
            new User { Id = 1, Name = "Eco Champion", Email = "eco.champion@carbonaware.org", CreatedAt = new DateTime(2026, 6, 1, 0, 0, 0, DateTimeKind.Utc) }
        );

        // Seed some historical emissions data for the last 7 days to populate the dashboard charts
        var baseDate = new DateTime(2026, 6, 1, 0, 0, 0, DateTimeKind.Utc);
        modelBuilder.Entity<DailyEmission>().HasData(
            new DailyEmission
            {
                Id = 1,
                UserId = 1,
                Date = baseDate,
                TransportDistanceKm = 25.0,
                TransportVehicleType = "Car",
                TransportFuelType = "Petrol",
                TransportEmissionsCo2Kg = 4.5,
                ElectricityKwh = 12.0,
                ElectricityEmissionsCo2Kg = 4.8,
                WasteWeightKg = 2.5,
                WasteType = "Mixed",
                RecyclingRatePercentage = 20.0,
                WasteEmissionsCo2Kg = 3.8,
                TotalEmissionsCo2Kg = 13.1
            },
            new DailyEmission
            {
                Id = 2,
                UserId = 1,
                Date = baseDate.AddDays(1),
                TransportDistanceKm = 15.0,
                TransportVehicleType = "Motorcycle",
                TransportFuelType = "Petrol",
                TransportEmissionsCo2Kg = 1.5,
                ElectricityKwh = 10.0,
                ElectricityEmissionsCo2Kg = 4.0,
                WasteWeightKg = 1.8,
                WasteType = "Mixed",
                RecyclingRatePercentage = 30.0,
                WasteEmissionsCo2Kg = 2.4,
                TotalEmissionsCo2Kg = 7.9
            },
            new DailyEmission
            {
                Id = 3,
                UserId = 1,
                Date = baseDate.AddDays(2),
                TransportDistanceKm = 45.0,
                TransportVehicleType = "Bus",
                TransportFuelType = "Diesel",
                TransportEmissionsCo2Kg = 3.6,
                ElectricityKwh = 15.0,
                ElectricityEmissionsCo2Kg = 6.0,
                WasteWeightKg = 3.0,
                WasteType = "Mixed",
                RecyclingRatePercentage = 10.0,
                WasteEmissionsCo2Kg = 5.13,
                TotalEmissionsCo2Kg = 14.73
            },
            new DailyEmission
            {
                Id = 4,
                UserId = 1,
                Date = baseDate.AddDays(3),
                TransportDistanceKm = 0.0,
                TransportVehicleType = "Bicycle",
                TransportFuelType = "None",
                TransportEmissionsCo2Kg = 0.0,
                ElectricityKwh = 8.0,
                ElectricityEmissionsCo2Kg = 3.2,
                WasteWeightKg = 1.0,
                WasteType = "Mixed",
                RecyclingRatePercentage = 80.0,
                WasteEmissionsCo2Kg = 0.38,
                TotalEmissionsCo2Kg = 3.58
            },
            new DailyEmission
            {
                Id = 5,
                UserId = 1,
                Date = baseDate.AddDays(4),
                TransportDistanceKm = 30.0,
                TransportVehicleType = "Car",
                TransportFuelType = "Electric",
                TransportEmissionsCo2Kg = 1.5,
                ElectricityKwh = 14.0,
                ElectricityEmissionsCo2Kg = 5.6,
                WasteWeightKg = 2.0,
                WasteType = "Mixed",
                RecyclingRatePercentage = 50.0,
                WasteEmissionsCo2Kg = 1.9,
                TotalEmissionsCo2Kg = 9.0
            },
            new DailyEmission
            {
                Id = 6,
                UserId = 1,
                Date = baseDate.AddDays(5),
                TransportDistanceKm = 10.0,
                TransportVehicleType = "Train",
                TransportFuelType = "Electric",
                TransportEmissionsCo2Kg = 0.4,
                ElectricityKwh = 11.5,
                ElectricityEmissionsCo2Kg = 4.6,
                WasteWeightKg = 1.5,
                WasteType = "Mixed",
                RecyclingRatePercentage = 60.0,
                WasteEmissionsCo2Kg = 1.14,
                TotalEmissionsCo2Kg = 6.14
            },
            new DailyEmission
            {
                Id = 7,
                UserId = 1,
                Date = baseDate.AddDays(6),
                TransportDistanceKm = 20.0,
                TransportVehicleType = "Car",
                TransportFuelType = "Diesel",
                TransportEmissionsCo2Kg = 3.4,
                ElectricityKwh = 13.0,
                ElectricityEmissionsCo2Kg = 5.2,
                WasteWeightKg = 2.2,
                WasteType = "Mixed",
                RecyclingRatePercentage = 40.0,
                WasteEmissionsCo2Kg = 2.5,
                TotalEmissionsCo2Kg = 11.1
            }
        );
    }
}
