Imports MySql.Data.MySqlClient
Imports System.Web.Configuration

''' <summary>
''' Centralised database connection factory.
''' Returns an open MySqlConnection using the CrewMgmtConn connection string from Web.config.
''' </summary>
Module DbHelper

    Public ReadOnly ConnStr As String =
        WebConfigurationManager.ConnectionStrings.Item("CrewMgmtConn").ConnectionString

    ''' <summary>Returns an already-open MySqlConnection. Caller MUST dispose.</summary>
    Public Function GetConnection() As MySqlConnection
        Dim cn As New MySqlConnection(ConnStr)
        cn.Open()
        Return cn
    End Function

    ''' <summary>Execute a scalar query. Returns DBNull.Value on error.</summary>
    Public Function ExecuteScalar(sql As String, ParamArray params() As MySqlParameter) As Object
        Using cn As MySqlConnection = GetConnection()
            Using cmd As New MySqlCommand(sql, cn)
                cmd.Parameters.AddRange(params)
                Return cmd.ExecuteScalar()
            End Using
        End Using
    End Function

    ''' <summary>Execute a non-query (INSERT/UPDATE/DELETE). Returns rows affected.</summary>
    Public Function ExecuteNonQuery(sql As String, ParamArray params() As MySqlParameter) As Integer
        Using cn As MySqlConnection = GetConnection()
            Using cmd As New MySqlCommand(sql, cn)
                cmd.Parameters.AddRange(params)
                Return cmd.ExecuteNonQuery()
            End Using
        End Using
    End Function

    ''' <summary>Fill and return a DataTable from an ad-hoc SQL or stored procedure.</summary>
    Public Function FillDataTable(sql As String, cmdType As System.Data.CommandType,
                                  ParamArray params() As MySqlParameter) As System.Data.DataTable
        Dim dt As New System.Data.DataTable()
        Using cn As MySqlConnection = GetConnection()
            Using cmd As New MySqlCommand(sql, cn)
                cmd.CommandType = cmdType
                cmd.Parameters.AddRange(params)
                Using da As New MySqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using
        Return dt
    End Function

End Module
