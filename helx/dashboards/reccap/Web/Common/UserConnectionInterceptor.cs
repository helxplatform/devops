using Microsoft.EntityFrameworkCore.Diagnostics;
using Renci.ReCCAP.Dashboard.Web.Services;
using System;
using System.Data;
using System.Data.Common;
using System.Threading;
using System.Threading.Tasks;

namespace Renci.ReCCAP.Dashboard.Web.Common
{
    /// <summary>
    ///
    /// </summary>
    /// <seealso cref="Microsoft.EntityFrameworkCore.Diagnostics.DbConnectionInterceptor" />
    public class UserConnectionInterceptor : DbConnectionInterceptor
    {
        private readonly ISessionContextResolver _sessionContextResolver;

        /// <summary>
        /// Initializes a new instance of the <see cref="UserConnectionInterceptor"/> class.
        /// </summary>
        /// <param name="httpContextAccessor">The HTTP context accessor.</param>
        public UserConnectionInterceptor(ISessionContextResolver sessionContextResolver)
        {
            this._sessionContextResolver = sessionContextResolver;
        }

        /// <summary>
        /// Called just after EF has called <see cref="System.Data.Common.DbConnection.OpenAsync()" />.
        /// </summary>
        /// <param name="connection">The connection.</param>
        /// <param name="eventData">Contextual information about the connection.</param>
        /// <param name="cancellationToken">The cancellation token.</param>
        public override async Task ConnectionOpenedAsync(DbConnection connection, ConnectionEndEventData eventData, CancellationToken cancellationToken = default)
        {
            if (connection == null)
                throw new ArgumentNullException(nameof(connection));

            await base.ConnectionOpenedAsync(connection, eventData, cancellationToken);

            var sessionContext = this._sessionContextResolver.ResolveSessionContext();
            if (sessionContext != null)
            {
                using var cmd = connection.CreateCommand();
                PrepareSessionCommand(cmd, sessionContext);
                await cmd.ExecuteNonQueryAsync();
            }
        }

        /// <summary>
        /// Called just after EF has called <see cref="System.Data.Common.DbConnection.Open" />.
        /// </summary>
        /// <param name="connection">The connection.</param>
        /// <param name="eventData">Contextual information about the connection.</param>
        public override void ConnectionOpened(DbConnection connection, ConnectionEndEventData eventData)
        {
            if (connection == null)
                throw new ArgumentNullException(nameof(connection));

            base.ConnectionOpened(connection, eventData);

            var sessionContext = this._sessionContextResolver.ResolveSessionContext();
            if (sessionContext != null)
            {
                using var cmd = connection.CreateCommand();
                PrepareSessionCommand(cmd, sessionContext);
                cmd.ExecuteNonQuery();
            }
        }

        private void PrepareSessionCommand(DbCommand cmd, string sessionContext)
        {
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.CommandText = $"sp_set_session_context";
            var keyParameter = cmd.CreateParameter();
            cmd.Parameters.Add(keyParameter);
            keyParameter.ParameterName = "key";
            keyParameter.Value = "user";
            var valueParameter = cmd.CreateParameter();
            cmd.Parameters.Add(valueParameter);
            valueParameter.ParameterName = "value";
            valueParameter.Value = sessionContext;
            var readOnlyParameter = cmd.CreateParameter();
            cmd.Parameters.Add(readOnlyParameter);
            readOnlyParameter.ParameterName = "read_only";
            readOnlyParameter.Value = 1;
        }
    }
}