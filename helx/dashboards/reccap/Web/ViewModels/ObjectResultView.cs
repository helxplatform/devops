using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels
{
    /// <summary>
    ///
    /// </summary>
    /// <typeparam name="T"></typeparam>
    public class ObjectResultView<T>
    {
        /// <summary>
        /// Gets or sets the current page.
        /// </summary>
        /// <value>
        /// The current page.
        /// </value>
        public int CurrentPage { get; set; }

        /// <summary>
        /// Gets or sets the items per page.
        /// </summary>
        /// <value>
        /// The items per page.
        /// </value>
        public int ItemsPerPage { get; set; }

        /// <summary>
        /// Gets or sets the total items.
        /// </summary>
        /// <value>
        /// The total items.
        /// </value>
        public int TotalItems { get; set; }

        /// <summary>
        /// Gets or sets the total pages.
        /// </summary>
        /// <value>
        /// The total pages.
        /// </value>
        public int TotalPages { get; set; }

        /// <summary>
        /// Gets or sets the data.
        /// </summary>
        /// <value>
        /// The data.
        /// </value>
        public IEnumerable<object> Data { get; set; }

        /// <summary>
        /// Gets or sets the title.
        /// </summary>
        /// <value>
        /// The title.
        /// </value>
        public string Title { get; set; }

        /// <summary>
        /// Prevents a default instance of the <see cref="ObjectResultView{T}"/> class from being created.
        /// </summary>
        private ObjectResultView()
        {
        }

        /// <summary>
        /// Creates the asynchronous.
        /// </summary>
        /// <param name="items">The items.</param>
        /// <param name="selector">The selector.</param>
        /// <param name="offset">The offset.</param>
        /// <param name="limit">The limit.</param>
        /// <param name="title">The title.</param>
        /// <returns></returns>
        public static async Task<ObjectResultView<T>> CreateAsync(IQueryable<T> items, Func<T, object> selector, int offset, int limit, string title = null)
        {
            var totalItems = await items.CountAsync();
            if (limit > 0)
            {
                items = items.Skip(offset).Take(limit);
            }
            var data = await items.ToListAsync();

            var result = new ObjectResultView<T>()
            {
                Data = data.Select(selector),
                CurrentPage = (limit > 0) ? offset / limit + 1 : 1,
                TotalItems = totalItems,
                ItemsPerPage = (limit > 0) ? limit : totalItems,
                TotalPages = (limit > 0) ? totalItems / limit : 1,
                Title = title,
            };
            return result;
        }
    }
}