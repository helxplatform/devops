using Microsoft.AspNetCore.Mvc;
using System;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.Admin
{
    /// <summary>
    /// Represent reports search criteria.
    /// </summary>
    /// <seealso cref="Renci.PlaceDb.Web.ViewModels.BaseSearchView" />
    public class ReportSearchView : BaseSearchView
    {
        /// <summary>
        /// The default sort
        /// </summary>
        public const string DefaultSort = nameof(ReportItemView.DisplayName);

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