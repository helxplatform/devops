using Microsoft.EntityFrameworkCore.Migrations;
using System;

namespace Renci.ReCCAP.Dashboard.Web.Data.Migrations.ApplicationDb
{
    public partial class Initial : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "Report");

            migrationBuilder.EnsureSchema(
                name: "Common");

            migrationBuilder.CreateTable(
                name: "AspNetUsers",
                columns: table => new
                {
                    Id = table.Column<Guid>(nullable: false),
                    UserName = table.Column<string>(maxLength: 256, nullable: true),
                    NormalizedUserName = table.Column<string>(maxLength: 256, nullable: true),
                    Email = table.Column<string>(maxLength: 256, nullable: true),
                    NormalizedEmail = table.Column<string>(maxLength: 256, nullable: true),
                    EmailConfirmed = table.Column<bool>(nullable: false),
                    PasswordHash = table.Column<string>(nullable: true),
                    SecurityStamp = table.Column<string>(nullable: true),
                    ConcurrencyStamp = table.Column<string>(nullable: true),
                    PhoneNumber = table.Column<string>(nullable: true),
                    PhoneNumberConfirmed = table.Column<bool>(nullable: false),
                    TwoFactorEnabled = table.Column<bool>(nullable: false),
                    LockoutEnd = table.Column<DateTimeOffset>(nullable: true),
                    LockoutEnabled = table.Column<bool>(nullable: false),
                    AccessFailedCount = table.Column<int>(nullable: false),
                    DisplayName = table.Column<string>(maxLength: 256, nullable: false),
                    CreatedDate = table.Column<DateTime>(nullable: false, defaultValueSql: "getdate()"),
                    LastLogin = table.Column<DateTime>(nullable: true),
                    Permissions = table.Column<string>(nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUsers", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "DataProtectionKeys",
                columns: table => new
                {
                    Id = table.Column<int>(nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FriendlyName = table.Column<string>(nullable: true),
                    Xml = table.Column<string>(nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DataProtectionKeys", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "AspNetRoles",
                columns: table => new
                {
                    Id = table.Column<Guid>(nullable: false),
                    Name = table.Column<string>(maxLength: 256, nullable: true),
                    NormalizedName = table.Column<string>(maxLength: 256, nullable: true),
                    ConcurrencyStamp = table.Column<string>(nullable: true),
                    Description = table.Column<string>(nullable: true),
                    Permissions = table.Column<string>(nullable: true),
                    CreatedUserId = table.Column<Guid>(nullable: false),
                    CreatedDate = table.Column<DateTime>(nullable: false, defaultValueSql: "getdate()"),
                    ModifiedUserId = table.Column<Guid>(nullable: true),
                    ModifiedDate = table.Column<DateTime>(nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetRoles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Role_CreatedUser",
                        column: x => x.CreatedUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Role_ModifiedUser",
                        column: x => x.ModifiedUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "AspNetUserClaims",
                columns: table => new
                {
                    Id = table.Column<int>(nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<Guid>(nullable: false),
                    ClaimType = table.Column<string>(nullable: true),
                    ClaimValue = table.Column<string>(nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUserClaims", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserClaim_User",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AspNetUserLogins",
                columns: table => new
                {
                    LoginProvider = table.Column<string>(nullable: false),
                    ProviderKey = table.Column<string>(nullable: false),
                    ProviderDisplayName = table.Column<string>(nullable: true),
                    UserId = table.Column<Guid>(nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUserLogins", x => new { x.LoginProvider, x.ProviderKey });
                    table.ForeignKey(
                        name: "FK_UserLogin_User",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AspNetUserTokens",
                columns: table => new
                {
                    UserId = table.Column<Guid>(nullable: false),
                    LoginProvider = table.Column<string>(nullable: false),
                    Name = table.Column<string>(nullable: false),
                    Value = table.Column<string>(nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUserTokens", x => new { x.UserId, x.LoginProvider, x.Name });
                    table.ForeignKey(
                        name: "FK_AspNetUserTokens_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Type",
                schema: "Common",
                columns: table => new
                {
                    TypeId = table.Column<Guid>(nullable: false),
                    ParentTypeId = table.Column<Guid>(nullable: true),
                    Code = table.Column<string>(maxLength: 32, nullable: true),
                    Name = table.Column<string>(maxLength: 256, nullable: false),
                    OrderSequence = table.Column<int>(nullable: false),
                    Category = table.Column<string>(nullable: false),
                    IsActive = table.Column<bool>(nullable: false),
                    CreatedUserId = table.Column<Guid>(nullable: false),
                    CreatedDate = table.Column<DateTime>(nullable: false, defaultValueSql: "getdate()"),
                    ModifiedUserId = table.Column<Guid>(nullable: true),
                    ModifiedDate = table.Column<DateTime>(nullable: true),
                    Version = table.Column<byte[]>(rowVersion: true, nullable: true),
                    NameSEO = table.Column<string>(maxLength: 256, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Type", x => x.TypeId);
                    table.ForeignKey(
                        name: "FK_Type_CreatedUser",
                        column: x => x.CreatedUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Type_ModifiedUser",
                        column: x => x.ModifiedUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Type_ParentType",
                        column: x => x.ParentTypeId,
                        principalSchema: "Common",
                        principalTable: "Type",
                        principalColumn: "TypeId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "AspNetRoleClaims",
                columns: table => new
                {
                    Id = table.Column<int>(nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    RoleId = table.Column<Guid>(nullable: false),
                    ClaimType = table.Column<string>(nullable: true),
                    ClaimValue = table.Column<string>(nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetRoleClaims", x => x.Id);
                    table.ForeignKey(
                        name: "FK_RoleClaim_Role",
                        column: x => x.RoleId,
                        principalTable: "AspNetRoles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AspNetUserRoles",
                columns: table => new
                {
                    UserId = table.Column<Guid>(nullable: false),
                    RoleId = table.Column<Guid>(nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUserRoles", x => new { x.UserId, x.RoleId });
                    table.ForeignKey(
                        name: "FK_UserRole_Role",
                        column: x => x.RoleId,
                        principalTable: "AspNetRoles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_UserRole_User",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TypeRole",
                schema: "Common",
                columns: table => new
                {
                    TypeId = table.Column<Guid>(nullable: false),
                    RoleId = table.Column<Guid>(nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TypeRole", x => new { x.TypeId, x.RoleId });
                    table.ForeignKey(
                        name: "FK_TypeRole_Role",
                        column: x => x.RoleId,
                        principalTable: "AspNetRoles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_TypeRole_Type",
                        column: x => x.TypeId,
                        principalSchema: "Common",
                        principalTable: "Type",
                        principalColumn: "TypeId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Report",
                schema: "Report",
                columns: table => new
                {
                    ReportId = table.Column<Guid>(nullable: false),
                    Name = table.Column<string>(maxLength: 256, nullable: false),
                    Description = table.Column<string>(nullable: true),
                    ShortDescription = table.Column<string>(maxLength: 512, nullable: true),
                    DisplayCategory = table.Column<string>(nullable: false),
                    ReportTypeId = table.Column<Guid>(nullable: false),
                    IsActive = table.Column<bool>(nullable: false),
                    IsVisible = table.Column<bool>(nullable: false),
                    IsPublic = table.Column<bool>(nullable: false),
                    OrderSequence = table.Column<int>(nullable: false),
                    QueryText = table.Column<string>(nullable: true),
                    QueryContext = table.Column<string>(nullable: true),
                    CreatedUserId = table.Column<Guid>(nullable: false),
                    CreatedDate = table.Column<DateTime>(nullable: false, defaultValueSql: "getdate()"),
                    ModifiedUserId = table.Column<Guid>(nullable: true),
                    ModifiedDate = table.Column<DateTime>(nullable: true),
                    Version = table.Column<byte[]>(rowVersion: true, nullable: true),
                    NameSEO = table.Column<string>(maxLength: 256, nullable: false),
                    DefaultSort = table.Column<string>(maxLength: 256, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Report", x => x.ReportId);
                    table.ForeignKey(
                        name: "FK_Report_CreatedUser",
                        column: x => x.CreatedUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Report_ModifiedUser",
                        column: x => x.ModifiedUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Report_ReportType",
                        column: x => x.ReportTypeId,
                        principalSchema: "Common",
                        principalTable: "Type",
                        principalColumn: "TypeId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ReportChartType",
                schema: "Report",
                columns: table => new
                {
                    ReportId = table.Column<Guid>(nullable: false),
                    ChartType = table.Column<string>(maxLength: 256, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ReportChartType", x => new { x.ReportId, x.ChartType });
                    table.ForeignKey(
                        name: "FK_ReportChartType_Report",
                        column: x => x.ReportId,
                        principalSchema: "Report",
                        principalTable: "Report",
                        principalColumn: "ReportId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ReportColumn",
                schema: "Report",
                columns: table => new
                {
                    ReportId = table.Column<Guid>(nullable: false),
                    Name = table.Column<string>(maxLength: 100, nullable: false),
                    DisplayName = table.Column<string>(maxLength: 256, nullable: false),
                    DisplayValue = table.Column<string>(nullable: true),
                    SortName = table.Column<string>(maxLength: 100, nullable: false),
                    CanView = table.Column<bool>(nullable: false),
                    CanDownload = table.Column<bool>(nullable: false),
                    OrderSequence = table.Column<int>(nullable: false),
                    ContextMenu = table.Column<string>(nullable: true),
                    ClassName = table.Column<string>(nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ReportColumn", x => new { x.ReportId, x.Name });
                    table.ForeignKey(
                        name: "FK_ReportColumn_Report",
                        column: x => x.ReportId,
                        principalSchema: "Report",
                        principalTable: "Report",
                        principalColumn: "ReportId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ReportParameter",
                schema: "Report",
                columns: table => new
                {
                    ReportId = table.Column<Guid>(nullable: false),
                    Name = table.Column<string>(maxLength: 100, nullable: false),
                    DisplayName = table.Column<string>(maxLength: 256, nullable: false),
                    HintText = table.Column<string>(maxLength: 256, nullable: true),
                    OrderSequence = table.Column<int>(nullable: false),
                    IsRequired = table.Column<bool>(nullable: false),
                    IsHidden = table.Column<bool>(nullable: false),
                    DefaultValue = table.Column<string>(maxLength: 256, nullable: true),
                    ParameterDataType = table.Column<string>(nullable: false),
                    CustomData = table.Column<string>(nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ReportParameter", x => new { x.ReportId, x.Name });
                    table.ForeignKey(
                        name: "FK_ReportParameter_Report",
                        column: x => x.ReportId,
                        principalSchema: "Report",
                        principalTable: "Report",
                        principalColumn: "ReportId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ReportRole",
                schema: "Report",
                columns: table => new
                {
                    ReportId = table.Column<Guid>(nullable: false),
                    RoleId = table.Column<Guid>(nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ReportRole", x => new { x.ReportId, x.RoleId });
                    table.ForeignKey(
                        name: "FK_ReportRole_Report",
                        column: x => x.ReportId,
                        principalSchema: "Report",
                        principalTable: "Report",
                        principalColumn: "ReportId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ReportRole_Role",
                        column: x => x.RoleId,
                        principalTable: "AspNetRoles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.InsertData(
                table: "AspNetUsers",
                columns: new[] { "Id", "AccessFailedCount", "ConcurrencyStamp", "DisplayName", "Email", "EmailConfirmed", "LastLogin", "LockoutEnabled", "LockoutEnd", "NormalizedEmail", "NormalizedUserName", "PasswordHash", "Permissions", "PhoneNumber", "PhoneNumberConfirmed", "SecurityStamp", "TwoFactorEnabled", "UserName" },
                values: new object[] { new Guid("7b8150c0-6837-484f-a68b-e2d0b2c1f50e"), 0, "343b83b4-e1cc-4bdf-a78a-16cecaf44ae7", "System User", "noreply@renci.org", true, null, false, null, "NOREPLY@RENCI.ORG", "SYSTEM", null, "[]", null, false, "ST635EPP5AO2AFLE32XBUGXKTUEDECRH", false, "System" });

            migrationBuilder.InsertData(
                table: "AspNetUsers",
                columns: new[] { "Id", "AccessFailedCount", "ConcurrencyStamp", "DisplayName", "Email", "EmailConfirmed", "LastLogin", "LockoutEnabled", "LockoutEnd", "NormalizedEmail", "NormalizedUserName", "PasswordHash", "Permissions", "PhoneNumber", "PhoneNumberConfirmed", "SecurityStamp", "TwoFactorEnabled", "UserName" },
                values: new object[] { new Guid("d7e05ee8-d900-4008-81a1-5375d69c7f03"), 0, "2016c062-c5f1-4ee5-8cfc-d59736372bc0", "Administrator", "noreply@renci.org", true, null, false, null, "NOREPLY@RENCI.ORG", "ADMIN", "AQAAAAEAACcQAAAAELBquuuXUxloH/MmNG3ynEqbNx4dJxPHKPYc1PytMkZ/i4VxbeOcQiq+9XITXjmuXA==", "[65535]", null, false, "AJ5AXSDLESEQIV23V42YFJQSQHPVLMOL", false, "admin" });

            migrationBuilder.InsertData(
                table: "AspNetRoles",
                columns: new[] { "Id", "ConcurrencyStamp", "CreatedUserId", "Description", "ModifiedDate", "ModifiedUserId", "Name", "NormalizedName", "Permissions" },
                values: new object[] { new Guid("df7d657d-603a-48af-979e-92a25892cad1"), "2e91ff1f-4102-42f8-bae8-488133b4ebc6", new Guid("7b8150c0-6837-484f-a68b-e2d0b2c1f50e"), null, null, null, "Administrator", null, "[]" });

            migrationBuilder.InsertData(
                table: "AspNetRoles",
                columns: new[] { "Id", "ConcurrencyStamp", "CreatedUserId", "Description", "ModifiedDate", "ModifiedUserId", "Name", "NormalizedName", "Permissions" },
                values: new object[] { new Guid("35826fa7-12f6-4ff3-bb21-fdcd591eff8d"), "648606ca-5f39-492c-8326-3f86cd2dbb53", new Guid("7b8150c0-6837-484f-a68b-e2d0b2c1f50e"), null, null, null, "Users", null, "[]" });

            migrationBuilder.InsertData(
                schema: "Common",
                table: "Type",
                columns: new[] { "TypeId", "Category", "Code", "CreatedDate", "CreatedUserId", "IsActive", "ModifiedDate", "ModifiedUserId", "Name", "NameSEO", "OrderSequence", "ParentTypeId" },
                values: new object[] { new Guid("796056fa-fb7e-471e-9887-11a4a64ffd4a"), "ReportType", null, new DateTime(2020, 8, 11, 14, 17, 40, 369, DateTimeKind.Local).AddTicks(2684), new Guid("7b8150c0-6837-484f-a68b-e2d0b2c1f50e"), true, null, null, "General", "general", 1, null });

            migrationBuilder.CreateIndex(
                name: "IX_AspNetRoleClaims_RoleId",
                table: "AspNetRoleClaims",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetRoles_CreatedUserId",
                table: "AspNetRoles",
                column: "CreatedUserId");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetRoles_ModifiedUserId",
                table: "AspNetRoles",
                column: "ModifiedUserId");

            migrationBuilder.CreateIndex(
                name: "RoleNameIndex",
                table: "AspNetRoles",
                column: "NormalizedName",
                unique: true,
                filter: "[NormalizedName] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUserClaims_UserId",
                table: "AspNetUserClaims",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUserLogins_UserId",
                table: "AspNetUserLogins",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUserRoles_RoleId",
                table: "AspNetUserRoles",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "EmailIndex",
                table: "AspNetUsers",
                column: "NormalizedEmail");

            migrationBuilder.CreateIndex(
                name: "UserNameIndex",
                table: "AspNetUsers",
                column: "NormalizedUserName",
                unique: true,
                filter: "[NormalizedUserName] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Type_CreatedUserId",
                schema: "Common",
                table: "Type",
                column: "CreatedUserId");

            migrationBuilder.CreateIndex(
                name: "IX_Type_ModifiedUserId",
                schema: "Common",
                table: "Type",
                column: "ModifiedUserId");

            migrationBuilder.CreateIndex(
                name: "IX_Type_ParentTypeId",
                schema: "Common",
                table: "Type",
                column: "ParentTypeId");

            migrationBuilder.CreateIndex(
                name: "IX_Type_Code",
                schema: "Common",
                table: "Type",
                columns: new[] { "Category", "Code" },
                unique: true,
                filter: "[Code] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Type_Unique",
                schema: "Common",
                table: "Type",
                columns: new[] { "Category", "Name" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Type_NameSEO_Unique",
                schema: "Common",
                table: "Type",
                columns: new[] { "Category", "NameSEO" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TypeRole_RoleId",
                schema: "Common",
                table: "TypeRole",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "IX_Report_CreatedUserId",
                schema: "Report",
                table: "Report",
                column: "CreatedUserId");

            migrationBuilder.CreateIndex(
                name: "IX_Report_ModifiedUserId",
                schema: "Report",
                table: "Report",
                column: "ModifiedUserId");

            migrationBuilder.CreateIndex(
                name: "IX_Report_Unique",
                schema: "Report",
                table: "Report",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Report_NameSEO_Unique",
                schema: "Report",
                table: "Report",
                column: "NameSEO",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Report_ReportTypeId",
                schema: "Report",
                table: "Report",
                column: "ReportTypeId");

            migrationBuilder.CreateIndex(
                name: "IX_ReportChartType_ChartType",
                schema: "Report",
                table: "ReportChartType",
                column: "ChartType");

            migrationBuilder.CreateIndex(
                name: "IX_ReportRole_RoleId",
                schema: "Report",
                table: "ReportRole",
                column: "RoleId");

            migrationBuilder.Sql(@"
CREATE TABLE [Log] (
    [Id] int IDENTITY(1, 1) NOT NULL,
    [Message] nvarchar(max) NULL,
    [MessageTemplate] nvarchar(max) NULL,
    [Level] nvarchar(128) NULL,
    [TimeStamp] datetimeoffset(7) NOT NULL,
    [Exception] nvarchar(max) NULL,
    [Properties] xml NULL,
    [LogEvent] nvarchar(max) NULL
    CONSTRAINT[PK_Log] PRIMARY KEY CLUSTERED([Id] ASC)
)");

            migrationBuilder.Sql(@"EXEC ('CREATE OR ALTER VIEW [Common].[AdminUserQueryView] AS
WITH src AS (
SELECT
	UR.UserId,
	rp.value
FROM
	[dbo].[AspNetRoles] r CROSS APPLY OPENJSON(r.Permissions) rp,
	[dbo].[AspNetUserRoles] ur
WHERE r.Id = ur.RoleId
UNION
SELECT
	u.Id,
	up.value
FROM
	[dbo].[AspNetUsers] u CROSS APPLY OPENJSON(u.Permissions) up
), u_p AS (SELECT UserId, STRING_AGG(CONCAT(''|'', value, ''|''), '','') permissions FROM src GROUP BY UserId)
SELECT
	[Id] UserId,
	[UserName],
	[Email],
	[EmailConfirmed],
	[PhoneNumber],
	[TwoFactorEnabled],
	[LockoutEnd],
	[DisplayName],
    [CreatedDate],
    [LastLogin],
	u_p.permissions [Permissions]
FROM
	[dbo].[AspNetUsers] u,
	u_p
WHERE
	u.Id = u_p.UserId
')");

            migrationBuilder.Sql(@"EXEC ('CREATE OR ALTER VIEW [Common].[AdminRoleQueryView] AS
SELECT
	[Id] RoleId,
	[Name],
	[Description],
	[Permissions],
	ISNULL(t.[ModifiedDate], t.[CreatedDate]) ModifiedDate
FROM
	[dbo].[AspNetRoles] t')");

            migrationBuilder.Sql(@"EXEC ('CREATE OR ALTER VIEW [Common].[AdminTypeQueryView] AS
SELECT
	t.[TypeId]	TypeId,
	t.[Name]	TypeName,
	pt.[Name]	ParentTypeName,
	pt.[TypeId]	ParentTypeId,
	t.[Category],
	t.[IsActive],
	t.OrderSequence,
	t.Code,
	t.Version,
	ISNULL(t.[ModifiedDate], t.[CreatedDate]) ModifiedDate
FROM
	[Common].[Type] t
		LEFT JOIN [Common].[Type] pt ON t.[ParentTypeId] = pt.[TypeId]')");

            migrationBuilder.Sql(@"EXEC ('
CREATE OR ALTER VIEW [Common].[AdminReportQueryView] AS
SELECT
	[ReportId],
	r.[Name] ReportName,
	r.ReportTypeId,
	t_ReportType.[Name] ReportTypeName,
	t_ReportType.NameSEO ReportTypeNameSEO,
	r.Description ReportDescription,
	r.NameSEO ReportNameSEO,
	ISNULL(r.[ModifiedDate], r.[CreatedDate]) ModifiedDate
FROM
	[Report].[Report] r,
	[Common].[Type] t_ReportType
WHERE
	r.ReportTypeId = t_ReportType.TypeId
')");

            migrationBuilder.Sql(@"EXEC ('
CREATE OR ALTER VIEW [Common].[ReportQueryView] AS
SELECT
	[ReportId],
	r.[Name] ReportName,
	r.ReportTypeId,
	t_ReportType.[Name] ReportTypeName,
	t_ReportType.NameSEO ReportTypeNameSEO,
	r.Description ReportDescription,
	r.NameSEO ReportNameSEO,
	ISNULL(r.[ModifiedDate], r.[CreatedDate]) ModifiedDate
FROM
	[Report].[Report] r,
	[Common].[Type] t_ReportType
WHERE
	r.IsActive = 1
	AND r.IsVisible = 1
	AND r.ReportTypeId = t_ReportType.TypeId
')");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AspNetRoleClaims");

            migrationBuilder.DropTable(
                name: "AspNetUserClaims");

            migrationBuilder.DropTable(
                name: "AspNetUserLogins");

            migrationBuilder.DropTable(
                name: "AspNetUserRoles");

            migrationBuilder.DropTable(
                name: "AspNetUserTokens");

            migrationBuilder.DropTable(
                name: "DataProtectionKeys");

            migrationBuilder.DropTable(
                name: "TypeRole",
                schema: "Common");

            migrationBuilder.DropTable(
                name: "ReportChartType",
                schema: "Report");

            migrationBuilder.DropTable(
                name: "ReportColumn",
                schema: "Report");

            migrationBuilder.DropTable(
                name: "ReportParameter",
                schema: "Report");

            migrationBuilder.DropTable(
                name: "ReportRole",
                schema: "Report");

            migrationBuilder.DropTable(
                name: "Report",
                schema: "Report");

            migrationBuilder.DropTable(
                name: "AspNetRoles");

            migrationBuilder.DropTable(
                name: "Type",
                schema: "Common");

            migrationBuilder.DropTable(
                name: "AspNetUsers");
        }
    }
}