using Microsoft.ApplicationInsights;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Logging;
using System;
using System.Net;

namespace Renci.ReCCAP.Dashboard.Web.Common
{
    /// <summary>
    ///
    /// </summary>
    /// <seealso cref="IExceptionFilter" />
    public class ApplicationExceptionFilter : IExceptionFilter
    {
        private readonly TelemetryClient _ai;
        private readonly ILogger<ApplicationExceptionFilter> _logger;

        /// <summary>
        /// Initializes a new instance of the <see cref="ApplicationExceptionFilter" /> class.
        /// </summary>
        /// <param name="logger">The logger.</param>
        /// <param name="ai">The ai.</param>
        public ApplicationExceptionFilter(ILogger<ApplicationExceptionFilter> logger, TelemetryClient ai = null)
        {
            this._logger = logger;
            this._ai = ai;
        }

        /// <summary>
        /// Called after an action has thrown an <see cref="System.Exception" />.
        /// </summary>
        /// <param name="context">The <see cref="Microsoft.AspNetCore.Mvc.Filters.ExceptionContext" />.</param>
        public void OnException(ExceptionContext context)
        {
            if (context == null)
                throw new ArgumentNullException(nameof(context));

            HttpStatusCode status = HttpStatusCode.InternalServerError;
            var message = "An unexpected error occurred!";

            var exceptionType = context.Exception.GetType();
            if (exceptionType == typeof(UnauthorizedAccessException))
            {
                message = "Unauthorized Access";
                status = HttpStatusCode.Unauthorized;
            }
            else if (exceptionType == typeof(NotImplementedException))
            {
                message = "A server error occurred.";
                status = HttpStatusCode.NotImplemented;
            }
            else
            {
                message = context.Exception.Message;
            }

            this._logger.LogError(context.Exception, message);
            this._ai?.TrackException(context.Exception);

            if (context.HttpContext.User.Identity.AuthenticationType == CookieAuthenticationDefaults.AuthenticationScheme)
            {
                //  If requested is not JWT authenticated then let ASP.NET core to handle this error
            }
            else
            {
                context.ExceptionHandled = true;
                context.HttpContext.Response.StatusCode = (int)status;
                context.HttpContext.Response.ContentType = "application/problem+json";
                context.Result = new JsonResult(new ProblemDetails
                {
                    Title = message,
                    Status = (int)status,
#if DEBUG
                    Detail = context.Exception.StackTrace,
#else
                Detail = "Application error occurred. Please contact your system administrator.",
#endif
                    Instance = $"urn:renci:error:{Guid.NewGuid()}"
                });
            }
        }
    }
}