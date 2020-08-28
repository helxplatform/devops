namespace Renci.ReCCAP.Dashboard.Web.Models.Settings
{
    /// <summary>
    ///
    /// </summary>
    public class EmailSettings
    {
        /// <summary>
        /// Gets or sets the name of the sender.
        /// </summary>
        /// <value>
        /// The name of the sender.
        /// </value>
        public string SenderName { get; set; }

        /// <summary>
        /// Gets or sets the sender email.
        /// </summary>
        /// <value>
        /// The sender email.
        /// </value>
        public string SenderEmail { get; set; }

        /// <summary>
        /// Gets or sets the mail server.
        /// </summary>
        /// <value>
        /// The mail server.
        /// </value>
        public string MailServer { get; set; }

        /// <summary>
        /// Gets or sets the mail port.
        /// </summary>
        /// <value>
        /// The mail port.
        /// </value>
        public int MailPort { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether [mail secure].
        /// </summary>
        /// <value>
        ///   <c>true</c> if [mail secure]; otherwise, <c>false</c>.
        /// </value>
        public bool MailSecure { get; set; }

        /// <summary>
        /// Gets or sets the username.
        /// </summary>
        /// <value>
        /// The username.
        /// </value>
        public string Username { get; set; }

        /// <summary>
        /// Gets or sets the password.
        /// </summary>
        /// <value>
        /// The password.
        /// </value>
        public string Password { get; set; }

        /// <summary>
        /// Gets or sets the mail folder.
        /// </summary>
        /// <value>
        /// The mail folder.
        /// </value>
        public string MailFolder { get; set; }
    }
}