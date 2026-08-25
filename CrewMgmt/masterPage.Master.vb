Imports MySql.Data.MySqlClient

Public Class masterPage
    Inherits System.Web.UI.MasterPage

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        Response.Cache.SetCacheability(System.Web.HttpCacheability.NoCache)
        Response.Cache.SetNoStore()

        ' Redirect to login if no session
        If Session("UserID") Is Nothing OrElse Session("UserID").ToString() = "" Then
            Response.Redirect("~/login.aspx", True)
            Return
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
        ' Crew dropdown — Internal Staff (Manning/Admin) and Principal/VesselOwner
        divNavCrew.Visible = (HasInternalStaffAccess() OrElse HasPrincipalAccess())

        ' Personnel dropdown — Internal Staff (Manning Staff, Doc Officer, Super Admin, Admin)
        divNavPersonnel.Visible = HasInternalStaffAccess()

        ' Admin dropdown — Administrative access (Super Admin, Admin)
        divNavAdmin.Visible = HasAdministrativeAccess()

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
