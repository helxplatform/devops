namespace Renci.ReCCAP.Dashboard.Web.ViewModels.Admin
{
    /// <summary>
    /// Represent users search criteria.
    /// </summary>
    /// <seealso cref="Renci.Dashboard.Web.ViewModels.BaseSearchView" />
    public class UserSearchView : BaseSearchView
    {
        /// <summary>
        /// The default sort
        /// </summary>
        public static string DefaultSort = "Username";

        /// <summary>
        /// Initializes a new instance of the <see cref="UserSearchView"/> class.
        /// </summary>
        public UserSearchView()
            : base(UserSearchView.DefaultSort)
        {
        }
    }
}