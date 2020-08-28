namespace Renci.ReCCAP.Dashboard.Web.ViewModels
{
    /// <summary>
    ///
    /// </summary>
    /// <typeparam name="T"></typeparam>
    public class CommonInfo<T>
    {
        /// <summary>
        /// Gets the identifier.
        /// </summary>
        /// <value>
        /// The identifier.
        /// </value>
        public T Id { get; set; }

        /// <summary>
        /// Gets the text.
        /// </summary>
        /// <value>
        /// The text.
        /// </value>
        public string Text { get; set; }

        /// <summary>
        /// Gets the code.
        /// </summary>
        /// <value>
        /// The code.
        /// </value>
        public string Code { get; }

        /// <summary>
        /// Initializes a new instance of the <see cref="CommonInfo{T}"/> class.
        /// </summary>
        public CommonInfo()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="CommonInfo{T}"/> class.
        /// </summary>
        /// <param name="id">The identifier.</param>
        /// <param name="text">The text.</param>
        public CommonInfo(T id, string text)
        {
            this.Id = id;
            this.Text = text;
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="CommonInfo{T}"/> class.
        /// </summary>
        /// <param name="id">The identifier.</param>
        /// <param name="text">The text.</param>
        /// <param name="code">The code.</param>
        public CommonInfo(T id, string text, string code)
            : this(id, text)
        {
            this.Code = code;
        }
    }
}