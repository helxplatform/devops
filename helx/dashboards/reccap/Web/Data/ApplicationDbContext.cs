using Microsoft.AspNetCore.DataProtection.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Renci.ReCCAP.Dashboard.Web.Models.Enums;
using Renci.ReCCAP.Dashboard.Web.Models.Interfaces;
using Renci.ReCCAP.Dashboard.Web.Services;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace Renci.ReCCAP.Dashboard.Web.Data
{
    public class ApplicationDbContext : IdentityDbContext<ApplicationUser, ApplicationRole, Guid>, IDataProtectionKeyContext
    {
        private readonly Guid _systemUserId = new Guid("7b8150c0-6837-484f-a68b-e2d0b2c1f50e");
        private readonly ISessionContextResolver _sessionContext;

        public virtual DbSet<DataProtectionKey> DataProtectionKeys { get; set; }

        #region Users

        /// <summary>
        /// Gets or sets the admin user query items.
        /// </summary>
        /// <value>
        /// The admin user query items.
        /// </value>
        public DbSet<AdminUserQueryItem> AdminUserQueryItems { get; set; }

        #endregion Users

        #region Roles

        /// <summary>
        /// Gets or sets the admin role query items.
        /// </summary>
        /// <value>
        /// The admin role query items.
        /// </value>
        public DbSet<AdminRoleQueryItem> AdminRoleQueryItems { get; set; }

        #endregion Roles

        #region Types

        /// <summary>
        /// Gets or sets the types.
        /// </summary>
        /// <value>
        /// The types.
        /// </value>
        public virtual DbSet<Type> Types { get; set; }

        /// <summary>
        /// Gets or sets the admin type query items.
        /// </summary>
        /// <value>
        /// The admin type query items.
        /// </value>
        public DbSet<AdminTypeQueryItem> AdminTypeQueryItems { get; set; }

        #endregion Types

        #region Reports

        /// <summary>
        /// Gets or sets the reports.
        /// </summary>
        /// <value>
        /// The reports.
        /// </value>
        public virtual DbSet<Report> Reports { get; set; }

        /// <summary>
        /// Gets or sets the admin report query items.
        /// </summary>
        /// <value>
        /// The admin report query items.
        /// </value>
        public DbSet<AdminReportQueryItem> AdminReportQueryItems { get; set; }

        /// <summary>
        /// Gets or sets the report query items.
        /// </summary>
        /// <value>
        /// The report query items.
        /// </value>
        public DbSet<ReportQueryItem> ReportQueryItems { get; set; }

        #endregion Reports

        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
            if (options == null)
                throw new ArgumentNullException(nameof(options));

            var extension = options.FindExtension<CoreOptionsExtension>();
            this._sessionContext = extension.ApplicationServiceProvider?.GetService<ISessionContextResolver>();
        }

        /// <summary>
        /// Saves all changes made in this context to the database.
        /// </summary>
        /// <returns>
        /// The number of state entries written to the database.
        /// </returns>
        /// <remarks>
        /// This method will automatically call <see cref="Microsoft.EntityFrameworkCore.ChangeTracking.ChangeTracker.DetectChanges" /> to discover any
        /// changes to entity instances before saving to the underlying database. This can be disabled via
        /// <see cref="Microsoft.EntityFrameworkCore.ChangeTracking.ChangeTracker.AutoDetectChangesEnabled" />.
        /// </remarks>
        public override int SaveChanges()
        {
            this.PreSaveProccessing();

            return base.SaveChanges();
        }

        /// <summary>
        /// Asynchronously saves all changes made in this context to the database.
        /// </summary>
        /// <param name="cancellationToken">A <see cref="System.Threading.CancellationToken" /> to observe while waiting for the task to complete.</param>
        /// <returns>
        /// A task that represents the asynchronous save operation. The task result contains the
        /// number of state entries written to the database.
        /// </returns>
        /// <remarks>
        /// <para>
        /// This method will automatically call <see cref="Microsoft.EntityFrameworkCore.ChangeTracking.ChangeTracker.DetectChanges" /> to discover any
        /// changes to entity instances before saving to the underlying database. This can be disabled via
        /// <see cref="Microsoft.EntityFrameworkCore.ChangeTracking.ChangeTracker.AutoDetectChangesEnabled" />.
        /// </para>
        /// <para>
        /// Multiple active operations on the same context instance are not supported.  Use 'await' to ensure
        /// that any asynchronous operations have completed before calling another method on this context.
        /// </para>
        /// </remarks>
        public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            this.PreSaveProccessing();

            return base.SaveChangesAsync(cancellationToken);
        }

        private void PreSaveProccessing()
        {
            ChangeTracker.DetectChanges();

            if (this._sessionContext != null)
            {
                var currentUserId = this._sessionContext.CurrentUserId;
                if (currentUserId != null)
                {
                    var added = from e in ChangeTracker.Entries()
                                where e.State == EntityState.Added
                                && e.Entity is ICreatable
                                select e.Entity;
                    foreach (ICreatable entity in added)
                    {
                        entity.CreatedDate = DateTime.Now;
                        entity.CreatedUserId = currentUserId.Value;
                    }
                }

                var modified = from e in ChangeTracker.Entries()
                               where e.State == EntityState.Modified
                               && e.Entity is ITrackable
                               select e.Entity;
                foreach (ITrackable entity in modified)
                {
                    var entry = this.Entry(entity);
                    entry.Property(nameof(ITrackable.CreatedUserId)).IsModified = false;
                    entry.Property(nameof(ITrackable.CreatedDate)).IsModified = false;
                    entity.ModifiedDate = DateTime.Now;
                    entity.ModifiedUserId = currentUserId;
                }
            }

            var addedOrModifiedEntities = from e in ChangeTracker.Entries()
                                          where e.State == EntityState.Added || e.State == EntityState.Modified
                                          select e.Entity;
            foreach (var entity in addedOrModifiedEntities)
            {
                var validationContext = new ValidationContext(entity);
                Validator.ValidateObject(entity, validationContext);
            }

            var versionedEntities = from e in ChangeTracker.Entries()
                                    where e.State == EntityState.Modified
                                    && e.Entity is IVersion
                                    select e.Entity;
            foreach (IVersion entity in versionedEntities)
            {
                this.Entry(entity).Property(m => m.Version).OriginalValue = entity.Version;
            }
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            if (modelBuilder == null)
                throw new ArgumentNullException(nameof(modelBuilder));

            base.OnModelCreating(modelBuilder);

            #region Security

            // Customize the ASP.NET Identity model and override the defaults.
            modelBuilder.Entity<ApplicationUser>(entity =>
            {
                entity.Property(e => e.DisplayName)
                .IsRequired()
                .HasMaxLength(256);

                entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("getdate()");

                entity.Property(e => e.Permissions)
                .HasColumnName("Permissions")
                .HasConversion(
                    v => JsonSerializer.Serialize(v, new JsonSerializerOptions { IgnoreNullValues = true }),
                    v => JsonSerializer.Deserialize<ICollection<Permission>>(v, new JsonSerializerOptions { IgnoreNullValues = true }));

                entity.HasMany(e => e.Claims)
                .WithOne()
                .HasForeignKey(e => e.UserId)
                .IsRequired()
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_UserClaim_User");

                entity.HasMany(e => e.Logins)
                .WithOne()
                .HasForeignKey(e => e.UserId)
                .IsRequired()
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_UserLogin_User");

                entity.HasMany(e => e.Roles)
                .WithOne()
                .HasForeignKey(e => e.UserId)
                .IsRequired()
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_UserRole_User");
            });

            modelBuilder.Entity<AdminUserQueryItem>(entity =>
            {
                entity.HasNoKey();
                entity.ToView("AdminUserQueryView", "Common");
            });

            modelBuilder.Entity<ApplicationRole>(entity =>
            {
                entity.HasIndex(e => e.CreatedUserId);

                entity.Property(e => e.CreatedUserId)
                .IsRequired();

                entity.Property(e => e.Permissions)
                .HasColumnName("Permissions")
                .HasConversion(
                v => JsonSerializer.Serialize(v, new JsonSerializerOptions { IgnoreNullValues = true }),
                v => JsonSerializer.Deserialize<ICollection<Permission>>(v, new JsonSerializerOptions { IgnoreNullValues = true }));

                entity.HasOne(e => e.CreatedUser)
                .WithMany()
                .HasForeignKey(e => e.CreatedUserId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("FK_Role_CreatedUser");

                entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("getdate()");

                entity.HasIndex(e => e.ModifiedUserId);

                entity.HasOne(e => e.ModifiedUser)
                .WithMany()
                .HasForeignKey(e => e.ModifiedUserId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("FK_Role_ModifiedUser");

                entity.HasMany(e => e.Claims)
                .WithOne()
                .HasForeignKey(e => e.RoleId)
                .IsRequired()
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_RoleClaim_Role");

                entity.HasMany(e => e.Users)
                .WithOne()
                .HasForeignKey(e => e.RoleId)
                .IsRequired()
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("FK_UserRole_Role");
            });

            modelBuilder.Entity<AdminRoleQueryItem>(entity =>
            {
                entity.HasNoKey();
                entity.ToView("AdminRoleQueryView", "Common");
            });

            modelBuilder.Entity<ApplicationUser>().HasData(
                new ApplicationUser
                {
                    Id = this._systemUserId,
                    DisplayName = "System User",
                    UserName = "System",
                    NormalizedUserName = "SYSTEM",
                    Email = "noreply@renci.org",
                    NormalizedEmail = "NOREPLY@RENCI.ORG",
                    EmailConfirmed = true,
                    SecurityStamp = "ST635EPP5AO2AFLE32XBUGXKTUEDECRH",
                    ConcurrencyStamp = "343b83b4-e1cc-4bdf-a78a-16cecaf44ae7",
                },
                new ApplicationUser
                {
                    Id = new Guid("d7e05ee8-d900-4008-81a1-5375d69c7f03"),
                    DisplayName = "Administrator",
                    UserName = "admin",
                    NormalizedUserName = "ADMIN",
                    Email = "noreply@renci.org",
                    NormalizedEmail = "NOREPLY@RENCI.ORG",
                    EmailConfirmed = true,
                    PasswordHash = "AQAAAAEAACcQAAAAELBquuuXUxloH/MmNG3ynEqbNx4dJxPHKPYc1PytMkZ/i4VxbeOcQiq+9XITXjmuXA==",
                    SecurityStamp = "AJ5AXSDLESEQIV23V42YFJQSQHPVLMOL",
                    ConcurrencyStamp = "2016c062-c5f1-4ee5-8cfc-d59736372bc0",
                    Permissions = { Permission.Administrator }
                });

            modelBuilder.Entity<ApplicationRole>().HasData(
                new ApplicationRole("Administrator") { Id = new Guid("df7d657d-603a-48af-979e-92a25892cad1"), CreatedUserId = _systemUserId, ConcurrencyStamp = "2e91ff1f-4102-42f8-bae8-488133b4ebc6" },
                new ApplicationRole("Users") { Id = new Guid("35826fa7-12f6-4ff3-bb21-fdcd591eff8d"), CreatedUserId = _systemUserId, ConcurrencyStamp = "648606ca-5f39-492c-8326-3f86cd2dbb53" }
                );

            #endregion Security

            #region Type

            modelBuilder.Entity<Type>(entity =>
            {
                entity.HasKey(e => e.TypeId);

                entity.ToTable("Type", "Common");

                entity.HasIndex(e => e.CreatedUserId);

                entity.HasIndex(e => e.ModifiedUserId);

                entity.HasIndex(e => e.ParentTypeId);

                entity.HasIndex(e => new { e.Category, e.Code })
                .IsUnique(true)
                .HasName("IX_Type_Code");

                entity.HasIndex(e => new { e.Category, e.Name })
                .IsUnique(true)
                .HasName("IX_Type_Unique");

                entity.HasIndex(e => new { e.Category, e.NameSEO })
                .IsUnique(true)
                .HasName("IX_Type_NameSEO_Unique");

                entity.Property(e => e.Category)
                .IsRequired()
                .HasConversion<string>();

                entity.Property(e => e.Code)
                .HasMaxLength(32);

                entity.Property(e => e.Name)
                .IsRequired()
                .HasMaxLength(256);

                entity.Property(e => e.NameSEO)
                .IsRequired()
                .HasMaxLength(256);

                entity.HasOne(e => e.ParentType)
                .WithMany()
                .HasForeignKey(e => e.ParentTypeId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("FK_Type_ParentType");

                entity.HasIndex(e => e.CreatedUserId);

                entity.Property(e => e.CreatedUserId)
                .IsRequired();

                entity.HasOne(e => e.CreatedUser)
                .WithMany()
                .HasForeignKey(e => e.CreatedUserId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("FK_Type_CreatedUser");

                entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("getdate()");

                entity.HasIndex(e => e.ModifiedUserId);

                entity.HasOne(e => e.ModifiedUser)
                .WithMany()
                .HasForeignKey(e => e.ModifiedUserId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("FK_Type_ModifiedUser");

                entity.Property(e => e.Version).IsRowVersion();
            });

            modelBuilder.Entity<Type>().HasData(
                new Type() { TypeId = new Guid("796056fa-fb7e-471e-9887-11a4a64ffd4a"), Name = "General", NameSEO = "general", OrderSequence = 1, Category = CategoryName.ReportType, IsActive = true, CreatedUserId = _systemUserId, CreatedDate = DateTime.Now }
                );

            modelBuilder.Entity<TypeRole>(entity =>
            {
                entity.HasKey(e => new { e.TypeId, e.RoleId });

                entity.ToTable("TypeRole", "Common");

                entity.HasIndex(e => e.RoleId);

                entity.HasOne(e => e.Role)
                .WithMany()
                .HasForeignKey(e => e.RoleId)
                .OnDelete(DeleteBehavior.Restrict)
                .IsRequired()
                .HasConstraintName("FK_TypeRole_Role");

                entity.HasOne(e => e.Type)
                .WithMany(e => e.Roles)
                .HasForeignKey(e => e.TypeId)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_TypeRole_Type");
            });

            modelBuilder.Entity<AdminTypeQueryItem>(entity =>
            {
                entity.HasNoKey();
                entity.ToView("AdminTypeQueryView", "Common");

                entity.Property(e => e.Category)
                .HasConversion<string>();
            });

            #endregion Type

            #region Report

            modelBuilder.Entity<Report>(entity =>
            {
                entity.HasKey(e => e.ReportId);

                entity.ToTable("Report", "Report");

                entity.HasIndex(e => e.Name)
                .IsUnique(true)
                .HasName("IX_Report_Unique");

                entity.HasIndex(e => e.NameSEO)
                .IsUnique(true)
                .HasName("IX_Report_NameSEO_Unique");

                entity.HasIndex(e => e.ReportTypeId);

                entity.Property(e => e.DisplayCategory)
                .HasConversion<string>();

                entity.Property(e => e.Name)
                .IsRequired()
                .HasMaxLength(256);

                entity.Property(e => e.NameSEO)
                .IsRequired()
                .HasMaxLength(256);

                entity.Property(e => e.ShortDescription)
                .HasMaxLength(512);

                entity.Property(e => e.DefaultSort)
                .HasMaxLength(256);

                entity.HasOne(e => e.ReportType)
                .WithMany()
                .HasForeignKey(e => e.ReportTypeId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("FK_Report_ReportType");

                entity.Property(e => e.QueryContext)
                .HasConversion(
                    v => JsonSerializer.Serialize(v, new JsonSerializerOptions { IgnoreNullValues = true }),
                    v => JsonSerializer.Deserialize<QueryContext>(v, new JsonSerializerOptions { IgnoreNullValues = true }));

                entity.HasIndex(e => e.CreatedUserId);

                entity.Property(e => e.CreatedUserId)
                .IsRequired();

                entity.HasOne(e => e.CreatedUser)
                .WithMany()
                .HasForeignKey(e => e.CreatedUserId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("FK_Report_CreatedUser");

                entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("getdate()");

                entity.HasIndex(e => e.ModifiedUserId);

                entity.HasOne(e => e.ModifiedUser)
                .WithMany()
                .HasForeignKey(e => e.ModifiedUserId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("FK_Report_ModifiedUser");

                entity.Property(e => e.Version).IsRowVersion();
            });

            modelBuilder.Entity<ReportParameter>(entity =>
            {
                entity.HasKey(e => new { e.ReportId, e.Name });

                entity.ToTable("ReportParameter", "Report");

                entity.Property(e => e.Name)
                .IsRequired()
                .HasMaxLength(100);

                entity.Property(e => e.CustomData);

                entity.Property(e => e.DefaultValue)
                .HasMaxLength(256);

                entity.Property(e => e.DisplayName)
                .IsRequired()
                .HasMaxLength(256);

                entity.Property(e => e.HintText)
                .HasMaxLength(256);

                entity.Property(e => e.ParameterDataType)
                .HasConversion<string>()
                .IsRequired();

                entity.HasOne(e => e.Report)
                .WithMany(e => e.ReportParameters)
                .HasForeignKey(e => e.ReportId)
                .OnDelete(DeleteBehavior.Cascade)
                .IsRequired()
                .HasConstraintName("FK_ReportParameter_Report");
            });

            modelBuilder.Entity<ReportColumn>(entity =>
            {
                entity.HasKey(e => new { e.ReportId, e.Name });

                entity.ToTable("ReportColumn", "Report");

                entity.Property(e => e.Name)
                .IsRequired()
                .HasMaxLength(100);

                entity.Property(e => e.DisplayName)
                .IsRequired()
                .HasMaxLength(256);

                entity.Property(e => e.SortName)
                .IsRequired()
                .HasMaxLength(100);

                entity.HasOne(e => e.Report)
                .WithMany(e => e.ReportColumns)
                .HasForeignKey(e => e.ReportId)
                .OnDelete(DeleteBehavior.Cascade)
                .IsRequired()
                .HasConstraintName("FK_ReportColumn_Report");
            });

            modelBuilder.Entity<ReportRole>(entity =>
            {
                entity.HasKey(e => new { e.ReportId, e.RoleId });

                entity.ToTable("ReportRole", "Report");

                entity.HasIndex(e => e.RoleId);

                entity.HasOne(e => e.Role)
                .WithMany()
                .HasForeignKey(e => e.RoleId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("FK_ReportRole_Role");

                entity.HasOne(e => e.Report)
                .WithMany(e => e.Roles)
                .HasForeignKey(e => e.ReportId)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_ReportRole_Report");
            });

            modelBuilder.Entity<ReportChartType>(entity =>
            {
                entity.HasKey(e => new { e.ReportId, e.ChartType });

                entity.ToTable("ReportChartType", "Report");

                entity.HasIndex(e => e.ChartType);

                entity.Property(e => e.ChartType)
                .IsRequired()
                .HasMaxLength(256);

                entity.HasOne(e => e.Report)
                .WithMany(e => e.ChartTypes)
                .HasForeignKey(e => e.ReportId)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_ReportChartType_Report");
            });

            modelBuilder.Entity<ReportQueryItem>(entity =>
            {
                entity.HasNoKey();
                entity.ToView("ReportQueryView", "Common");
            });

            modelBuilder.Entity<AdminReportQueryItem>(entity =>
            {
                entity.HasNoKey();
                entity.ToView("AdminReportQueryView", "Common");
            });

            #endregion Report
        }
    }
}