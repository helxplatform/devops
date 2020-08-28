using Microsoft.AspNetCore.Authorization;
using Renci.ReCCAP.Dashboard.Web.Models.Enums;
using System;

namespace Renci.ReCCAP.Dashboard.Web.Common.Security
{
    /// <summary>
    ///
    /// </summary>
    /// <seealso cref="Microsoft.AspNetCore.Authorization.AuthorizeAttribute" />
    [AttributeUsage(AttributeTargets.Method | AttributeTargets.Class, Inherited = false)]
    public sealed class HasPermissionAttribute : AuthorizeAttribute
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="HasPermissionAttribute"/> class.
        /// </summary>
        /// <param name="permission">The permission.</param>
        public HasPermissionAttribute(Permission permission)
           : base(permission.ToString()) { }

        /// <summary>
        /// Initializes a new instance of the <see cref="HasPermissionAttribute"/> class.
        /// </summary>
        public HasPermissionAttribute()
           : base() { }
    }
}