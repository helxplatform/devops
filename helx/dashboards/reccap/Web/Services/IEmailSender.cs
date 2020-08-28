using System.Threading.Tasks;

namespace Renci.ReCCAP.Dashboard.Web.Services
{
    public interface IEmailSender
    {
        Task SendEmailAsync(string subject, string message, params string[] email);
    }
}