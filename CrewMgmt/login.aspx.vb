Imports MySql.Data.MySqlClient
Imports System.Web.Security

Public Class login
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        lblNotify.Text = ""

        If Not IsPostBack Then
            ' Handle encrypted applicant link (?e=...)  [WBS 1.3.8 / UC-CM-24]
            Dim credentials As String = Request.QueryString("e")
            If Not String.IsNullOrEmpty(credentials) Then
                HandleApplicantLink(credentials)
                Return
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

        Dim hashedPw As String = CreateHash(password)

        Dim sql As String = "SELECT id, fullname, type, management, " &
                            "viewcrewcontactdetails, viewcreatecontract, disable_user " &
                            "FROM tbl_users " &
                            "WHERE username=@u AND password=@p LIMIT 1"

        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                cmd.Parameters.AddWithValue("@u", username)
                cmd.Parameters.AddWithValue("@p", hashedPw)
                Using dr As MySqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        If dr.GetInt32("disable_user") = 1 Then
                            GetAdmin("Attempted login with disabled account", "0", "Login", username)
                            ShowError("This account is disabled. Contact your administrator.")
                            Return
                        End If

                        Dim userID   As String = dr.GetInt32("id").ToString()
                        Dim fullname As String = dr.GetString("fullname")
                        Dim role     As String = dr.GetString("type")
                        Dim viewCC   As String = dr.GetInt32("viewcrewcontactdetails").ToString()

                        dr.Close()
                        cn.Close()

                        ' Store session
                        Session("UserID")                    = userID
                        Session("UserFullname")              = fullname
                        Session("UserType")                  = role
                        Session("UserViewCrewContactDetails") = viewCC

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
                Response.Redirect("~/login.aspx", True)
                Return
            End If

            ' Expected format: "linkid=<ID>"
            Dim parts As System.Collections.Specialized.NameValueCollection =
                System.Web.HttpUtility.ParseQueryString(decrypted)
            Dim linkID As String = parts("linkid")

            If String.IsNullOrEmpty(linkID) Then
                Response.Redirect("~/login.aspx", True)
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
                            Session("ApplicantLinkID")           = linkID

                            GetAdmin("Accessed encoding link", linkID, "ApplicantLink", applicantName)
                            FormsAuthentication.SetAuthCookie("LNK-" & linkID, False)
                            Response.Redirect("~/Applicant/SelfEncode.aspx", True)
                        Else
                            GetAdmin("Invalid/expired encoding link attempt", "0", "ApplicantLink", credentials.Substring(0, Math.Min(20, credentials.Length)))
                            ShowError("This applicant link is invalid or has expired.")
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            ShowError("Unable to process the link. Please try logging in manually.")
        End Try
    End Sub

    Private Sub RedirectByRole(role As String)
        Select Case role
            Case "SUPER_ADMIN", "MANNING_STAFF"
                Response.Redirect("~/Home.aspx", True)
            Case "PRINCIPAL"
                Response.Redirect("~/Crew/QueryCrew.aspx", True)
            Case "APPLICANT"
                Response.Redirect("~/Applicant/SelfEncode.aspx", True)
            Case Else
                Response.Redirect("~/Home.aspx", True)
        End Select
    End Sub

    Private Sub ShowError(message As String)
        lblNotify.Text = "<div class='alert alert-danger alert-dismissible fade show' role='alert'>" &
                         "<i class='fa fa-circle-exclamation me-2'></i>" &
                         Server.HtmlEncode(message) &
                         "<button type='button' class='btn-close' data-bs-dismiss='alert'></button>" &
                         "</div>"
    End Sub

End Class
