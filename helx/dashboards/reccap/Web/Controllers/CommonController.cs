using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Renci.ReCCAP.Dashboard.Web.Common;
using Renci.ReCCAP.Dashboard.Web.Models.Enums;
using Renci.ReCCAP.Dashboard.Web.ViewModels;
using System;
using System.ComponentModel;
using System.Linq;
using System.Reflection;
using System.Threading.Tasks;

namespace Renci.ReCCAP.Dashboard.Web.Controllers
{
    /// <summary>
    /// Class that provides common functionality with different requests used in multiple places in application
    /// </summary>
    /// <seealso cref="Renci.Dashboard.Web.Common.ApiControllerBase" />
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/common")]
    [Produces("application/json")]
    [Authorize]
    [ProducesResponseType(401)]
    [ProducesResponseType(403)]
    [ProducesResponseType(typeof(ProblemDetails), 500)]
    [ApiController]
    public class CommonController : ApiControllerBase
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="CommonController" /> class.
        /// </summary>
        /// <param name="dbContext">The database context.</param>
        /// <param name="configuration">The configuration.</param>
        /// <param name="logger">The logger.</param>
        public CommonController(ILogger<CommonController> logger)
            : base(logger)
        {
        }

        /// <summary>
        /// Gets navigation menu for the user.
        /// </summary>
        /// <returns></returns>
        [HttpGet("menu")]
        [AllowAnonymous]
        [ProducesResponseType(200)]
        public async Task<IActionResult> GetMenu()
        {
            var enumType = typeof(CategoryName);

            var categories = enumType.GetFields()
                                    .Where(m => m.IsSpecialName == false && m.Name != nameof(CategoryName.None))
                                    .Select(m => new { Description = m.GetCustomAttribute<DescriptionAttribute>()?.Description ?? m.Name, m.Name })
                                    .OrderBy(m => m.Description);
            return Ok(new
            {
                Categories = categories.Select(m => new CommonInfo<string>(m.Name, m.Description)).ToList(),
            });
        }

        /// <summary>
        /// Gets list of enum values specified by parameter.
        /// </summary>
        /// <param name="name">The enum name.</param>
        /// <returns>
        /// List of enum values specified by <paramref name="name" />.
        /// </returns>
        /// <response code="200">If items was successfully returned</response>
        [HttpGet("enums/{name}")]
        [ProducesResponseType(200)]
        [ResponseCache(Duration = 600)]
        public async Task<IActionResult> GetEnumValues(string name)
        {
            var enumType = System.Type.GetType($"Renci.ReCCAP.Dashboard.Web.Models.Enums.{name}");
            var obj = Activator.CreateInstance(enumType);

            var values = enumType.GetFields()
                .Where(m => m.IsSpecialName == false)
                .Select(m => new CommonInfo<int>((int)m.GetValue(obj),
                m.GetCustomAttribute<DescriptionAttribute>()?.Description ?? m.Name,
                m.Name))
                .OrderBy(m => m.Text);
            return Ok(await Task.FromResult(values));
        }
    }
}