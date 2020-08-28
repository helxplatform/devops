using Renci.ReCCAP.Dashboard.Web.Common.Attributes;
using Renci.ReCCAP.Dashboard.Web.Data;
using System;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.Admin
{
    /// <summary>
    ///
    /// </summary>
    public class ReportItemView : BaseItemView
    {
        private readonly AdminReportQueryItem _entity;

        /// <summary>
        /// Gets the identifier for the item.
        /// </summary>
        /// <value>
        /// The identifier.
        /// </value>
        public override Guid Id => this._entity.ReportId;

        /// <summary>
        /// Gets the display name for the item.
        /// </summary>
        /// <value>
        /// The display name.
        /// </value>
        [SortPropertyName(nameof(AdminReportQueryItem.ReportName))]
        public override string DisplayName => this._entity.ReportName;

        /// <summary>
        /// Gets or sets the name seo.
        /// </summary>
        /// <value>
        /// The name seo.
        /// </value>
        [SortPropertyName(nameof(AdminReportQueryItem.ReportNameSEO))]
        public string NameSEO => this._entity.ReportNameSEO;

        /// <summary>
        /// Gets or sets the name of the report type.
        /// </summary>
        /// <value>
        /// The name of the report type.
        /// </value>
        [SortPropertyName(nameof(AdminReportQueryItem.ReportTypeName))]
        public string ReportTypeName => this._entity.ReportTypeName;

        /// <summary>
        /// Gets or sets the report type seo.
        /// </summary>
        /// <value>
        /// The report type seo.
        /// </value>
        [SortPropertyName(nameof(AdminReportQueryItem.ReportTypeNameSEO))]
        public string ReportTypeSEO => this._entity.ReportTypeNameSEO;

        /// <summary>
        /// Gets or sets the description.
        /// </summary>
        /// <value>
        /// The description.
        /// </value>
        [SortPropertyName(nameof(AdminReportQueryItem.ReportDescription))]
        public string Description => this._entity.ReportDescription;

        /// <summary>
        /// Gets or sets the modified date.
        /// </summary>
        /// <value>
        /// The modified date.
        /// </value>
        [SortPropertyName(nameof(AdminReportQueryItem.ModifiedDate))]
        public DateTime ModifiedDate => this._entity.ModifiedDate;

        /// <summary>
        /// Initializes a new instance of the <see cref="ReportItemView" /> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        public ReportItemView(AdminReportQueryItem entity)
        {
            this._entity = entity;
        }
    }
}