Imports MySql.Data.MySqlClient

Public Class masterPage
    Inherits System.Web.UI.MasterPage

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        Response.Cache.SetCacheability(System.Web.HttpCacheability.NoCache)
        Response.Cache.SetNoStore()

        ' Redirect to login if no session (with applicant link re-hydration support)
        If Session("UserID") Is Nothing OrElse Session("UserID").ToString() = "" Then
            If Context.Request.IsAuthenticated AndAlso Context.User IsNot Nothing AndAlso Context.User.Identity IsNot Nothing AndAlso
               Context.User.Identity.Name.StartsWith("LNK-", StringComparison.OrdinalIgnoreCase) Then
                Dim authLinkId As String = Context.User.Identity.Name.Substring(4)
                Dim lidInt As Integer
                Dim isValid As Boolean = False
                Dim applicantName As String = Nothing
                If Integer.TryParse(authLinkId, lidInt) AndAlso lidInt > 0 Then
                    Try
                        Using cn As New MySqlConnection(DbHelper.ConnStr)
                            cn.Open()
                            Using cmd As New MySqlCommand("SELECT fullname FROM tbl_applicant_generated_link WHERE id=@lid AND status='Active' AND (validity IS NULL OR validity >= NOW()) LIMIT 1", cn)
                                cmd.Parameters.AddWithValue("@lid", authLinkId)
                                Dim objName As Object = cmd.ExecuteScalar()
                                If objName IsNot Nothing AndAlso Not Convert.IsDBNull(objName) Then
                                    applicantName = objName.ToString()
                                    isValid = True
                                End If
                            End Using
                        End Using
                    Catch
                        isValid = False
                    End Try
                End If

                If isValid Then
                    Session("UserID") = Context.User.Identity.Name
                    Session("ApplicantLinkID") = authLinkId
                    Session("UserType") = "APPLICANT"
                    Session("UserViewCrewContactDetails") = "0"
                    Session("UserFullname") = applicantName
                    If Session("ApplicantCsrfToken") Is Nothing Then
                        Session("ApplicantCsrfToken") = Guid.NewGuid().ToString("N")
                    End If
                Else
                    FormsAuthentication.SignOut()
                    Session.Clear()
                    Session.Abandon()
                    Response.Redirect("~/login.aspx", True)
                    Return
                End If
            Else
                Response.Redirect("~/login.aspx", True)
                Return
            End If
        End If

        Dim role     As String = If(Session("UserType")     IsNot Nothing, Session("UserType").ToString(),     "")
        Dim fullname As String = If(Session("UserFullname") IsNot Nothing, Session("UserFullname").ToString(), "")

        ' ── Topbar labels ──
        lblTopbarUser.Text = Server.HtmlEncode(fullname)
        lblTopbarDate.Text = DateTime.Now.ToString("MMMM dd, yyyy")
        lblSidebarUser.Text = Server.HtmlEncode(fullname)
        If fullname.Length > 0 Then
            lblUserInitial.Text = fullname.Substring(0, 1).ToUpper()
        End If

        ' ── Role badge (preserves exact role identity display) ──
        lblSidebarRole.Text    = GetRoleDisplayName(role)
        lblSidebarRole.CssClass = "role-badge"

        ' ── Nav visibility by role access groups ──
        ApplyNavVisibility()
    End Sub

    Private Sub ApplyNavVisibility()
        ' Crew dropdown and individual items
        Dim canCS As Boolean = CanAccessCrewSearch()
        Dim canAP As Boolean = CanAccessApplicantPool()
        navQueryCrew.Visible = canCS
        divNavApplicantPool.Visible = canAP
        divNavCrew.Visible = canCS OrElse canAP

        ' Personnel dropdown — Internal Staff (Manning Staff, Doc Officer, Super Admin, Admin)
        divNavPersonnel.Visible = HasInternalStaffAccess()

        ' Admin dropdown — Administrative access (Super Admin, Admin)
        divNavAdmin.Visible = HasAdministrativeAccess()
        navUserAccounts.Visible = IsSuperAdmin()

        ' Applicant self-encode — Applicant only
        divNavApplicant.Visible = HasApplicantAccess()
        lnkSelfEncode.Visible   = HasApplicantAccess()
        lnkHome.Visible         = Not HasApplicantAccess()
    End Sub

    Protected Sub btnLogout_Click(ByVal sender As Object, e As EventArgs)
        Dim userID   As String = If(Session("UserID")       IsNot Nothing, Session("UserID").ToString(),       "0")
        Dim fullname As String = If(Session("UserFullname") IsNot Nothing, Session("UserFullname").ToString(), "")
        GetAdmin("Logged Out", userID, "Login", fullname)
        Session.Clear()
        Session.Abandon()
        Response.Cookies.Remove("ASP.NET_SessionId")
        Response.Redirect("~/login.aspx", True)
    End Sub

End Class
