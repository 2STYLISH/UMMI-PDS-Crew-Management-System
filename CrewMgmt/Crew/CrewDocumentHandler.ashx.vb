Imports System.IO
Imports System.Web
Imports System.Web.SessionState
Imports MySql.Data.MySqlClient

''' <summary>
''' Secure HTTP handler for serving crew personnel documents (scanned documents/certificates).
''' Enforces:
''' 1. Authentication (valid active session)
''' 2. Role authorization (internal staff, principal, vessel owner)
''' 3. Crew access and vessel scoping for Principal and Vessel Owner roles
''' 4. Document category permissions (Medical and Personal require CanViewContactDetails)
''' 5. Streaming with proper Content-Type and X-Content-Type-Options: nosniff
''' </summary>
Public Class CrewDocumentHandler
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
            context.Response.Write("Access Denied: Role not authorized to view crew documents.")
            Return
        End If

        ' 3. Identify requested personnel document (requires valid numeric document ID)
        Dim docIdStr As String = context.Request.QueryString("id")
        If String.IsNullOrEmpty(docIdStr) Then
            docIdStr = context.Request.QueryString("pd_id")
        End If
        If String.IsNullOrEmpty(docIdStr) Then
            docIdStr = context.Request.QueryString("doc_id")
        End If

        Dim pdId As Integer = 0
        If String.IsNullOrWhiteSpace(docIdStr) OrElse Not Integer.TryParse(docIdStr, pdId) OrElse pdId <= 0 Then
            context.Response.StatusCode = 400
            context.Response.StatusDescription = "Bad Request"
            context.Response.ContentType = "text/plain"
            context.Response.Write("Bad Request: A valid document ID is required.")
            Return
        End If

        ' 4. Look up personnel document, category, crew, and vessel in database
        Dim personnelId As Integer = 0
        Dim imgId As String = ""
        Dim docType As String = ""
        Dim docName As String = ""
        Dim assignedVesselId As Object = DBNull.Value

        Dim sql As String = "SELECT pd.id, pd.personnel_id, pd.img_id, d.docType, d.documentName, pi.assigned_vessel_id " &
                            "FROM tbl_personnel_documents pd " &
                            "JOIN tbl_documents d ON d.id = pd.document_id " &
                            "LEFT JOIN tbl_personnel_info pi ON pi.id = pd.personnel_id " &
                            "WHERE pd.id = @id LIMIT 1"

        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                cmd.Parameters.AddWithValue("@id", pdId)
                Using dr As MySqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        personnelId = Convert.ToInt32(dr("personnel_id"))
                        imgId = If(Not IsDBNull(dr("img_id")), dr("img_id").ToString().Trim(), "")
                        docType = If(Not IsDBNull(dr("docType")), dr("docType").ToString().Trim(), "")
                        docName = If(Not IsDBNull(dr("documentName")), dr("documentName").ToString().Trim(), "")
                        assignedVesselId = dr("assigned_vessel_id")
                    Else
                        context.Response.StatusCode = 404
                        context.Response.StatusDescription = "Not Found"
                        context.Response.ContentType = "text/plain"
                        context.Response.Write("Document record not found.")
                        Return
                    End If
                End Using
            End Using

            ' 5. Crew vessel scoping enforcement for PRINCIPAL and VESSEL_OWNER
            If role = ROLE_PRINCIPAL OrElse role = ROLE_VESSEL_OWNER Then
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

            ' 6. Document permission enforcement for sensitive categories (Medical and Personal)
            If String.Equals(docType, "Medical", StringComparison.OrdinalIgnoreCase) OrElse
               String.Equals(docType, "Personal", StringComparison.OrdinalIgnoreCase) Then
                If Not CanViewContactDetails() Then
                    context.Response.StatusCode = 403
                    context.Response.StatusDescription = "Forbidden"
                    context.Response.ContentType = "text/plain"
                    context.Response.Write("Access Denied: You do not have permission to view sensitive crew documents of this category.")
                    Return
                End If
            End If
        End Using

        If String.IsNullOrEmpty(imgId) Then
            context.Response.StatusCode = 404
            context.Response.StatusDescription = "Not Found"
            context.Response.ContentType = "text/plain"
            context.Response.Write("No scan file associated with this document record.")
            Return
        End If

        ' Prevent path traversal attacks
        Dim cleanImgId As String = imgId.Replace("\", "/").TrimStart("/"c)
        If cleanImgId.Contains("..") Then
            context.Response.StatusCode = 400
            context.Response.StatusDescription = "Bad Request"
            context.Response.ContentType = "text/plain"
            context.Response.Write("Invalid file path.")
            Return
        End If

        ' 7. File-to-crew path validation: ensure folder prefix matches personnel_id
        Dim normalizedPath As String = cleanImgId.Trim("/"c)
        Dim firstSlashIdx As Integer = normalizedPath.IndexOf("/"c)
        If firstSlashIdx > 0 Then
            Dim folderPrefix As String = normalizedPath.Substring(0, firstSlashIdx)
            ' If a subfolder is specified, it MUST match the crew member's personnel_id
            If Not String.Equals(folderPrefix, personnelId.ToString(), StringComparison.OrdinalIgnoreCase) Then
                context.Response.StatusCode = 403
                context.Response.StatusDescription = "Forbidden"
                context.Response.ContentType = "text/plain"
                context.Response.Write("Access Denied: Document file path does not match the associated crew member.")
                Return
            End If
        End If

        ' 8. Locate physical file on disk
        Dim basePath As String = context.Server.MapPath("~/Uploads/documents")
        Dim fileNameOnly As String = Path.GetFileName(cleanImgId)

        Dim candidatePaths As New List(Of String)()
        ' (a) Full relative path as stored if folder prefix matches crew (e.g. 183/183_1_xyz.jpg)
        If firstSlashIdx > 0 Then
            candidatePaths.Add(Path.Combine(basePath, cleanImgId.Replace("/", Path.DirectorySeparatorChar.ToString())))
        End If
        ' (b) Inside crew personnel_id subfolder
        candidatePaths.Add(Path.Combine(basePath, personnelId.ToString(), fileNameOnly))
        ' (c) Directly under documents/
        candidatePaths.Add(Path.Combine(basePath, fileNameOnly))

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
            context.Response.Write("Document scan file not found on server.")
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
