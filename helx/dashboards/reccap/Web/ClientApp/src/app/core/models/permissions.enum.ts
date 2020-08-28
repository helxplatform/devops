export enum Permissions {
  Administrator = 0xffff,

  ReportCanList = 0x0001,
  ReportCanRead = 0x0002,
  ReportCanExecute = 0x0003,

  AdminUserCanList = 0x0101,
  AdminUserCanRead = 0x0102,
  AdminUserCanUpdate = 0x0103,
  AdminUserCanDelete = 0x0104,

  AdminRoleCanList = 0x0111,
  AdminRoleCanRead = 0x0112,
  AdminRoleCanUpdate = 0x0113,
  AdminRoleCanDelete = 0x0114,
  AdminRoleCanCreate = 0x0115,

  AdminTypeCanList = 0x0121,
  AdminTypeCanRead = 0x0122,
  AdminTypeCanUpdate = 0x0123,
  AdminTypeCanDelete = 0x0124,
  AdminTypeCanCreate = 0x0125,

  AdminReportCanList = 0x0131,
  AdminReportCanRead = 0x0132,
  AdminReportCanUpdate = 0x0133,
  AdminReportCanDelete = 0x0134,
  AdminReportCanCreate = 0x0135,
}
