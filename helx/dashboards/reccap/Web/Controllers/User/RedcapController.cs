using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Redcap;
using Renci.ReCCAP.Dashboard.Web.Common;
using Renci.ReCCAP.Dashboard.Web.Models.Redcap;
using Renci.ReCCAP.Dashboard.Web.Models.Settings;
using Renci.ReCCAP.Dashboard.Web.ViewModels.User.Redcap;
using System;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Text.Json;
using System.Threading.Tasks;

namespace Renci.ReCCAP.Dashboard.Web.Controllers.User
{
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/redcap")]
    [Produces("application/json")]
    [AllowAnonymous]
    [ProducesResponseType(401)]
    [ProducesResponseType(403)]
    [ProducesResponseType(typeof(ProblemDetails), 500)]
    [ApiController]
    public class RedcapController : ApiControllerBase
    {
        private readonly RedcapSettings _redcapSettings;

        public RedcapController(
            IOptions<RedcapSettings> redcapSettings, ILogger<RedcapController> logger)
            : base(logger)
        {
            if (redcapSettings == null)
            {
                throw new NullReferenceException(nameof(redcapSettings));
            }
            _redcapSettings = redcapSettings.Value;
        }

        [HttpGet("all")]
        public async Task<IActionResult> GetAll([FromQuery] RedcapSearchView search)
        {
            var redcap_api = new RedcapApi(this._redcapSettings.ApiUrl);

            var result = await redcap_api.ExportRecordsAsync(
                this._redcapSettings.ApiToken,
                fields: new string[] {
                    "study_id",
                    "compliance_5",
                    "compliance_5a",
                    "mns_01",
                    "mns_result_01",
                    "mns_result_date_01",
                    "tasso_01",
                    "tasso_result_01",
                    "tasso_result_date_01",
                    "gold_cap_01",
                    "gold_cap_result_01",
                    "gold_cap_result_date_01",
                    "gold_cap_result_01b",
                    "gold_cap_result_date_01b",
                    "saliva_01",
                    "saliva_result_01",
                    "saliva_result_date_01",
                    "confirm_result_01",
                    "confirm_loc_01",
                    "mns_02",
                    "mns_result_02",
                    "mns_result_date_02",
                    "tasso_02",
                    "tasso_result_02",
                    "tasso_result_date_02",
                    "saliva_02",
                    "saliva_result_02",
                    "saliva_result_date_02",
                    "complete_study",
                    "withdraw_date",
                    "withdraw_reason"
                }
                );

            var items = JsonSerializer.Deserialize<RedcapEntity[]>(result).AsQueryable();

            var totalCount = items.Count();

            if (string.IsNullOrEmpty(search.Sort) == false)
            {
                items = items.OrderBy(search.Sort);
            }
            items = items.Skip((search.Page - 1) * search.PageSize).Take(search.PageSize);

            return Ok(new
            {
                TotalItems = totalCount,
                Data = items.ToList()
            });
        }
    }
}