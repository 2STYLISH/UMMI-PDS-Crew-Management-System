Imports MySql.Data.MySqlClient
Imports System.Web

''' <summary>
''' Audit trail logging helpers — mirrors GetAdmin / GetPortalAct in PDS production.
''' Writes to tbl_activity_log.
''' </summary>
Public Module AuditHelper

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

    ''' <summary>
    ''' FR-CM-71: Privacy-safe audit logging for applicant document events.
    ''' Records upload, validation, extraction, linkage, access, or cleanup events with outcomes.
    ''' GUARANTEE: Strictly never logs raw file contents, applicant PII, or security tokens.
    ''' </summary>
    Public Sub LogApplicantDocumentEvent(action As String, fileCount As Integer, outcome As String, Optional detailSummary As String = "")
        Dim context As HttpContext = HttpContext.Current
        Dim userIdentifier As String = "Applicant"
        Dim userId As String = "0"

        If context IsNot Nothing Then
            If context.Session IsNot Nothing AndAlso context.Session("UserID") IsNot Nothing Then
                userId = context.Session("UserID").ToString()
                If context.Session("UserFullname") IsNot Nothing Then
                    userIdentifier = context.Session("UserFullname").ToString()
                End If
            ElseIf context.Session IsNot Nothing AndAlso context.Session("ApplicantLinkID") IsNot Nothing Then
                userIdentifier = "Applicant Link #" & context.Session("ApplicantLinkID").ToString()
            End If
        End If

        Dim sanitizedDetail As String = If(Not String.IsNullOrEmpty(detailSummary), " (" & detailSummary & ")", "")
        Dim activity As String = String.Format("{0} | Files: {1} | Outcome: {2}{3}", action, fileCount, outcome, sanitizedDetail)
        LogActivity(activity, userId, "ApplicantDocument", userIdentifier)
    End Sub

    ''' <summary>
    ''' FR-CM-71: Privacy-safe audit logging for applicant AI extraction events.
    ''' Records document extraction events with category 'ApplicantAiExtract'.
    ''' GUARANTEE: Strictly never logs raw extracted text, field values, filenames, or applicant PII.
    ''' </summary>
    Public Sub LogApplicantExtractionEvent(action As String, itemCount As Integer, outcome As String, durationMs As Long, Optional modeSummary As String = "")
        Dim context As HttpContext = HttpContext.Current
        Dim userIdentifier As String = "Applicant"
        Dim userId As String = "0"

        If context IsNot Nothing Then
            If context.Session IsNot Nothing AndAlso context.Session("UserID") IsNot Nothing Then
                userId = context.Session("UserID").ToString()
                If context.Session("UserFullname") IsNot Nothing Then
                    userIdentifier = context.Session("UserFullname").ToString()
                End If
            ElseIf context.Session IsNot Nothing AndAlso context.Session("ApplicantLinkID") IsNot Nothing Then
                userIdentifier = "Applicant Link #" & context.Session("ApplicantLinkID").ToString()
            End If
        End If

        Dim sanitizedMode As String = If(Not String.IsNullOrEmpty(modeSummary), " | Mode: " & modeSummary, "")
        Dim activity As String = String.Format("{0} | Items: {1} | Outcome: {2} | Duration: {3}ms{4}", action, itemCount, outcome, durationMs, sanitizedMode)
        LogActivity(activity, userId, "ApplicantAiExtract", userIdentifier)
    End Sub

    ''' <summary>
    ''' FR-CM-71: Privacy-safe audit logging for applicant AI extraction validation and mapping events.
    ''' Records document count, mapped field count, conflict count, and unresolved count.
    ''' GUARANTEE: Strictly never logs raw extracted text, applicant PII, or security tokens.
    ''' </summary>
    Public Sub LogApplicantMappingEvent(docsCount As Integer, fieldsCount As Integer, conflictsCount As Integer, unresolvedCount As Integer, durationMs As Long, outcome As String)
        Dim context As HttpContext = HttpContext.Current
        Dim userIdentifier As String = "Applicant"
        Dim userId As String = "0"

        If context IsNot Nothing Then
            If context.Session IsNot Nothing AndAlso context.Session("UserID") IsNot Nothing Then
                userId = context.Session("UserID").ToString()
                If context.Session("UserFullname") IsNot Nothing Then
                    userIdentifier = context.Session("UserFullname").ToString()
                End If
            ElseIf context.Session IsNot Nothing AndAlso context.Session("ApplicantLinkID") IsNot Nothing Then
                userIdentifier = "Applicant Link #" & context.Session("ApplicantLinkID").ToString()
            End If
        End If

        Dim activity As String = String.Format("AI Extraction Mapping | Docs: {0} | Fields: {1} | Conflicts: {2} | Unresolved: {3} | Outcome: {4} | Duration: {5}ms",
                                               docsCount, fieldsCount, conflictsCount, unresolvedCount, outcome, durationMs)
        LogActivity(activity, userId, "ApplicantAiMapping", userIdentifier)
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
