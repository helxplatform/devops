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
    public class RoleEditView : BaseEditView<ApplicationRole>
    {
        /// <summary>
        /// Gets or sets the role identifier.
        /// </summary>
        /// <value>
        /// The role identifier.
        /// </value>
        public Guid RoleId { get; set; }

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
        /// Gets or sets the users.
        /// </summary>
        /// <value>
        /// The users.
        /// </value>
        public IEnumerable<CommonInfo<Guid>> Users { get; set; } = new List<CommonInfo<Guid>>();

        /// <summary>
        /// Initializes a new instance of the <see cref="RoleEditView"/> class.
        /// </summary>
        public RoleEditView()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="RoleEditView" /> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        /// <param name="userManager">The user manager.</param>
        public RoleEditView(ApplicationRole entity, UserManager<ApplicationUser> userManager)
            : this()
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            if (userManager == null)
                throw new ArgumentNullException(nameof(userManager));

            this.RoleId = entity.Id;
            this.Name = entity.Name;
            this.Description = entity.Description;
            this.ConcurrencyStamp = entity.ConcurrencyStamp;
            this.Claims = entity.Claims.Select(m => new ClaimEditView(m)).ToList();

            var userids = entity.Users.Select(m => m.UserId);
            this.Users = userManager.Users.Where(m => userids.Contains(m.Id))
                .Select(m => new CommonInfo<Guid>(m.Id, m.DisplayName)).ToList();

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
        public override void ApplyChangesTo(ApplicationRole entity)
        {
            //  Set entity properties
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            entity.Name = this.Name;
            entity.Description = this.Description;
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
                    entity.Claims.Add(new IdentityRoleClaim<Guid>()
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

            this.UpdateCollection(entity.Users, this.Users, (item) => new IdentityUserRole<Guid>() { RoleId = entity.Id, UserId = item.Id });

            entity.Permissions = this.Permissions?.Select(m => m.Permission).ToList();
        }
    }
}