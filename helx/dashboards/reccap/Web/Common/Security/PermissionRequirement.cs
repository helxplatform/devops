using Microsoft.AspNetCore.Authorization;
using System;

namespace Renci.ReCCAP.Dashboard.Web.Common.Security
{
    /// <summary>
    ///
    /// </summary>
    /// <seealso cref="Microsoft.AspNetCore.Authorization.IAuthorizationRequirement" />
    public class PermissionRequirement : IAuthorizationRequirement
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="PermissionRequirement"/> class.
        /// </summary>
        /// <param name="permissionName">Name of the permission.</param>
        /// <exception cref="ArgumentNullException">permissionName</exception>
        public PermissionRequirement(string permissionName)
        {
            this.PermissionName = permissionName ?? throw new ArgumentNullException(nameof(permissionName));
        }

        /// <summary>
        /// Gets the name of the permission.
        /// </summary>
        /// <value>
        /// The name of the permission.
        /// </value>
        public string PermissionName { get; }
    }
}