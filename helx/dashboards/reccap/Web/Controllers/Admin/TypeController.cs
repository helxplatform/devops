using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
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
using System.Collections.Generic;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Reflection;
using System.Threading.Tasks;

namespace Renci.ReCCAP.Dashboard.Web.Controllers.Admin
{
    /// <summary>
    /// Class that provides administrative functionality to manage types
    /// </summary>
    /// <seealso cref="Renci.Dashboard.Web.Common.ApiControllerBase" />
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/admin/types/{categoryName}")]
    [Produces("application/json")]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
    [ProducesResponseType(401)]
    [ProducesResponseType(403)]
    [ProducesResponseType(typeof(ProblemDetails), 500)]
    [ApiController]
    public class TypeController : ApiControllerBase
    {
        private readonly ApplicationDbContext _dbContext;

        /// <summary>
        /// Initializes a new instance of the <see cref="TypeController" /> class.
        /// </summary>
        /// <param name="dbContext">The database context.</param>
        /// <param name="logger">The logger.</param>
        /// <param name="ai">The ai.</param>
        public TypeController(ApplicationDbContext dbContext, ILogger<TypeController> logger)
            : base(logger)
        {
            this._dbContext = dbContext;
        }

        /// <summary>
        /// Gets list of types based on search parameters.
        /// </summary>
        /// <param name="categoryName">Name of the category.</param>
        /// <param name="search">The search.</param>
        /// <returns>
        /// List of items specified by search parameter.
        /// </returns>
        /// <response code="200">If items was successfully returned</response>
        [HttpGet]
        [HasPermission(Permission.AdminTypeCanList)]
        [ProducesResponseType(typeof(ObjectResultView<TypeItemView>), 200)]
        public async Task<IActionResult> List(CategoryName categoryName, [FromQuery] TypeSearchView search)
        {
            if (search == null)
                throw new ArgumentNullException(nameof(search));

            var items = this._dbContext.AdminTypeQueryItems
                .Where(m => m.Category == categoryName)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                items = items.Where(m => EF.Functions.Like(m.TypeName, $"%{search.Name}%"));
            }

            if (search.Category != CategoryName.None)
            {
                items = items.Where(m => m.Category == search.Category);
            }

            if (search.ParentId != null)
            {
                items = items.Where(m => m.ParentTypeId == search.ParentId);
            }

            //  Sort items
            search.Sort ??= TypeSearchView.DefaultSort;
            var sort = search.Sort.Replace(".a", " ascending", StringComparison.OrdinalIgnoreCase);
            sort = sort.Replace(".d", " descending", StringComparison.OrdinalIgnoreCase);
            items = items.OrderBy(sort);

            var titleName = typeof(CategoryName).GetFields()
                .Where(m => m.IsSpecialName == false && m.Name == categoryName.ToString())
                .Select(m => m.GetCustomAttribute<DescriptionAttribute>()?.Description ?? m.Name)
                .FirstOrDefault();

            return Ok(await ObjectResultView<AdminTypeQueryItem>.CreateAsync(items, m => new TypeItemView(m), (search.Page - 1) * search.PageSize, search.PageSize, titleName));
        }

        /// <summary>
        /// Gets type edit view.
        /// </summary>
        /// <param name="categoryName">Name of the category.</param>
        /// <param name="id">The identifier.</param>
        /// <returns>
        /// Returns instance of the <see cref="TypeEditView" /> class specified by identifier.
        /// </returns>
        /// <response code="200">If item was successfully returned</response>
        /// <response code="404">If item was not found</response>
        [HttpGet("{id:guidurl}", Name = "GetType")]
        [HasPermission(Permission.AdminTypeCanRead)]
        [ProducesResponseType(typeof(TypeEditView), 200)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> GetEditView(CategoryName categoryName, Guid id)
        {
            var item = await this.GetEntityItemAsync(categoryName, id);

            if (item == null)
            {
                return NotFound();
            }
            return Ok(new TypeEditView(item));
        }

        /// <summary>
        /// Creates new type.
        /// </summary>
        /// <param name="categoryName">Name of the category.</param>
        /// <param name="item">The item.</param>
        /// <returns>
        /// Returns new instance of the <see cref="TypeEditView" /> class.
        /// </returns>
        /// <response code="201">Returns the newly created item</response>
        /// <response code="400">If the item is invalid</response>
        [HttpPost]
        [ProducesResponseType(typeof(TypeEditView), 201)]
        [ProducesResponseType(typeof(ValidationProblemDetails), 400)]
        [HasPermission(Permission.AdminTypeCanCreate)]
        public async Task<IActionResult> Create(CategoryName categoryName, [FromBody, Required] TypeEditView item)
        {
            if (item == null)
                throw new ArgumentNullException(nameof(item));

            try
            {
                item.Category = categoryName;

                var entity = new Data.Type()
                {
                    Category = item.Category
                };

                //  Add entity to context
                this._dbContext.Add(entity);

                item.ApplyChangesTo(entity);

                var orderEquence = await this._dbContext.Types.Where(m => m.Category == categoryName)
                    .GroupBy(e => 1)
                    .Select(t => t.Max(e => e.OrderSequence))
                    .FirstOrDefaultAsync();

                entity.OrderSequence = orderEquence + 1;

                await this._dbContext.SaveChangesAsync();

                //  If save was successful return new entity
                return CreatedAtAction("GetType", new { id = entity.TypeId.EncodeToUrlCode(), categoryName = categoryName.ToString() }, new TypeEditView(await this.GetEntityItemAsync(categoryName, entity.TypeId)));
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
        /// Updates an existing type.
        /// </summary>
        /// <param name="categoryName">Name of the category.</param>
        /// <param name="id">The identifier.</param>
        /// <param name="item">The item.</param>
        /// <returns>
        /// Returns updated instance of the <see cref="TypeEditView" /> class.
        /// </returns>
        /// <response code="200">Returns the updated item</response>
        /// <response code="400">If the item is invalid</response>
        [HttpPut("{id:guidurl}")]
        [HasPermission(Permission.AdminTypeCanUpdate)]
        [ProducesResponseType(typeof(TypeEditView), 200)]
        [ProducesResponseType(typeof(ValidationProblemDetails), 400)]
        public async Task<IActionResult> Update(CategoryName categoryName, Guid id, [FromBody, Required] TypeEditView item)
        {
            if (item == null || item.TypeId != id || item.Category != categoryName)
            {
                return BadRequest("Invalid item.");
            }

            try
            {
                var entity = await this.GetEntityItemAsync(categoryName, id);

                if (entity == null)
                {
                    return this.RecordDeletedResult;
                }

                this._dbContext.Update(entity);

                item.ApplyChangesTo(entity);

                await this._dbContext.SaveChangesAsync();

                //  If save was successful return new entity
                return Ok(new TypeEditView(await this.GetEntityItemAsync(categoryName, entity.TypeId)));
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
        /// Deletes an existing type.
        /// </summary>
        /// <param name="categoryName">Name of the category.</param>
        /// <param name="id">The type identifier.</param>
        /// <returns>
        /// Returns No Content if successful.
        /// </returns>
        /// <response code="204">If item was deleted</response>
        /// <response code="404">If item was not found</response>
        [HttpDelete("{id:guidurl}")]
        [HasPermission(Permission.AdminTypeCanDelete)]
        [ProducesResponseType(204)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> Delete(CategoryName categoryName, Guid id)
        {
            var item = await this.GetEntityItemAsync(categoryName, id);

            if (item == null)
            {
                return NotFound();
            }

            try
            {
                this._dbContext.Types.Remove(item);

                await this._dbContext.SaveChangesAsync();

                return new NoContentResult();
            }
            catch (DbUpdateException exp)
            {
                return HandleDbUpdateException(exp);
            }
        }

        /// <summary>
        /// Sorteds the list.
        /// </summary>
        /// <param name="categoryName">Name of the category.</param>
        /// <returns></returns>
        [HttpGet("sort")]
        [HasPermission(Permission.AdminTypeCanList)]
        [ProducesResponseType(typeof(ObjectResultView<TypeSortView>), 200)]
        public async Task<IActionResult> SortedList(CategoryName categoryName)
        {
            var items = this._dbContext.AdminTypeQueryItems
                .Where(m => m.Category == categoryName)
                .OrderBy(m => m.OrderSequence)
                .ThenBy(m => m.TypeName)
                .AsQueryable();

            var titleName = typeof(CategoryName).GetFields()
                .Where(m => m.IsSpecialName == false && m.Name == categoryName.ToString())
                .Select(m => m.GetCustomAttribute<DescriptionAttribute>()?.Description ?? m.Name)
                .FirstOrDefault();

            return Ok(await ObjectResultView<AdminTypeQueryItem>.CreateAsync(items, m => new TypeSortView(m), 0, 0, titleName));
        }

        /// <summary>
        /// Update items in batch.
        /// </summary>
        /// <param name="categoryName">Name of the category.</param>
        /// <param name="sortedItems">The sorted items.</param>
        /// <returns>
        /// Returns updated instances of the <see cref="TypeItemView" /> class.
        /// </returns>
        /// <response code="200">Returns updated items</response>
        /// <response code="400">If the item is invalid</response>
        [HttpPut("sort")]
        [HasPermission(Permission.AdminTypeCanUpdate)]
        [ProducesResponseType(typeof(IEnumerable<TypeItemView>), 200)]
        [ProducesResponseType(typeof(ValidationProblemDetails), 400)]
        public async Task<IActionResult> Sort(CategoryName categoryName, [FromBody] IEnumerable<TypeSortView> sortedItems)
        {
            if (sortedItems == null)
            {
                return BadRequest("Invalid item.");
            }

            try
            {
                var entities = await this._dbContext.Types.Where(m => m.Category == categoryName && sortedItems.Select(t => t.TypeId).Contains(m.TypeId)).ToListAsync();
                foreach (var entity in entities)
                {
                    this._dbContext.Update(entity);

                    var sortedItem = sortedItems.Where(m => m.TypeId == entity.TypeId).First();
                    entity.OrderSequence = sortedItem.OrderSequence;
                    entity.Version = sortedItem.Version;
                }

                await this._dbContext.SaveChangesAsync();

                var items = this._dbContext.AdminTypeQueryItems
                    .Where(m => m.Category == categoryName)
                    .OrderBy(m => m.OrderSequence)
                    .ThenBy(m => m.TypeName)
                    .AsQueryable();

                var titleName = typeof(CategoryName).GetFields()
                    .Where(m => m.IsSpecialName == false && m.Name == categoryName.ToString())
                    .Select(m => m.GetCustomAttribute<DescriptionAttribute>()?.Description ?? m.Name)
                    .FirstOrDefault();

                return Ok(await ObjectResultView<AdminTypeQueryItem>.CreateAsync(items, m => new TypeSortView(m), 0, 0, titleName));
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
                    when sqlException.Message.Contains("IX_Type_Unique", StringComparison.InvariantCultureIgnoreCase)
                    && new int[] { 2601, 2627 }.Contains(sqlException.Number):
                    return BadRequest("Type with the same name already exists.");

                case Microsoft.Data.SqlClient.SqlException sqlException
                    when sqlException.Message.Contains("IX_Type_Code", StringComparison.InvariantCultureIgnoreCase)
                    && new int[] { 2601, 2627 }.Contains(sqlException.Number):
                    return BadRequest("Type with the same code already exists.");

                case Microsoft.Data.SqlClient.SqlException sqlException
                    when sqlException.Message.Contains("The DELETE statement conflicted with the REFERENCE constraint", StringComparison.InvariantCultureIgnoreCase)
                    && sqlException.Number == 547:
                    return BadRequest("Type is in use and cannot be deleted.");

                default:
                    break;
            }
            return base.HandleDbUpdateException(exp);
        }

        private Task<Data.Type> GetEntityItemAsync(CategoryName categoryName, Guid id)
        {
            return this._dbContext
                .Types
                .Include(m => m.ParentType)
                .Include(m => m.Roles)
                    .ThenInclude(m => m.Role)
                .Where(m => m.TypeId == id && m.Category == categoryName)
                .FirstOrDefaultAsync();
        }
    }
}