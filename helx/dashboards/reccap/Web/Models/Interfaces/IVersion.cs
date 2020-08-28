namespace Renci.ReCCAP.Dashboard.Web.Models.Interfaces
{
    /// <summary>
    ///
    /// </summary>
    public interface IVersion
    {
        /// <summary>
        /// Gets or sets entity version.
        /// </summary>
        /// <value>
        /// The version.
        /// </value>
        byte[] Version { get; set; }
    }
}