using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CarbonFootprint.Api.Data;
using CarbonFootprint.Api.Models;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace CarbonFootprint.Api.Controllers;

/// <summary>
/// API Controller for managing users on the carbon awareness platform.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly CarbonDbContext _context;

    /// <summary>
    /// Initializes a new instance of the <see cref="UsersController"/> class.
    /// </summary>
    /// <param name="context">The database context instance.</param>
    public UsersController(CarbonDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Retrieves a list of all registered users.
    /// Uses database query tracing optimization (AsNoTracking).
    /// </summary>
    /// <returns>A list of users.</returns>
    [HttpGet]
    [ProducesResponseType(200, Type = typeof(IEnumerable<User>))]
    public async Task<ActionResult<IEnumerable<User>>> GetUsers()
    {
        var users = await _context.Users
            .AsNoTracking()
            .ToListAsync();

        return Ok(users);
    }

    /// <summary>
    /// Retrieves a specific user by their ID.
    /// Uses database query tracing optimization (AsNoTracking).
    /// </summary>
    /// <param name="id">The unique identifier of the user.</param>
    /// <returns>The user details if found; otherwise, NotFound.</returns>
    [HttpGet("{id:int}")]
    [ProducesResponseType(200, Type = typeof(User))]
    [ProducesResponseType(404)]
    public async Task<ActionResult<User>> GetUser(int id)
    {
        var user = await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null)
        {
            return NotFound($"User with ID {id} was not found.");
        }

        return Ok(user);
    }

    /// <summary>
    /// Registers a new user on the platform.
    /// </summary>
    /// <param name="user">The user payload to create.</param>
    /// <returns>The created user details.</returns>
    [HttpPost]
    [ProducesResponseType(201, Type = typeof(User))]
    [ProducesResponseType(400)]
    public async Task<ActionResult<User>> CreateUser([FromBody] User user)
    {
        if (user == null)
        {
            return BadRequest("Payload is null.");
        }

        if (string.IsNullOrWhiteSpace(user.Name) || string.IsNullOrWhiteSpace(user.Email))
        {
            return BadRequest("User Name and Email are required.");
        }

        // Sanitize string inputs
        user.Name = user.Name.Trim();
        user.Email = user.Email.Trim();

        // Check if email already exists
        var emailExists = await _context.Users.AnyAsync(u => u.Email.ToLower() == user.Email.ToLower());
        if (emailExists)
        {
            return BadRequest($"A user with the email '{user.Email}' already exists.");
        }

        user.CreatedAt = DateTime.UtcNow;

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetUser), new { id = user.Id }, user);
    }
}
