using Renci.ReCCAP.Dashboard.Web.Common;
using Renci.ReCCAP.Dashboard.Web.Data;
using Renci.ReCCAP.Dashboard.Web.Models.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.Admin
{
    /// <summary>
    ///
    /// </summary>
    /// <seealso cref="Renci.PlaceDb.Web.ViewModels.BaseEditView{T}" />
    /// <seealso cref="System.ComponentModel.DataAnnotations.IValidatableObject" />
    public class ReportEditView : BaseEditView<Data.Report>, IValidatableObject
    {
        /// <summary>
        /// Gets or sets the display name.
        /// </summary>
        /// <value>
        /// The display name.
        /// </value>
        public string DisplayName { get; }

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
        [Required]
        [StringLength(256, ErrorMessage = "The '{0}' must be maximum {1} characters long.")]
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
        [StringLength(512, ErrorMessage = "The '{0}' must be maximum {1} characters long.")]
        public string ShortDescription { get; set; }

        /// <summary>
        /// Gets or sets the display category.
        /// </summary>
        /// <value>
        /// The display category.
        /// </value>
        [RequireNonDefault(ErrorMessage = "The '{0}' is required.")]
        public ReportDisplayCategory DisplayCategory { get; set; }

        /// <summary>
        /// Gets or sets the report type identifier.
        /// </summary>
        /// <value>
        /// The report type identifier.
        /// </value>
        [RequireNonDefault(ErrorMessage = "The '{0}' is required.")]
        public Guid ReportTypeId { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether report is active.
        /// </summary>
        /// <value>
        ///   <c>true</c> if report is active; otherwise, <c>false</c>.
        /// </value>
        public bool IsActive { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether report is visible.
        /// </summary>
        /// <value>
        ///   <c>true</c> if report is visible; otherwise, <c>false</c>.
        /// </value>
        public bool IsVisible { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether report is public.
        /// </summary>
        /// <value>
        ///   <c>true</c> if report is public; otherwise, <c>false</c>.
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
        [Required]
        public string QueryText { get; set; }

        /// <summary>
        /// Gets the query context.
        /// </summary>
        /// <value>
        /// The query context.
        /// </value>
        public QueryContext QueryContext { get; } = new QueryContext();

        /// <summary>
        /// Gets or sets a value indicating whether query validation should be ignored.
        /// </summary>
        /// <value>
        ///   <c>true</c> if query validation should be ignored; otherwise, <c>false</c>.
        /// </value>
        public bool IgnoreQueryValidation { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether [ignore total rows].
        /// </summary>
        /// <value>
        ///   <c>true</c> if [ignore total rows]; otherwise, <c>false</c>.
        /// </value>
        public bool IgnoreTotalRowsColumn { get; set; }

        /// <summary>
        /// Gets or sets the default sort order.
        /// </summary>
        /// <value>
        /// The default sort.
        /// </value>
        [StringLength(256, ErrorMessage = "The '{0}' must be maximum {1} characters long.")]
        public string DefaultSort { get; set; }

        /// <summary>
        /// Gets or sets the version.
        /// </summary>
        /// <value>
        /// The version.
        /// </value>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Performance", "CA1819")]
        public byte[] Version { get; set; }

        /// <summary>
        /// Gets or sets the columns.
        /// </summary>
        /// <value>
        /// The columns.
        /// </value>
        public IEnumerable<ReportColumnEditView> Columns { get; set; } = new List<ReportColumnEditView>();

        /// <summary>
        /// Gets or sets the parameters.
        /// </summary>
        /// <value>
        /// The parameters.
        /// </value>
        public IEnumerable<ReportParameterEditView> Parameters { get; set; } = new List<ReportParameterEditView>();

        /// <summary>
        /// Gets or sets the roles.
        /// </summary>
        /// <value>
        /// The roles.
        /// </value>
        public IEnumerable<CommonInfo<Guid>> Roles { get; set; } = new List<CommonInfo<Guid>>();

        /// <summary>
        /// Gets or sets the chart types.
        /// </summary>
        /// <value>
        /// The chart types.
        /// </value>
        public IEnumerable<CommonInfo<string>> ChartTypes { get; set; } = new List<CommonInfo<string>>();

        /// <summary>
        /// Initializes a new instance of the <see cref="ReportEditView"/> class.
        /// </summary>
        public ReportEditView()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="ReportEditView"/> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        public ReportEditView(Data.Report entity)
            : this()
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            this.DisplayName = entity.Name;
            this.ReportId = entity.ReportId;
            this.Name = entity.Name;
            this.Description = entity.Description;
            this.ShortDescription = entity.ShortDescription;
            this.DisplayCategory = entity.DisplayCategory;
            this.ReportTypeId = entity.ReportTypeId;
            this.IsActive = entity.IsActive;
            this.IsVisible = entity.IsVisible;
            this.IsPublic = entity.IsPublic;
            this.OrderSequence = entity.OrderSequence;
            this.QueryText = entity.QueryText;
            this.DefaultSort = entity.DefaultSort;
            this.Version = entity.Version;

            this.Columns = entity.ReportColumns.OrderBy(m => m.OrderSequence).Select(m => new ReportColumnEditView(m)).ToList();
            this.Parameters = entity.ReportParameters.OrderBy(m => m.OrderSequence).Select(m => new ReportParameterEditView(m)).ToList();
            this.Roles = entity.Roles.Select(m => new CommonInfo<Guid>(m.RoleId, m.Role.Name)).ToList();
            var chartTypes = new Dictionary<string, string>()
            {
                { "line",  "Line" },
                { "bar",  "Bar" },
                { "doughnut",  "Doughnut" },
                { "radar",  "Radar" },
                { "pie",  "Pie" },
                { "polarArea",  "Polar Area" }
            };
            this.ChartTypes = entity.ChartTypes.Select(m => new CommonInfo<string>(m.ChartType, chartTypes[m.ChartType])).ToList();
        }

        /// <summary>
        /// Applies the changes to the entity.
        /// </summary>
        /// <param name="entity">The entity to apply changes to.</param>
        public override void ApplyChangesTo(Data.Report entity)
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            //  Set entity properties
            entity.Name = this.Name;
            entity.NameSEO = this.Name.ToUrlSlug();
            entity.Description = this.Description;
            entity.ShortDescription = this.ShortDescription;
            entity.DisplayCategory = this.DisplayCategory;
            entity.ReportTypeId = this.ReportTypeId;
            entity.IsActive = this.IsActive;
            entity.IsVisible = this.IsVisible;
            entity.IsPublic = this.IsPublic;
            entity.OrderSequence = this.OrderSequence;
            entity.QueryText = this.QueryText;
            entity.QueryContext = this.QueryContext;
            entity.DefaultSort = this.DefaultSort;
            entity.Version = this.Version;

            var columnCounter = 0;
            this.UpdateCollection(entity.ReportColumns, this.Columns, (e, e1) => e.Name == e1.Name, () => new ReportColumn() { Report = entity }, (e, b) => { e.OrderSequence = columnCounter++; });
            var paramCounter = 0;
            this.UpdateCollection(entity.ReportParameters, this.Parameters, (e, e1) => e.Name == e1.Name, () => new ReportParameter() { Report = entity }, (e, b) => { e.OrderSequence = paramCounter++; });

            foreach (var item in entity.Roles.Where(m => !this.Roles.Where(i => i.Id == m.RoleId).Any()).ToList())
            {
                entity.Roles.Remove(item);
            }
            foreach (var item in this.Roles.Where(m => !entity.Roles.Where(i => i.RoleId == m.Id).Any()).ToList())
            {
                entity.Roles.Add(new ReportRole() { Report = entity, RoleId = item.Id });
            }
            foreach (var item in entity.ChartTypes.Where(m => !this.ChartTypes.Where(i => i.Id == m.ChartType).Any()).ToList())
            {
                entity.ChartTypes.Remove(item);
            }
            foreach (var item in this.ChartTypes.Where(m => !entity.ChartTypes.Where(i => i.ChartType == m.Id).Any()).ToList())
            {
                entity.ChartTypes.Add(new ReportChartType() { Report = entity, ChartType = item.Id });
            }
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
            if (!this.Roles.Any())
            {
                yield return new ValidationResult("At least one role is required", new[] { "Roles" });
            }

            foreach (var duplicate in this.Columns.GroupBy(m => m.Name).Where(g => g.Count() > 1).Select(m => m.Key))
            {
                yield return new ValidationResult($"Column '{duplicate}' specified more than once.", new[] { "Columns" });
            }

            foreach (var duplicate in this.Parameters.GroupBy(m => m.Name).Where(g => g.Count() > 1).Select(m => m.Key))
            {
                yield return new ValidationResult($"Parameter '{duplicate}' specified more than once.", new[] { "Parameters" });
            }

            foreach (var result in this.Columns.SelectMany(m => m.Validate(validationContext)))
            {
                yield return result;
            }
            foreach (var result in this.Parameters.SelectMany(m => m.Validate(validationContext)))
            {
                yield return result;
            }
        }
    }
}