using System;

namespace Renci.ReCCAP.Dashboard.Web.Models.Interfaces
{
    public interface ICreatable
    {
        /// <summary>
        /// Gets or sets the created user identifier.
        /// </summary>
        /// <value>
        /// The created user identifier.
        /// </value>
        Guid CreatedUserId { get; set; }

        /// <summary>
        /// Gets or sets the created date.
        /// </summary>
        /// <value>
        /// The created date.
        /// </value>
        DateTime CreatedDate { get; set; }
    }
}