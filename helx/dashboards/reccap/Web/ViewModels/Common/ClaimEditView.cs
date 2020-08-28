using Microsoft.AspNetCore.Identity;
using System;
using System.ComponentModel.DataAnnotations;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels
{
    /// <summary>
    ///
    /// </summary>
    public class ClaimEditView
    {
        /// <summary>
        /// Gets or sets the identifier.
        /// </summary>
        /// <value>
        /// The identifier.
        /// </value>
        public int Id { get; set; }

        /// <summary>
        /// Gets or sets the type of the claim.
        /// </summary>
        /// <value>
        /// The type of the claim.
        /// </value>
        [Required]
        public string ClaimType { get; set; }

        /// <summary>
        /// Gets or sets the claim value.
        /// </summary>
        /// <value>
        /// The claim value.
        /// </value>
        [Required]
        public string ClaimValue { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="ClaimEditView"/> class.
        /// </summary>
        public ClaimEditView()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="ClaimEditView"/> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        public ClaimEditView(IdentityRoleClaim<Guid> entity)
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            this.Id = entity.Id;
            this.ClaimType = entity.ClaimType;
            this.ClaimValue = entity.ClaimValue;
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="ClaimEditView"/> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        public ClaimEditView(IdentityUserClaim<Guid> entity)
        {
            if (entity == null)
                throw new ArgumentNullException(nameof(entity));

            this.Id = entity.Id;
            this.ClaimType = entity.ClaimType;
            this.ClaimValue = entity.ClaimValue;
        }
    }
}