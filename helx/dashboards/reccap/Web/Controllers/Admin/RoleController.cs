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
    /// Class that provides administrative functionality to manage roles
    /// </summary>
    /// <seealso cref="Renci.Dashboard.Web.Common.ApiControllerBase" />
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/admin/roles")]
    [Produces("application/json")]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
    [ProducesResponseType(401)]
    [ProducesResponseType(403)]
    [ProducesResponseType(typeof(ProblemDetails), 500)]
    [ApiController]
    public class RoleController : ApiControllerBase
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<ApplicationRole> _roleManager;
        private readonly ApplicationDbContext _dbContext;

        /// <summary>
        /// Initializes a new instance of the <see cref="RoleController" /> class.
        /// </summary>
        /// <param name="userManager">The user manager.</param>
        /// <param name="roleManager">The role manager.</param>
        /// <param name="logger">The logger.</param>
        /// <param name="ai">The ai.</param>
        public RoleController(ApplicationDbContext dbContext, UserManager<ApplicationUser> userManager, RoleManager<ApplicationRole> roleManager, ILogger<RoleController> logger)
            : base(logger)
        {
            this._dbContext = dbContext;
            this._userManager = userManager;
            this._roleManager = roleManager;
        }

        /// <summary>
        /// Gets list of roles based on search parameters.
        /// </summary>
        /// <param name="search">The search.</param>
        /// <returns>List of items specified by search parameter.</returns>
        /// <response code="200">If items was successfully returned</response>
        [HttpGet]
        [HasPermission(Permission.AdminRoleCanList)]
        [ProducesResponseType(typeof(ObjectResultView<RoleItemView>), 200)]
        public async Task<IActionResult> List([FromQuery] RoleSearchView search)
        {
            if (search == null)
                throw new ArgumentNullException(nameof(search));

            var items = this._dbContext.AdminRoleQueryItems.AsQueryable();

            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                items = items.Where(m => EF.Functions.Like(m.Name, $"%{search.Name}%"));
            }

            //  Sort items
            search.Sort ??= RoleSearchView.DefaultSort;
            var sort = search.Sort.Replace(".a", " ascending", StringComparison.OrdinalIgnoreCase);
            sort = sort.Replace(".d", " descending", StringComparison.OrdinalIgnoreCase);
            items = items.OrderBy(sort);

            return Ok(await ObjectResultView<AdminRoleQueryItem>.CreateAsync(items, m => new RoleItemView(m), (search.Page - 1) * search.PageSize, search.PageSize));
        }

        /// <summary>
        /// Gets role edit view
        /// </summary>
        /// <param name="id">The role identifier.</param>
        /// <returns>Returns instance of the <see cref="RoleEditView"/> class specified by identifier.</returns>
        /// <response code="200">If item was successfully returned</response>
        /// <response code="404">If item was not found</response>
        [HttpGet("{id:guidurl}", Name = "GetRole")]
        [HasPermission(Permission.AdminRoleCanRead)]
        [ProducesResponseType(typeof(RoleEditView), 200)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> GetEditView(Guid id)
        {
            var item = await this.GetEntityItemAsync(id);

            if (item == null)
            {
                return NotFound();
            }
            return Ok(new RoleEditView(item, this._userManager));
        }

        /// <summary>
        /// Creates new role.
        /// </summary>
        /// <param name="item">The role edit view.</param>
        /// <returns>Returns new instance of the <see cref="RoleEditView"/> class.</returns>
        /// <response code="201">Returns the newly created item</response>
        /// <response code="400">If the item is invalid</response>
        [HttpPost]
        [HasPermission(Permission.AdminRoleCanCreate)]
        [ProducesResponseType(typeof(RoleEditView), 201)]
        [ProducesResponseType(typeof(ValidationProblemDetails), 400)]
        public async Task<IActionResult> Create([FromBody, Required] RoleEditView item)
        {
            if (item == null)
            {
                return BadRequest("Invalid item.");
            }

            try
            {
                var entity = new ApplicationRole();

                item.ApplyChangesTo(entity);

                var result = await this._roleManager.CreateAsync(entity);

                if (!result.Succeeded)
                {
                    return BadRequest(result);
                }

                //  If save was successful return new entity
                return CreatedAtAction("GetRole", new { id = entity.Id.EncodeToUrlCode() }, new RoleEditView(entity, this._userManager));
            }
            catch (ValidationException exp)
            {
                return HandleValidationException(exp);
            }
            catch (DbUpdateException exp)
            {
                return HandleDbUpdateException(exp);
            }
        }

        /// <summary>
        /// Updates an existing role.
        /// </summary>
        /// <param name="id">The role identifier.</param>
        /// <param name="item">The role edit view.</param>
        /// <returns>Returns updated instance of the <see cref="RoleEditView"/> class.</returns>
        /// <response code="200">Returns the updated item</response>
        /// <response code="400">If the item is invalid</response>
        [HttpPut("{id:guidurl}")]
        [HasPermission(Permission.AdminRoleCanUpdate)]
        [ProducesResponseType(typeof(RoleEditView), 200)]
        [ProducesResponseType(typeof(ValidationProblemDetails), 400)]
        public async Task<IActionResult> Update(Guid id, [FromBody, Required] RoleEditView item)
        {
            if (item == null || item.RoleId != id)
            {
                return BadRequest("Invalid item.");
            }

            try
            {
                var entity = await this.GetEntityItemAsync(id);

                item.ApplyChangesTo(entity);

                var result = await this._roleManager.UpdateAsync(entity);
                if (!result.Succeeded)
                {
                    return BadRequest(result);
                }

                //  If save was successful return new entity
                return Ok(new RoleEditView(entity, this._userManager));
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
        /// Deletes an existing role.
        /// </summary>
        /// <param name="id">The role identifier.</param>
        /// <returns>Returns No Content if successful.</returns>
        /// <response code="204">If item was deleted</response>
        /// <response code="404">If item was not found</response>
        [HttpDelete("{id:guidurl}")]
        [HasPermission(Permission.AdminRoleCanDelete)]
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
                await this._roleManager.DeleteAsync(item);

                return new NoContentResult();
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
                    when sqlException.Message.Contains("RoleNameIndex", StringComparison.InvariantCultureIgnoreCase)
                    && new int[] { 2601, 2627 }.Contains(sqlException.Number):
                    return BadRequest("Role already exists.");

                default:
                    break;
            }
            return base.HandleDbUpdateException(exp);
        }

        private Task<ApplicationRole> GetEntityItemAsync(Guid id)
        {
            return this._roleManager.Roles
                .AsTracking()
                .Include(m => m.Claims)
                .Include(m => m.Users)
                .Where(m => m.Id == id).SingleOrDefaultAsync();
        }
    }
}