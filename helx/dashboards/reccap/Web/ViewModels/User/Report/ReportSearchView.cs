using Microsoft.AspNetCore.Mvc;
using System;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.User
{
    /// <summary>
    /// Represent reports search criteria.
    /// </summary>
    /// <seealso cref="Renci.Dashboard.Web.ViewModels.BaseSearchView" />
    public class ReportSearchView : BaseSearchView
    {
        /// <summary>
        /// The default sort
        /// </summary>
        public static string DefaultSort = "ReportName";

        /// <summary>
        /// Gets or sets the name.
        /// </summary>
        /// <value>
        /// The name.
        /// </value>
        [FromQuery(Name = "name")]
        public string Name { get; set; }

        /// <summary>
        /// Gets or sets the report type identifier.
        /// </summary>
        /// <value>
        /// The report type identifier.
        /// </value>
        [FromQuery(Name = "typeid")]
        public Guid? ReportTypeId { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="ReportSearchView"/> class.
        /// </summary>
        public ReportSearchView()
            : base(ReportSearchView.DefaultSort)
        {
        }
    }
}