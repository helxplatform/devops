namespace Renci.ReCCAP.Dashboard.Web.Common.Security
{
    using Microsoft.AspNetCore.Authorization;
    using Renci.ReCCAP.Dashboard.Web.Models.Enums;
    using System;
    using System.ComponentModel;
    using System.Globalization;
    using System.Linq;
    using System.Threading.Tasks;

    /// <summary>
    ///
    /// </summary>
    /// <seealso cref="Microsoft.AspNetCore.Authorization.AuthorizationHandler{T}" />
    public class PermissionHandler : AuthorizationHandler<PermissionRequirement>
    {
        /// <summary>
        /// Makes a decision if authorization is allowed based on a specific requirement.
        /// </summary>
        /// <param name="context">The authorization context.</param>
        /// <param name="requirement">The requirement to evaluate.</param>
        /// <returns></returns>
        protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, PermissionRequirement requirement)
        {
            if (context == null)
                throw new ArgumentNullException(nameof(context));

            if (requirement == null)
                throw new ArgumentNullException(nameof(requirement));

            if (context.User.Claims.Where(m => m.Type == PermissionConstants.PackedPermissionClaimType && m.Value == ((int)Permission.Administrator).ToString(CultureInfo.InvariantCulture)).Any())
                context.Succeed(requirement);

            if (!Enum.TryParse<Permission>(requirement.PermissionName, true, out var permissionToCheck))
                throw new InvalidEnumArgumentException($"{requirement.PermissionName} could not be converted to a {nameof(Permission)}.");

            if (context.User.Claims.Where(m => m.Type == PermissionConstants.PackedPermissionClaimType && m.Value == ((int)permissionToCheck).ToString(CultureInfo.InvariantCulture)).Any())
                context.Succeed(requirement);

            return Task.CompletedTask;
        }
    }
}