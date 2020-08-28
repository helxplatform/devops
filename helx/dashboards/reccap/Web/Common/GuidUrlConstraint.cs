using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using System;
using System.Globalization;
using System.Text.RegularExpressions;

namespace Renci.ReCCAP.Dashboard.Web.Common
{
    /// <summary>
    ///
    /// </summary>
    /// <seealso cref="Microsoft.AspNetCore.Routing.IRouteConstraint" />
    public class GuidUrlConstraint : IRouteConstraint
    {
        private static readonly Regex regex = new Regex(@"^_[a-zA-Z0-9_-]{22}$",
                    RegexOptions.CultureInvariant | RegexOptions.IgnoreCase | RegexOptions.Compiled,
                    TimeSpan.FromSeconds(10));

        /// <summary>
        /// Determines whether the URL parameter contains a valid value for this constraint.
        /// </summary>
        /// <param name="httpContext">An object that encapsulates information about the HTTP request.</param>
        /// <param name="route">The router that this constraint belongs to.</param>
        /// <param name="routeKey">The name of the parameter that is being checked.</param>
        /// <param name="values">A dictionary that contains the parameters for the URL.</param>
        /// <param name="routeDirection">An object that indicates whether the constraint check is being performed
        /// when an incoming request is being handled or when a URL is being generated.</param>
        /// <returns>
        ///   <c>true</c> if the URL parameter contains a valid value; otherwise, <c>false</c>.
        /// </returns>
        /// <exception cref="ArgumentNullException">
        /// httpContext
        /// or
        /// route
        /// or
        /// routeKey
        /// or
        /// values
        /// </exception>
        public bool Match(HttpContext httpContext,
            IRouter route,
            string routeKey,
            RouteValueDictionary values,
            RouteDirection routeDirection)
        {
            if (routeKey == null)
                throw new ArgumentNullException(nameof(routeKey));

            if (values == null)
                throw new ArgumentNullException(nameof(values));

            if (values.TryGetValue(routeKey, out var routeValue))
            {
                return regex.IsMatch(Convert.ToString(routeValue, CultureInfo.InvariantCulture));
            }

            return false;
        }
    }
}