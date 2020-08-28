using System;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels
{
    /// <summary>
    ///
    /// </summary>
    public abstract class BaseItemView
    {
        /// <summary>
        /// Gets the identifier for the item.
        /// </summary>
        /// <value>
        /// The identifier.
        /// </value>
        public abstract Guid Id { get; }

        /// <summary>
        /// Gets the display name for the item.
        /// </summary>
        /// <value>
        /// The display name.
        /// </value>
        public abstract string DisplayName { get; }
    }
}