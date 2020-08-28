namespace Renci.ReCCAP.Dashboard.Web.ViewModels.Admin
{
    /// <summary>
    /// Represent roles search criteria.
    /// </summary>
    /// <seealso cref="Renci.Dashboard.Web.ViewModels.BaseSearchView" />
    public class RoleSearchView : BaseSearchView
    {
        /// <summary>
        /// The default sort
        /// </summary>
        public static string DefaultSort = "Name";

        /// <summary>
        /// Initializes a new instance of the <see cref="RoleSearchView"/> class.
        /// </summary>
        public RoleSearchView()
            : base(RoleSearchView.DefaultSort)
        {
        }
    }
}