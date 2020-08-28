using Microsoft.ApplicationInsights;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Abstractions;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.AspNetCore.Mvc.Razor;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.AspNetCore.Mvc.ViewEngines;
using Microsoft.AspNetCore.Mvc.ViewFeatures;
using Microsoft.AspNetCore.Routing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System;
using System.ComponentModel.DataAnnotations;
using System.IO;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Threading.Tasks;

namespace Renci.ReCCAP.Dashboard.Web.Common
{
    /// <summary>
    /// Base class for WebApi controllers
    /// </summary>
    /// <seealso cref="Microsoft.AspNetCore.Mvc.ControllerBase" />
    public class ApiControllerBase : ControllerBase
    {
        /// <summary>
        /// Gets the logger.
        /// </summary>
        /// <value>
        /// The logger.
        /// </value>
        public ILogger Logger { get; }

        /// <summary>
        /// Initializes a new instance of the <see cref="ApiControllerBase" /> class.
        /// </summary>
        /// <param name="logger">The logger.</param>
        /// <param name="ai">The ai.</param>
        protected ApiControllerBase(ILogger logger)
        {
            this.Logger = logger;
        }

        /// <summary>
        /// Gets the record deleted result.
        /// </summary>
        /// <value>
        /// The record deleted result.
        /// </value>
        protected virtual IActionResult RecordDeletedResult
        {
            get
            {
                return Conflict(new ProblemDetails()
                {
                    Title = "Record was not updated because it has been deleted by another user.",
                    Status = (int)HttpStatusCode.BadRequest,
                    Instance = $"urn:renci:error:conflict",
                });
            }
        }

        /// <summary>
        /// Handles the database update exception.
        /// </summary>
        /// <param name="exp">The exp.</param>
        /// <returns></returns>
        protected virtual IActionResult HandleDbUpdateException(DbUpdateException exp)
        {
            if (exp == null)
                throw new ArgumentNullException(nameof(exp));

            var errorId = Guid.NewGuid();

            var ai = this.HttpContext.RequestServices.GetService<TelemetryClient>();
            ai?.TrackException(exp.GetBaseException());

            this.Logger.LogError(exp.GetBaseException(), $"Database update error occured ({errorId})");

            var validationProblem = new ProblemDetails()
            {
                Title = "Database update error occured",
                Status = (int)HttpStatusCode.BadRequest,
                Instance = $"urn:renci:error:{errorId}"
            };
#if DEBUG
            validationProblem.Detail = exp.GetBaseException().Message;
#else
            validationProblem.Detail = "Application error occurred. Please contact your system administrator.";
#endif
            return this.BadRequest(validationProblem);
        }

        /// <summary>
        /// Handles the validation exception.
        /// </summary>
        /// <param name="exp">The exp.</param>
        /// <returns></returns>
        protected IActionResult HandleValidationException(ValidationException exp)
        {
            if (exp == null)
                throw new ArgumentNullException(nameof(exp));

            var errorId = Guid.NewGuid();
            var ai = this.HttpContext.RequestServices.GetService<TelemetryClient>();
            ai?.TrackException(exp.GetBaseException());

            this.Logger.LogError(exp.GetBaseException(), $"Validation error occured ({errorId})");

            var validationProblem = new ValidationProblemDetails()
            {
                Title = "Validation error occured",
                Status = (int)HttpStatusCode.BadRequest,
                Instance = $"urn:renci:error:{errorId}",
                Detail = exp.ValidationResult.ErrorMessage,
                Errors =
                        {
                            { "", exp.ValidationResult.MemberNames.ToArray() },
                        }
            };

            return this.BadRequest(validationProblem);
        }

        /// <summary>
        /// Handles the update concurrency exception asynchronous.
        /// </summary>
        /// <param name="exp">The exp.</param>
        /// <returns></returns>
        protected async Task<IActionResult> HandleUpdateConcurrencyExceptionAsync(DbUpdateConcurrencyException exp)
        {
            if (exp == null)
                throw new ArgumentNullException(nameof(exp));

            var errorId = Guid.NewGuid();

            var ai = this.HttpContext.RequestServices.GetService<TelemetryClient>();
            ai?.TrackException(exp.GetBaseException());

            this.Logger.LogError(exp.GetBaseException(), "Concurrency Exception");

            var entry = exp.Entries.Single();
            var databaseEntry = await entry.GetDatabaseValuesAsync();
            if (databaseEntry == null)
            {
                return Conflict(new ProblemDetails()
                {
                    Title = "Record was not updated because it has been deleted by another user.",
                    Status = (int)HttpStatusCode.BadRequest,
                    Instance = $"urn:renci:error:{errorId}",
                });
            }
            else
            {
                return Conflict(new ProblemDetails()
                {
                    Title = "The record you attempted to edit was modified by another user after you got the original value. The edit operation was canceled. If you still want to edit this record, please refresh record with new values from the database.",
                    Status = (int)HttpStatusCode.BadRequest,
                    Instance = $"urn:renci:error:{errorId}",
                });
            }
        }

        /// <summary>
        /// Creates an <see cref="Microsoft.AspNetCore.Mvc.BadRequestObjectResult" /> that produces a Bad Request (400) response.
        /// </summary>
        /// <param name="modelState"></param>
        /// <returns>
        /// The created <see cref="Microsoft.AspNetCore.Mvc.BadRequestObjectResult" /> for the response.
        /// </returns>
        /// <exception cref="System.ArgumentNullException">modelState</exception>
        [NonAction]
        public override BadRequestObjectResult BadRequest(ModelStateDictionary modelState)
        {
            return new BadRequestObjectResult(new ValidationProblemDetails(modelState));
        }

        /// <summary>
        /// Bads the request.
        /// </summary>
        /// <param name="identityResult">The identity result.</param>
        /// <returns></returns>
        [NonAction]
        public virtual BadRequestObjectResult BadRequest(IdentityResult identityResult)
        {
            if (identityResult == null)
            {
                throw new ArgumentNullException(nameof(identityResult));
            }

            return new BadRequestObjectResult(new ValidationProblemDetails(identityResult.Errors
                .GroupBy(g => g.Code)
                .ToDictionary(m => m.Key, e => e.Select(l => l.Description).ToArray())));
        }

        /// <summary>
        /// Bads the request.
        /// </summary>
        /// <param name="errorMessage">The error message.</param>
        /// <returns></returns>
        /// <exception cref="System.ArgumentNullException">errorMessage</exception>
        [NonAction]
        public virtual BadRequestObjectResult BadRequest(string errorMessage)
        {
            return this.BadRequest(new ValidationProblemDetails()
            {
                Title = errorMessage,
                Instance = $"urn:renci:error:{Guid.NewGuid()}",
            });
        }

        #region Helper Functions

        /// <summary>
        /// Loads the template.
        /// </summary>
        /// <param name="templateName">Name of the template.</param>
        /// <returns></returns>
        protected static string LoadTemplate(string templateName)
        {
            var assembly = typeof(ApiControllerBase).GetTypeInfo().Assembly;
            var resourceName = $"Renci.ReCCAP.Dashboard.Web.Templates.{templateName}.html";

            using var stream = assembly.GetManifestResourceStream(resourceName);
            using var reader = new StreamReader(stream);
            return reader.ReadToEnd();
        }

        protected async Task<string> RenderViewToStringAsync<TModel>(string folder, string viewName, TModel model)
        {
            var tempDataProvider = this.HttpContext.RequestServices.GetRequiredService<ITempDataProvider>();

            var actionContext = GetActionContext(folder);
            var view = FindView(actionContext, viewName);

            using var output = new StringWriter();
            var viewContext = new ViewContext(
                actionContext,
                view,
                new ViewDataDictionary<TModel>(
                    metadataProvider: new EmptyModelMetadataProvider(),
                    modelState: new ModelStateDictionary())
                {
                    Model = model
                },
                new TempDataDictionary(
                    actionContext.HttpContext,
                    tempDataProvider),
                output,
                new HtmlHelperOptions());

            await view.RenderAsync(viewContext);

            return output.ToString();
        }

        private IView FindView(ActionContext actionContext, string viewName)
        {
            var viewEngine = this.HttpContext.RequestServices.GetRequiredService<IRazorViewEngine>();

            var getViewResult = viewEngine.GetView(executingFilePath: null, viewPath: viewName, isMainPage: true);
            if (getViewResult.Success)
            {
                return getViewResult.View;
            }

            var findViewResult = viewEngine.FindView(actionContext, viewName, isMainPage: true);
            if (findViewResult.Success)
            {
                return findViewResult.View;
            }

            var searchedLocations = getViewResult.SearchedLocations.Concat(findViewResult.SearchedLocations);
            var errorMessage = string.Join(
                Environment.NewLine,
                new[] { $"Unable to find view '{viewName}'. The following locations were searched:" }.Concat(searchedLocations)); ;

            throw new InvalidOperationException(errorMessage);
        }

        private ActionContext GetActionContext(string name)
        {
            var httpContext = new DefaultHttpContext()
            {
                RequestServices = this.HttpContext.RequestServices
            };
            var routeData = new RouteData();
            routeData.Values.Add("controller", name);
            return new ActionContext(httpContext, routeData, new ActionDescriptor());
        }

        #endregion Helper Functions
    }
}