namespace Renci.ReCCAP.Dashboard.Web.ViewModels
{
    /// <summary>
    ///
    /// </summary>
    public enum ClientMessageType
    {
        /// <summary>
        /// The success message type
        /// </summary>
        Success = 1,

        /// <summary>
        /// The error message type
        /// </summary>
        Error = 2,

        /// <summary>
        /// The information message type
        /// </summary>
        Info = 3,

        /// <summary>
        /// The warning message type
        /// </summary>
        Warning = 4
    }

    /// <summary>
    ///
    /// </summary>
    public enum ClientMessageMode
    {
        /// <summary>
        /// The default
        /// </summary>
        Default = 1,

        /// <summary>
        /// The toast
        /// </summary>
        Toast = 2,
    }

    public class ClientMessage
    {
        /// <summary>
        /// Gets the type.
        /// </summary>
        /// <value>
        /// The type.
        /// </value>
        public ClientMessageType Type { get; } = ClientMessageType.Info;

        /// <summary>
        /// Gets the position.
        /// </summary>
        /// <value>
        /// The position.
        /// </value>
        public ClientMessageMode Mode { get; } = ClientMessageMode.Default;

        /// <summary>
        /// Gets the text.
        /// </summary>
        /// <value>
        /// The text.
        /// </value>
        public string Text { get; }

        /// <summary>
        /// Gets the title.
        /// </summary>
        /// <value>
        /// The title.
        /// </value>
        public string Title { get; }

        /// <summary>
        /// Initializes a new instance of the <see cref="ClientMessage"/> class.
        /// </summary>
        /// <param name="text">The text.</param>
        public ClientMessage(string text)
        {
            this.Text = text;
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="ClientMessage"/> class.
        /// </summary>
        /// <param name="type">The type.</param>
        /// <param name="text">The text.</param>
        public ClientMessage(ClientMessageType type, string text)
        {
            this.Type = type;
            this.Text = text;
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="ClientMessage"/> class.
        /// </summary>
        /// <param name="mode">The mode.</param>
        /// <param name="text">The text.</param>
        /// <param name="title">The title.</param>
        public ClientMessage(ClientMessageMode mode, string text, string title = null)
        {
            this.Mode = mode;
            this.Text = text;
            this.Title = title;
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="ClientMessage"/> class.
        /// </summary>
        /// <param name="mode">The mode.</param>
        /// <param name="type">The type.</param>
        /// <param name="text">The text.</param>
        /// <param name="title">The title.</param>
        public ClientMessage(ClientMessageMode mode, ClientMessageType type, string text, string title = null)
        {
            this.Mode = mode;
            this.Type = type;
            this.Text = text;
            this.Title = title;
        }
    }
}