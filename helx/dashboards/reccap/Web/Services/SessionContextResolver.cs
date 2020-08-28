using Microsoft.AspNetCore.Http;
using Renci.ReCCAP.Dashboard.Web.Common;
using Renci.ReCCAP.Dashboard.Web.Common.Security;
using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Text.Json;

namespace Renci.ReCCAP.Dashboard.Web.Services
{
    public class SessionContextResolver : ISessionContextResolver
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public Guid? CurrentUserId
        {
            get
            {
                var userId = this._httpContextAccessor.HttpContext?.User?.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return null;
                }
                return Guid.Parse(userId);
            }
        }

        public SessionContextResolver(IHttpContextAccessor httpContextAccessor)
        {
            this._httpContextAccessor = httpContextAccessor;
        }

        public string ResolveSessionContext()
        {
            //  TASK:   Update this logic for specific project

            var roles = this._httpContextAccessor.HttpContext?.User?.FindAll("roleIds");
            var permissions = this._httpContextAccessor.HttpContext?.User?.FindAll(PermissionConstants.PackedPermissionClaimType);

            return JsonSerializer.Serialize(new
            {
                userId = this.CurrentUserId,
                roles = roles?.Select(m => m.Value.DecodeFromUrlCode()),
                permissions = permissions?.Select(m => m.Value),
            });
        }
    }
}