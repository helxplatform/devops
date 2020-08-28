namespace Renci.ReCCAP.Dashboard.Web.Models.Interfaces
{
    /// <summary>
    ///
    /// </summary>
    /// <typeparam name="T"></typeparam>
    public interface IEditView<T> where T : class
    {
        /// <summary>
        /// Applies the changes to an entity.
        /// </summary>
        /// <param name="entity">The entity.</param>
        void ApplyChangesTo(T entity);
    }
}