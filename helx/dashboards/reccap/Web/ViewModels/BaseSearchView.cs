using Microsoft.AspNetCore.Mvc;
using System.ComponentModel;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels
{
    /// <summary>
    /// Provides generic properties for search
    /// </summary>
    public class BaseSearchView
    {
        /// <summary>
        /// Gets or sets the page number.
        /// </summary>
        /// <value>
        /// The page.
        /// </value>
        [FromQuery(Name = "page")]
        [DefaultValue(1)]
        public int Page { get; set; } = 1;

        /// <summary>
        /// Gets or sets the size of the page.
        /// </summary>
        /// <value>
        /// The size of the page.
        /// </value>
        [FromQuery(Name = "pageSize")]
        [DefaultValue(20)]
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

        /// <summary>
        /// Gets or sets the name.
        /// </summary>
        /// <value>
        /// The name.
        /// </value>
        [FromQuery(Name = "name")]
        public string Name { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="BaseSearchView"/> class.
        /// </summary>
        /// <param name="sort">The sort.</param>
        public BaseSearchView(string sort)
        {
            this.Sort = sort;
        }
    }
}