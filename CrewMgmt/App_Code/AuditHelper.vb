Imports MySql.Data.MySqlClient
Imports System.Web

''' <summary>
''' Audit trail logging helpers — mirrors GetAdmin / GetPortalAct in PDS production.
''' Writes to tbl_activity_log.
''' </summary>
Module AuditHelper

    ''' <summary>
    ''' Log a system/navigation event.
    ''' act   = action verb  (e.g. "Visited", "Searched", "Attempted to visit")
    ''' id    = user ID
    ''' cat   = category    (e.g. "QueryCrew", "ApplicantPool", "Login")
    ''' val   = detail      (e.g. search string, crew name, page name)
    ''' </summary>
    Public Sub GetAdmin(act As String, id As String, cat As String, val As String)
        Dim fullname As String = String.Empty
        Dim context As HttpContext = HttpContext.Current
        If context IsNot Nothing AndAlso context.Session("UserFullname") IsNot Nothing Then
            fullname = context.Session("UserFullname").ToString()
        End If
        LogActivity(act & " " & val, id, cat, fullname)
    End Sub

    ''' <summary>Log a personnel-specific event with a PDS record reference.</summary>
    Public Sub GetPortalAct(act As String, id As String, cat As String, activity As String, PDSID As String)
        Dim fullname As String = String.Empty
        Dim context As HttpContext = HttpContext.Current
        If context IsNot Nothing AndAlso context.Session("UserFullname") IsNot Nothing Then
            fullname = context.Session("UserFullname").ToString()
        End If
        LogActivity(act & " | " & activity & " | PDS-ID: " & PDSID, id, cat, fullname)
    End Sub

    ''' <summary>
    ''' Mirror of GetAdmin specifically for crew profile views (logs personnel name separately).
    ''' </summary>
    Public Sub GetPersonnelAct(act As String, id As String, cat As String, val As String)
        Dim fullname As String = String.Empty
        Dim context As HttpContext = HttpContext.Current
        If context IsNot Nothing AndAlso context.Session("UserFullname") IsNot Nothing Then
            fullname = context.Session("UserFullname").ToString()
        End If
        LogActivity(act & " " & val, id, cat, fullname)
    End Sub

    ' --------------------------------------------------------
    Private Sub LogActivity(activity As String, userId As String, category As String, fullname As String)
        Try
            Dim ip As String = GetIPAddress()
            Dim uid As Integer = 0
            Integer.TryParse(userId, uid)

            Dim sql As String = "INSERT INTO tbl_activity_log (user_id, activity, fullname, category, ip_address) " &
                                "VALUES (@uid, @act, @fn, @cat, @ip)"
            Using cn As New MySqlConnection(DbHelper.ConnStr)
                cn.Open()
                Using cmd As New MySqlCommand(sql, cn)
                    cmd.Parameters.AddWithValue("@uid", If(uid = 0, DBNull.Value, CObj(uid)))
                    cmd.Parameters.AddWithValue("@act", activity)
                    cmd.Parameters.AddWithValue("@fn",  fullname)
                    cmd.Parameters.AddWithValue("@cat", category)
                    cmd.Parameters.AddWithValue("@ip",  ip)
                    cmd.ExecuteNonQuery()
                End Using
            End Using
        Catch ex As Exception
            ' Fail silently — audit must not break the main workflow
        End Try
    End Sub

    Private Function GetIPAddress() As String
        Dim context As HttpContext = HttpContext.Current
        If context Is Nothing Then Return "0.0.0.0"
        Dim ip As String = context.Request.ServerVariables("HTTP_X_FORWARDED_FOR")
        If String.IsNullOrEmpty(ip) Then ip = context.Request.ServerVariables("REMOTE_ADDR")
        Return ip
    End Function

End Module
