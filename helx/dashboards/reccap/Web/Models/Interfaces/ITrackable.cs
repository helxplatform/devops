using System;

namespace Renci.ReCCAP.Dashboard.Web.Models.Interfaces
{
    public interface ITrackable : ICreatable
    {
        /// <summary>
        /// Gets or sets the modified user identifier.
        /// </summary>
        /// <value>
        /// The modified user identifier.
        /// </value>
        Guid? ModifiedUserId { get; set; }

        /// <summary>
        /// Gets or sets the modified date.
        /// </summary>
        /// <value>
        /// The modified date.
        /// </value>
        DateTime? ModifiedDate { get; set; }
    }
}