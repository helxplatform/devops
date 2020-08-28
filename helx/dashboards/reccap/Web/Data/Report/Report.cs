using Renci.ReCCAP.Dashboard.Web.Models.Enums;
using Renci.ReCCAP.Dashboard.Web.Models.Interfaces;
using System;
using System.Collections.Generic;

namespace Renci.ReCCAP.Dashboard.Web.Data
{
    public partial class Report : ITrackable, IVersion
    {
        /// <summary>
        /// Gets or sets the report identifier.
        /// </summary>
        /// <value>
        /// The report identifier.
        /// </value>
        public Guid ReportId { get; set; }

        /// <summary>
        /// Gets or sets the name.
        /// </summary>
        /// <value>
        /// The name.
        /// </value>
        public string Name { get; set; }

        /// <summary>
        /// Gets or sets the description.
        /// </summary>
        /// <value>
        /// The description.
        /// </value>
        public string Description { get; set; }

        /// <summary>
        /// Gets or sets the short description.
        /// </summary>
        /// <value>
        /// The short description.
        /// </value>
        public string ShortDescription { get; set; }

        /// <summary>
        /// Gets or sets the display category.
        /// </summary>
        /// <value>
        /// The display category.
        /// </value>
        public ReportDisplayCategory DisplayCategory { get; set; }

        /// <summary>
        /// Gets or sets the report type identifier.
        /// </summary>
        /// <value>
        /// The report type identifier.
        /// </value>
        public Guid ReportTypeId { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is active.
        /// </summary>
        /// <value>
        ///   <c>true</c> if this instance is active; otherwise, <c>false</c>.
        /// </value>
        public bool IsActive { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is visible.
        /// </summary>
        /// <value>
        ///   <c>true</c> if this instance is visible; otherwise, <c>false</c>.
        /// </value>
        public bool IsVisible { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is public.
        /// </summary>
        /// <value>
        ///   <c>true</c> if this instance is public; otherwise, <c>false</c>.
        /// </value>
        public bool IsPublic { get; set; }

        /// <summary>
        /// Gets or sets the order sequence.
        /// </summary>
        /// <value>
        /// The order sequence.
        /// </value>
        public int OrderSequence { get; set; }

        /// <summary>
        /// Gets or sets the query text.
        /// </summary>
        /// <value>
        /// The query text.
        /// </value>
        public string QueryText { get; set; }

        /// <summary>
        /// Gets or sets the query context.
        /// </summary>
        /// <value>
        /// The query context.
        /// </value>
        public QueryContext QueryContext { get; set; }

        /// <summary>
        /// Gets or sets the created user identifier.
        /// </summary>
        /// <value>
        /// The created user identifier.
        /// </value>
        public Guid CreatedUserId { get; set; }

        /// <summary>
        /// Gets or sets the created date.
        /// </summary>
        /// <value>
        /// The created date.
        /// </value>
        public DateTime CreatedDate { get; set; }

        /// <summary>
        /// Gets or sets the modified user identifier.
        /// </summary>
        /// <value>
        /// The modified user identifier.
        /// </value>
        public Guid? ModifiedUserId { get; set; }

        /// <summary>
        /// Gets or sets the modified date.
        /// </summary>
        /// <value>
        /// The modified date.
        /// </value>
        public DateTime? ModifiedDate { get; set; }

        /// <summary>
        /// Gets or sets entity version.
        /// </summary>
        /// <value>
        /// The version.
        /// </value>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Performance", "CA1819")]
        public byte[] Version { get; set; }

        /// <summary>
        /// Gets or sets the name seo.
        /// </summary>
        /// <value>
        /// The name seo.
        /// </value>
        public string NameSEO { get; set; }

        /// <summary>
        /// Gets or sets the default sort.
        /// </summary>
        /// <value>
        /// The default sort.
        /// </value>
        public string DefaultSort { get; set; }

        /// <summary>
        /// Gets or sets the type of the report.
        /// </summary>
        /// <value>
        /// The type of the report.
        /// </value>
        public virtual Type ReportType { get; set; }

        /// <summary>
        /// Gets or sets the created user.
        /// </summary>
        /// <value>
        /// The created user.
        /// </value>
        public virtual ApplicationUser CreatedUser { get; set; }

        /// <summary>
        /// Gets or sets the modified user.
        /// </summary>
        /// <value>
        /// The modified user.
        /// </value>
        public virtual ApplicationUser ModifiedUser { get; set; }

        /// <summary>
        /// Gets or sets the report columns.
        /// </summary>
        /// <value>
        /// The report columns.
        /// </value>
        public ICollection<ReportColumn> ReportColumns { get; } = new List<ReportColumn>();

        /// <summary>
        /// Gets or sets the report parameters.
        /// </summary>
        /// <value>
        /// The report parameters.
        /// </value>
        public ICollection<ReportParameter> ReportParameters { get; } = new List<ReportParameter>();

        /// <summary>
        /// Gets or sets the roles.
        /// </summary>
        /// <value>
        /// The roles.
        /// </value>
        public ICollection<ReportRole> Roles { get; } = new List<ReportRole>();

        /// <summary>
        /// Gets or sets the chart types.
        /// </summary>
        /// <value>
        /// The chart types.
        /// </value>
        public ICollection<ReportChartType> ChartTypes { get; } = new List<ReportChartType>();
    }
}