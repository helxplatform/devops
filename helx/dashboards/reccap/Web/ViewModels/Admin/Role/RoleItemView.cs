using Renci.ReCCAP.Dashboard.Web.Data;
using System;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.Admin
{
    public class RoleItemView : BaseItemView
    {
        private readonly AdminRoleQueryItem _entity;

        /// <summary>
        /// Gets the identifier for the item.
        /// </summary>
        /// <value>
        /// The identifier.
        /// </value>
        public override Guid Id => this._entity.RoleId;

        /// <summary>
        /// Gets the display name for the item.
        /// </summary>
        /// <value>
        /// The display name.
        /// </value>
        public override string DisplayName => this._entity.Name;

        /// <summary>
        /// Gets or sets the modified date.
        /// </summary>
        /// <value>
        /// The modified date.
        /// </value>
        public DateTime ModifiedDate => this._entity.ModifiedDate;

        /// <summary>
        /// Initializes a new instance of the <see cref="RoleItemView"/> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        public RoleItemView(AdminRoleQueryItem entity)
        {
            this._entity = entity;
        }
    }
}