using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Xunit;
using CarbonFootprint.Api.Controllers;
using CarbonFootprint.Api.Data;
using CarbonFootprint.Api.Models;
using CarbonFootprint.Api.DTOs;
using CarbonFootprint.Api.Services;

namespace CarbonFootprint.Api.Tests;

public class CarbonLogsControllerTests
{
    private readonly DbContextOptions<CarbonDbContext> _dbOptions;
    private readonly ICarbonCalculatorService _calculatorService;

    public CarbonLogsControllerTests()
    {
        _dbOptions = new DbContextOptionsBuilder<CarbonDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        _calculatorService = new CarbonCalculatorService();
    }

    private async Task SeedDatabaseAsync(CarbonDbContext context)
    {
        var user = new User { Id = 1, Name = "Test User", Email = "test@user.com" };
        context.Users.Add(user);

        var log = new DailyEmission
        {
            Id = 1,
            UserId = 1,
            Date = DateTime.UtcNow.Date,
            TransportDistanceKm = 10.0,
            TransportVehicleType = "Car",
            TransportFuelType = "Petrol",
            TransportEmissionsCo2Kg = 1.8,
            ElectricityKwh = 10.0,
            ElectricityEmissionsCo2Kg = 4.0,
            WasteWeightKg = 2.0,
            WasteType = "Mixed",
            RecyclingRatePercentage = 0.0,
            WasteEmissionsCo2Kg = 3.8,
            TotalEmissionsCo2Kg = 9.6
        };
        context.DailyEmissions.Add(log);

        await context.SaveChangesAsync();
    }

    [Fact]
    public async Task GetLogs_ReturnsLogsForValidUser()
    {
        using var context = new CarbonDbContext(_dbOptions);
        await SeedDatabaseAsync(context);

        var controller = new CarbonLogsController(context, _calculatorService);

        var result = await controller.GetLogs(1);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var logs = Assert.IsAssignableFrom<IEnumerable<DailyEmissionDto>>(okResult.Value);
        Assert.Single(logs);
        Assert.Equal(9.6, logs.First().TotalEmissionsCo2Kg);
    }

    [Fact]
    public async Task GetLog_ReturnsLogForValidId()
    {
        using var context = new CarbonDbContext(_dbOptions);
        await SeedDatabaseAsync(context);

        var controller = new CarbonLogsController(context, _calculatorService);

        var result = await controller.GetLog(1);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var log = Assert.IsType<DailyEmissionDto>(okResult.Value);
        Assert.Equal(9.6, log.TotalEmissionsCo2Kg);
        Assert.Equal("Car", log.TransportVehicleType);
    }

    [Fact]
    public async Task GetLog_ReturnsNotFoundForInvalidId()
    {
        using var context = new CarbonDbContext(_dbOptions);
        await SeedDatabaseAsync(context);

        var controller = new CarbonLogsController(context, _calculatorService);

        var result = await controller.GetLog(999);

        Assert.IsType<NotFoundObjectResult>(result.Result);
    }

    [Fact]
    public async Task GetStats_ReturnsEmissionsCalculationsForValidUser()
    {
        using var context = new CarbonDbContext(_dbOptions);
        await SeedDatabaseAsync(context);

        var controller = new CarbonLogsController(context, _calculatorService);

        var result = await controller.GetStats(1);

        var okResult = Assert.IsType<OkObjectResult>(result);

        // Use reflection to assert anonymous type values
        var value = okResult.Value;
        Assert.NotNull(value);
        var totalEmissions = (double)value.GetType().GetProperty("totalEmissionsCo2Kg")!.GetValue(value)!;
        var logCount = (int)value.GetType().GetProperty("logCount")!.GetValue(value)!;

        Assert.Equal(9.6, totalEmissions);
        Assert.Equal(1, logCount);
    }

    [Fact]
    public async Task CreateLog_ValidPayload_SavesAndReturns201Created()
    {
        using var context = new CarbonDbContext(_dbOptions);
        await SeedDatabaseAsync(context);

        var controller = new CarbonLogsController(context, _calculatorService);

        var payload = new CreateDailyEmissionDto
        {
            UserId = 1,
            Date = DateTime.UtcNow.Date.AddDays(1),
            TransportDistanceKm = 20.0,
            TransportVehicleType = "Car",
            TransportFuelType = "Petrol",
            ElectricityKwh = 15.0,
            WasteWeightKg = 5.0,
            WasteType = "Mixed",
            RecyclingRatePercentage = 20.0
        };

        var result = await controller.CreateLog(payload);

        var createdResult = Assert.IsType<CreatedAtActionResult>(result.Result);
        var logDto = Assert.IsType<DailyEmissionDto>(createdResult.Value);

        // Verify the action and route values in CreatedAtActionResult
        Assert.Equal(nameof(controller.GetLog), createdResult.ActionName);
        Assert.NotNull(createdResult.RouteValues);
        Assert.Equal(logDto.Id, createdResult.RouteValues["id"]);

        // Math:
        // Transport: 20 * 0.18 = 3.6
        // Electricity: 15 * 0.40 = 6.0
        // Waste: 5 * 1.9 * (1 - 0.2) = 7.6
        // Total: 3.6 + 6.0 + 7.6 = 17.2
        Assert.Equal(17.2, logDto.TotalEmissionsCo2Kg);

        // Verify it was saved to DB
        var dbLogs = await context.DailyEmissions.Where(e => e.UserId == 1).ToListAsync();
        Assert.Equal(2, dbLogs.Count);
    }

    [Theory]
    [InlineData("InvalidVehicle", "Petrol", "Mixed")]
    [InlineData("Car", "InvalidFuel", "Mixed")]
    [InlineData("Car", "Petrol", "InvalidWaste")]
    public async Task CreateLog_InvalidEnumSetPayload_Returns400BadRequest(string vehicle, string fuel, string wasteType)
    {
        using var context = new CarbonDbContext(_dbOptions);
        await SeedDatabaseAsync(context);

        var controller = new CarbonLogsController(context, _calculatorService);

        var payload = new CreateDailyEmissionDto
        {
            UserId = 1,
            Date = DateTime.UtcNow.Date.AddDays(1),
            TransportDistanceKm = 20.0,
            TransportVehicleType = vehicle,
            TransportFuelType = fuel,
            ElectricityKwh = 15.0,
            WasteWeightKg = 5.0,
            WasteType = wasteType,
            RecyclingRatePercentage = 20.0
        };

        var result = await controller.CreateLog(payload);

        Assert.IsType<BadRequestObjectResult>(result.Result);
    }

    [Theory]
    [InlineData(-10.0, 10.0, 2.0, 20.0)]
    [InlineData(10.0, -5.0, 2.0, 20.0)]
    [InlineData(10.0, 10.0, -1.0, 20.0)]
    [InlineData(10.0, 10.0, 2.0, -5.0)]
    [InlineData(10.0, 10.0, 2.0, 105.0)]
    public async Task CreateLog_InvalidRangeBoundsPayload_Returns400BadRequest(
        double distance, double electricity, double wasteWeight, double recyclingRate)
    {
        using var context = new CarbonDbContext(_dbOptions);
        await SeedDatabaseAsync(context);

        var controller = new CarbonLogsController(context, _calculatorService);

        var payload = new CreateDailyEmissionDto
        {
            UserId = 1,
            Date = DateTime.UtcNow.Date.AddDays(1),
            TransportDistanceKm = distance,
            TransportVehicleType = "Car",
            TransportFuelType = "Petrol",
            ElectricityKwh = electricity,
            WasteWeightKg = wasteWeight,
            WasteType = "Mixed",
            RecyclingRatePercentage = recyclingRate
        };

        var result = await controller.CreateLog(payload);

        Assert.IsType<BadRequestObjectResult>(result.Result);
    }

    [Fact]
    public async Task CreateLog_NonExistentUser_Returns400BadRequest()
    {
        using var context = new CarbonDbContext(_dbOptions);
        await SeedDatabaseAsync(context);

        var controller = new CarbonLogsController(context, _calculatorService);

        var payload = new CreateDailyEmissionDto
        {
            UserId = 999, // Non-existent user ID
            Date = DateTime.UtcNow.Date.AddDays(1),
            TransportDistanceKm = 10.0,
            TransportVehicleType = "Car",
            TransportFuelType = "Petrol",
            ElectricityKwh = 10.0,
            WasteWeightKg = 2.0,
            WasteType = "Mixed",
            RecyclingRatePercentage = 20.0
        };

        var result = await controller.CreateLog(payload);

        Assert.IsType<BadRequestObjectResult>(result.Result);
    }

    [Fact]
    public async Task CreateLog_ExistingLogOnSameDay_UpdatesLogAndReturns201Created()
    {
        using var context = new CarbonDbContext(_dbOptions);
        await SeedDatabaseAsync(context);

        var controller = new CarbonLogsController(context, _calculatorService);

        // First creation (already seeded in SeedDatabaseAsync for UtcNow.Date)
        // Transport = 10km, Car, Petrol = 1.8 kg
        // Electricity = 10kWh = 4.0 kg
        // Waste = 2.0kg, Mixed, 0% = 3.8 kg
        // Total = 9.6 kg

        // Now post again for the same date (UtcNow.Date) with updated values:
        var payload = new CreateDailyEmissionDto
        {
            UserId = 1,
            Date = DateTime.UtcNow.Date,
            TransportDistanceKm = 20.0, // Double distance
            TransportVehicleType = "Car",
            TransportFuelType = "Petrol",
            ElectricityKwh = 5.0, // Half energy
            WasteWeightKg = 1.0, // Half waste
            WasteType = "Mixed",
            RecyclingRatePercentage = 50.0 // 50% recycling
        };

        var result = await controller.CreateLog(payload);

        var createdResult = Assert.IsType<CreatedAtActionResult>(result.Result);
        var logDto = Assert.IsType<DailyEmissionDto>(createdResult.Value);

        // Verification of update calculations:
        // Transport = 20 * 0.18 = 3.6
        // Electricity = 5 * 0.40 = 2.0
        // Waste = 1.0 * 1.9 * (1 - 0.5) = 0.95
        // Total = 3.6 + 2.0 + 0.95 = 6.55
        Assert.Equal(6.55, logDto.TotalEmissionsCo2Kg);

        // Verify it was updated in the DB and no new record was created
        var dbLogs = await context.DailyEmissions.Where(e => e.UserId == 1).ToListAsync();
        Assert.Single(dbLogs); // Count remains 1!
        Assert.Equal(6.55, dbLogs.First().TotalEmissionsCo2Kg);
    }

    [Fact]
    public async Task GetStats_NoLogs_ReturnsZeroedStats()
    {
        using var context = new CarbonDbContext(_dbOptions);
        // Add user but do NOT seed logs
        var user = new User { Id = 1, Name = "Test User", Email = "test@user.com" };
        context.Users.Add(user);
        await context.SaveChangesAsync();

        var controller = new CarbonLogsController(context, _calculatorService);

        var result = await controller.GetStats(1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var value = okResult.Value;
        Assert.NotNull(value);

        var totalEmissions = (double)value.GetType().GetProperty("totalEmissionsCo2Kg")!.GetValue(value)!;
        var averageDaily = (double)value.GetType().GetProperty("averageDailyEmissionsCo2Kg")!.GetValue(value)!;
        var logCount = (int)value.GetType().GetProperty("logCount")!.GetValue(value)!;

        Assert.Equal(0.0, totalEmissions);
        Assert.Equal(0.0, averageDaily);
        Assert.Equal(0, logCount);
    }
}
