using Renci.ReCCAP.Dashboard.Web.Data;
using Renci.ReCCAP.Dashboard.Web.Models.Enums;
using System;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.Admin
{
    public class TypeItemView : BaseItemView
    {
        private readonly AdminTypeQueryItem _entity;

        /// <summary>
        /// Gets the identifier for the item.
        /// </summary>
        /// <value>
        /// The identifier.
        /// </value>
        /// <exception cref="NotImplementedException"></exception>
        public override Guid Id => this._entity.TypeId;

        /// <summary>
        /// Gets the display name for the item.
        /// </summary>
        /// <value>
        /// The display name.
        /// </value>
        public override string DisplayName => this._entity.TypeName;

        /// <summary>
        /// Gets or sets the type identifier.
        /// </summary>
        /// <value>
        /// The type identifier.
        /// </value>
        public Guid TypeId { get; set; }

        /// <summary>
        /// Gets the category.
        /// </summary>
        /// <value>
        /// The category.
        /// </value>
        public CategoryName Category => this._entity.Category;

        /// <summary>
        /// Gets the code.
        /// </summary>
        /// <value>
        /// The code.
        /// </value>
        public string Code => this._entity.Code;

        /// <summary>
        /// Gets or sets the order sequence.
        /// </summary>
        /// <value>
        /// The order sequence.
        /// </value>
        public int OrderSequence { get; set; }

        /// <summary>
        /// Gets the name of the parent type.
        /// </summary>
        /// <value>
        /// The name of the parent type.
        /// </value>
        public string ParentTypeName => this._entity.ParentTypeName;

        /// <summary>
        /// Gets a value indicating whether this instance is active.
        /// </summary>
        /// <value>
        ///   <c>true</c> if this instance is active; otherwise, <c>false</c>.
        /// </value>
        public bool IsActive => this._entity.IsActive;

        /// <summary>
        /// Gets or sets the modified date.
        /// </summary>
        /// <value>
        /// The modified date.
        /// </value>
        public DateTime ModifiedDate => this._entity.ModifiedDate;

        /// <summary>
        /// Gets or sets the version.
        /// </summary>
        /// <value>
        /// The version.
        /// </value>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Performance", "CA1819")]
        public byte[] Version { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="TypeItemView"/> class.
        /// </summary>
        public TypeItemView()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="TypeItemView" /> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        public TypeItemView(AdminTypeQueryItem entity)
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            this._entity = entity;
            this.TypeId = entity.TypeId;
            this.OrderSequence = entity.OrderSequence;
            this.Version = entity.Version;
        }
    }
}