using IdentityServer4.Models;
using IdentityServer4.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Renci.ReCCAP.Dashboard.Web.Common;
using Renci.ReCCAP.Dashboard.Web.Common.Security;
using Renci.ReCCAP.Dashboard.Web.Data;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

namespace Renci.ReCCAP.Dashboard.Web.IdentityServer
{
    public class ProfileService : IProfileService
    {
        protected UserManager<ApplicationUser> _userManager;
        private readonly ApplicationDbContext _dbContext;

        public ProfileService(UserManager<ApplicationUser> userManager, ApplicationDbContext dbContext)
        {
            _userManager = userManager;
            _dbContext = dbContext;
        }

        public async Task GetProfileDataAsync(ProfileDataRequestContext context)
        {
            var user = await _userManager.GetUserAsync(context.Subject);

            context.IssuedClaims.Add(new Claim("displayName", user.DisplayName, ClaimValueTypes.String));

            var roles = await (from r in this._dbContext.Roles
                               from ur in r.Users
                               where r.Id == ur.RoleId && ur.UserId == user.Id
                               select r).ToListAsync();

            var userPermissions = roles.Where(m => m.Permissions != null)
                .SelectMany(m => m.Permissions)
                .ToList();

            if (user.Permissions != null)
            {
                userPermissions.AddRange(user.Permissions);
            }

            userPermissions
                .Distinct()
                .ToList()
                .ForEach(m => context.IssuedClaims.Add(new Claim(PermissionConstants.PackedPermissionClaimType, ((int)m).ToString(CultureInfo.InvariantCulture), ClaimValueTypes.Integer32)));

            roles.ForEach(m =>
                context.IssuedClaims.Add(new Claim("roleId", m.Id.EncodeToUrlCode(), ClaimValueTypes.String))
            );
        }

        public async Task IsActiveAsync(IsActiveContext context)
        {
            var user = await _userManager.GetUserAsync(context.Subject);

            context.IsActive = (user != null);
        }
    }
}