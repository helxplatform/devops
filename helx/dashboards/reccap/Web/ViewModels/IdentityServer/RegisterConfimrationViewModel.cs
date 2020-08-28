using System.ComponentModel.DataAnnotations;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.IdentityServer
{
    public class RegisterConfimrationViewModel
    {
        /// <summary>
        /// Gets or sets the username.
        /// </summary>
        /// <value>
        /// The username.
        /// </value>
        [Required]
        public string Username { get; set; }

        /// <summary>
        /// Gets or sets the email.
        /// </summary>
        /// <value>
        /// The email.
        /// </value>
        [Required]
        public string Code { get; set; }
    }
}