using Xunit;
using CarbonFootprint.Api.Services;

namespace CarbonFootprint.Api.Tests;

public class CarbonCalculatorServiceTests
{
    private readonly ICarbonCalculatorService _calculatorService;

    public CarbonCalculatorServiceTests()
    {
        _calculatorService = new CarbonCalculatorService();
    }

    [Theory]
    [InlineData(100.0, "Car", "Petrol", 18.0)]
    [InlineData(100.0, "Car", "Diesel", 17.0)]
    [InlineData(100.0, "Car", "Electric", 5.0)]
    [InlineData(50.0, "Motorcycle", "Petrol", 5.0)]
    [InlineData(10.0, "Bus", "None", 0.8)]
    [InlineData(20.0, "Train", "Electric", 0.8)]
    [InlineData(15.0, "Bicycle", "None", 0.0)]
    [InlineData(5.0, "Walking", "None", 0.0)]
    [InlineData(-10.0, "Car", "Petrol", 0.0)]
    public void CalculateTransportEmissions_ReturnsExpectedResults(
        double distance, string vehicle, string fuel, double expectedEmissions)
    {
        var result = _calculatorService.CalculateTransportEmissions(distance, vehicle, fuel);
        Assert.Equal(expectedEmissions, result);
    }

    [Theory]
    [InlineData(10.0, 4.0)]
    [InlineData(0.0, 0.0)]
    [InlineData(-5.0, 0.0)]
    public void CalculateElectricityEmissions_ReturnsExpectedResults(double kwh, double expectedEmissions)
    {
        var result = _calculatorService.CalculateElectricityEmissions(kwh);
        Assert.Equal(expectedEmissions, result);
    }

    [Theory]
    [InlineData(10.0, "Mixed", 0.0, 19.0)] // 10kg * 1.9 * (1 - 0) = 19
    [InlineData(10.0, "Mixed", 50.0, 9.5)] // 10kg * 1.9 * (1 - 0.5) = 9.5
    [InlineData(5.0, "Mixed", 100.0, 0.0)] // 5kg * 1.9 * (1 - 1.0) = 0
    [InlineData(0.0, "Mixed", 30.0, 0.0)]
    [InlineData(-2.0, "Mixed", 30.0, 0.0)]
    public void CalculateWasteEmissions_ReturnsExpectedResults(
        double weight, string wasteType, double recyclingRate, double expectedEmissions)
    {
        var result = _calculatorService.CalculateWasteEmissions(weight, wasteType, recyclingRate);
        Assert.Equal(expectedEmissions, result);
    }
}
