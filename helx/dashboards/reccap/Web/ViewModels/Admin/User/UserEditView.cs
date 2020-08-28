using Microsoft.AspNetCore.Identity;
using Renci.ReCCAP.Dashboard.Web.Data;
using Renci.ReCCAP.Dashboard.Web.Models;
using Renci.ReCCAP.Dashboard.Web.Models.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Reflection;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.Admin
{
    /// <summary>
    ///
    /// </summary>
    /// <seealso cref="Renci.Dashboard.Web.ViewModels.BaseEditView{T}" />
    public class UserEditView : BaseEditView<ApplicationUser>
    {
        /// <summary>
        /// Gets or sets the user identifier.
        /// </summary>
        /// <value>
        /// The user identifier.
        /// </value>
        public Guid UserId { get; set; }

        /// <summary>
        /// Gets or sets the name of the user.
        /// </summary>
        /// <value>
        /// The name of the user.
        /// </value>
        public string UserName { get; set; }

        /// <summary>
        /// Gets or sets the display name.
        /// </summary>
        /// <value>
        /// The display name.
        /// </value>
        [Required]
        [StringLength(255, ErrorMessage = "The '{0}' must be maximum {1} characters long.")]
        public string DisplayName { get; set; }

        /// <summary>
        /// Gets or sets the email.
        /// </summary>
        /// <value>
        /// The email.
        /// </value>
        public string Email { get; set; }

        /// <summary>
        /// Gets or sets the concurrency stamp.
        /// </summary>
        /// <value>
        /// The concurrency stamp.
        /// </value>
        public string ConcurrencyStamp { get; set; }

        /// <summary>
        /// Gets or sets the permissions.
        /// </summary>
        /// <value>
        /// The permissions.
        /// </value>
        public IEnumerable<PermissionInfo> Permissions { get; } = new List<PermissionInfo>();

        /// <summary>
        /// Gets or sets the claims.
        /// </summary>
        /// <value>
        /// The claims.
        /// </value>
        public IEnumerable<ClaimEditView> Claims { get; } = new List<ClaimEditView>();

        /// <summary>
        /// Gets or sets the roles.
        /// </summary>
        /// <value>
        /// The roles.
        /// </value>
        public IEnumerable<CommonInfo<Guid>> Roles { get; set; } = new List<CommonInfo<Guid>>();

        /// <summary>
        /// Initializes a new instance of the <see cref="UserEditView"/> class.
        /// </summary>
        public UserEditView()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="UserEditView" /> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        /// <param name="roleManager">The role manager.</param>
        public UserEditView(ApplicationUser entity, RoleManager<ApplicationRole> roleManager)
            : this()
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            if (roleManager == null)
                throw new ArgumentNullException(nameof(roleManager));

            this.UserId = entity.Id;
            this.UserName = entity.UserName;
            this.DisplayName = entity.DisplayName;
            this.Email = entity.Email;
            this.ConcurrencyStamp = entity.ConcurrencyStamp;
            this.Claims = entity.Claims.Select(m => new ClaimEditView(m)).ToList();

            var roleIds = entity.Roles.Select(m => m.RoleId);
            this.Roles = roleManager.Roles.Where(m => roleIds.Contains(m.Id))
                .Select(m => new CommonInfo<Guid>(m.Id, m.Name)).ToList();

            if (entity.Permissions != null)
            {
                var enumType = typeof(Permission);
                this.Permissions = from permission in entity.Permissions
                                   let permissionName = Enum.GetName(enumType, permission)
                                   where permissionName != null
                                   let member = enumType.GetMember(permissionName)
                                   let displayAttribute = member[0].GetCustomAttribute<DisplayAttribute>()
                                   select new PermissionInfo()
                                   {
                                       Permission = permission,
                                       Name = displayAttribute.Name,
                                       GroupName = displayAttribute.GroupName,
                                       Description = displayAttribute.Description
                                   };
            }
        }

        /// <summary>
        /// Applies the changes to the entity.
        /// </summary>
        /// <param name="entity">The entity to apply changes to.</param>
        public override void ApplyChangesTo(ApplicationUser entity)
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            //  Set entity properties
            entity.DisplayName = this.DisplayName;
            entity.Email = this.Email;
            entity.ConcurrencyStamp = this.ConcurrencyStamp;

            foreach (var item in entity.Claims.Where(m => !this.Claims.Where(e => e.Id == m.Id).Any()).ToList())
            {
                entity.Claims.Remove(item);
            }
            foreach (var item in this.Claims)
            {
                var itemEntity = entity.Claims.Where(m => m.Id == item.Id).SingleOrDefault();
                if (itemEntity == null)
                {
                    entity.Claims.Add(new IdentityUserClaim<Guid>()
                    {
                        ClaimType = item.ClaimType,
                        ClaimValue = item.ClaimValue
                    });
                }
                else
                {
                    itemEntity.ClaimType = item.ClaimType;
                    itemEntity.ClaimValue = item.ClaimValue;
                }
            }

            this.UpdateCollection(entity.Roles, this.Roles, (item) => new IdentityUserRole<Guid>() { RoleId = item.Id, UserId = entity.Id });

            entity.Permissions = this.Permissions?.Select(m => m.Permission).ToList();
        }
    }
}