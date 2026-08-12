Imports MySql.Data.MySqlClient
Imports System.Data

Public Class PrintPage
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        RequireLogin()
        If Not IsPostBack Then
            CType(Master, masterPage).lblPageTitle.Text = "Print"
            lblPrintedBy.Text = CurrentUserFullname()
            lblPrintFilters.Text = If(Session("PrintFilters") IsNot Nothing, Session("PrintFilters").ToString(), "")
            Dim printType As String = Request.QueryString("printType")
            If printType = "Personnel" Then
                Dim pid As String = Decrypt(HttpUtility.UrlDecode(Request.QueryString("PersonnelID")))
                LoadPersonnelPrint(pid)
            Else
                LoadCrewListPrint()
            End If
        End If
    End Sub

    Private ReadOnly CrewListSQL As String =
        "SELECT pi.lastname, pi.firstname, pi.middlename, r.rank_code, " &
        "TIMESTAMPDIFF(YEAR,pi.date_of_birth,CURDATE()) AS age, " &
        "ds.meaning AS crew_status_text, pr.provinces AS province_name " &
        "FROM tbl_personnel_info pi " &
        "LEFT JOIN tbl_rank r ON r.id=pi.position " &
        "LEFT JOIN tbl_dropdown_selection ds ON ds.type='crew_status' AND ds.sequence=pi.crew_status " &
        "LEFT JOIN tbl_provinces pr ON pr.id=pi.province " &
        "ORDER BY pi.lastname"

    Private Sub LoadCrewListPrint()
        lblPrintTitle.Text = "Crew List"
        Dim dt As DataTable = DbHelper.FillDataTable(CrewListSQL, CommandType.Text)
        gvPrint.DataSource = dt
        gvPrint.DataBind()
    End Sub

    Private Sub LoadPersonnelPrint(pid As String)
        lblPrintTitle.Text = "Personnel Data Sheet"
        Dim sql As String =
            "SELECT pi.lastname, pi.firstname, pi.middlename, r.rank_code, " &
            "TIMESTAMPDIFF(YEAR,pi.date_of_birth,CURDATE()) AS age, " &
            "ds.meaning AS crew_status_text, pr.provinces AS province_name " &
            "FROM tbl_personnel_info pi " &
            "LEFT JOIN tbl_rank r ON r.id=pi.position " &
            "LEFT JOIN tbl_dropdown_selection ds ON ds.type='crew_status' AND ds.sequence=pi.crew_status " &
            "LEFT JOIN tbl_provinces pr ON pr.id=pi.province " &
            "WHERE pi.id=@id"
        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text, New MySqlParameter("@id", pid))
        gvPrint.DataSource = dt
        gvPrint.DataBind()
    End Sub

End Class
