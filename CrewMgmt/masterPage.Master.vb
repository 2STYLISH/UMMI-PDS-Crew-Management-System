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

        ' ── Role badge ──
        Select Case role
            Case "SUPER_ADMIN"
                lblSidebarRole.Text    = "Super Admin"
                lblSidebarRole.CssClass = "role-badge"
            Case "MANNING_STAFF"
                lblSidebarRole.Text    = "Manning Staff"
                lblSidebarRole.CssClass = "role-badge"
            Case "PRINCIPAL"
                lblSidebarRole.Text    = "Principal"
                lblSidebarRole.CssClass = "role-badge"
            Case "APPLICANT"
                lblSidebarRole.Text    = "Applicant"
                lblSidebarRole.CssClass = "role-badge"
            Case Else
                lblSidebarRole.Text    = role
                lblSidebarRole.CssClass = "role-badge"
        End Select

        ' ── Nav visibility by role ──
        ApplyNavVisibility(role)
    End Sub

    Private Sub ApplyNavVisibility(role As String)
        Dim isManning   As Boolean = (role = "MANNING_STAFF" OrElse role = "SUPER_ADMIN")
        Dim isPrincipal As Boolean = (role = "PRINCIPAL")
        Dim isApplicant As Boolean = (role = "APPLICANT")

        ' Crew dropdown — Manning, SuperAdmin, Principal
        divNavCrew.Visible = (isManning OrElse isPrincipal)

        ' Personnel dropdown — Manning/SuperAdmin only
        divNavPersonnel.Visible = isManning

        ' Admin dropdown — SuperAdmin only
        divNavAdmin.Visible = (role = "SUPER_ADMIN")

        ' Applicant self-encode — Applicant only
        divNavApplicant.Visible = isApplicant
        lnkSelfEncode.Visible   = isApplicant
        lnkHome.Visible         = Not isApplicant
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
