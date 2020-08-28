using System;

namespace Renci.ReCCAP.Dashboard.Web.Services
{
    /// <summary>
    ///
    /// </summary>
    public interface ISessionContextResolver
    {
        /// <summary>
        /// Gets the current user identifier.
        /// </summary>
        /// <value>
        /// The current user identifier.
        /// </value>
        public Guid? CurrentUserId { get; }

        /// <summary>
        /// Resolves the session context.
        /// </summary>
        /// <returns></returns>
        string ResolveSessionContext();
    }
}