using Renci.ReCCAP.Dashboard.Web.Data;
using System;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.Admin
{
    /// <summary>
    ///
    /// </summary>
    public class ReportColumnExportView
    {
        /// <summary>
        /// Gets or sets the name.
        /// </summary>
        /// <value>
        /// The name.
        /// </value>
        public string Name { get; set; }

        /// <summary>
        /// Gets or sets the display name.
        /// </summary>
        /// <value>
        /// The display name.
        /// </value>
        public string DisplayName { get; set; }

        /// <summary>
        /// Gets or sets the display value.
        /// </summary>
        /// <value>
        /// The display value.
        /// </value>
        public string DisplayValue { get; set; }

        /// <summary>
        /// Gets or sets the name of the sort.
        /// </summary>
        /// <value>
        /// The name of the sort.
        /// </value>
        public string SortName { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether this instance can view.
        /// </summary>
        /// <value>
        ///   <c>true</c> if this instance can view; otherwise, <c>false</c>.
        /// </value>
        public bool CanView { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether this instance can download.
        /// </summary>
        /// <value>
        ///   <c>true</c> if this instance can download; otherwise, <c>false</c>.
        /// </value>
        public bool CanDownload { get; set; }

        /// <summary>
        /// Gets or sets the order sequence.
        /// </summary>
        /// <value>
        /// The order sequence.
        /// </value>
        public int OrderSequence { get; set; }

        /// <summary>
        /// Gets or sets the context menu.
        /// </summary>
        /// <value>
        /// The context menu.
        /// </value>
        public string ContextMenu { get; set; }

        /// <summary>
        /// Gets or sets the name of the class.
        /// </summary>
        /// <value>
        /// The name of the class.
        /// </value>
        public string ClassName { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="ReportColumnExportView"/> class.
        /// </summary>
        public ReportColumnExportView()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="ReportColumnExportView"/> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        public ReportColumnExportView(ReportColumn entity)
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            this.Name = entity.Name;
            this.DisplayName = entity.DisplayName;
            this.DisplayValue = entity.DisplayValue;
            this.SortName = entity.SortName;
            this.CanView = entity.CanView;
            this.CanDownload = entity.CanDownload;
            this.OrderSequence = entity.OrderSequence;
            this.ContextMenu = entity.ContextMenu;
            this.ClassName = entity.ClassName;
        }
    }
}