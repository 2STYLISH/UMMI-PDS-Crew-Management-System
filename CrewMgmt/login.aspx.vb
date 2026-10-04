Imports MySql.Data.MySqlClient
Imports System.Web.Security

Public Class login
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        lblNotify.Text = ""
        lblNotify.Visible = False

        If Not IsPostBack Then
            ' Handle encrypted applicant link (?e=...)  [WBS 1.3.8 / UC-CM-24]
            If Request.QueryString("e") IsNot Nothing Then
                Dim credentials As String = Request.QueryString("e")
                If String.IsNullOrWhiteSpace(credentials) Then
                    GetAdmin("Malformed encoding link (empty token)", "0", "ApplicantLink", "")
                    Response.Redirect("~/Applicant/AccessDenied.aspx", False)
                    Context.ApplicationInstance.CompleteRequest()
                    Return
                Else
                    HandleApplicantLink(credentials)
                    Return
                End If
            End If

            ' Already logged in?
            If Session("UserID") IsNot Nothing AndAlso Session("UserID").ToString() <> "" Then
                RedirectByRole(Session("UserType").ToString())
            End If
        End If
    End Sub

    ' ── Login button click ──────────────────────────────────────────
    Protected Sub btnLogin_Click(sender As Object, e As EventArgs)
        Dim username As String = txtUsername.Text.Trim()
        Dim password As String = txtPassword.Text

        If String.IsNullOrEmpty(username) OrElse String.IsNullOrEmpty(password) Then
            ShowError("Username and password are required.")
            Return
        End If

        ' Fetch user by username only first — we verify password manually to support migration
        Dim sql As String = "SELECT id, fullname, type, management, " &
                            "viewcrewcontactdetails, viewcreatecontract, disable_user, ccl_permission, " &
                            "password, password_salt " &
                            "FROM tbl_users " &
                            "WHERE username=@u LIMIT 1"

        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                cmd.Parameters.AddWithValue("@u", username)
                Using dr As MySqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        Dim storedHash As String = dr.GetString("password")
                        Dim storedSalt As String = If(dr.IsDBNull(dr.GetOrdinal("password_salt")), Nothing, dr.GetString("password_salt"))

                        ' TC-CM-186: VerifyHashedPassword handles v1 (SHA-256 no salt),
                        ' v2 (SHA-256+salt), and v3 (PBKDF2) transparently.
                        ' needsUpgrade is True for v1 and v2 — triggers immediate rehash.
                        Dim needsUpgrade As Boolean = False
                        Dim isValid As Boolean = VerifyHashedPassword(password, storedHash, storedSalt, needsUpgrade)

                        If Not isValid Then
                            dr.Close()
                            GetAdmin("Failed Login Attempt", "0", "Login", username)
                            ShowError("Invalid username or password. Please try again.")
                            Return
                        End If

                        If dr.GetInt32("disable_user") = 1 Then
                            dr.Close()
                            GetAdmin("Attempted login with disabled account", "0", "Login", username)
                            ShowError("This account is disabled. Contact your administrator.")
                            Return
                        End If

                        Dim userID   As String = dr.GetInt32("id").ToString()
                        Dim fullname As String = dr.GetString("fullname")
                        Dim role     As String = dr.GetString("type")
                        Dim viewCC   As String = dr.GetInt32("viewcrewcontactdetails").ToString()
                        Dim cclPerm  As String = dr.GetInt32("ccl_permission").ToString()
                        dr.Close()

                        ' TC-CM-186: Silently upgrade v1/v2 hash to PBKDF2 (v3) on first successful login
                        If needsUpgrade Then
                            Try
                                Dim newSalt As String = GenerateSalt()
                                Dim newHash As String = CreateHash(password, newSalt)
                                Using upgCmd As New MySqlCommand(
                                    "UPDATE tbl_users SET password=@h, password_salt=@s WHERE id=@id", cn)
                                    upgCmd.Parameters.AddWithValue("@h", newHash)
                                    upgCmd.Parameters.AddWithValue("@s", newSalt)
                                    upgCmd.Parameters.AddWithValue("@id", userID)
                                    upgCmd.ExecuteNonQuery()
                                End Using
                                GetAdmin("Upgraded password hash to PBKDF2", userID, "Login", fullname)
                            Catch ex As Exception
                                ' Non-fatal: log but do not block login
                                GetAdmin("Hash upgrade failed: " & ex.Message, userID, "Login", fullname)
                            End Try
                        End If

                        ' Store session
                        Session("UserID")                    = userID
                        Session("UserFullname")              = fullname
                        Session("UserType")                  = role
                        Session("UserViewCrewContactDetails") = viewCC
                        Session("UserCCLPermission")         = cclPerm

                        ' Audit log
                        GetAdmin("Logged In", userID, "Login", fullname & " [" & role & "]")

                        ' Forms auth ticket
                        FormsAuthentication.SetAuthCookie(userID, False)

                        RedirectByRole(role)
                    Else
                        GetAdmin("Failed Login Attempt", "0", "Login", username)
                        ShowError("Invalid username or password. Please try again.")
                    End If
                End Using
            End Using
        End Using
    End Sub

    ' ── Encrypted link access for Applicant (UC-CM-24) ─────────────
    Private Sub HandleApplicantLink(credentials As String)
        Try
            Dim decrypted As String = Decrypt(credentials)
            If String.IsNullOrEmpty(decrypted) Then
                ' TC-CM-163/164 FIX: malformed/unrecognizable token -> AccessDenied
                GetAdmin("Malformed encoding link (empty decrypt)", "0", "ApplicantLink", credentials.Substring(0, Math.Min(20, credentials.Length)))
                Response.Redirect("~/Applicant/AccessDenied.aspx", False)
                Context.ApplicationInstance.CompleteRequest()
                Return
            End If

            ' Expected format: "linkid=<ID>"
            Dim parts As System.Collections.Specialized.NameValueCollection =
                System.Web.HttpUtility.ParseQueryString(decrypted)
            Dim linkID As String = parts("linkid")

            Dim lidInt As Integer
            If String.IsNullOrEmpty(linkID) OrElse Not Integer.TryParse(linkID, lidInt) OrElse lidInt <= 0 Then
                ' TC-CM-163/164 FIX: decrypted but invalid linkid -> AccessDenied
                GetAdmin("Malformed encoding link (invalid linkid)", "0", "ApplicantLink", credentials.Substring(0, Math.Min(20, credentials.Length)))
                Response.Redirect("~/Applicant/AccessDenied.aspx", False)
                Context.ApplicationInstance.CompleteRequest()
                Return
            End If

            ' Validate link in DB
            Dim sql As String = "SELECT id, fullname, status, validity FROM tbl_applicant_generated_link " &
                                "WHERE id=@lid AND status='Active' AND " &
                                "(validity IS NULL OR validity >= NOW()) LIMIT 1"
            Using cn As New MySqlConnection(DbHelper.ConnStr)
                cn.Open()
                Using cmd As New MySqlCommand(sql, cn)
                    cmd.Parameters.AddWithValue("@lid", linkID)
                    Using dr As MySqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            Dim applicantName As String = dr.GetString("fullname")
                            dr.Close()

                            ' Update last access
                            Dim upd As String = "UPDATE tbl_applicant_generated_link " &
                                                "SET last_date_access=NOW() WHERE id=@lid"
                            Using cmd2 As New MySqlCommand(upd, cn)
                                cmd2.Parameters.AddWithValue("@lid", linkID)
                                cmd2.ExecuteNonQuery()
                            End Using

                            ' Create applicant session
                            Session("UserID")                    = "LNK-" & linkID
                            Session("UserFullname")              = applicantName
                            Session("UserType")                  = "APPLICANT"
                            Session("UserViewCrewContactDetails") = "0"
                            ' Reuse existing non-empty CSRF token ONLY IF the session is already authorized for this exact link ID;
                            ' otherwise (new session, empty token, or switching applicant identity), generate a fresh token.
                            Dim existingLinkID As String = If(Session("ApplicantLinkID") IsNot Nothing, Session("ApplicantLinkID").ToString(), "")
                            Dim existingToken As String = If(Session("ApplicantCsrfToken") IsNot Nothing, Session("ApplicantCsrfToken").ToString(), "")
                            Dim isSameAuthorizedSession As Boolean = Not String.IsNullOrEmpty(existingLinkID) AndAlso
                                                                    String.Equals(existingLinkID, linkID.ToString(), StringComparison.Ordinal) AndAlso
                                                                    Not String.IsNullOrEmpty(existingToken)

                            Session("ApplicantLinkID")           = linkID
                            If Not isSameAuthorizedSession Then
                                Session("ApplicantCsrfToken")    = Guid.NewGuid().ToString("N")
                            End If

                            GetAdmin("Accessed encoding link", linkID, "ApplicantLink", applicantName)
                            FormsAuthentication.SetAuthCookie("LNK-" & linkID, False)
                            Response.Redirect("~/Applicant/SelfEncode.aspx", False)
                            Context.ApplicationInstance.CompleteRequest()
                            Return
                        Else
                            GetAdmin("Invalid/expired encoding link attempt", "0", "ApplicantLink", credentials.Substring(0, Math.Min(20, credentials.Length)))
                            Response.Redirect("~/Applicant/AccessDenied.aspx", False)
                            Context.ApplicationInstance.CompleteRequest()
                            Return
                        End If
                    End Using
                End Using
            End Using
        Catch ex As System.Threading.ThreadAbortException
            ' Ignore normal thread abort from redirects
            Throw
        Catch ex As Exception
            ' TC-CM-163/164 FIX: decrypt exceptions (corrupt token) -> AccessDenied
            GetAdmin("Encoding link exception: " & ex.Message.Substring(0, Math.Min(80, ex.Message.Length)), "0", "ApplicantLink", credentials.Substring(0, Math.Min(20, credentials.Length)))
            Response.Redirect("~/Applicant/AccessDenied.aspx", False)
            Context.ApplicationInstance.CompleteRequest()
        End Try
    End Sub

    Private Sub RedirectByRole(role As String)
        Select Case role
            Case ROLE_SUPER_ADMIN, ROLE_ADMIN, ROLE_MANNING_STAFF, ROLE_DOCUMENTATION_OFFICER
                Response.Redirect("~/Home.aspx", True)
            Case ROLE_PRINCIPAL, ROLE_VESSEL_OWNER
                Response.Redirect("~/Crew/QueryCrew.aspx", True)
            Case ROLE_APPLICANT
                Response.Redirect("~/Applicant/SelfEncode.aspx", True)
            Case Else
                Response.Redirect("~/Home.aspx", True)
        End Select
    End Sub

    Private Sub ShowError(message As String)
        lblNotify.Text = "<i class='fa fa-circle-exclamation me-2'></i>" & Server.HtmlEncode(message)
        lblNotify.Visible = True
    End Sub

End Class
