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

namespace CarbonFootprint.Api.Tests;

public class UsersControllerTests
{
    private readonly DbContextOptions<CarbonDbContext> _dbOptions;

    public UsersControllerTests()
    {
        _dbOptions = new DbContextOptionsBuilder<CarbonDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
    }

    [Fact]
    public async Task GetUsers_ReturnsAllUsers()
    {
        using var context = new CarbonDbContext(_dbOptions);
        var user = new User { Id = 1, Name = "Test User", Email = "test@user.com" };
        context.Users.Add(user);
        await context.SaveChangesAsync();

        var controller = new UsersController(context);

        var result = await controller.GetUsers();

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var users = Assert.IsAssignableFrom<IEnumerable<User>>(okResult.Value);
        Assert.Single(users);
        Assert.Equal("Test User", users.First().Name);
    }

    [Fact]
    public async Task GetUser_ValidId_ReturnsUser()
    {
        using var context = new CarbonDbContext(_dbOptions);
        var user = new User { Id = 1, Name = "Test User", Email = "test@user.com" };
        context.Users.Add(user);
        await context.SaveChangesAsync();

        var controller = new UsersController(context);

        var result = await controller.GetUser(1);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var returnedUser = Assert.IsType<User>(okResult.Value);
        Assert.Equal("Test User", returnedUser.Name);
    }

    [Fact]
    public async Task GetUser_InvalidId_Returns404NotFound()
    {
        using var context = new CarbonDbContext(_dbOptions);
        var controller = new UsersController(context);

        var result = await controller.GetUser(999);

        Assert.IsType<NotFoundObjectResult>(result.Result);
    }

    [Fact]
    public async Task CreateUser_ValidPayload_SavesAndReturns201Created()
    {
        using var context = new CarbonDbContext(_dbOptions);
        var controller = new UsersController(context);

        var user = new User { Name = "New User", Email = "new@user.com" };

        var result = await controller.CreateUser(user);

        var createdResult = Assert.IsType<CreatedAtActionResult>(result.Result);
        var returnedUser = Assert.IsType<User>(createdResult.Value);

        Assert.Equal("New User", returnedUser.Name);
        Assert.Equal(nameof(controller.GetUser), createdResult.ActionName);
        Assert.NotNull(createdResult.RouteValues);
        Assert.Equal(returnedUser.Id, createdResult.RouteValues["id"]);

        var dbUsers = await context.Users.ToListAsync();
        Assert.Single(dbUsers);
    }

    [Fact]
    public async Task CreateUser_DuplicateEmail_Returns400BadRequest()
    {
        using var context = new CarbonDbContext(_dbOptions);
        var existing = new User { Id = 1, Name = "Test User", Email = "test@user.com" };
        context.Users.Add(existing);
        await context.SaveChangesAsync();

        var controller = new UsersController(context);
        var duplicate = new User { Name = "Duplicate User", Email = "test@user.com" };

        var result = await controller.CreateUser(duplicate);

        Assert.IsType<BadRequestObjectResult>(result.Result);
    }
}
