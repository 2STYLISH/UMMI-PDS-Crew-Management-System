Imports MySql.Data.MySqlClient
Imports System.Data

Public Class PersonnelFile
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        RequireLogin()
        RequireRole("MANNING_STAFF", "SUPER_ADMIN")
        If Not IsPostBack Then
            CType(Master, masterPage).lblPageTitle.Text = "Personnel File"
            GetAdmin("Visited", CurrentUserID().ToString(), "PersonnelFile", "Personnel File")
            LoadStatusDropdown()
            SearchPersonnel(Nothing, Nothing)
        End If
    End Sub

    Private Sub LoadStatusDropdown()
        drpdwnStatus.Items.Clear()
        drpdwnStatus.Items.Add(New System.Web.UI.WebControls.ListItem("ALL", ""))
        Dim dt As DataTable = DbHelper.FillDataTable(
            "SELECT id, meaning FROM tbl_dropdown_selection WHERE type='crew_status' ORDER BY sequence",
            CommandType.Text)
        For Each row As DataRow In dt.Rows
            drpdwnStatus.Items.Add(New System.Web.UI.WebControls.ListItem(row("meaning").ToString(), row("id").ToString()))
        Next
    End Sub

    Protected Sub SearchPersonnel(sender As Object, e As EventArgs)
        Dim sql As String =
            "SELECT pi.id, pi.lastname, pi.firstname, r.rank_code, " &
            "ds.meaning AS crew_status_text, pi.date_hired " &
            "FROM tbl_personnel_info pi " &
            "LEFT JOIN tbl_rank r ON r.id=pi.position " &
            "LEFT JOIN tbl_dropdown_selection ds ON ds.type='crew_status' AND ds.sequence=pi.crew_status " &
            "WHERE (@ln = '' OR pi.lastname  LIKE CONCAT('%',@ln,'%')) " &
            "AND   (@fn = '' OR pi.firstname LIKE CONCAT('%',@fn,'%')) " &
            "AND   (@st = '' OR pi.crew_status = @st) " &
            "ORDER BY pi.lastname"

        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text,
            New MySqlParameter("@ln", txtLastName.Text.Trim()),
            New MySqlParameter("@fn", txtFirstName.Text.Trim()),
            New MySqlParameter("@st", drpdwnStatus.SelectedValue))
        gvPersonnel.DataSource = dt
        gvPersonnel.PageIndex = 0
        gvPersonnel.DataBind()
    End Sub

    Protected Sub ShowAddNew(sender As Object, e As EventArgs)
        lblNotify.Text = "<div class='alert alert-info'>" &
            "<i class='fa fa-circle-info me-2'></i>" &
            "Use the <strong>Applicant Pool &rarr; Generate Link</strong> workflow to add new crew, " &
            "or redirect Manning Staff to the SelfEncode form directly.</div>"
    End Sub

    Protected Sub gvPersonnel_PageIndexChanging(sender As Object, e As System.Web.UI.WebControls.GridViewPageEventArgs)
        gvPersonnel.PageIndex = e.NewPageIndex
        SearchPersonnel(Nothing, Nothing)
    End Sub

    Public Function GetProfileUrl(id As Object) As String
        Return "~/Crew/ProfileViewer.aspx?ID=" &
            HttpUtility.UrlEncode(Encrypt(id.ToString())) & "&Type=" &
            HttpUtility.UrlEncode(Encrypt("Viewer"))
    End Function

    Public Function GetStatusBadge(status As String) As String
        Select Case status.ToUpper()
            Case "ON BOARD"   : Return "badge badge-onboard"
            Case "ON VACATION": Return "badge badge-vacation"
            Case "LINE-UP"    : Return "badge badge-lineup"
            Case "APPLICANT"  : Return "badge badge-applicant"
            Case "RELIEVED"   : Return "badge badge-relieved"
            Case "RESIGNED"   : Return "badge badge-resigned"
            Case Else         : Return "badge badge-gray"
        End Select
    End Function

    Public Function GetCOEUrl(id As Object) As String
        Return "~/Personnel/COE.aspx?ID=" & HttpUtility.UrlEncode(Encrypt(id.ToString()))
    End Function

    Public Function GetCertsUrl(id As Object) As String
        Return "~/Personnel/Certificates.aspx?ID=" & HttpUtility.UrlEncode(Encrypt(id.ToString()))
    End Function

End Class

