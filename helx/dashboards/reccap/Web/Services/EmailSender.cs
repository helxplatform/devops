using MailKit.Net.Smtp;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Options;
using MimeKit;
using MimeKit.Text;
using Renci.ReCCAP.Dashboard.Web.Models.Settings;
using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Renci.ReCCAP.Dashboard.Web.Services
{
    public class EmailSender : IEmailSender
    {
        private readonly EmailSettings _emailSettings;
        private readonly IWebHostEnvironment _env;

        public EmailSender(
            IOptions<EmailSettings> emailSettings,
            IWebHostEnvironment env)
        {
            _emailSettings = emailSettings.Value;
            _env = env;
        }

        public async Task SendEmailAsync(string subject, string message, params string[] emails)
        {
            if (emails == null)
                throw new ArgumentNullException(nameof(emails));

            var emailMessage = new MimeMessage();
            emailMessage.From.Add(new MailboxAddress(this._emailSettings.SenderName, this._emailSettings.SenderEmail));
            emailMessage.To.AddRange(emails.Select(m => new MailboxAddress(m)));
            emailMessage.Date = DateTime.Now;
            emailMessage.Subject = subject;
            emailMessage.Body = new TextPart(TextFormat.Html)
            {
                Text = message
            };

            if (string.IsNullOrEmpty(this._emailSettings.MailFolder))
            {
                using var client = new SmtpClient()
                {
                    ServerCertificateValidationCallback = (s, c, h, e) => true
                };
                await client.ConnectAsync(this._emailSettings.MailServer, this._emailSettings.MailPort, this._emailSettings.MailSecure);

                if (!string.IsNullOrEmpty(this._emailSettings.Username) && !string.IsNullOrEmpty(this._emailSettings.Password))
                {
                    await client.AuthenticateAsync(Encoding.ASCII, this._emailSettings.Username, this._emailSettings.Password);
                }

                await client.SendAsync(emailMessage);
                await client.DisconnectAsync(true);
            }
            else
            {
                await Task.Run(() =>
                {
                    var path = $"{Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location)}\\{this._emailSettings.MailFolder}";
                    Directory.CreateDirectory(path);
                    using StreamWriter data = System.IO.File.CreateText($"{path}\\email.{Guid.NewGuid()}.eml");
                    emailMessage.WriteTo(data.BaseStream);
                });
            }
        }
    }
}