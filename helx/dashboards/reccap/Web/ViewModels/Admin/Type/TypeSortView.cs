using Renci.ReCCAP.Dashboard.Web.Data;
using Renci.ReCCAP.Dashboard.Web.Models.Enums;
using System;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.Admin
{
    public class TypeSortView
    {
        private readonly AdminTypeQueryItem _entity;

        /// <summary>
        /// Gets or sets the type identifier.
        /// </summary>
        /// <value>
        /// The type identifier.
        /// </value>
        public Guid TypeId { get; set; }

        /// <summary>
        /// Gets the name.
        /// </summary>
        /// <value>
        /// The name.
        /// </value>
        public string Name => this._entity.TypeName;

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
        /// Gets a value indicating whether this instance is active.
        /// </summary>
        /// <value>
        ///   <c>true</c> if this instance is active; otherwise, <c>false</c>.
        /// </value>
        public bool IsActive => this._entity.IsActive;

        /// <summary>
        /// Gets or sets the version.
        /// </summary>
        /// <value>
        /// The version.
        /// </value>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Performance", "CA1819")]
        public byte[] Version { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="TypeSortView"/> class.
        /// </summary>
        public TypeSortView()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="TypeSortView" /> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        public TypeSortView(AdminTypeQueryItem entity)
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