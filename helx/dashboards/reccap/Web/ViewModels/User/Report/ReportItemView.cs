using Renci.ReCCAP.Dashboard.Web.Common.Attributes;
using Renci.ReCCAP.Dashboard.Web.Data;
using System;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.User
{
    /// <summary>
    ///
    /// </summary>
    public class ReportItemView : BaseItemView
    {
        private readonly ReportQueryItem _entity;

        /// <summary>
        /// Gets the identifier for the item.
        /// </summary>
        /// <value>
        /// The identifier.
        /// </value>
        [SortPropertyName(nameof(ReportQueryItem.ReportId))]
        public override Guid Id => this._entity.ReportId;

        /// <summary>
        /// Gets the display name for the item.
        /// </summary>
        /// <value>
        /// The display name.
        /// </value>
        [SortPropertyName(nameof(ReportQueryItem.ReportName))]
        public override string DisplayName => this._entity.ReportName;

        /// <summary>
        /// Gets the name.
        /// </summary>
        /// <value>
        /// The name.
        /// </value>
        [SortPropertyName(nameof(ReportQueryItem.ReportName))]
        public string Name => this._entity.ReportName;

        /// <summary>
        /// Gets or sets the name seo.
        /// </summary>
        /// <value>
        /// The name seo.
        /// </value>
        [SortPropertyName(nameof(ReportQueryItem.ReportNameSEO))]
        public string NameSEO => this._entity.ReportNameSEO;

        /// <summary>
        /// Gets or sets the name of the report type.
        /// </summary>
        /// <value>
        /// The name of the report type.
        /// </value>
        [SortPropertyName(nameof(ReportQueryItem.ReportTypeName))]
        public string ReportTypeName => this._entity.ReportTypeName;

        /// <summary>
        /// Gets or sets the report type seo.
        /// </summary>
        /// <value>
        /// The report type seo.
        /// </value>
        [SortPropertyName(nameof(ReportQueryItem.ReportTypeNameSEO))]
        public string ReportTypeSEO => this._entity.ReportTypeNameSEO;

        /// <summary>
        /// Gets or sets the short description.
        /// </summary>
        /// <value>
        /// The short description.
        /// </value>
        [SortPropertyName(nameof(ReportQueryItem.ReportDescription))]
        public string Description => this._entity.ReportDescription;

        /// <summary>
        /// Initializes a new instance of the <see cref="ReportItemView"/> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        public ReportItemView(ReportQueryItem entity)
        {
            this._entity = entity;
        }
    }
}