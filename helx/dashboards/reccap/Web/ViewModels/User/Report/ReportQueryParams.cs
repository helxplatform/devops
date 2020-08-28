using Microsoft.AspNetCore.Mvc;
using System;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.User
{
    /// <summary>
    ///
    /// </summary>
    public class ReportQueryParams
    {
        /// <summary>
        /// Gets or sets the page number.
        /// </summary>
        /// <value>
        /// The page.
        /// </value>
        [FromQuery(Name = "page")]
        [DefaultValue(1)]
        [Range(1, int.MaxValue)]
        public int Page { get; set; } = 1;

        /// <summary>
        /// Gets or sets the size of the page.
        /// </summary>
        /// <value>
        /// The size of the page.
        /// </value>
        [FromQuery(Name = "pageSize")]
        [DefaultValue(20)]
        [Range(0, int.MaxValue)]
        public int PageSize { get; set; } = 20;

        /// <summary>
        /// Gets or sets the sort.
        /// </summary>
        /// <value>
        /// The sort.
        /// </value>
        [FromQuery(Name = "sort")]
        public string Sort { get; set; }

        /// <summary>
        /// Gets or sets the direction.
        /// </summary>
        /// <value>
        /// The direction.
        /// </value>
        [FromQuery(Name = "dir")]
        public string Direction { get; set; }
    }
}