using Renci.ReCCAP.Dashboard.Web.Common;
using Renci.ReCCAP.Dashboard.Web.Data;
using Renci.ReCCAP.Dashboard.Web.Models.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.Admin
{
    /// <summary>
    ///
    /// </summary>
    public class ReportParameterEditView : BaseEditView<ReportParameter>, IValidatableObject
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
        [Required]
        [StringLength(256, ErrorMessage = "The '{0}' must be maximum {1} characters long.")]
        public string DisplayName { get; set; }

        /// <summary>
        /// Gets or sets the hint text.
        /// </summary>
        /// <value>
        /// The hint text.
        /// </value>
        [StringLength(256, ErrorMessage = "The '{0}' must be maximum {1} characters long.")]
        public string HintText { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is required.
        /// </summary>
        /// <value>
        ///   <c>true</c> if this instance is required; otherwise, <c>false</c>.
        /// </value>
        public bool IsRequired { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is hidden.
        /// </summary>
        /// <value>
        ///   <c>true</c> if this instance is hidden; otherwise, <c>false</c>.
        /// </value>
        public bool IsHidden { get; set; }

        /// <summary>
        /// Gets or sets the default value.
        /// </summary>
        /// <value>
        /// The default value.
        /// </value>
        [StringLength(256, ErrorMessage = "The '{0}' must be maximum {1} characters long.")]
        public string DefaultValue { get; set; }

        /// <summary>
        /// Gets or sets the type of the parameter data.
        /// </summary>
        /// <value>
        /// The type of the parameter data.
        /// </value>
        [RequireNonDefault(ErrorMessage = "The '{0}' is required.")]
        public ReportParameterDataType ParameterDataType { get; set; }

        /// <summary>
        /// Gets or sets the data URL.
        /// </summary>
        /// <value>
        /// The data URL.
        /// </value>
        public string CustomData { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="ReportParameterEditView"/> class.
        /// </summary>
        public ReportParameterEditView()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="ReportParameterEditView"/> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        public ReportParameterEditView(ReportParameter entity)
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            this.Name = entity.Name;
            this.DisplayName = entity.DisplayName;
            this.HintText = entity.HintText;
            this.IsRequired = entity.IsRequired;
            this.IsHidden = entity.IsHidden;
            this.DefaultValue = entity.DefaultValue;
            this.ParameterDataType = entity.ParameterDataType;
            this.CustomData = entity.CustomData;
        }

        /// <summary>
        /// Applies the changes to the entity.
        /// </summary>
        /// <param name="entity">The entity to apply changes to.</param>
        public override void ApplyChangesTo(ReportParameter entity)
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            entity.Name = this.Name;
            entity.DisplayName = this.DisplayName;
            entity.HintText = this.HintText;
            entity.IsRequired = this.IsRequired;
            entity.IsHidden = this.IsHidden;
            entity.DefaultValue = this.DefaultValue;
            entity.ParameterDataType = this.ParameterDataType;
            entity.CustomData = this.CustomData;
        }

        /// <summary>
        /// Determines whether the specified object is valid.
        /// </summary>
        /// <param name="validationContext">The validation context.</param>
        /// <returns>
        /// A collection that holds failed-validation information.
        /// </returns>
        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            yield break;
        }
    }
}