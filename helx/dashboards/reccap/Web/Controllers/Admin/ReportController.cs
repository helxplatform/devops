using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Renci.ReCCAP.Dashboard.Web.Common;
using Renci.ReCCAP.Dashboard.Web.Common.Attributes;
using Renci.ReCCAP.Dashboard.Web.Common.Security;
using Renci.ReCCAP.Dashboard.Web.Data;
using Renci.ReCCAP.Dashboard.Web.Models.Enums;
using Renci.ReCCAP.Dashboard.Web.ViewModels;
using Renci.ReCCAP.Dashboard.Web.ViewModels.Admin;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace Renci.ReCCAP.Dashboard.Web.Controllers.Admin
{
    /// <summary>
    /// Class that provides administrative functionality to manage reports
    /// </summary>
    /// <seealso cref="Renci.PlaceDb.Web.Common.ApiControllerBase" />
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/admin/reports")]
    [Produces("application/json")]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
    [ProducesResponseType(401)]
    [ProducesResponseType(403)]
    [ProducesResponseType(typeof(ProblemDetails), 500)]
    [ApiController]
    public class ReportController : ApiControllerBase
    {
        private readonly ApplicationDbContext _dbContext;

        /// <summary>
        /// Initializes a new instance of the <see cref="ReportController" /> class.
        /// </summary>
        /// <param name="dbContext">The database context.</param>
        /// <param name="logger">The logger.</param>
        /// <param name="ai">The ai.</param>
        public ReportController(ApplicationDbContext dbContext, ILogger<ReportController> logger)
            : base(logger)
        {
            this._dbContext = dbContext;
        }

        /// <summary>
        /// Gets list of reports based on search parameters.
        /// </summary>
        /// <param name="search">The search.</param>
        /// <returns>List of items specified by search parameter.</returns>
        /// <response code="200">If items was successfully returned</response>
        [HttpGet]
        [HasPermission(Permission.AdminReportCanList)]
        [ProducesResponseType(typeof(ObjectResultView<ReportItemView>), 200)]
        public async Task<IActionResult> List([FromQuery] ReportSearchView search)
        {
            if (search == null)
                throw new ArgumentNullException(nameof(search));

            var items = this._dbContext.AdminReportQueryItems
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                items = items.Where(m => EF.Functions.Like(m.ReportName, $"%{search.Name}%"));
            }

            if (search.ReportTypeId != null)
            {
                items = items.Where(m => m.ReportTypeId == search.ReportTypeId);
            }

            //  Sort items
            search.Sort ??= ViewModels.Admin.ReportSearchView.DefaultSort;

            var sortProperty = (from p in typeof(ReportItemView).GetProperties()
                                from attr in p.GetCustomAttributes(true).OfType<SortPropertyNameAttribute>()
                                where p.Name.Equals(search.Sort, StringComparison.CurrentCultureIgnoreCase)
                                select attr.Name).FirstOrDefault();

            if ("desc".Equals(search.Direction))
            {
                items = items.OrderBy($"{sortProperty} descending");
            }
            else
            {
                items = items.OrderBy($"{sortProperty} ascending");
            }

            return this.Ok(await ObjectResultView<AdminReportQueryItem>.CreateAsync(items, m => new ViewModels.Admin.ReportItemView(m), (search.Page - 1) * search.PageSize, search.PageSize));
        }

        /// <summary>
        /// Gets report edit view.
        /// </summary>
        /// <param name="id">The identifier.</param>
        /// <returns>Returns instance of the <see cref="ReportEditView"/> class specified by identifier.</returns>
        /// <response code="200">If item was successfully returned</response>
        /// <response code="404">If item was not found</response>
        [HttpGet("{id}", Name = "GetReport")]
        [HasPermission(Permission.AdminReportCanRead)]
        [ProducesResponseType(typeof(ReportEditView), 200)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> GetEditView(Guid id)
        {
            var item = await this.GetEntityItemAsync(id);

            if (item == null)
            {
                return this.NotFound();
            }
            return this.Ok(new ReportEditView(item));
        }

        /// <summary>
        /// Exports the specified identifier.
        /// </summary>
        /// <param name="id">The identifier.</param>
        /// <returns></returns>
        //[HttpGet("{id:guidurl}/export")]
        //[HasPermission(Permission.AdminReportCanRead)]
        //[ProducesResponseType(typeof(ReportExportView), 200)]
        //[ProducesResponseType(404)]
        //public async Task<IActionResult> Export(Guid id)
        //{
        //    var item = await this.GetEntityItemAsync(id);

        //    if (item == null)
        //    {
        //        return this.NotFound();
        //    }

        //    var result = JsonConvert.SerializeObject(
        //                            new ReportExportView(item),
        //                            new JsonSerializerSettings()
        //                            {
        //                                ContractResolver = new CamelCasePropertyNamesContractResolver(),
        //                                NullValueHandling = NullValueHandling.Ignore,
        //                                DateFormatHandling = DateFormatHandling.IsoDateFormat,
        //                            });
        //    var json = JsonConvert.DeserializeObject<JObject>(result);

        //    return this.File(Encoding.ASCII.GetBytes(json.ToString()), "text/json");
        //}

        /// <summary>
        /// Creates new report.
        /// </summary>
        /// <param name="item">The item.</param>
        /// <returns>Returns new instance of the <see cref="ReportExportView"/> class.</returns>
        /// <response code="201">Returns the newly created item</response>
        /// <response code="400">If the item is invalid</response>
        [HttpPost("import")]
        [HasPermission(Permission.AdminReportCanCreate)]
        [ProducesResponseType(typeof(ReportExportView), 201)]
        [ProducesResponseType(typeof(ValidationProblemDetails), 400)]
        public async Task<IActionResult> Import([FromBody, Required] ReportExportView item)
        {
            if (item == null)
            {
                return this.BadRequest("Invalid item.");
            }

            try
            {
                var entity = new Report();

                //  Add entity to context
                this._dbContext.Add(entity);

                item.ApplyChangesTo(entity, this._dbContext);

                await this._dbContext.SaveChangesAsync();

                //  If save was successful return new entity
                return CreatedAtAction("GetReport", new { id = entity.ReportId }, new ReportEditView(await this.GetEntityItemAsync(entity.ReportId)));
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
        /// Creates new report.
        /// </summary>
        /// <param name="item">The item.</param>
        /// <returns>Returns new instance of the <see cref="ReportEditView"/> class.</returns>
        /// <response code="201">Returns the newly created item</response>
        /// <response code="400">If the item is invalid</response>
        [HttpPost]
        [HasPermission(Permission.AdminReportCanCreate)]
        [ProducesResponseType(typeof(ReportEditView), 201)]
        [ProducesResponseType(typeof(ValidationProblemDetails), 400)]
        public async Task<IActionResult> Create([FromBody, Required] ReportEditView item)
        {
            if (item == null)
            {
                return this.BadRequest("Invalid item.");
            }

            await this.ValidateQuery(item);

            if (!ModelState.IsValid)
            {
                return this.BadRequest(ModelState);
            }

            try
            {
                var entity = new Report();

                //  Add entity to context
                this._dbContext.Add(entity);

                item.ApplyChangesTo(entity);

                await this._dbContext.SaveChangesAsync();

                //  If save was successful return new entity
                return CreatedAtAction("GetReport", new { id = entity.ReportId }, new ReportEditView(await this.GetEntityItemAsync(entity.ReportId)));
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
        /// Updates an existing report.
        /// </summary>
        /// <param name="id">The identifier.</param>
        /// <param name="item">The item.</param>
        /// <returns>Returns updated instance of the <see cref="ReportEditView"/> class.</returns>
        /// <response code="200">Returns the updated item</response>
        /// <response code="400">If the item is invalid</response>
        [HttpPut("{id:guidurl}")]
        [HasPermission(Permission.AdminReportCanUpdate)]
        [ProducesResponseType(typeof(ReportEditView), 200)]
        [ProducesResponseType(typeof(ValidationProblemDetails), 400)]
        public async Task<IActionResult> Update(Guid id, [FromBody, Required] ReportEditView item)
        {
            if (item == null || item.ReportId != id)
            {
                return this.BadRequest("Invalid item.");
            }

            await this.ValidateQuery(item);

            if (!ModelState.IsValid)
            {
                return this.BadRequest(ModelState);
            }

            try
            {
                var entity = await this.GetEntityItemAsync(id);

                if (entity == null)
                {
                    return this.RecordDeletedResult;
                }

                this._dbContext.Update(entity);

                item.ApplyChangesTo(entity);

                await this._dbContext.SaveChangesAsync();

                //  If save was successful return new entity
                return this.Ok(new ReportEditView(await this.GetEntityItemAsync(entity.ReportId)));
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
        /// Creates new report.
        /// </summary>
        /// <param name="item">The item.</param>
        /// <returns>Returns new instance of the <see cref="ReportEditView"/> class.</returns>
        /// <response code="201">Returns the newly created item</response>
        /// <response code="400">If the item is invalid</response>
        [HttpPost("parse-columns")]
        [HasPermission(Permission.AdminReportCanUpdate)]
        [ProducesResponseType(typeof(IEnumerable<string>), 200)]
        [ProducesResponseType(typeof(ValidationProblemDetails), 400)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> GetColumns([FromBody, Required] ReportEditView item)
        {
            if (item == null)
            {
                return this.BadRequest("Invalid item.");
            }

            await this.ValidateQuery(item);

            if (!ModelState.IsValid)
            {
                return this.BadRequest(ModelState);
            }
            return this.Ok(await this.ParseColumns(item));
        }

        /// <summary>
        /// Deletes an existing report.
        /// </summary>
        /// <param name="id">The report identifier.</param>
        /// <returns>Returns No Content if successful.</returns>
        /// <response code="204">If item was deleted</response>
        /// <response code="404">If item was not found</response>
        [HttpDelete("{id:guidurl}")]
        [HasPermission(Permission.AdminReportCanDelete)]
        [ProducesResponseType(204)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> Delete(Guid id)
        {
            var item = await this.GetEntityItemAsync(id);

            if (item == null)
            {
                return this.NotFound();
            }

            try
            {
                this._dbContext.Remove(item);

                await this._dbContext.SaveChangesAsync();

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
                    when sqlException.Message.Contains("IX_Report_Unique", StringComparison.OrdinalIgnoreCase)
                    && new int[] { 2601, 2627 }.Contains(sqlException.Number):
                    return this.BadRequest("Report already exists.");

                default:
                    break;
            }
            return base.HandleDbUpdateException(exp);
        }

        private Task<Report> GetEntityItemAsync(Guid id)
        {
            return this._dbContext.Reports
                .Include(m => m.ReportColumns)
                .Include(m => m.ReportParameters)
                .Include(m => m.ChartTypes)
                .Include(m => m.Roles)
                    .ThenInclude(m => m.Role)
                .Include(m => m.ReportType)
                .Where(m => m.ReportId == id)
                .FirstOrDefaultAsync();
        }

        private async Task ValidateQuery(ReportEditView item)
        {
            if (item.IgnoreQueryValidation)
            {
                return;
            }

            using (var command = this._dbContext.Database.GetDbConnection().CreateCommand())
            {
                foreach (var parameter in item.Parameters.Where(m => m.ParameterDataType == ReportParameterDataType.SqlList && m.CustomData != null))
                {
                    command.CommandText = $"SET FMTONLY ON;{parameter.CustomData} OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;SET FMTONLY OFF;";
                    try
                    {
                        this._dbContext.Database.OpenConnection();
                        using var reader = await command.ExecuteReaderAsync();
                        if (reader.FieldCount < 2)
                        {
                            ModelState.AddModelError("Parameters", $"Parameter '{parameter.Name}' custom query returns less than 2 columns.");
                        }
                    }
                    catch (SqlException exp)
                    {
                        ModelState.AddModelError("Parameters", $"Parameter '{parameter.Name}' has an error: {exp.Message}");
                    }
                    finally
                    {
                        this._dbContext.Database.CloseConnection();
                    }
                }
            }

            if (item.IgnoreTotalRowsColumn)
            {
                return;
            }

            using (var command = this._dbContext.Database.GetDbConnection().CreateCommand())
            {
                //  Add empty parameters for test
                foreach (var parameter in item.Parameters)
                {
                    var param = command.CreateParameter();
                    param.ParameterName = parameter.Name;
                    param.Value = DBNull.Value;

                    switch (parameter.ParameterDataType)
                    {
                        case ReportParameterDataType.Number:
                            param.DbType = System.Data.DbType.Decimal;
                            break;

                        case ReportParameterDataType.Regex:
                            break;

                        case ReportParameterDataType.TypesList:
                            param.DbType = System.Data.DbType.Guid;
                            break;

                        case ReportParameterDataType.Date:
                            param.DbType = System.Data.DbType.DateTime;
                            break;

                        case ReportParameterDataType.SqlList:
                            param.DbType = System.Data.DbType.Object;
                            break;
                        //case ReportParameterDataType.List:
                        //    param.DbType = System.Data.DbType.String;
                        //    break;
                        case ReportParameterDataType.Text:
                        default:
                            param.DbType = System.Data.DbType.String;
                            break;
                    }
                    command.Parameters.Add(param);
                }

                try
                {
                    await this._dbContext.Database.OpenConnectionAsync();

                    await this._dbContext.Database.ExecuteSqlRawAsync("SET FMTONLY ON");
                    try
                    {
                        command.CommandText = $"{item.QueryText} ORDER BY {(string.IsNullOrWhiteSpace(item.DefaultSort) ? "1" : item.DefaultSort)} OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;";

                        using var reader = await command.ExecuteReaderAsync();
                        var duplicateColumns = Enumerable.Range(0, reader.FieldCount).GroupBy(i => reader.GetName(i)).Where(g => g.Count() > 1).Select(m => m.Key);
                        foreach (var duplicateColumn in duplicateColumns)
                        {
                            ModelState.AddModelError("QueryText", $"Column '{duplicateColumn}' used more than once.");
                        }
                    }
                    catch (SqlException exp)
                    {
                        ModelState.AddModelError("QueryText", exp.Message);
                        return;
                    }

                    var matches = Regex.Matches(item.QueryText, @"\bFROM\b");
                    foreach (Match match in matches)
                    {
                        command.CommandText = item.QueryText.Insert(match.Index, ", COUNT(*) OVER() __TotalRows ");
                        try
                        {
                            using var r1 = await command.ExecuteReaderAsync();
                            item.QueryContext.TotalRowsOrdinal = Enumerable.Range(0, r1.FieldCount)
                                .Where(m => r1.GetName(m) == "__TotalRows").DefaultIfEmpty(-1).FirstOrDefault();
                            if (item.QueryContext.TotalRowsOrdinal > 0)
                            {
                                break;
                            }
                        }
                        catch (SqlException exp)
                        {
                        }
                    }

                    item.QueryContext.Query = command.CommandText;
                    await this._dbContext.Database.ExecuteSqlRawAsync("SET FMTONLY OFF");
                }
                catch (SqlException exp)
                {
                }
                finally
                {
                    await this._dbContext.Database.CloseConnectionAsync();
                }
            }
        }

        private async Task<IEnumerable<string>> ParseColumns(ReportEditView item)
        {
            using var command = this._dbContext.Database.GetDbConnection().CreateCommand();
            command.CommandText = $"SET FMTONLY ON;{item.QueryText} ORDER BY {(string.IsNullOrWhiteSpace(item.DefaultSort) ? "1" : item.DefaultSort)} OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;SET FMTONLY OFF;";

            //  Add empty parameters for test
            foreach (var parameter in item.Parameters)
            {
                var param = command.CreateParameter();
                param.ParameterName = parameter.Name;
                param.Value = DBNull.Value;
                command.Parameters.Add(param);
            }

            try
            {
                this._dbContext.Database.OpenConnection();
                using var reader = await command.ExecuteReaderAsync();
                return Enumerable.Range(0, reader.FieldCount).Select(m => reader.GetName(m)).ToArray();
            }
            catch (SqlException exp)
            {
                ModelState.AddModelError("QueryText", exp.Message);
                return null;
            }
            finally
            {
                this._dbContext.Database.CloseConnection();
            }
        }
    }
}