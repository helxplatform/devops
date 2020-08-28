using Renci.ReCCAP.Dashboard.Web.Models.Enums;
using Renci.ReCCAP.Dashboard.Web.Models.Interfaces;
using System;
using System.Collections.Generic;

namespace Renci.ReCCAP.Dashboard.Web.Data
{
    public partial class Type : ITrackable, IVersion
    {
        /// <summary>
        /// Gets or sets the type identifier.
        /// </summary>
        /// <value>
        /// The type identifier.
        /// </value>
        public Guid TypeId { get; set; }

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
        /// The code.
        /// </value>
        public string Code { get; set; }

        /// <summary>
        /// Gets or sets the name.
        /// </summary>
        /// <value>
        /// The name.
        /// </value>
        public string Name { get; set; }

        /// <summary>
        /// Gets or sets the order sequence.
        /// </summary>
        /// <value>
        /// The order sequence.
        /// </value>
        public int OrderSequence { get; set; }

        /// <summary>
        /// Gets or sets the category.
        /// </summary>
        /// <value>
        /// The category.
        /// </value>
        public CategoryName Category { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether this instance is active.
        /// </summary>
        /// <value>
        ///   <c>true</c> if this instance is active; otherwise, <c>false</c>.
        /// </value>
        public bool IsActive { get; set; }

        /// <summary>
        /// Gets or sets the created user identifier.
        /// </summary>
        /// <value>
        /// The created user identifier.
        /// </value>
        public Guid CreatedUserId { get; set; }

        /// <summary>
        /// Gets or sets the created date.
        /// </summary>
        /// <value>
        /// The created date.
        /// </value>
        public DateTime CreatedDate { get; set; }

        /// <summary>
        /// Gets or sets the modified user identifier.
        /// </summary>
        /// <value>
        /// The modified user identifier.
        /// </value>
        public Guid? ModifiedUserId { get; set; }

        /// <summary>
        /// Gets or sets the modified date.
        /// </summary>
        /// <value>
        /// The modified date.
        /// </value>
        public DateTime? ModifiedDate { get; set; }

        /// <summary>
        /// Gets or sets entity version.
        /// </summary>
        /// <value>
        /// The version.
        /// </value>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Performance", "CA1819")]
        public byte[] Version { get; set; }

        /// <summary>
        /// Gets or sets the name seo.
        /// </summary>
        /// <value>
        /// The name seo.
        /// </value>
        public string NameSEO { get; set; }

        /// <summary>
        /// Gets or sets the type of the parent.
        /// </summary>
        /// <value>
        /// The type of the parent.
        /// </value>
        public virtual Type ParentType { get; set; }

        /// <summary>
        /// Gets or sets the created user.
        /// </summary>
        /// <value>
        /// The created user.
        /// </value>
        public virtual ApplicationUser CreatedUser { get; set; }

        /// <summary>
        /// Gets or sets the modified user.
        /// </summary>
        /// <value>
        /// The modified user.
        /// </value>
        public virtual ApplicationUser ModifiedUser { get; set; }

        /// <summary>
        /// Gets or sets the roles.
        /// </summary>
        /// <value>
        /// The roles.
        /// </value>
        public ICollection<TypeRole> Roles { get; } = new List<TypeRole>();
    }
}