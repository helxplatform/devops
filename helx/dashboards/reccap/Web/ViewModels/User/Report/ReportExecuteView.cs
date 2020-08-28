using Renci.ReCCAP.Dashboard.Web.Data;
using Renci.ReCCAP.Dashboard.Web.Models.Enums;
using System;
using System.Collections.Generic;
using System.Linq;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.User
{
    /// <summary>
    ///
    /// </summary>
    public class ReportExecuteView
    {
        /// <summary>
        /// Gets the report identifier.
        /// </summary>
        /// <value>
        /// The report identifier.
        /// </value>
        public Guid ReportId { get; private set; }

        /// <summary>
        /// Gets or sets the name.
        /// </summary>
        /// <value>
        /// The name.
        /// </value>
        public string Name { get; set; }

        /// <summary>
        /// Gets or sets the SEO name.
        /// </summary>
        /// <value>
        /// The name seo.
        /// </value>
        public string NameSEO { get; set; }

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
        /// Gets or sets the report type seo.
        /// </summary>
        /// <value>
        /// The report type seo.
        /// </value>
        public string ReportTypeSEO { get; set; }

        /// <summary>
        /// Gets or sets the name of the report type.
        /// </summary>
        /// <value>
        /// The name of the report type.
        /// </value>
        public string ReportTypeName { get; set; }

        /// <summary>
        /// Gets or sets the columns.
        /// </summary>
        /// <value>
        /// The columns.
        /// </value>
        public IEnumerable<object> Columns { get; set; }

        /// <summary>
        /// Gets or sets the parameters.
        /// </summary>
        /// <value>
        /// The parameters.
        /// </value>
        public IEnumerable<object> Parameters { get; set; }

        /// <summary>
        /// Gets or sets the chart types.
        /// </summary>
        /// <value>
        /// The chart types.
        /// </value>
        public IEnumerable<string> ChartTypes { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="ReportExecuteView"/> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        public ReportExecuteView(Report entity)
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            this.ReportId = entity.ReportId;
            this.Name = entity.Name;
            this.NameSEO = entity.NameSEO;
            this.Description = entity.Description;
            this.ShortDescription = entity.ShortDescription;
            this.ReportTypeSEO = entity.ReportType.NameSEO;
            this.ReportTypeName = entity.ReportType.Name;

            this.Columns = entity.ReportColumns.Where(m => m.CanView == true).OrderBy(m => m.OrderSequence).Select(m => new
            {
                m.Name,
                DisplayName = string.IsNullOrWhiteSpace(m.DisplayName) ? m.Name : m.DisplayName,
                m.DisplayValue,
                SortName = string.IsNullOrWhiteSpace(m.SortName) ? m.Name : m.SortName,
                m.OrderSequence,
                m.ContextMenu,
                m.ClassName,
            }).ToList();

            this.Parameters = entity.ReportParameters.OrderBy(m => m.OrderSequence).Select(m => new
            {
                m.Name,
                DisplayName = string.IsNullOrWhiteSpace(m.DisplayName) ? m.Name : m.DisplayName,
                m.HintText,
                m.OrderSequence,
                m.IsRequired,
                m.IsHidden,
                m.DefaultValue,
                ParameterDataType = Enum.GetName(typeof(ReportParameterDataType), m.ParameterDataType),
                m.CustomData,
            }).ToList();

            this.ChartTypes = entity.ChartTypes.Select(m => m.ChartType).ToList();
        }
    }
}