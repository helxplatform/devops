using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Renci.ReCCAP.Dashboard.Web.Common;
using Renci.ReCCAP.Dashboard.Web.Common.Security;
using Renci.ReCCAP.Dashboard.Web.Data;
using Renci.ReCCAP.Dashboard.Web.Models.Enums;
using Renci.ReCCAP.Dashboard.Web.ViewModels;
using Renci.ReCCAP.Dashboard.Web.ViewModels.Admin;
using System;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Threading.Tasks;

namespace Renci.ReCCAP.Dashboard.Web.Controllers.Admin
{
    /// <summary>
    /// Class that provides administrative functionality to manage users.
    /// </summary>
    /// <seealso cref="Renci.Dashboard.Web.Common.ApiControllerBase" />
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/admin/users")]
    [Produces("application/json")]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
    [ProducesResponseType(401)]
    [ProducesResponseType(403)]
    [ProducesResponseType(typeof(ProblemDetails), 500)]
    [ApiController]
    public class UserController : ApiControllerBase
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<ApplicationRole> _roleManager;
        private readonly ApplicationDbContext _dbContext;

        /// <summary>
        /// Initializes a new instance of the <see cref="UserController" /> class.
        /// </summary>
        /// <param name="dbContext">The database context.</param>
        /// <param name="userManager">The user manager.</param>
        /// <param name="roleManager">The role manager.</param>
        /// <param name="logger">The logger.</param>
        /// <param name="ai">The ai.</param>
        public UserController(ApplicationDbContext dbContext, UserManager<ApplicationUser> userManager, RoleManager<ApplicationRole> roleManager, ILogger<UserController> logger)
            : base(logger)
        {
            this._dbContext = dbContext;
            this._userManager = userManager;
            this._roleManager = roleManager;
        }

        /// <summary>
        /// Gets list of users based on search parameters.
        /// </summary>
        /// <param name="search">The search.</param>
        /// <returns>List of items specified by search parameter.</returns>
        /// <response code="200">If items was successfully returned</response>
        [HttpGet]
        [HasPermission(Permission.AdminUserCanList)]
        [ProducesResponseType(typeof(ObjectResultView<UserItemView>), 200)]
        public async Task<IActionResult> List([FromQuery] UserSearchView search)
        {
            if (search == null)
                throw new ArgumentNullException(nameof(search));

            var items = this._dbContext.AdminUserQueryItems.AsQueryable();

            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                items = items.Where(m => EF.Functions.Like(m.UserName, $"%{search.Name}%") || EF.Functions.Like(m.DisplayName, $"%{search.Name}%") || EF.Functions.Like(m.Email, $"%{search.Name}%"));
            }

            //  Sort items
            search.Sort ??= UserSearchView.DefaultSort;
            var sort = search.Sort.Replace(".a", " ascending", StringComparison.OrdinalIgnoreCase);
            sort = sort.Replace(".d", " descending", StringComparison.OrdinalIgnoreCase);
            items = items.OrderBy(sort);

            return Ok(await ObjectResultView<AdminUserQueryItem>.CreateAsync(items, m => new UserItemView(m), (search.Page - 1) * search.PageSize, search.PageSize));
        }

        /// <summary>
        /// Gets user edit view.
        /// </summary>
        /// <param name="id">The user identifier.</param>
        /// <returns>Returns instance of the <see cref="UserEditView"/> class specified by identifier.</returns>
        /// <response code="200">If item was successfully returned</response>
        /// <response code="404">If item was not found</response>
        [HttpGet("{id:guidurl}", Name = "GetUser")]
        [HasPermission(Permission.AdminUserCanRead)]
        [ProducesResponseType(typeof(UserEditView), 200)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> GetEditView(Guid id)
        {
            var item = await this.GetEntityItemAsync(id);
            if (item == null)
            {
                return NotFound();
            }
            return Ok(new UserEditView(item, this._roleManager));
        }

        /// <summary>
        /// Updates an existing user.
        /// </summary>
        /// <param name="id">User id.</param>
        /// <param name="item">User edit view.</param>
        /// <returns>Returns updated instance of the <see cref="UserEditView"/> class.</returns>
        /// <response code="200">Returns the updated item</response>
        /// <response code="400">If the item is invalid</response>
        [HttpPut("{id:guidurl}")]
        [HasPermission(Permission.AdminUserCanUpdate)]
        [ProducesResponseType(typeof(UserEditView), 200)]
        [ProducesResponseType(typeof(ValidationProblemDetails), 400)]
        public async Task<IActionResult> Update(Guid id, [FromBody, Required] UserEditView item)
        {
            if (item == null || item.UserId != id)
            {
                return BadRequest("Invalid item.");
            }

            try
            {
                var entity = await this.GetEntityItemAsync(id);

                item.ApplyChangesTo(entity);

                var result = await this._userManager.UpdateAsync(entity);

                if (!result.Succeeded)
                {
                    return BadRequest(result);
                }

                //  If save was successful return new entity
                return Ok(new UserEditView(entity, this._roleManager));
            }
            catch (ValidationException exp)
            {
                return HandleValidationException(exp);
            }
            catch (DbUpdateConcurrencyException exp)
            {
                return await HandleUpdateConcurrencyExceptionAsync(exp);
            }
            catch (DbUpdateException exp)
            {
                return HandleDbUpdateException(exp);
            }
        }

        /// <summary>
        /// Deletes an existing user.
        /// </summary>
        /// <param name="id">The user identifier.</param>
        /// <returns>Returns No Content if successful.</returns>
        /// <response code="204">If item was deleted</response>
        /// <response code="404">If item was not found</response>
        [HttpDelete("{id:guidurl}")]
        [HasPermission(Permission.AdminUserCanDelete)]
        [ProducesResponseType(204)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> Delete(Guid id)
        {
            var item = await this.GetEntityItemAsync(id);

            if (item == null)
            {
                return NotFound();
            }

            try
            {
                await this._userManager.DeleteAsync(item);

                return new NoContentResult();
            }
            catch (DbUpdateException exp)
            {
                return HandleDbUpdateException(exp);
            }
        }

        /// <summary>
        /// Enables an existing user.
        /// </summary>
        /// <param name="id">User id.</param>
        /// <returns>Returns updated instance of the <see cref="UserItemView"/> class.</returns>
        /// <response code="200">Returns the updated item</response>
        /// <response code="400">If the item is invalid</response>
        [HttpPut("{id:guidurl}/enable")]
        [HasPermission(Permission.AdminUserCanUpdate)]
        [ProducesResponseType(typeof(UserItemView), 200)]
        [ProducesResponseType(typeof(ValidationProblemDetails), 400)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> Enable(Guid id)
        {
            try
            {
                var entity = await this.GetEntityItemAsync(id);

                entity.LockoutEnd = null;

                var result = await this._userManager.UpdateAsync(entity);

                if (!result.Succeeded)
                {
                    return BadRequest(result);
                }

                var item = await this._dbContext.AdminUserQueryItems.Where(m => m.UserId == entity.Id).FirstOrDefaultAsync();
                if (item == null)
                {
                    return NotFound();
                }

                //  If save was successful return new entity
                return Ok(new UserItemView(item));
            }
            catch (ValidationException exp)
            {
                return HandleValidationException(exp);
            }
            catch (DbUpdateConcurrencyException exp)
            {
                return await HandleUpdateConcurrencyExceptionAsync(exp);
            }
            catch (DbUpdateException exp)
            {
                return HandleDbUpdateException(exp);
            }
        }

        /// <summary>
        /// Enables an existing user.
        /// </summary>
        /// <param name="id">User id.</param>
        /// <returns>Returns updated instance of the <see cref="UserItemView"/> class.</returns>
        /// <response code="200">Returns the updated item</response>
        /// <response code="400">If the item is invalid</response>
        [HttpPut("{id:guidurl}/disable")]
        [HasPermission(Permission.AdminUserCanUpdate)]
        [ProducesResponseType(typeof(UserItemView), 200)]
        [ProducesResponseType(typeof(ValidationProblemDetails), 400)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> Disable(Guid id)
        {
            try
            {
                var entity = await this.GetEntityItemAsync(id);

                entity.LockoutEnd = DateTime.Now.AddYears(100);

                var result = await this._userManager.UpdateAsync(entity);

                if (!result.Succeeded)
                {
                    return BadRequest(result);
                }

                var item = await this._dbContext.AdminUserQueryItems.Where(m => m.UserId == entity.Id).FirstOrDefaultAsync();
                if (item == null)
                {
                    return NotFound();
                }

                //  If save was successful return new entity
                return Ok(new UserItemView(item));
            }
            catch (ValidationException exp)
            {
                return HandleValidationException(exp);
            }
            catch (DbUpdateConcurrencyException exp)
            {
                return await HandleUpdateConcurrencyExceptionAsync(exp);
            }
            catch (DbUpdateException exp)
            {
                return HandleDbUpdateException(exp);
            }
        }

        /// <summary>
        /// Handles the database update exception.
        /// </summary>
        /// <param name="exp">The exp.</param>
        /// <returns></returns>
        protected override IActionResult HandleDbUpdateException(DbUpdateException exp)
        {
            if (exp == null)
                throw new ArgumentNullException(nameof(exp));

            switch (exp.GetBaseException())
            {
                case Microsoft.Data.SqlClient.SqlException sqlException
                    when sqlException.Message.Contains("UserNameIndex", StringComparison.InvariantCultureIgnoreCase)
                    && new int[] { 2601, 2627 }.Contains(sqlException.Number):
                    return BadRequest("User already exists.");

                case Microsoft.Data.SqlClient.SqlException sqlException
                    when sqlException.Message.Contains("The DELETE statement conflicted with the REFERENCE constraint", StringComparison.InvariantCultureIgnoreCase)
                    && sqlException.Number == 547:
                    return BadRequest($"User is in use and cannot be deleted.");

                default:
                    break;
            }
            return base.HandleDbUpdateException(exp);
        }

        private Task<ApplicationUser> GetEntityItemAsync(Guid id)
        {
            return this._userManager.Users
                .AsTracking()
                .Include(m => m.Claims)
                .Include(m => m.Roles)
                .Where(m => m.Id == id)
                .SingleOrDefaultAsync();
        }
    }
}