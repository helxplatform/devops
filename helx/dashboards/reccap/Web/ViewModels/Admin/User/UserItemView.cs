using Renci.ReCCAP.Dashboard.Web.Data;
using System;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.Admin
{
    /// <summary>
    ///
    /// </summary>
    public class UserItemView : BaseItemView
    {
        private readonly AdminUserQueryItem _entity;

        /// <summary>
        /// Gets the identifier for the item.
        /// </summary>
        /// <value>
        /// The identifier.
        /// </value>
        public override Guid Id => this._entity.UserId;

        /// <summary>
        /// Gets the display name for the item.
        /// </summary>
        /// <value>
        /// The display name.
        /// </value>
        public override string DisplayName => this._entity.DisplayName;

        /// <summary>
        /// Gets or sets the email.
        /// </summary>
        /// <value>
        /// The email.
        /// </value>
        public string Email => this._entity.Email;

        /// <summary>
        /// Gets or sets a value indicating whether this instance is disabled.
        /// </summary>
        /// <value>
        ///   <c>true</c> if this instance is disabled; otherwise, <c>false</c>.
        /// </value>
        public bool IsDisabled => this._entity.LockoutEnd != null && this._entity.LockoutEnd > DateTime.Now;

        /// <summary>
        /// Gets the create date.
        /// </summary>
        /// <value>
        /// The create date.
        /// </value>
        public DateTime CreateDate => this._entity.CreatedDate;

        /// <summary>
        /// Gets the last login.
        /// </summary>
        /// <value>
        /// The last login.
        /// </value>
        public DateTime? LastLogin => this._entity.LastLogin;

        /// <summary>
        /// Initializes a new instance of the <see cref="UserItemView"/> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        public UserItemView(AdminUserQueryItem entity)
        {
            this._entity = entity;
        }
    }
}