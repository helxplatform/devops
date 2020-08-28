using Renci.ReCCAP.Dashboard.Web.Data;
using Renci.ReCCAP.Dashboard.Web.Models.Enums;
using System;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.Admin
{
    /// <summary>
    ///
    /// </summary>
    public class ReportParameterExportView
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
        /// Gets or sets the hint text.
        /// </summary>
        /// <value>
        /// The hint text.
        /// </value>
        public string HintText { get; set; }

        /// <summary>
        /// Gets or sets the order sequence.
        /// </summary>
        /// <value>
        /// The order sequence.
        /// </value>
        public int OrderSequence { get; set; }

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
        public string DefaultValue { get; set; }

        /// <summary>
        /// Gets or sets the type of the parameter data.
        /// </summary>
        /// <value>
        /// The type of the parameter data.
        /// </value>
        public ReportParameterDataType ParameterDataType { get; set; }

        /// <summary>
        /// Gets or sets the data URL.
        /// </summary>
        /// <value>
        /// The data URL.
        /// </value>
        public string CustomData { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="ReportParameterExportView"/> class.
        /// </summary>
        public ReportParameterExportView()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="ReportParameterExportView"/> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        public ReportParameterExportView(ReportParameter entity)
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            this.Name = entity.Name;
            this.DisplayName = entity.DisplayName;
            this.HintText = entity.HintText;
            this.OrderSequence = entity.OrderSequence;
            this.IsRequired = entity.IsRequired;
            this.IsHidden = entity.IsHidden;
            this.DefaultValue = entity.DefaultValue;
            this.ParameterDataType = entity.ParameterDataType;
            this.CustomData = entity.CustomData;
        }
    }
}