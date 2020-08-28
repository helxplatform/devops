using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Renci.ReCCAP.Dashboard.Web.Common;
using Renci.ReCCAP.Dashboard.Web.Common.Attributes;
using Renci.ReCCAP.Dashboard.Web.Common.Security;
using Renci.ReCCAP.Dashboard.Web.Data;
using Renci.ReCCAP.Dashboard.Web.Models.Enums;
using Renci.ReCCAP.Dashboard.Web.ViewModels;
using Renci.ReCCAP.Dashboard.Web.ViewModels.User;
using SmartFormat;
using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Text;
using System.Threading.Tasks;

namespace Renci.ReCCAP.Dashboard.Web.Controllers.User
{
    /// <summary>
    /// Class that provides administrative functionality to manage reports
    /// </summary>
    /// <seealso cref="Renci.Dashboard.Web.Common.ApiControllerBase" />
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/user/reports/{typeName}")]
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
        /// <param name="typeName">Name of the type.</param>
        /// <param name="search">The search.</param>
        /// <returns>
        /// List of items specified by search parameter.
        /// </returns>
        /// <response code="200">If items was successfully returned</response>
        [HttpGet]
        [HasPermission(Permission.ReportCanList)]
        [ProducesResponseType(typeof(ObjectResultView<ReportItemView>), 200)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> List(string typeName, [FromQuery] ReportSearchView search)
        {
            if (search == null)
                throw new ArgumentNullException(nameof(search));

            var items = this._dbContext.ReportQueryItems
                .Where(m => m.ReportTypeNameSEO == typeName)
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

            var titleName = this._dbContext.Types.Where(m => m.Category == CategoryName.ReportType && m.NameSEO == typeName).Select(m => m.Name).FirstOrDefault();
            if (string.IsNullOrEmpty(titleName))
            {
                return NotFound();
            }

            return this.Ok(await ObjectResultView<ReportQueryItem>.CreateAsync(items, m => new ReportItemView(m), (search.Page - 1) * search.PageSize, search.PageSize, titleName));
        }

        /// <summary>
        /// Gets report read only view
        /// </summary>
        /// <param name="typeName">Name of the type.</param>
        /// <param name="id">The identifier.</param>
        /// <returns>
        /// Returns instance of the <see cref="ReportExecuteView" /> class specified by identifier.
        /// </returns>
        /// <response code="200">If item was successfully returned</response>
        [HttpGet("{id:guidurl}")]
        [HasPermission(Permission.ReportCanRead)]
        [ProducesResponseType(typeof(ReportExecuteView), 200)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> GetExecuteView(string typeName, Guid id)
        {
            var item = await this.GetEntityItemAsync(typeName, id);

            if (item == null)
            {
                return NotFound();
            }
            return Ok(new ReportExecuteView(item));
        }

        /// <summary>
        /// Gets report read only view
        /// </summary>
        /// <param name="typeName">Name of the type.</param>
        /// <param name="seoName">Name of the seo.</param>
        /// <returns>
        /// Returns instance of the <see cref="ReportExecuteView" /> class specified by identifier.
        /// </returns>
        /// <response code="200">If item was successfully returned</response>
        [HttpGet("{seoName}")]
        [HasPermission(Permission.ReportCanRead)]
        [ProducesResponseType(typeof(ReportExecuteView), 200)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> GetExecuteView(string typeName, string seoName)
        {
            var item = await this.GetEntityItemAsync(typeName, seoName);

            if (item == null)
            {
                return NotFound();
            }
            return Ok(new ReportExecuteView(item));
        }

        /// <summary>
        /// Gets report data.
        /// </summary>
        /// <param name="typeName">Report type.</param>
        /// <param name="id">Report identifier.</param>
        /// <param name="search">The search parameters for query.</param>
        /// <returns>
        /// Returns data generate by report
        /// </returns>
        /// <response code="200">If item was successfully returned</response>
        /// <response code="404">If item was not found</response>
        [HttpGet("execute/{id:guidurl}")]
        [HasPermission(Permission.ReportCanExecute)]
        [ProducesResponseType(typeof(Array), 200)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> Execute(string typeName, Guid id, [FromQuery] ReportQueryParams search)
        {
            if (search == null)
                throw new ArgumentNullException(nameof(search));

            var item = await this.GetEntityItemAsync(typeName, id);

            if (item == null)
            {
                return NotFound();
            }

            return await this.ExecuteInternal(item, search);
        }

        /// <summary>
        /// Gets report data.
        /// </summary>
        /// <param name="typeName">Report type.</param>
        /// <param name="seoName">Name of the seo.</param>
        /// <param name="search">The search parameters for query.</param>
        /// <returns>
        /// Returns data generate by report
        /// </returns>
        /// <response code="200">If item was successfully returned</response>
        /// <response code="404">If item was not found</response>
        [HttpGet("execute/{seoName}")]
        [HasPermission(Permission.ReportCanExecute)]
        [ProducesResponseType(typeof(Array), 200)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> Execute(string typeName, string seoName, [FromQuery] ReportQueryParams search)
        {
            if (search == null)
                throw new ArgumentNullException(nameof(search));

            var item = await this.GetEntityItemAsync(typeName, seoName);

            if (item == null)
            {
                return NotFound();
            }

            return await this.ExecuteInternal(item, search);
        }

        /// <summary>
        /// Gets report data as a file.
        /// </summary>
        /// <param name="typeName">Report type.</param>
        /// <param name="id">Report identifier.</param>
        /// <param name="type">The type of file to download.</param>
        /// <param name="search">The search parameters for query.</param>
        /// <returns>
        /// Returns data generate by report
        /// </returns>
        /// <response code="200">If item was successfully returned</response>
        /// <response code="404">If item was not found</response>
        [HttpGet("download/{type:alpha}/{id:guidurl}")]
        [HasPermission(Permission.ReportCanExecute)]
        [ProducesResponseType(typeof(string), 200)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> Download(string typeName, Guid id, string type, [FromQuery] ReportQueryParams search)
        {
            if (search == null)
                throw new ArgumentNullException(nameof(search));

            if (type == null)
                throw new ArgumentNullException(nameof(type));

            var item = await this.GetEntityItemAsync(typeName, id);

            if (item == null)
            {
                return NotFound();
            }

            return type.ToUpperInvariant() switch
            {
                "CSV" => await this.DownloadCsvInternal(item, search),
                _ => NotFound()
            };
        }

        /// <summary>
        /// Gets report data as a file.
        /// </summary>
        /// <param name="typeName">Report type.</param>
        /// <param name="seoName">Name of the seo.</param>
        /// <param name="type">The type of file to download.</param>
        /// <param name="search">The search parameters for query.</param>
        /// <returns>
        /// Returns data generate by report
        /// </returns>
        /// <response code="200">If item was successfully returned</response>
        /// <response code="404">If item was not found</response>
        [HttpGet("download/{type:alpha}/{seoName}")]
        [HasPermission(Permission.ReportCanExecute)]
        [ProducesResponseType(typeof(string), 200)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> Download(string typeName, string seoName, string type, [FromQuery] ReportQueryParams search)
        {
            if (search == null)
                throw new ArgumentNullException(nameof(search));

            if (type == null)
                throw new ArgumentNullException(nameof(type));

            var item = await this.GetEntityItemAsync(typeName, seoName);

            if (item == null)
            {
                return NotFound();
            }

            return type.ToUpperInvariant() switch
            {
                "CSV" => await this.DownloadCsvInternal(item, search),
                _ => NotFound()
            };
        }

        /// <summary>
        /// Gets chart data.
        /// </summary>
        /// <param name="typeName">Report type.</param>
        /// <param name="id">Report identifier.</param>
        /// <returns>
        /// Returns data generate for chart
        /// </returns>
        /// <response code="200">If item was successfully returned</response>
        /// <response code="404">If item was not found</response>
        [HttpGet("{id:guidurl}/chart")]
        //[HasPermission(Permissions.ReportCanExecute)]
        [ProducesResponseType(typeof(string), 200)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> ChartData(string typeName, Guid id)
        {
            var item = await this.GetEntityItemAsync(typeName, id);

            if (item == null)
            {
                return NotFound();
            }

            return await this.ChartInternal(item);
        }

        /// <summary>
        /// Gets chart data.
        /// </summary>
        /// <param name="typeName">Report type.</param>
        /// <param name="seoName">Name of the seo.</param>
        /// <returns>
        /// Returns data generate for chart
        /// </returns>
        /// <response code="200">If item was successfully returned</response>
        /// <response code="404">If item was not found</response>
        [HttpGet("{seoName}/chart")]
        //[HasPermission(Permissions.ReportCanExecute)]
        [ProducesResponseType(typeof(string), 200)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> ChartData(string typeName, string seoName)
        {
            var item = await this.GetEntityItemAsync(typeName, seoName);

            if (item == null)
            {
                return NotFound();
            }

            return await this.ChartInternal(item);
        }

        /// <summary>
        /// Parameters the data.
        /// </summary>
        /// <param name="typeName">Name of the type.</param>
        /// <param name="seoName">Name of the seo.</param>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        [HttpGet("{seoName}/parameters/{name}")]
        [HasPermission(Permission.ReportCanExecute)]
        [ProducesResponseType(typeof(ObjectResultView<ReportItemView>), 200)]
        public async Task<IActionResult> ParameterData(string typeName, string seoName, string name)
        {
            var parameter = await (from r in this.GetUserReports(typeName)
                                   from p in r.ReportParameters
                                   where r.NameSEO == seoName
                                   && p.Name == name
                                   && p.ParameterDataType == ReportParameterDataType.SqlList
                                   && p.CustomData != null
                                   select p).FirstOrDefaultAsync();

            var result = new List<object>();

            if (parameter != null)
            {
                using var command = this._dbContext.Database.GetDbConnection().CreateCommand();
                command.CommandText = parameter.CustomData;

                try
                {
                    this._dbContext.Database.OpenConnection();
                    using var reader = await command.ExecuteReaderAsync();
                    if (reader.FieldCount > 1)
                    {
                        while (await reader.ReadAsync())
                        {
                            result.Add(
                                new
                                {
                                    id = reader.GetValue(0),
                                    text = reader.GetValue(1),
                                });
                        }
                    }
                    else
                    {
                        result.Add(new
                        {
                            text = "Invalid query"
                        });
                    }
                }
                finally
                {
                    this._dbContext.Database.CloseConnection();
                }
            }
            else
            {
                result.Add(new
                {
                    text = "Parameter dataa not found"
                });
            }

            return new JsonResult(result);
        }

        private async Task<IActionResult> ExecuteInternal(Report item, [FromQuery] ReportQueryParams search)
        {
            var queryParameters = QueryHelpers.ParseQuery(this.Request.QueryString.Value);

            //  Make sure all required parameters are supplied
            var requiredParameterNames = from rp in item.ReportParameters
                                         join qp in queryParameters on rp.Name equals qp.Key into ps
                                         from p in ps.DefaultIfEmpty()
                                         where rp.IsRequired == true && rp.IsHidden == false
                                         && p.Key is null
                                         select rp;

            foreach (var reportParameter in requiredParameterNames)
            {
                ModelState.AddModelError(reportParameter.Name, $"{(string.IsNullOrWhiteSpace(reportParameter.DisplayName) ? reportParameter.Name : reportParameter.DisplayName)} is required.");
            }

            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var columns = from column in item.ReportColumns
                          where
                          column.CanView == true || column.CanDownload == true
                          orderby column.OrderSequence, column.Name
                          select column;
            var data = new List<Dictionary<string, object>>();

            using var command = this._dbContext.Database.GetDbConnection().CreateCommand();
            this.AddParameters(command, item.ReportParameters, queryParameters);

            //  Update sorting column if need to be replaced
            var columnName = item.ReportColumns.Where(m => m.Name == search.Sort && m.SortName.Length > 0).Select(m => m.SortName).FirstOrDefault() ?? search.Sort ?? item.DefaultSort ?? "1";

            var sortDirection = "desc".Equals(search.Direction) ? "DESC" : "ASC";

            var orderBy = $"ORDER BY {columnName} {sortDirection}";

            var sql = $"{item.QueryContext?.Query ?? item.QueryText} {orderBy}";

            if (search.PageSize != 0)
            {
                var param = command.CreateParameter();
                param.ParameterName = "Skip";
                param.Value = search.PageSize * (search.Page - 1);
                command.Parameters.Add(param);

                param = command.CreateParameter();
                param.ParameterName = "Take";
                param.Value = search.PageSize;
                command.Parameters.Add(param);

                sql = $"{sql} OFFSET (@Skip) ROWS FETCH NEXT (@Take) ROWS ONLY";
            }

            command.CommandText = sql;

            try
            {
                this._dbContext.Database.OpenConnection();

                using var reader = await command.ExecuteReaderAsync();
                long? totalRows = null;

                while (await reader.ReadAsync())
                {
                    var rowValues = Enumerable.Range(0, reader.FieldCount)
                        .ToDictionary(i => reader.GetName(i), i => reader.IsDBNull(i) ? null : reader.GetValue(i));

                    if (item.QueryContext?.Query != null)
                    {
                        totalRows = reader.GetInt32(item.QueryContext.TotalRowsOrdinal);
                    }

                    var values = from column in columns
                                 from rowColumn in rowValues.Where(m => m.Key == column.Name).DefaultIfEmpty()
                                 select new
                                 {
                                     column.Name,
                                     Value = (string.IsNullOrWhiteSpace(column.DisplayValue)) ? rowColumn.Value : Smart.Format(column.DisplayValue, rowValues)
                                 };
                    data.Add(values.ToDictionary(m => m.Name, m => m.Value));
                }

                return new JsonResult(new
                {
                    totalItems = totalRows,
                    data,
                });
            }
            finally
            {
                this._dbContext.Database.CloseConnection();
            }
        }

        private async Task<IActionResult> ChartInternal(Report item)
        {
            var queryParameters = QueryHelpers.ParseQuery(this.Request.QueryString.Value);

            //  Make sure all required parameters are supplied
            var requiredParameterNames = from rp in item.ReportParameters
                                         join qp in queryParameters on rp.Name equals qp.Key into ps
                                         from p in ps.DefaultIfEmpty()
                                         where rp.IsRequired == true && rp.IsHidden == false
                                         && p.Key is null
                                         select rp;

            foreach (var reportParameter in requiredParameterNames)
            {
                ModelState.AddModelError(reportParameter.Name, $"{(string.IsNullOrWhiteSpace(reportParameter.DisplayName) ? reportParameter.Name : reportParameter.DisplayName)} is required.");
            }

            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var columns = from column in item.ReportColumns
                          where
                          column.CanView == true || column.CanDownload == true
                          orderby column.OrderSequence, column.Name
                          select column;

            var chart = new Dictionary<string, List<object>>();

            using var command = this._dbContext.Database.GetDbConnection().CreateCommand();
            this.AddParameters(command, item.ReportParameters, queryParameters);

            //  Update sorting column if need to be replaced
            var columnName = item.DefaultSort ?? "1";

            var orderBy = $"ORDER BY {columnName} ASC";

            var sql = $"{item.QueryContext?.Query ?? item.QueryText} {orderBy}";

            command.CommandText = sql;

            try
            {
                this._dbContext.Database.OpenConnection();
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    var rowValues = Enumerable.Range(0, reader.FieldCount)
                        .ToDictionary(i => reader.GetName(i), i => reader.IsDBNull(i) ? null : reader.GetValue(i));

                    var values = from column in columns
                                 from rowColumn in rowValues.Where(m => m.Key == column.Name).DefaultIfEmpty()
                                 select new
                                 {
                                     column.Name,
                                     Value = (string.IsNullOrWhiteSpace(column.DisplayValue)) ? rowColumn.Value : Smart.Format(column.DisplayValue, rowValues)
                                 };
                    foreach (var value in values)
                    {
                        if (!chart.ContainsKey(value.Name))
                        {
                            chart.Add(value.Name, new List<object>());
                        }
                        chart[value.Name].Add(value.Value);
                    }
                }
            }
            finally
            {
                this._dbContext.Database.CloseConnection();
            }

            return new JsonResult(chart);
        }

        private async Task<IActionResult> DownloadCsvInternal(Report item, [FromQuery] ReportQueryParams search)
        {
            var queryParameters = QueryHelpers.ParseQuery(this.Request.QueryString.Value);

            //  Make sure all required parameters are supplied
            var requiredParameterNames = from rp in item.ReportParameters
                                         join qp in queryParameters on rp.Name equals qp.Key into ps
                                         from p in ps.DefaultIfEmpty()
                                         where rp.IsRequired == true
                                         && p.Key is null
                                         select rp;

            foreach (var reportParameter in requiredParameterNames)
            {
                ModelState.AddModelError(reportParameter.Name, $"{(string.IsNullOrWhiteSpace(reportParameter.DisplayName) ? reportParameter.Name : reportParameter.DisplayName)} is required.");
            }

            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var columns = from column in item.ReportColumns
                          where
                          column.CanDownload == true
                          orderby column.OrderSequence, column.Name
                          select column;
            var data = new List<IEnumerable<object>>();

            using var command = this._dbContext.Database.GetDbConnection().CreateCommand();
            this.AddParameters(command, item.ReportParameters, queryParameters);

            //  Update sorting column if need to be replaced
            var columnName = item.ReportColumns.Where(m => m.Name == search.Sort && m.SortName.Length > 0).Select(m => m.SortName).FirstOrDefault() ?? search.Sort ?? item.DefaultSort ?? "1";

            var sortDirection = "desc".Equals(search.Direction) ? "DESC" : "ASC";

            var orderBy = $"ORDER BY {columnName} {sortDirection}";

            var sql = $"{item.QueryContext?.Query ?? item.QueryText} {orderBy}";

            command.CommandText = sql;

            try
            {
                this._dbContext.Database.OpenConnection();

                using var reader = await command.ExecuteReaderAsync();
                var order = (from c in columns orderby c.OrderSequence, c.Name select reader.GetOrdinal(c.Name)).ToList();

                while (await reader.ReadAsync())
                {
                    data.Add((from o in order select reader.GetValue(o)).ToArray());
                }
            }
            finally
            {
                this._dbContext.Database.CloseConnection();
            }
            return CsvFile(columns, data, $"{item.NameSEO}.csv");
        }

        private IActionResult CsvFile(IOrderedEnumerable<ReportColumn> columns, List<IEnumerable<object>> data, string fileName)
        {
            var separator = ",";
            var quoted = "\"";
            var sb = new StringBuilder();

            var header = string.Join(separator,
                columns
                .Select(m => string.IsNullOrWhiteSpace(m.DisplayName) ? m.Name : m.DisplayName)
                .Select(m => $"{quoted}{m}{quoted}")
                );
            sb.AppendLine(header);

            foreach (var row in data)
            {
                var rowData = row.Select(i =>
                {
                    switch (System.Type.GetTypeCode(i.GetType()))
                    {
                        case TypeCode.Boolean:
                            return $"{quoted}{i}{quoted}";

                        case TypeCode.DateTime:
                            return $"{quoted}{i:yyyy-MM-dd HH:mm:ss}{quoted}";

                        case TypeCode.DBNull:
                            return $"";

                        case TypeCode.Empty:
                            return $"{quoted}{quoted}";

                        case TypeCode.Object:
                            return $"{quoted}{i}{quoted}";

                        case TypeCode.Byte:
                        case TypeCode.Decimal:
                        case TypeCode.Double:
                        case TypeCode.SByte:
                        case TypeCode.Single:
                        case TypeCode.Int16:
                        case TypeCode.Int32:
                        case TypeCode.Int64:
                        case TypeCode.UInt16:
                        case TypeCode.UInt32:
                        case TypeCode.UInt64:
                            return $"{i}";

                        case TypeCode.Char:
                        case TypeCode.String:
                        default:
                            return $"{quoted}{i}{quoted}";
                    }
                }).ToArray();
                sb.AppendLine(string.Join(separator, rowData));
            }

            this.Response.Headers.Clear();
            this.Response.Headers.Add("Cache-Control", "private, no-cache, no-store, must-revalidate, max-stale=0, post-check=0, pre-check=0");
            this.Response.Headers.Add("Pragma", "no-cache");
            this.Response.Headers.Add("Expires", "-1");

            return File(
                Encoding.ASCII.GetBytes(sb.ToString()),
                "text/csv",
                fileName);
        }

        private void AddParameters(DbCommand command, ICollection<ReportParameter> reportParameters, Dictionary<string, Microsoft.Extensions.Primitives.StringValues> queryParameters)
        {
            var parameters = from rp in reportParameters
                             join qp in queryParameters on rp.Name equals qp.Key into ps
                             from p in ps.DefaultIfEmpty()
                             select new
                             {
                                 rp.Name,
                                 DataType = rp.ParameterDataType,
                                 Value = p.Value.FirstOrDefault() ?? rp.DefaultValue
                             };

            //  Add empty parameters for test
            foreach (var parameter in parameters)
            {
                var param = command.CreateParameter();
                param.ParameterName = parameter.Name;
                command.Parameters.Add(param);

                if (parameter.Value == null)
                {
                    param.Value = DBNull.Value;
                    continue;
                }

                switch (parameter.DataType)
                {
                    case ReportParameterDataType.Number:
                        {
                            param.DbType = System.Data.DbType.Decimal;
                            if (Decimal.TryParse(parameter.Value, out var value))
                            {
                                param.Value = value;
                            }
                            else
                            {
                                param.Value = DBNull.Value;
                            }
                        }
                        break;

                    case ReportParameterDataType.Regex:
                        break;

                    case ReportParameterDataType.TypesList:
                        {
                            param.DbType = System.Data.DbType.Guid;
                            var value = parameter.Value.DecodeFromUrlCode();
                            if (value == Guid.Empty)
                            {
                                param.Value = DBNull.Value;
                            }
                            else
                            {
                                param.Value = value;
                            }
                        }
                        break;

                    case ReportParameterDataType.Date:
                        {
                            param.DbType = System.Data.DbType.DateTime;
                            if (DateTime.TryParse(parameter.Value, out var value))
                            {
                                param.Value = value;
                            }
                            else
                            {
                                param.Value = DBNull.Value;
                            }
                        }
                        break;

                    case ReportParameterDataType.UrlList:
                    case ReportParameterDataType.CustomList:
                    case ReportParameterDataType.Text:
                    default:
                        param.DbType = System.Data.DbType.String;
                        param.Size = 1024;
                        if (string.IsNullOrEmpty(parameter.Value))
                        {
                            param.Value = DBNull.Value;
                        }
                        else
                        {
                            param.Value = parameter.Value;
                        }
                        break;
                }
            }
        }

        private Task<Report> GetEntityItemAsync(string typeName, Guid id)
        {
            return this.GetUserReports(typeName)
                .Where(m => m.ReportId == id)
                .FirstOrDefaultAsync();
        }

        private Task<Report> GetEntityItemAsync(string typeName, string seoName)
        {
            return this.GetUserReports(typeName)
                .Where(m => m.NameSEO == seoName)
                .FirstOrDefaultAsync();
        }

        private IQueryable<Report> GetUserReports(string typeName)
        {
            return this._dbContext.Reports
                    .Include(m => m.ReportType)
                    .Include(m => m.ReportParameters)
                    .Include(m => m.ReportColumns)
                    .Include(m => m.ChartTypes)
                    .Where(m => m.ReportType.NameSEO == typeName && m.IsActive == true)
                    .AsQueryable();
        }
    }
}