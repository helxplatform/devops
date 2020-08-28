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
    public class ReportExportView : BaseEditView<Report>, IValidatableObject
    {
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
        /// Gets or sets the name of the report type.
        /// </summary>
        /// <value>
        /// The name of the report type.
        /// </value>
        public string ReportTypeName { get; set; }

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
        /// Gets or sets the query text.
        /// </summary>
        /// <value>
        /// The query text.
        /// </value>
        [Required]
        public string QueryText { get; set; }

        /// <summary>
        /// Gets or sets the default sort order.
        /// </summary>
        /// <value>
        /// The default sort.
        /// </value>
        public string DefaultSort { get; set; }

        /// <summary>
        /// Gets or sets the columns.
        /// </summary>
        /// <value>
        /// The columns.
        /// </value>
        public IEnumerable<ReportColumnEditView> Columns { get; } = new List<ReportColumnEditView>();

        /// <summary>
        /// Gets or sets the parameters.
        /// </summary>
        /// <value>
        /// The parameters.
        /// </value>
        public IEnumerable<ReportParameterEditView> Parameters { get; } = new List<ReportParameterEditView>();

        /// <summary>
        /// Gets or sets the roles.
        /// </summary>
        /// <value>
        /// The roles.
        /// </value>
        public IEnumerable<string> Roles { get; } = new List<string>();

        /// <summary>
        /// Gets or sets the chart types.
        /// </summary>
        /// <value>
        /// The chart types.
        /// </value>
        public IEnumerable<string> ChartTypes { get; } = new List<string>();

        /// <summary>
        /// Initializes a new instance of the <see cref="ReportEditView"/> class.
        /// </summary>
        public ReportExportView()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="ReportEditView"/> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        public ReportExportView(Report entity)
            : this()
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            this.Name = entity.Name;
            this.Description = entity.Description;
            this.ShortDescription = entity.ShortDescription;
            this.DisplayCategory = entity.DisplayCategory;
            this.ReportTypeName = entity.ReportType.Name;
            this.IsActive = entity.IsActive;
            this.IsVisible = entity.IsVisible;
            this.IsPublic = entity.IsPublic;
            this.QueryText = entity.QueryText;
            this.DefaultSort = entity.DefaultSort;

            this.Columns = entity.ReportColumns.OrderBy(m => m.OrderSequence).Select(m => new ReportColumnEditView(m)).ToList();
            this.Parameters = entity.ReportParameters.OrderBy(m => m.OrderSequence).Select(m => new ReportParameterEditView(m)).ToList();
            this.Roles = entity.Roles.Select(m => m.Role.Name).ToList();
            this.ChartTypes = entity.ChartTypes.Select(m => m.ChartType).ToList();
        }

        /// <summary>
        /// Applies the changes to an entity.
        /// </summary>
        /// <param name="entity">The entity.</param>
        /// <param name="dbContext">The database context.</param>
        public void ApplyChangesTo(Report entity, ApplicationDbContext dbContext)
        {
            if (entity == null)
            {
                throw new ArgumentNullException(nameof(entity));
            }

            this.ApplyChangesTo(entity);

            if (dbContext == null)
            {
                throw new ArgumentNullException(nameof(dbContext));
            }

            entity.ReportTypeId = dbContext.Types
                .Where(m => m.Category == CategoryName.ReportType && m.Name == this.ReportTypeName)
                .Select(m => m.TypeId).FirstOrDefault();

            var roleIds = dbContext.Roles.Where(m => this.Roles.Contains(m.Name)).Select(m => m.Id);
            foreach (var roleId in roleIds)
            {
                entity.Roles.Add(new ReportRole()
                {
                    RoleId = roleId
                });
            }

            foreach (var chartType in this.ChartTypes)
            {
                entity.ChartTypes.Add(new ReportChartType()
                {
                    ChartType = chartType
                });
            }
        }

        /// <summary>
        /// Applies the changes to the entity.
        /// </summary>
        /// <param name="entity">The entity to apply changes to.</param>
        public override void ApplyChangesTo(Report entity)
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            //  Set entity properties
            entity.Name = this.Name;
            entity.NameSEO = this.Name.ToUrlSlug();
            entity.Description = this.Description;
            entity.ShortDescription = this.ShortDescription;
            entity.DisplayCategory = this.DisplayCategory;
            entity.IsActive = this.IsActive;
            entity.IsVisible = this.IsVisible;
            entity.IsPublic = this.IsPublic;
            entity.QueryText = this.QueryText;
            entity.DefaultSort = this.DefaultSort;

            foreach (var item in entity.ReportColumns.Where(m => !this.Columns.Where(e => e.Name == m.Name).Any()).ToList())
            {
                entity.ReportColumns.Remove(item);
            }

            var columnIndex = 0;
            foreach (var item in this.Columns)
            {
                var itemEntity = entity.ReportColumns.Where(m => m.Name == item.Name).SingleOrDefault();
                if (itemEntity == null)
                {
                    itemEntity = new ReportColumn()
                    {
                        Name = item.Name,
                        DisplayName = item.DisplayName,
                        DisplayValue = item.DisplayValue,
                        SortName = item.SortName,
                        CanView = item.CanView,
                        CanDownload = item.CanDownload,
                        ContextMenu = item.ContextMenu,
                        ClassName = item.ClassName,
                    };
                    entity.ReportColumns.Add(itemEntity);
                }
                else
                {
                    itemEntity.DisplayName = item.DisplayName;
                    itemEntity.DisplayValue = item.DisplayValue;
                    itemEntity.SortName = item.SortName;
                    itemEntity.CanView = item.CanView;
                    itemEntity.CanDownload = item.CanDownload;
                    itemEntity.ContextMenu = item.ContextMenu;
                    itemEntity.ClassName = item.ClassName;
                }
                itemEntity.OrderSequence = columnIndex++;
            }

            foreach (var item in entity.ReportParameters.Where(m => !this.Parameters.Where(e => e.Name == m.Name).Any()).ToList())
            {
                entity.ReportParameters.Remove(item);
            }

            var parameterIndex = 0;
            foreach (var item in this.Parameters)
            {
                var itemEntity = entity.ReportParameters.Where(m => m.Name == item.Name).SingleOrDefault();
                if (itemEntity == null)
                {
                    itemEntity = new ReportParameter()
                    {
                        Name = item.Name,
                        DisplayName = item.DisplayName,
                        HintText = item.HintText,
                        IsRequired = item.IsRequired,
                        IsHidden = item.IsHidden,
                        DefaultValue = item.DefaultValue,
                        ParameterDataType = item.ParameterDataType,
                        CustomData = item.CustomData,
                    };
                    entity.ReportParameters.Add(itemEntity);
                }
                else
                {
                    itemEntity.DisplayName = item.DisplayName;
                    itemEntity.HintText = item.HintText;
                    itemEntity.IsRequired = item.IsRequired;
                    itemEntity.IsHidden = item.IsHidden;
                    itemEntity.DefaultValue = item.DefaultValue;
                    itemEntity.ParameterDataType = item.ParameterDataType;
                    itemEntity.CustomData = item.CustomData;
                }
                itemEntity.OrderSequence = parameterIndex++;
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
        }
    }
}