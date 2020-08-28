using Renci.ReCCAP.Dashboard.Web.Models.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;

namespace Renci.ReCCAP.Dashboard.Web.ViewModels
{
    /// <summary>
    ///
    /// </summary>
    /// <typeparam name="T"></typeparam>
    public abstract class BaseEditView<T> : IEditView<T> where T : class
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="BaseEditView{T}"/> class.
        /// </summary>
        public BaseEditView()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="BaseEditView{T}" /> class.
        /// </summary>
        /// <param name="entity">The entity.</param>
        public BaseEditView(T entity)
            : this()
        {
        }

        /// <summary>
        /// Applies the changes to the entity.
        /// </summary>
        /// <param name="entity">The entity to apply changes to.</param>
        public abstract void ApplyChangesTo(T entity);

        /// <summary>
        /// Updates the collection.
        /// </summary>
        /// <typeparam name="TEC">The type of the c.</typeparam>
        /// <typeparam name="TEEC">The type of the ec.</typeparam>
        /// <param name="entityChildren">The entity children.</param>
        /// <param name="editEntityChildren">The edit entity children.</param>
        /// <param name="compareFunc">The compare function.</param>
        /// <param name="createEntityFunc">The create entity function.</param>
        /// <param name="updateFunc">The update function.</param>
        protected void UpdateCollection<TEC, TEEC>(
            ICollection<TEC> entityChildren,
            IEnumerable<TEEC> editEntityChildren,
            Func<TEC, TEEC, bool> compareFunc,
            Func<TEC> createEntityFunc,
            Action<TEC, TEEC> updateFunc = null
            ) where TEEC : IEditView<TEC> where TEC : class
        {
            if (editEntityChildren == null)
            {
                return;
            }

            if (entityChildren == null)
                throw new ArgumentNullException(nameof(entityChildren));

            foreach (var item in entityChildren.Where(m => !editEntityChildren.Where(e => compareFunc(m, e)).Any()).ToList())
            {
                entityChildren.Remove(item);
            }

            foreach (var item in editEntityChildren)
            {
                var itemEntity = entityChildren.Where(m => compareFunc(m, item)).SingleOrDefault();
                if (itemEntity == null)
                {
                    itemEntity = createEntityFunc();
                    entityChildren.Add(itemEntity);
                }
                item.ApplyChangesTo(itemEntity);
                updateFunc?.Invoke(itemEntity, item);
            }
        }

        /// <summary>
        /// Updates the collection.
        /// </summary>
        /// <typeparam name="ТEC">The type of the c.</typeparam>
        /// <typeparam name="ТEEC">The type of the ec.</typeparam>
        /// <param name="entityChildren">The entity children.</param>
        /// <param name="editEntityChildren">The edit entity children.</param>
        /// <param name="compareFunc">The compare function.</param>
        /// <param name="createEntityFunc">The create entity function.</param>
        /// <param name="updateFunc">The update function.</param>
        protected void UpdateCollection<ТEC, ТEEC>(
                    ICollection<ТEC> entityChildren,
                    IEnumerable<ТEEC> editEntityChildren,
                    Func<ТEC, ТEEC, bool> compareFunc,
                    Func<ТEEC, ТEC> createEntityFunc,
                    Action<ТEC, ТEEC> updateFunc = null
                    ) where ТEEC : IEditView<ТEC> where ТEC : class
        {
            if (editEntityChildren == null)
            {
                return;
            }

            if (entityChildren == null)
                throw new ArgumentNullException(nameof(entityChildren));

            foreach (var item in entityChildren.Where(m => !editEntityChildren.Where(e => compareFunc(m, e)).Any()).ToList())
            {
                entityChildren.Remove(item);
            }

            foreach (var item in editEntityChildren)
            {
                var itemEntity = entityChildren.Where(m => compareFunc(m, item)).SingleOrDefault();
                if (itemEntity == null)
                {
                    itemEntity = createEntityFunc(item);
                    entityChildren.Add(itemEntity);
                }
                item.ApplyChangesTo(itemEntity);
                updateFunc?.Invoke(itemEntity, item);
            }
        }

        /// <summary>
        /// Updates the collection.
        /// </summary>
        /// <typeparam name="ТEC">The type of the c.</typeparam>
        /// <typeparam name="ТEEC">The type of the ec.</typeparam>
        /// <param name="entityChildren">The entity children.</param>
        /// <param name="editEntityChildren">The edit entity children.</param>
        /// <param name="createEntityFunc">The create entity function.</param>
        protected void UpdateCollection<ТEC, ТEEC>(ICollection<ТEC> entityChildren, IEnumerable<ТEEC> editEntityChildren, Func<ТEEC, ТEC> createEntityFunc)
        {
            if (editEntityChildren == null)
            {
                return;
            }

            if (entityChildren == null)
                throw new ArgumentNullException(nameof(entityChildren));

            entityChildren.Clear();
            foreach (var item in editEntityChildren)
            {
                entityChildren.Add(createEntityFunc(item));
            }
        }
    }
}