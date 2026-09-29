Imports System.IO
Imports System.Web
Imports System.Web.SessionState
Imports MySql.Data.MySqlClient

Public Class AssessmentAttachmentHandler
    Implements IHttpHandler, IRequiresSessionState

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    Public Sub ProcessRequest(ByVal context As HttpContext) Implements IHttpHandler.ProcessRequest
        ' 1. Authentication check
        If context.Session Is Nothing OrElse context.Session("UserID") Is Nothing OrElse
           String.IsNullOrEmpty(context.Session("UserID").ToString()) Then
            context.Response.StatusCode = 403
            context.Response.StatusDescription = "Forbidden"
            context.Response.ContentType = "text/plain"
            context.Response.Write("Access Denied: Authentication required.")
            Return
        End If

        ' 2. Role check (must have permission to view crew profiles)
        Dim role As String = If(context.Session("UserType") IsNot Nothing, context.Session("UserType").ToString(), "")
        Dim allowedRoles As String() = {
            ROLE_MANNING_STAFF, ROLE_DOCUMENTATION_OFFICER, ROLE_SUPER_ADMIN,
            ROLE_ADMIN, ROLE_PRINCIPAL, ROLE_VESSEL_OWNER
        }
        Dim isRoleAllowed As Boolean = False
        For Each r As String In allowedRoles
            If String.Equals(role, r, StringComparison.OrdinalIgnoreCase) Then
                isRoleAllowed = True
                Exit For
            End If
        Next
        If Not isRoleAllowed Then
            context.Response.StatusCode = 403
            context.Response.StatusDescription = "Forbidden"
            context.Response.ContentType = "text/plain"
            context.Response.Write("Access Denied: Role not authorized to view crew assessment attachments.")
            Return
        End If

        ' 3. Assessment / Contact details permission check (CanViewContactDetails)
        If Not CanViewContactDetails() Then
            context.Response.StatusCode = 403
            context.Response.StatusDescription = "Forbidden"
            context.Response.ContentType = "text/plain"
            context.Response.Write("Access Denied: You do not have permission to view crew assessment details.")
            Return
        End If

        ' 4. Identify requested comment/attachment
        Dim commentIdStr As String = context.Request.QueryString("cid")
        If String.IsNullOrEmpty(commentIdStr) Then
            commentIdStr = context.Request.QueryString("comment_id")
        End If
        Dim fileParam As String = context.Request.QueryString("file")
        If String.IsNullOrEmpty(fileParam) Then
            fileParam = context.Request.QueryString("img_id")
        End If

        Dim commentId As Integer = 0
        Dim hasCommentId As Boolean = Not String.IsNullOrEmpty(commentIdStr) AndAlso Integer.TryParse(commentIdStr, commentId) AndAlso commentId > 0

        If Not hasCommentId AndAlso String.IsNullOrWhiteSpace(fileParam) Then
            context.Response.StatusCode = 400
            context.Response.StatusDescription = "Bad Request"
            context.Response.ContentType = "text/plain"
            context.Response.Write("Bad Request: Missing comment ID or file parameter.")
            Return
        End If

        ' 5. Look up comment, crew, and vessel in database
        Dim personnelId As Integer = 0
        Dim imgId As String = ""
        Dim principalView As String = "0"
        Dim assignedVesselId As Object = DBNull.Value

        Dim sql As String = "SELECT c.id, c.personnel_id, c.img_id, c.principal_view, pi.assigned_vessel_id " &
                            "FROM tbl_personnel_comment c " &
                            "LEFT JOIN tbl_personnel_info pi ON pi.id = c.personnel_id "
        If hasCommentId Then
            sql &= "WHERE c.id = @cid LIMIT 1"
        Else
            sql &= "WHERE c.img_id = @file LIMIT 1"
        End If

        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                If hasCommentId Then
                    cmd.Parameters.AddWithValue("@cid", commentId)
                Else
                    cmd.Parameters.AddWithValue("@file", fileParam.Trim())
                End If
                Using dr As MySqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        personnelId = Convert.ToInt32(dr("personnel_id"))
                        imgId = If(Not IsDBNull(dr("img_id")), dr("img_id").ToString().Trim(), "")
                        principalView = If(Not IsDBNull(dr("principal_view")), dr("principal_view").ToString(), "0")
                        assignedVesselId = dr("assigned_vessel_id")
                    Else
                        context.Response.StatusCode = 404
                        context.Response.StatusDescription = "Not Found"
                        context.Response.ContentType = "text/plain"
                        context.Response.Write("Assessment attachment record not found.")
                        Return
                    End If
                End Using
            End Using

            ' 6. Crew vessel scoping and principal_view enforcement for PRINCIPAL and VESSEL_OWNER
            If role = ROLE_PRINCIPAL OrElse role = ROLE_VESSEL_OWNER Then
                If principalView <> "1" Then
                    context.Response.StatusCode = 403
                    context.Response.StatusDescription = "Forbidden"
                    context.Response.ContentType = "text/plain"
                    context.Response.Write("Access Denied: This assessment is not marked for principal viewing.")
                    Return
                End If

                If assignedVesselId Is DBNull.Value OrElse Convert.ToInt32(assignedVesselId) <= 0 Then
                    context.Response.StatusCode = 403
                    context.Response.StatusDescription = "Forbidden"
                    context.Response.ContentType = "text/plain"
                    context.Response.Write("Access Denied: Crew member is not assigned to an authorized vessel.")
                    Return
                End If

                Dim currentUid As Integer = CurrentUserID()
                Dim vSql As String = "SELECT COUNT(*) FROM tbl_user_assigned_vessel " &
                                     "WHERE user_id = @uid AND vessel_id = @vid AND status = 'Active'"
                Using vCmd As New MySqlCommand(vSql, cn)
                    vCmd.Parameters.AddWithValue("@uid", currentUid)
                    vCmd.Parameters.AddWithValue("@vid", Convert.ToInt32(assignedVesselId))
                    Dim vCount As Long = Convert.ToInt64(vCmd.ExecuteScalar())
                    If vCount <= 0 Then
                        context.Response.StatusCode = 403
                        context.Response.StatusDescription = "Forbidden"
                        context.Response.ContentType = "text/plain"
                        context.Response.Write("Access Denied: Crew assigned vessel is outside your authorized scope.")
                        Return
                    End If
                End Using
            End If
        End Using

        If String.IsNullOrEmpty(imgId) Then
            context.Response.StatusCode = 404
            context.Response.StatusDescription = "Not Found"
            context.Response.ContentType = "text/plain"
            context.Response.Write("No attachment image associated with this assessment comment.")
            Return
        End If

        ' Prevent path traversal attacks
        Dim safeFileName As String = Path.GetFileName(imgId)
        If safeFileName <> imgId Then
            If imgId.Contains("..") Then
                context.Response.StatusCode = 400
                context.Response.Write("Invalid file identifier.")
                Return
            End If
        End If

        ' 7. Locate physical file on disk
        Dim basePath As String = context.Server.MapPath("~/Uploads")
        Dim candidatePaths As New List(Of String) From {
            Path.Combine(basePath, "assessments", safeFileName),
            Path.Combine(basePath, "documents", safeFileName),
            Path.Combine(basePath, "documents", personnelId.ToString(), safeFileName)
        }

        Dim resolvedPath As String = Nothing
        For Each p As String In candidatePaths
            If File.Exists(p) Then
                resolvedPath = p
                Exit For
            End If
        Next

        If resolvedPath Is Nothing Then
            context.Response.StatusCode = 404
            context.Response.StatusDescription = "Not Found"
            context.Response.ContentType = "text/plain"
            context.Response.Write("Assessment attachment file not found on server.")
            Return
        End If

        ' 8. Stream file bytes with proper content-type and security headers
        Dim ext As String = Path.GetExtension(resolvedPath).ToLowerInvariant()
        Dim contentType As String = "application/octet-stream"
        Select Case ext
            Case ".jpg", ".jpeg"
                contentType = "image/jpeg"
            Case ".png"
                contentType = "image/png"
            Case ".gif"
                contentType = "image/gif"
            Case ".pdf"
                contentType = "application/pdf"
        End Select

        context.Response.Clear()
        context.Response.ContentType = contentType
        context.Response.AddHeader("X-Content-Type-Options", "nosniff")
        context.Response.TransmitFile(resolvedPath)
        context.Response.Flush()
    End Sub

End Class
