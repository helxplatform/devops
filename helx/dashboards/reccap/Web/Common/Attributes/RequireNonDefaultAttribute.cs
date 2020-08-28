using System;
using System.ComponentModel.DataAnnotations;

namespace Renci.ReCCAP.Dashboard.Web.Common
{
    /// <summary>
    ///
    /// </summary>
    /// <seealso cref="System.ComponentModel.DataAnnotations.ValidationAttribute" />
    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class RequireNonDefaultAttribute : ValidationAttribute
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="RequireNonDefaultAttribute"/> class.
        /// </summary>
        public RequireNonDefaultAttribute()
            : base("The {0} field requires a non-default value.")
        {
        }

        /// <summary>
        /// Returns true if ... is valid.
        /// </summary>
        /// <param name="value">The value of the object to validate.</param>
        /// <returns>
        /// true if the specified value is valid; otherwise, false.
        /// </returns>
        public override bool IsValid(object value)
        {
            return value != null && !object.Equals(value, Activator.CreateInstance(value.GetType()));
        }
    }
}