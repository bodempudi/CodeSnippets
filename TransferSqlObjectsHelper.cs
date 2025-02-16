 
using System;
using System.Collections.Specialized;
using System.Data.SqlClient;
using System.Text;
using Microsoft.SqlServer.Dts.ManagedMsg;
using Microsoft.SqlServer.Dts.Runtime;
using Microsoft.SqlServer.Management.Common;
using Microsoft.SqlServer.Management.Smo;
using Microsoft.SqlServer.Management.Smo.Agent;

namespace Microsoft.SqlServer.Dts.Tasks.TransferSqlObjects;

internal sealed class TransferSqlObjectsHelper
{
    public string INVALID_CONNSTRING;

    public string INVALID_OBJECTNAME_FORMAT;

    public string INVALID_OBJECTNAME;

    public string TASK_DISPLAY_NAME;

    public string INVALID_SOURCEDATABASE;

    public string INVALID_DESTDATABASE;

    public string INVALID_SERVER;

    public string CANT_GET_OBJECTNAMELIST;

    public SqlServerObjectType ObjectType;

    private const int SQLSERVER2000 = 8;

    private const int SQLSERVER2005 = 9;

    private string m_SourceConnectionID = "";

    private string m_DestinationConnectionID = "";

    private string m_SourceDatabaseName = "";

    private string m_DestinationDatabaseName = "";

    private bool m_DropObjectAtDestination;

    private bool m_CopySchema = true;

    private bool m_CopyData = true;

    private Database m_SourceDatabase;

    private Database m_DestinationDatabase;

    private Server m_SourceServer;

    private Server m_DestinationServer;

    private Transfer m_TransObject;

    public string SourceConnection
    {
        get
        {
            return m_SourceConnectionID;
        }
        set
        {
            m_SourceConnectionID = value;
        }
    }

    public string DestinationConnection
    {
        get
        {
            return m_DestinationConnectionID;
        }
        set
        {
            m_DestinationConnectionID = value;
        }
    }

    public string SourceDatabaseName
    {
        get
        {
            return m_SourceDatabaseName;
        }
        set
        {
            m_SourceDatabaseName = value;
        }
    }

    public string DestinationDatabaseName
    {
        get
        {
            return m_DestinationDatabaseName;
        }
        set
        {
            m_DestinationDatabaseName = value;
        }
    }

    public int NumberOfElements
    {
        get
        {
            if (m_TransObject == null)
            {
                return 0;
            }

            if (((TransferBase)m_TransObject).ObjectList == null)
            {
                return 0;
            }

            return ((TransferBase)m_TransObject).ObjectList.Count;
        }
    }

    public bool DropObjectAtDestination
    {
        get
        {
            return m_DropObjectAtDestination;
        }
        set
        {
            m_DropObjectAtDestination = value;
        }
    }

    public bool CopySchema
    {
        get
        {
            return m_CopySchema;
        }
        set
        {
            m_CopySchema = value;
        }
    }

    public bool CopyData
    {
        get
        {
            return m_CopyData;
        }
        set
        {
            m_CopyData = value;
        }
    }

    public Database SourceDatabase => m_SourceDatabase;

    public Database DestinationDatabase => m_DestinationDatabase;

    public Server SourceServer => m_SourceServer;

    public Server DestinationServer => m_DestinationServer;

    public Transfer TransferObject => m_TransObject;

    public TransferSqlObjectsHelper(string taskDisplayName, string invalidConnString, string invalidObjectNameFormat, string invalidObjectName, string invalidSourceDatabase, string invalidDestinationDatabase, string invalidServer, string cantGetObjectNameList)
    {
        TASK_DISPLAY_NAME = taskDisplayName;
        INVALID_CONNSTRING = invalidConnString;
        INVALID_OBJECTNAME_FORMAT = invalidObjectNameFormat;
        INVALID_OBJECTNAME = invalidObjectName;
        INVALID_SOURCEDATABASE = invalidSourceDatabase;
        INVALID_DESTDATABASE = invalidDestinationDatabase;
        INVALID_SERVER = invalidServer;
        CANT_GET_OBJECTNAMELIST = cantGetObjectNameList;
    }

    public bool AddSqlServerObject(string strObjectName, object objectToTransfer, IDTSComponentEvents events)
    {
        if (objectToTransfer == null)
        {
            FireEvent(EventType.Error, string.Format(INVALID_OBJECTNAME, strObjectName), events, 0, 0, 0);
            return false;
        }

        ((TransferBase)m_TransObject).ObjectList.Add(objectToTransfer);
        return true;
    }

    public bool CheckDatabasesList(string serverName, StringCollection m_DatabasesList, string m_SourceConnectionID, Connections connections, IDTSComponentEvents events)
    {
        if (string.IsNullOrEmpty(serverName) || m_DatabasesList == null || m_DatabasesList.Count == 0)
        {
            return false;
        }

        bool result = true;
        ConnectionManager val = connections[(object)serverName];
        Server val2 = null;
        try
        {
            object obj = val.AcquireConnection((object)null);
            val2 = (Server)((obj is Server) ? obj : null);
            if (val2 == null)
            {
                FireEvent(EventType.Error, string.Format(INVALID_SERVER, serverName), events, 0, 0, 0);
                return false;
            }

            StringEnumerator enumerator = m_DatabasesList.GetEnumerator();
            try
            {
                while (enumerator.MoveNext())
                {
                    string current = enumerator.Current;
                    if (!((SimpleObjectCollectionBase)val2.Databases).Contains(current))
                    {
                        result = false;
                        FireEvent(EventType.Error, string.Format(INVALID_SOURCEDATABASE, current), events, 0, 0, 0);
                    }
                }
            }
            finally
            {
                if (enumerator is IDisposable disposable)
                {
                    disposable.Dispose();
                }
            }

            return result;
        }
        finally
        {
            if (val2 != null && (DtsObject)(object)val != (DtsObject)null)
            {
                val.ReleaseConnection((object)val2);
            }
        }
    }

    public bool CheckDatabase(Database databaseName, bool bSource, IDTSComponentEvents events)
    {
        if (databaseName == null)
        {
            FireEvent(EventType.Error, bSource ? INVALID_SOURCEDATABASE : INVALID_SOURCEDATABASE, events, 0, 0, 0);
            return false;
        }

        return true;
    }

    public bool CheckFormatOfString(int iLen, int iTotLen, IDTSComponentEvents events)
    {
        if (iLen < 0 || iLen > iTotLen)
        {
            FireEvent(EventType.Error, INVALID_OBJECTNAME_FORMAT, events, 0, 0, 0);
            return false;
        }

        return true;
    }

    public bool CheckLoginsList(string serverName, StringCollection m_LoginsList, string m_SourceConnectionID, Connections connections, IDTSComponentEvents events)
    {
        //IL_007d: Unknown result type (might be due to invalid IL or missing references)
        if (string.IsNullOrEmpty(serverName) || m_LoginsList == null || m_LoginsList.Count == 0)
        {
            return false;
        }

        bool flag = false;
        ConnectionManager val = connections[(object)serverName];
        Server val2 = null;
        try
        {
            object obj = val.AcquireConnection((object)null);
            val2 = (Server)((obj is Server) ? obj : null);
            if (val2 == null)
            {
                FireEvent(EventType.Error, string.Format(INVALID_SERVER, serverName), events, 0, 0, 0);
                return false;
            }

            StringEnumerator enumerator = m_LoginsList.GetEnumerator();
            try
            {
                while (enumerator.MoveNext())
                {
                    string current = enumerator.Current;
                    bool flag2 = false;
                    foreach (Login item in (SmoCollectionBase)val2.Logins)
                    {
                        if (((NamedSmoObject)item).Name == current)
                        {
                            flag2 = true;
                        }
                    }

                    if (!flag2)
                    {
                        flag = true;
                        FireEvent(EventType.Error, string.Format(INVALID_OBJECTNAME, current), events, 0, 0, 0);
                    }
                }
            }
            finally
            {
                if (enumerator is IDisposable disposable)
                {
                    disposable.Dispose();
                }
            }

            return (!flag) ? true : false;
        }
        finally
        {
            if ((DtsObject)(object)val != (DtsObject)null && val2 != null)
            {
                val.ReleaseConnection((object)val2);
            }
        }
    }

    public bool CheckServer(Server serverName, bool bSource, IDTSComponentEvents events)
    {
        if (serverName == null)
        {
            FireEvent(EventType.Error, string.Format(INVALID_SERVER, bSource ? SourceConnection : DestinationConnection), events, 0, 0, 0);
            return false;
        }

        return true;
    }

    public SameConnections ConnectionsAreTheSame(string srcConn, string destConn, Connections connections, IDTSComponentEvents events)
    {
        //IL_006f: Unknown result type (might be due to invalid IL or missing references)
        //IL_0075: Expected O, but got Unknown
        //IL_00a4: Unknown result type (might be due to invalid IL or missing references)
        //IL_00aa: Expected O, but got Unknown
        Server val = null;
        Server val2 = null;
        try
        {
            if (string.IsNullOrEmpty(srcConn))
            {
                FireEvent(EventType.Error, string.Format(INVALID_CONNSTRING, srcConn), events, 0, 0, 0);
                return SameConnections.Error;
            }

            if (string.IsNullOrEmpty(destConn))
            {
                FireEvent(EventType.Error, string.Format(INVALID_CONNSTRING, destConn), events, 0, 0, 0);
                return SameConnections.Error;
            }

            if (srcConn == destConn)
            {
                return SameConnections.Same;
            }

            val = (Server)connections[(object)srcConn].AcquireConnection((object)null);
            if (val == null)
            {
                FireEvent(EventType.Error, string.Format(INVALID_SERVER, srcConn), events, 0, 0, 0);
                return SameConnections.Error;
            }

            val2 = (Server)connections[(object)destConn].AcquireConnection((object)null);
            if (val2 == null)
            {
                FireEvent(EventType.Error, string.Format(INVALID_SERVER, destConn), events, 0, 0, 0);
                return SameConnections.Error;
            }

            if (val.ConnectionContext.TrueName.ToUpper() == val2.ConnectionContext.TrueName.ToUpper())
            {
                return SameConnections.Same;
            }
        }
        catch (Exception ex)
        {
            FireEvent(EventType.Error, ex.Message, events, 0, 0, 0);
            return SameConnections.Error;
        }
        finally
        {
            if (val != null)
            {
                connections[(object)srcConn].ReleaseConnection((object)val);
            }

            if (val2 != null)
            {
                connections[(object)destConn].ReleaseConnection((object)val2);
            }
        }

        return SameConnections.Different;
    }

    public void ExtractObjectNameListFromXml(string strValue, ref StringCollection strCol, IDTSInfoEvents events)
    {
        try
        {
            if (strValue == "0")
            {
                return;
            }

            int iEndPosition = 0;
            _ = strValue.Length;
            if (!GetLengthFromString(strValue, 0, out iEndPosition, null))
            {
                events.FireError(0, TASK_DISPLAY_NAME, INVALID_OBJECTNAME_FORMAT, "", 0);
                return;
            }

            long num = Convert.ToInt64(strValue.Substring(0, iEndPosition));
            int iEndPosition2 = 0;
            int num2 = 0;
            iEndPosition++;
            for (long num3 = 0L; num3 < num; num3++)
            {
                if (!GetLengthFromString(strValue, iEndPosition, out iEndPosition2, null))
                {
                    events.FireError(0, TASK_DISPLAY_NAME, INVALID_OBJECTNAME_FORMAT, "", 0);
                    break;
                }

                iEndPosition2 -= iEndPosition;
                num2 = iEndPosition2;
                iEndPosition2 = Convert.ToInt32(strValue.Substring(iEndPosition, iEndPosition2));
                iEndPosition += num2 + 1;
                strCol.Add(strValue.Substring(iEndPosition, iEndPosition2));
                iEndPosition += iEndPosition2 + 1;
            }
        }
        catch (Exception)
        {
            events.FireError(0, TASK_DISPLAY_NAME, INVALID_OBJECTNAME_FORMAT, "", 0);
        }
    }

    public void FireEvent(EventType eventType, string evMessage, IDTSComponentEvents events, int percentComplete, int progressCountLow, int progressCountHigh)
    {
        //IL_0012: Unknown result type (might be due to invalid IL or missing references)
        //IL_0018: Expected O, but got Unknown
        ErrorSupport val = new ErrorSupport(DtsConvert.GetExtendedInterface(events), TASK_DISPLAY_NAME, string.Empty, 0);
        bool flag = true;
        if (events == null)
        {
            return;
        }

        switch (eventType)
        {
            case EventType.Error:
                {
                    bool flag2 = default(bool);
                    val.FireErrorWithArgs(-1073548540, ref flag2, new object[1] { evMessage });
                    break;
                }
            case EventType.Warning:
                val.FireWarningWithArgs(-2147290364, new object[1] { evMessage });
                break;
            case EventType.Information:
                if (flag)
                {
                    val.FireInformationWithArgs(1073935108, ref flag, new object[1] { evMessage });
                }

                break;
            case EventType.Progress:
                if (flag)
                {
                    events.FireProgress(evMessage, percentComplete, progressCountLow, progressCountHigh, (string)null, ref flag);
                }

                break;
        }
    }

    private Database GetDatabase(bool bSource, Server server, string DBName, IDTSComponentEvents events)
    {
        Database val = server.Databases[DBName];
        if (val == null)
        {
            FireEvent(EventType.Error, bSource ? INVALID_SOURCEDATABASE : INVALID_DESTDATABASE, events, 0, 0, 0);
        }

        return val;
    }

    public bool GetLengthFromString(string strValue, int iStartPosition, out int iEndPosition, IDTSComponentEvents events)
    {
        iEndPosition = strValue.IndexOf(',', iStartPosition);
        return CheckFormatOfString(iEndPosition, strValue.Length, events);
    }

    public bool GetStoredProceduresList(SqlConnection sqlConn, ref StringCollection strColl, IDTSComponentEvents events)
    {
        if (sqlConn == null)
        {
            return false;
        }

        try
        {
            SqlDataReader sqlDataReader = new SqlCommand("select name from sysobjects where type = 'p'", sqlConn).ExecuteReader();
            while (sqlDataReader.Read())
            {
                strColl.Add(sqlDataReader.GetString(0));
            }

            return true;
        }
        catch (Exception ex)
        {
            FireEvent(EventType.Error, string.Format(CANT_GET_OBJECTNAMELIST, ex.Message), events, 0, 0, 0);
            return false;
        }
    }

    public void WriteLog(IDTSLogging log, string eventName, string message)
    {
        if (log != null)
        {
            byte[] array = null;
            log.Log(eventName, (string)null, (string)null, (string)null, (string)null, (string)null, message, DateTime.Now, DateTime.Now, 0, ref array);
        }
    }

    public string GetObjectNameList(StringCollection strColNameList, IDTSInfoEvents events)
    {
        StringBuilder stringBuilder = null;
        try
        {
            if (strColNameList.Count == 0)
            {
                return "0";
            }

            stringBuilder = new StringBuilder();
            stringBuilder.Append(strColNameList.Count.ToString((IFormatProvider)null));
            stringBuilder.Append(",");
            StringEnumerator enumerator = strColNameList.GetEnumerator();
            try
            {
                while (enumerator.MoveNext())
                {
                    string current = enumerator.Current;
                    stringBuilder.Append(current.Length);
                    stringBuilder.Append(",");
                    stringBuilder.Append(current);
                    stringBuilder.Append(",");
                }
            }
            finally
            {
                if (enumerator is IDisposable disposable)
                {
                    disposable.Dispose();
                }
            }
        }
        catch (Exception)
        {
            events.FireError(0, TASK_DISPLAY_NAME, INVALID_OBJECTNAME_FORMAT, "", 0);
        }

        return stringBuilder.ToString();
    }

    public bool ServerIs2005OrNewer(string serverID, Connections connections, IDTSComponentEvents events)
    {
        //IL_0030: Unknown result type (might be due to invalid IL or missing references)
        //IL_0036: Expected O, but got Unknown
        if (string.IsNullOrEmpty(serverID))
        {
            FireEvent(EventType.Error, string.Format(INVALID_CONNSTRING, serverID), events, 0, 0, 0);
            return false;
        }

        Server val = null;
        try
        {
            val = (Server)connections[(object)serverID].AcquireConnection((object)null);
            if (9 <= val.Information.Version.Major)
            {
                return true;
            }

            return false;
        }
        finally
        {
            if (val != null)
            {
                connections[(object)serverID].ReleaseConnection((object)val);
            }
        }
    }

    public bool SetGenericProperties(Connections connections, IDTSComponentEvents events)
    {
        //IL_0015: Unknown result type (might be due to invalid IL or missing references)
        //IL_001f: Expected O, but got Unknown
        //IL_0036: Unknown result type (might be due to invalid IL or missing references)
        //IL_0040: Expected O, but got Unknown
        //IL_0098: Unknown result type (might be due to invalid IL or missing references)
        //IL_00a2: Expected O, but got Unknown
        //IL_008b: Unknown result type (might be due to invalid IL or missing references)
        //IL_0095: Expected O, but got Unknown
        try
        {
            ConnectionManager val = connections[(object)m_SourceConnectionID];
            m_SourceServer = (Server)val.AcquireConnection((object)null);
            val = null;
            val = connections[(object)m_DestinationConnectionID];
            m_DestinationServer = (Server)val.AcquireConnection((object)null);
            m_SourceDatabase = null;
            m_DestinationDatabase = null;
            if (!string.IsNullOrEmpty(m_SourceDatabaseName))
            {
                m_SourceDatabase = GetDatabase(bSource: true, m_SourceServer, m_SourceDatabaseName, events);
                if (m_SourceDatabase == null)
                {
                    return false;
                }

                m_TransObject = new Transfer(m_SourceDatabase);
            }
            else
            {
                m_TransObject = new Transfer();
            }

            if (!string.IsNullOrEmpty(m_DestinationDatabaseName))
            {
                m_DestinationDatabase = GetDatabase(bSource: false, m_DestinationServer, m_DestinationDatabaseName, events);
                if (m_DestinationDatabase == null)
                {
                    return false;
                }
            }

            if (m_TransObject == null)
            {
                FireEvent(EventType.Error, INVALID_SOURCEDATABASE, events, 0, 0, 0);
                return false;
            }

            ((TransferBase)m_TransObject).CopyAllObjects = false;
            ((TransferBase)m_TransObject).DestinationServer = m_DestinationServer.Name;
            ((TransferBase)m_TransObject).DestinationDatabase = ((!string.IsNullOrEmpty(m_DestinationDatabaseName)) ? ((NamedSmoObject)m_DestinationDatabase).Name : "");
            ((TransferBase)m_TransObject).DestinationLoginSecure = ((ConnectionSettings)m_DestinationServer.ConnectionContext).LoginSecure;
            if (!((ConnectionSettings)m_DestinationServer.ConnectionContext).LoginSecure)
            {
                ((TransferBase)m_TransObject).DestinationLogin = ((ConnectionSettings)m_DestinationServer.ConnectionContext).Login;
                ((TransferBase)m_TransObject).DestinationPassword = ((ConnectionSettings)m_DestinationServer.ConnectionContext).Password;
            }

            ((TransferBase)m_TransObject).CreateTargetDatabase = false;
            ((TransferBase)m_TransObject).DropDestinationObjectsFirst = m_DropObjectAtDestination;
            ((TransferBase)m_TransObject).CopySchema = m_CopySchema;
            ((TransferBase)m_TransObject).CopyData = m_CopyData;
            return true;
        }
        catch (Exception ex)
        {
            FireEvent(EventType.Error, ex.Message, events, 0, 0, 0);
            return false;
        }
    }

    public void TransferObjects()
    {
        m_TransObject.TransferData();
    }

    public bool VerifyServer(string serverName, Connections connections, IDTSComponentEvents events)
    {
        ConnectionManager val = null;
        Server val2 = null;
        try
        {
            if (string.IsNullOrEmpty(serverName))
            {
                FireEvent(EventType.Error, string.Format(INVALID_CONNSTRING, serverName), events, 0, 0, 0);
                return false;
            }

            val = connections[(object)serverName];
            if (val.CreationName != "SMOServer")
            {
                FireEvent(EventType.Error, string.Format(INVALID_CONNSTRING, serverName), events, 0, 0, 0);
                return false;
            }

            object obj = val.AcquireConnection((object)null);
            val2 = (Server)((obj is Server) ? obj : null);
            if (val2 == null)
            {
                FireEvent(EventType.Error, string.Format(INVALID_SERVER, serverName), events, 0, 0, 0);
                return false;
            }

            return true;
        }
        catch (Exception ex)
        {
            FireEvent(EventType.Error, ex.Message, events, 0, 0, 0);
            return false;
        }
        finally
        {
            if ((DtsObject)(object)val != (DtsObject)null && val2 != null)
            {
                val.ReleaseConnection((object)val2);
            }
        }
    }

    public bool VerifyDatabase(bool bSkipVerificationOfServer, bool bSource, string serverName, string DBName, Connections connections, IDTSComponentEvents events)
    {
        //IL_0055: Unknown result type (might be due to invalid IL or missing references)
        //IL_005b: Expected O, but got Unknown
        if (string.IsNullOrEmpty(DBName))
        {
            string format = (bSource ? INVALID_SOURCEDATABASE : INVALID_DESTDATABASE);
            FireEvent(EventType.Error, string.Format(format, DBName), events, 0, 0, 0);
            return false;
        }

        if (!bSkipVerificationOfServer && !VerifyServer(serverName, connections, events))
        {
            return false;
        }

        ConnectionManager val = connections[(object)serverName];
        Server val2 = null;
        try
        {
            val2 = (Server)val.AcquireConnection((object)null);
            if (val2.Databases[DBName] == null)
            {
                string format2 = (bSource ? INVALID_SOURCEDATABASE : INVALID_DESTDATABASE);
                FireEvent(EventType.Error, string.Format(format2, DBName), events, 0, 0, 0);
                return false;
            }

            return true;
        }
        finally
        {
            if ((DtsObject)(object)val != (DtsObject)null && val2 != null)
            {
                val.ReleaseConnection((object)val2);
            }
        }
    }

    public bool VerifyDatabase(Server server, bool bSource, string DBName, IDTSComponentEvents events)
    {
        if (string.IsNullOrEmpty(DBName))
        {
            FireEvent(EventType.Error, bSource ? INVALID_SOURCEDATABASE : INVALID_DESTDATABASE, events, 0, 0, 0);
            return false;
        }

        if (server.Databases[DBName] == null)
        {
            FireEvent(EventType.Error, bSource ? INVALID_SOURCEDATABASE : INVALID_DESTDATABASE, events, 0, 0, 0);
            return false;
        }

        return true;
    }

    public bool VerifyJobs(StringCollection jobsList, string connectionID, Connections connections, IDTSComponentEvents events)
    {
        ConnectionManager val = connections[(object)connectionID];
        Server val2 = null;
        try
        {
            object obj = val.AcquireConnection((object)null);
            val2 = (Server)((obj is Server) ? obj : null);
            if (val2 == null)
            {
                FireEvent(EventType.Error, string.Format(INVALID_SERVER, connectionID), events, 0, 0, 0);
                return false;
            }

            Job val3 = null;
            StringEnumerator enumerator = jobsList.GetEnumerator();
            try
            {
                while (enumerator.MoveNext())
                {
                    string current = enumerator.Current;
                    val3 = val2.JobServer.Jobs[current];
                    if (val3 == null)
                    {
                        FireEvent(EventType.Error, string.Format(INVALID_OBJECTNAME, current), events, 0, 0, 0);
                        return false;
                    }
                }
            }
            finally
            {
                if (enumerator is IDisposable disposable)
                {
                    disposable.Dispose();
                }
            }

            return true;
        }
        finally
        {
            if ((DtsObject)(object)val != (DtsObject)null && val2 != null)
            {
                val.ReleaseConnection((object)val2);
            }
        }
    }

    public bool VerifyErrorMessages(StringCollection errorMessagesList, StringCollection errMsgLangs, string connectionID, Connections connections, IDTSComponentEvents events)
    {
        ConnectionManager val = null;
        Server val2 = null;
        try
        {
            val = connections[(object)connectionID];
            object obj = val.AcquireConnection((object)null);
            val2 = (Server)((obj is Server) ? obj : null);
            if (val2 == null)
            {
                FireEvent(EventType.Error, string.Format(INVALID_SERVER, connectionID), events, 0, 0, 0);
                return false;
            }

            UserDefinedMessage val3 = null;
            for (int i = 0; i < errorMessagesList.Count; i++)
            {
                val3 = val2.UserDefinedMessages.ItemByIdAndLanguageId(Convert.ToInt32(errorMessagesList[i]), Convert.ToInt32(errMsgLangs[i]));
                if (val3 == null)
                {
                    FireEvent(EventType.Error, string.Format(INVALID_OBJECTNAME, errorMessagesList[i]), events, 0, 0, 0);
                    return false;
                }
            }

            return true;
        }
        catch (Exception ex)
        {
            FireEvent(EventType.Error, ex.Message, events, 0, 0, 0);
            return false;
        }
        finally
        {
            if ((DtsObject)(object)val != (DtsObject)null && val2 != null)
            {
                val.ReleaseConnection((object)val2);
            }
        }
    }

    public bool VerifyStoredProcedures(StringCollection storedProceduresList, string connectionID, string databaseName, Connections connections, IDTSComponentEvents events)
    {
        ConnectionManager val = null;
        Server val2 = null;
        try
        {
            val = connections[(object)connectionID];
            object obj = val.AcquireConnection((object)null);
            val2 = (Server)((obj is Server) ? obj : null);
            if (val2 == null)
            {
                FireEvent(EventType.Error, string.Format(INVALID_SERVER, connectionID), events, 0, 0, 0);
                return false;
            }

            StoredProcedure val3 = null;
            StringEnumerator enumerator = storedProceduresList.GetEnumerator();
            try
            {
                while (enumerator.MoveNext())
                {
                    string current = enumerator.Current;
                    val3 = val2.Databases[databaseName].StoredProcedures[current];
                    if (val3 == null)
                    {
                        FireEvent(EventType.Error, string.Format(INVALID_OBJECTNAME, current), events, 0, 0, 0);
                        return false;
                    }
                }
            }
            finally
            {
                if (enumerator is IDisposable disposable)
                {
                    disposable.Dispose();
                }
            }

            return true;
        }
        finally
        {
            if ((DtsObject)(object)val != (DtsObject)null && val2 != null)
            {
                val.ReleaseConnection((object)val2);
            }
        }
    }
}
