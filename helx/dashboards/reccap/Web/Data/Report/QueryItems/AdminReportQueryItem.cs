using System;

namespace Renci.ReCCAP.Dashboard.Web.Data
{
    /// <summary>
    ///
    /// </summary>
    public class AdminReportQueryItem
    {
        /// <summary>
        /// Gets or sets the report identifier.
        /// </summary>
        /// <value>
        /// The report identifier.
        /// </value>
        public Guid ReportId { get; set; }

        /// <summary>
        /// Gets or sets the name of the report.
        /// </summary>
        /// <value>
        /// The name of the report.
        /// </value>
        public string ReportName { get; set; }

        /// <summary>
        /// Gets or sets the report type identifier.
        /// </summary>
        /// <value>
        /// The report type identifier.
        /// </value>
        public Guid ReportTypeId { get; set; }

        /// <summary>
        /// Gets or sets the name of the report type.
        /// </summary>
        /// <value>
        /// The name of the report type.
        /// </value>
        public string ReportTypeName { get; set; }

        /// <summary>
        /// Gets or sets the report type name seo.
        /// </summary>
        /// <value>
        /// The report type name seo.
        /// </value>
        public string ReportTypeNameSEO { get; set; }

        /// <summary>
        /// Gets or sets the report description.
        /// </summary>
        /// <value>
        /// The report description.
        /// </value>
        public string ReportDescription { get; set; }

        /// <summary>
        /// Gets or sets the report name seo.
        /// </summary>
        /// <value>
        /// The report name seo.
        /// </value>
        public string ReportNameSEO { get; set; }

        /// <summary>
        /// Gets or sets the modified date.
        /// </summary>
        /// <value>
        /// The modified date.
        /// </value>
        public DateTime ModifiedDate { get; set; }
    }
}