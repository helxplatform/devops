using System.ComponentModel.DataAnnotations;

namespace Renci.ReCCAP.Dashboard.Web.Models.Enums
{
    public enum Permission
    {
        /// <summary>
        /// The is administrator
        /// </summary>
        [Display(GroupName = "Admin", Name = "System Administrator", Description = "zzz")]
        Administrator = 0xFFFF,

        #region Common

        /// <summary>
        /// The report can list
        /// </summary>
        [Display(GroupName = "Common", Name = "ReportCanList", Description = "zzz")]
        ReportCanList = 0x0001,

        /// <summary>
        /// The report can read
        /// </summary>
        [Display(GroupName = "Common", Name = "ReportCanRead", Description = "zzz")]
        ReportCanRead = 0x0002,

        /// <summary>
        /// The report can execute
        /// </summary>
        [Display(GroupName = "Common", Name = "ReportCanExecute", Description = "zzz")]
        ReportCanExecute = 0x0003,

        #endregion Common

        #region Admin

        /// <summary>
        /// The admin user can list
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminUserCanList", Description = "Can list users")]
        AdminUserCanList = 0x0101,

        /// <summary>
        /// The admin user can read
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminUserCanRead", Description = "Can read users")]
        AdminUserCanRead = 0x0102,

        /// <summary>
        /// The admin user can write
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminUserCanUpdate", Description = "Can update users")]
        AdminUserCanUpdate = 0x0103,

        /// <summary>
        /// The admin user can delete
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminUserCanDelete", Description = "Can delete users")]
        AdminUserCanDelete = 0x0104,

        /// <summary>
        /// The admin role can list
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminRoleCanList", Description = "zzz")]
        AdminRoleCanList = 0x0111,

        /// <summary>
        /// The admin role can read
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminRoleCanRead", Description = "zzz")]
        AdminRoleCanRead = 0x0112,

        /// <summary>
        /// The admin role can write
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminRoleCanUpdate", Description = "zzz")]
        AdminRoleCanUpdate = 0x0113,

        /// <summary>
        /// The admin role can delete
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminRoleCanDelete", Description = "zzz")]
        AdminRoleCanDelete = 0x0114,

        /// <summary>
        /// The admin role can create
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminRoleCanCreate", Description = "zzz")]
        AdminRoleCanCreate = 0x0115,

        /// <summary>
        /// The admin type can list
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminTypeCanList", Description = "zzz")]
        AdminTypeCanList = 0x0121,

        /// <summary>
        /// The admin type can read
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminTypeCanRead", Description = "zzz")]
        AdminTypeCanRead = 0x0122,

        /// <summary>
        /// The admin type can write
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminTypeCanUpdate", Description = "zzz")]
        AdminTypeCanUpdate = 0x0123,

        /// <summary>
        /// The admin type can delete
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminTypeCanDelete", Description = "zzz")]
        AdminTypeCanDelete = 0x0124,

        /// <summary>
        /// The admin type can create
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminTypeCanCreate", Description = "zzz")]
        AdminTypeCanCreate = 0x0125,

        /// <summary>
        /// The admin report can list
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminReportCanList", Description = "zzz")]
        AdminReportCanList = 0x0131,

        /// <summary>
        /// The admin report can read
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminReportCanRead", Description = "zzz")]
        AdminReportCanRead = 0x0132,

        /// <summary>
        /// The admin report can write
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminReportCanUpdate", Description = "zzz")]
        AdminReportCanUpdate = 0x0133,

        /// <summary>
        /// The admin report can delete
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminReportCanDelete", Description = "zzz")]
        AdminReportCanDelete = 0x0134,

        /// <summary>
        /// The admin report can create
        /// </summary>
        [Display(GroupName = "Admin", Name = "AdminReportCanCreate", Description = "zzz")]
        AdminReportCanCreate = 0x0135,

        #endregion Admin
    }
}