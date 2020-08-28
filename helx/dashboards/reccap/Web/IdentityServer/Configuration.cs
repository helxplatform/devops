using IdentityServer4.Models;
using System.Collections.Generic;

namespace Renci.ReCCAP.Dashboard.IdentityServer
{
    public static class Configuration
    {
        public static IEnumerable<IdentityResource> GetIdentityResources() =>
            new List<IdentityResource>
            {
                new IdentityResources.OpenId(),
                new IdentityResources.Profile(),
            };

        public static IEnumerable<ApiResource> GetApis() => new List<ApiResource> {
            new ApiResource("ApiOne"),
        };

        public static IEnumerable<Client> GetClients(string baseUrl) => new List<Client> {
            new Client
            {
                ClientId = "renci-reccap-dashboard",

                AllowedGrantTypes = GrantTypes.Code,

                RedirectUris = {
                    baseUrl
                },
                PostLogoutRedirectUris = {
                    baseUrl
                },

                AllowedScopes = {
                    IdentityServer4.IdentityServerConstants.StandardScopes.OpenId,
                    IdentityServer4.IdentityServerConstants.StandardScopes.Profile,
                    IdentityServer4.IdentityServerConstants.StandardScopes.OfflineAccess,
                },

                AllowAccessTokensViaBrowser = true,

                AllowOfflineAccess = true,

                RequireConsent = false,

                RequireClientSecret = false,

                RequirePkce = true,
            }
        };
    }
}