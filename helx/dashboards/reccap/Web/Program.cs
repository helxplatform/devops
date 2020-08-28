using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Serilog;
using System.IO;
using System.Net;
using System.Reflection;
using System.Security.Cryptography.X509Certificates;

namespace Renci.ReCCAP.Dashboard.Web
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args)
                .ConfigureLogging((ctx, logging) =>
                {
                    Log.Logger = new LoggerConfiguration()
                    .ReadFrom.Configuration(ctx.Configuration)
                    .CreateLogger();
                })
                .Build()
                .Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureAppConfiguration((hostingContext, config) =>
                {
                    config.AddEnvironmentVariables(prefix: "RECCAP_");
                })
                .UseSerilog()
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.ConfigureKestrel(serverOptions =>
                    {
                        serverOptions.Listen(IPAddress.Any, 80);
                        serverOptions.Listen(IPAddress.Any, 443,
                            listenOptions =>
                            {
                                listenOptions.UseHttps(GetCertificate());
                            });
                    });
                    webBuilder.UseStartup<Startup>();
                });

        private static X509Certificate2 GetCertificate()
        {
            //  TASK:   Update certificate
            var assembly = typeof(Program).GetTypeInfo().Assembly;
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