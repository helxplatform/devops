using Renci.ReCCAP.Dashboard.Web.Data;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.Admin
{
    /// <summary>
    ///
    /// </summary>
    public class ReportColumnEditView : BaseEditView<ReportColumn>, IValidatableObject
    {
        /// <summary>
        /// Gets or sets the name.
        /// </summary>
        /// <value>
        /// The name.
        /// </value>
        [Required]
        [StringLength(100, ErrorMessage = "The '{0}' must be maximum {1} characters long.")]
        public string Name { get; set; }

        /// <summary>
        /// Gets or sets the display name.
        /// </summary>
        /// <value>
        /// The display name.
        /// </value>
        [StringLength(256, ErrorMessage = "The '{0}' must be maximum {1} characters long.")]
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
        [StringLength(100, ErrorMessage = "The '{0}' must be maximum {1} characters long.")]
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
        /// Initializes a new instance of the <see cref="ReportColumnEditView"/> class.
        /// </summary>
        public ReportColumnEditView()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="ReportColumnEditView"/> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        public ReportColumnEditView(ReportColumn entity)
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            this.Name = entity.Name;
            this.DisplayName = entity.DisplayName;
            this.DisplayValue = entity.DisplayValue;
            this.SortName = entity.SortName;
            this.CanView = entity.CanView;
            this.CanDownload = entity.CanDownload;
            this.ContextMenu = entity.ContextMenu;
            this.ClassName = entity.ClassName;
        }

        /// <summary>
        /// Applies the changes to the entity.
        /// </summary>
        /// <param name="entity">The entity to apply changes to.</param>
        public override void ApplyChangesTo(ReportColumn entity)
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            entity.Name = this.Name;
            entity.DisplayName = this.DisplayName ?? this.Name;
            entity.DisplayValue = this.DisplayValue;
            entity.SortName = this.SortName ?? this.Name;
            entity.CanView = this.CanView;
            entity.CanDownload = this.CanDownload;
            entity.ContextMenu = this.ContextMenu;
            entity.ClassName = this.ClassName;
        }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            yield break;
        }
    }
}