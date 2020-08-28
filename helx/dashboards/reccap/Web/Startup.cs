using IdentityServer4.AccessTokenValidation;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc.Razor;
using Microsoft.AspNetCore.Routing;
using Microsoft.AspNetCore.SpaServices.AngularCli;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Renci.ReCCAP.Dashboard.Web.Common;
using Renci.ReCCAP.Dashboard.Web.Common.Converters;
using Renci.ReCCAP.Dashboard.Web.Common.Security;
using Renci.ReCCAP.Dashboard.Web.Data;
using Renci.ReCCAP.Dashboard.Web.IdentityServer;
using Renci.ReCCAP.Dashboard.Web.Models.Settings;
using Renci.ReCCAP.Dashboard.Web.Services;
using System;
using System.IO;
using System.Reflection;
using System.Security.Cryptography.X509Certificates;

namespace Renci.ReCCAP.Dashboard.Web
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        public void ConfigureServices(IServiceCollection services)
        {
            var connectionString = Configuration.GetConnectionString("DefaultConnection");

            services.Configure<RedcapSettings>(Configuration.GetSection("RedcapSettings"));
            services.Configure<EmailSettings>(Configuration.GetSection("EmailSettings"));
            services.Configure<IdentityOptions>(Configuration.GetSection("IdentityOptions"));
            services.Configure<IdentityServerAuthenticationOptions>(Configuration.GetSection("IdentityServer"));

            services.AddSingleton<IAuthorizationPolicyProvider, AuthorizationPolicyProvider>();
            services.AddSingleton<IAuthorizationHandler, PermissionHandler>();
            services.AddSingleton<IEmailSender, EmailSender>();
            services.AddSingleton<IHttpContextAccessor, HttpContextAccessor>();
            services.AddSingleton<ISessionContextResolver, SessionContextResolver>();

            services
                .AddEntityFrameworkSqlServer()
                .AddDbContext<ApplicationDbContext>((sp, options) =>
                {
                    var sessionContextResolver = sp.GetRequiredService<ISessionContextResolver>();
                    options
                    .UseSqlServer(connectionString)
                    .AddInterceptors(new UserConnectionInterceptor(sessionContextResolver))
                    .UseInternalServiceProvider(sp)
                    .UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking)
                    .ConfigureWarnings(x => x.Ignore(RelationalEventId.AmbientTransactionWarning));
                });

            services.AddIdentity<ApplicationUser, ApplicationRole>()
                .AddEntityFrameworkStores<ApplicationDbContext>()
                .AddDefaultTokenProviders();

            services
                .AddAuthentication(IdentityServerAuthenticationDefaults.AuthenticationScheme)
                .AddIdentityServerAuthentication(options =>
                {
                    // base-address of your identityserver
                    options.Authority = Configuration["IdentityServer:Authority"];
                });

            services
                .ConfigureApplicationCookie(config =>
                {
                    config.Cookie.Name = "Renci.ReCCAP.Dashboard.Cookie";
                    config.LoginPath = "/login";
                    config.LogoutPath = "/logout";
                    config.AccessDeniedPath = "/access-denied";
                });

            var migrationsAssembly = typeof(Startup).GetTypeInfo().Assembly.GetName().Name;

            services.AddIdentityServer()
                .AddAspNetIdentity<ApplicationUser>()
                .AddOperationalStore(options =>
                {
                    //options.ConfigureDbContext = b => b.UseSqlServer(connectionString,
                    //sql => sql.MigrationsAssembly(migrationsAssembly));

                    // this enables automatic token cleanup. this is optional.
                    options.EnableTokenCleanup = true;
                })
                .AddInMemoryIdentityResources(Dashboard.IdentityServer.Configuration.GetIdentityResources())
                .AddInMemoryClients(Dashboard.IdentityServer.Configuration.GetClients(Configuration["IdentityServer:Authority"]))
                .AddProfileService<ProfileService>()
                .AddSigningCredential(this.GetCertificate());

            //services
            //    .AddDataProtection()
            //    .PersistKeysToDbContext<ApplicationDbContext>()
            //    .SetDefaultKeyLifetime(TimeSpan.FromDays(7))
            //    .SetApplicationName("dashboard-app")
            //    .UseCryptographicAlgorithms(new AuthenticatedEncryptorConfiguration()
            //    {
            //        EncryptionAlgorithm = EncryptionAlgorithm.AES_256_CBC,
            //        ValidationAlgorithm = ValidationAlgorithm.HMACSHA256
            //    });

            services.AddResponseCaching();

            services
                .AddControllers(options =>
                {
                    options.Filters.Add(typeof(ApplicationExceptionFilter));
                    options.ReturnHttpNotAcceptable = true;
                    options.ModelBinderProviders.Insert(0, new GuidUrlBinderProvider());
                    options.RespectBrowserAcceptHeader = true;
                })
                .AddJsonOptions(options =>
                {
                    options.JsonSerializerOptions.WriteIndented = true;
                    options.JsonSerializerOptions.Converters.Add(new GuidUrlConverter());
                    options.JsonSerializerOptions.Converters.Add(new GuidUrlNullableConverter());
                });

            services.AddHttpsRedirection(options =>
            {
                options.RedirectStatusCode = StatusCodes.Status301MovedPermanently;
            });

            services.AddRazorPages();

            services.Configure<RouteOptions>(routeOptions =>
            {
                routeOptions.ConstraintMap.Add("guidurl", typeof(GuidUrlConstraint));
            });

            services.AddSignalR();

            // In production, the Angular files will be served from this directory
            services.AddSpaStaticFiles(configuration =>
            {
                configuration.RootPath = "ClientApp/dist";
            });

            services.AddApiVersioning();

            services.AddAntiforgery(options => options.HeaderName = "X-XSRF-TOKEN");

            services.Configure<RazorViewEngineOptions>(o =>
            {
                o.ViewLocationFormats.Add("/Templates/{1}/{0}" + RazorViewEngine.ViewExtension);
            });
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env, IAntiforgery antiforgery)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseExceptionHandler("/Error");
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
            }

            app.UseHttpsRedirection();

            app.UseResponseCaching();

            app.UseStaticFiles();

            app.UseCookiePolicy();

            if (!env.IsDevelopment())
            {
                app.UseSpaStaticFiles();
            }

            app.UseRouting();

            app.UseIdentityServer();

            app.UseAuthorization();

            app.Use(async (context, next) =>
            {
                //  Add XSRF-TOKEN cookie
                if (context.Request.Path.HasValue &&
            context.Request.Path.Value.StartsWith("/api", StringComparison.Ordinal))
                {
                    var tokens = antiforgery.GetAndStoreTokens(context);
                    context.Response.Cookies.Append("XSRF-TOKEN", tokens.RequestToken,
                        new CookieOptions()
                        {
                            HttpOnly = false,
                            Secure = true,
                        });
                }

                await next();
            });

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapDefaultControllerRoute();
            });

            app.UseSpa(spa =>
            {
                // To learn more about options for serving an Angular SPA from ASP.NET Core,
                // see https://go.microsoft.com/fwlink/?linkid=864501

                spa.Options.SourcePath = "ClientApp";

                if (env.IsDevelopment())
                {
                    spa.UseAngularCliServer(npmScript: "start");
                }
            });
        }

        private X509Certificate2 GetCertificate()
        {
            //  TASK:   Update certificate
            var assembly = typeof(ApiControllerBase).GetTypeInfo().Assembly;
            var resourceName = $"Renci.ReCCAP.Dashboard.Web.rsaCert.pfx";
            using var stream = assembly.GetManifestResourceStream(resourceName);
            using var reader = new StreamReader(stream);
            using (var memstream = new MemoryStream())
            {
                reader.BaseStream.CopyTo(memstream);
                return new X509Certificate2(memstream.ToArray(), "1234");
            }
        }
    }
}