using Renci.ReCCAP.Dashboard.Web.Common;
using Renci.ReCCAP.Dashboard.Web.Data;
using Renci.ReCCAP.Dashboard.Web.Models.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Reflection;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.Admin
{
    /// <summary>
    ///
    /// </summary>
    /// <seealso cref="Renci.Dashboard.Web.ViewModels.BaseEditView{T}" />
    public class TypeEditView : BaseEditView<Data.Type>
    {
        /// <summary>
        /// Gets or sets the display name.
        /// </summary>
        /// <value>
        /// The display name.
        /// </value>
        public string DisplayName { get; }

        /// <summary>
        /// Gets or sets the type identifier.
        /// </summary>
        /// <value>
        /// The type identifier.
        /// </value>
        public Guid TypeId { get; set; }

        /// <summary>
        /// Gets or sets the parent category identifier.
        /// </summary>
        /// <value>
        /// The parent category identifier.
        /// </value>
        public CategoryName? ParentCategoryId { get; set; }

        /// <summary>
        /// Gets or sets the parent type identifier.
        /// </summary>
        /// <value>
        /// The parent type identifier.
        /// </value>
        public Guid? ParentTypeId { get; set; }

        /// <summary>
        /// Gets or sets the code.
        /// </summary>
        /// <value>
        /// The name.
        /// </value>
        [StringLength(32, ErrorMessage = "The '{0}' must be maximum {1} characters long.")]
        public string Code { get; set; }

        /// <summary>
        /// Gets or sets the order sequence.
        /// </summary>
        /// <value>
        /// The order sequence.
        /// </value>
        public int OrderSequence { get; set; }

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
        /// Gets or sets the category.
        /// </summary>
        /// <value>
        /// The category.
        /// </value>
        public CategoryName Category { get; set; }

        /// <summary>
        /// Gets or sets the name of the category.
        /// </summary>
        /// <value>
        /// The name of the category.
        /// </value>
        public string CategoryName { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is active.
        /// </summary>
        /// <value>
        ///   <c>true</c> if this instance is active; otherwise, <c>false</c>.
        /// </value>
        public bool IsActive { get; set; } = true;

        /// <summary>
        /// Gets or sets the version.
        /// </summary>
        /// <value>
        /// The version.
        /// </value>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Performance", "CA1819")]
        public byte[] Version { get; set; }

        /// <summary>
        /// Gets or sets the roles.
        /// </summary>
        /// <value>
        /// The roles.
        /// </value>
        public IEnumerable<CommonInfo<Guid>> Roles { get; set; } = new List<CommonInfo<Guid>>();

        /// <summary>
        /// Initializes a new instance of the <see cref="TypeEditView"/> class.
        /// </summary>
        public TypeEditView()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="TypeEditView"/> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        public TypeEditView(Data.Type entity)
            : this()
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            this.DisplayName = entity.Name;
            this.TypeId = entity.TypeId;
            this.ParentCategoryId = entity.ParentType?.Category;
            this.ParentTypeId = entity.ParentTypeId;
            this.Name = entity.Name;
            this.Code = entity.Code;
            this.OrderSequence = entity.OrderSequence;
            this.IsActive = entity.IsActive;
            this.Category = entity.Category;
            this.CategoryName = entity.Category.GetType()
                .GetFields()
                .Where(m => m.IsSpecialName == false && (int)m.GetValue(entity.Category) == (int)entity.Category)
                .Select(m => m.GetCustomAttribute<DescriptionAttribute>()?.Description ?? m.Name)
                .FirstOrDefault();
            this.Roles = entity.Roles.Select(m => new CommonInfo<Guid>(m.RoleId, m.Role.Name)).ToList();
            this.Version = entity.Version;
        }

        /// <summary>
        /// Applies the changes to the entity.
        /// </summary>
        /// <param name="entity">The entity to apply changes to.</param>
        public override void ApplyChangesTo(Data.Type entity)
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            //  Set entity properties
            entity.ParentTypeId = this.ParentTypeId;
            entity.Name = this.Name;
            entity.Code = string.IsNullOrWhiteSpace(this.Code) ? null : this.Code;
            entity.OrderSequence = this.OrderSequence;
            entity.NameSEO = this.Name.ToUrlSlug();
            entity.IsActive = this.IsActive;
            entity.Category = this.Category;
            entity.Version = this.Version;

            this.UpdateCollection(entity.Roles, this.Roles, (item) => new TypeRole() { Type = entity, RoleId = item.Id });
        }
    }
}