using Microsoft.AspNetCore.Mvc;
using Renci.ReCCAP.Dashboard.Web.Models.Enums;
using System;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.Admin
{
    /// <summary>
    /// Represent types search criteria.
    /// </summary>
    /// <seealso cref="Renci.Dashboard.Web.ViewModels.BaseSearchView" />
    public class TypeSearchView : BaseSearchView
    {
        /// <summary>
        /// The default sort
        /// </summary>
        public static string DefaultSort = "OrderSequence, TypeName";

        /// <summary>
        /// Gets or sets the category.
        /// </summary>
        /// <value>
        /// The category.
        /// </value>
        [FromQuery(Name = "category")]
        public CategoryName Category { get; set; }

        /// <summary>
        /// Gets or sets the parent.
        /// </summary>
        /// <value>
        /// The parent.
        /// </value>
        [FromQuery(Name = "parent")]
        public Guid? ParentId { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="TypeSearchView"/> class.
        /// </summary>
        public TypeSearchView()
            : base(TypeSearchView.DefaultSort)
        {
        }
    }
}