using System.ComponentModel.DataAnnotations;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels.IdentityServer
{
    public class ForgotPasswordViewModel
    {
        /// <summary>
        /// Gets or sets the username.
        /// </summary>
        /// <value>
        /// The username.
        /// </value>
        [Required]
        [StringLength(256, ErrorMessage = "The {0} must be at least {2} characters long.")]
        public string Username { get; set; }
    }
}