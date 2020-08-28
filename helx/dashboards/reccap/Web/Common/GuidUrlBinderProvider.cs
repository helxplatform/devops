using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.AspNetCore.Mvc.ModelBinding.Binders;
using System;

namespace Renci.ReCCAP.Dashboard.Web.Common
{
    /// <summary>
    ///
    /// </summary>
    /// <seealso cref="Microsoft.AspNetCore.Mvc.ModelBinding.IModelBinderProvider" />
    public class GuidUrlBinderProvider : IModelBinderProvider
    {
        /// <summary>
        /// Creates a <see cref="Microsoft.AspNetCore.Mvc.ModelBinding.IModelBinder" /> based on <see cref="Microsoft.AspNetCore.Mvc.ModelBinding.ModelBinderProviderContext" />.
        /// </summary>
        /// <param name="context">The <see cref="Microsoft.AspNetCore.Mvc.ModelBinding.ModelBinderProviderContext" />.</param>
        /// <returns>
        /// An <see cref="Microsoft.AspNetCore.Mvc.ModelBinding.IModelBinder" />.
        /// </returns>
        /// <exception cref="ArgumentNullException">context</exception>
        public IModelBinder GetBinder(ModelBinderProviderContext context)
        {
            if (context == null)
            {
                throw new ArgumentNullException(nameof(context));
            }

            if (context.Metadata.ModelType == typeof(Guid))
            {
                return new BinderTypeModelBinder(typeof(GuidUrlBinder));
            }

            if (context.Metadata.ModelType == typeof(Guid?))
            {
                return new BinderTypeModelBinder(typeof(GuidUrlBinder));
            }

            return null;
        }
    }
}