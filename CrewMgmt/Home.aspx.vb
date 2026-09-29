Imports MySql.Data.MySqlClient

Public Class Home
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        RequireLogin()
        Dim role As String = CurrentRole()

        ' Applicant has no dashboard; redirect to self-encode
        If HasApplicantAccess() Then
            Response.Redirect("~/Applicant/SelfEncode.aspx", True)
            Return
        End If

        If Not IsPostBack Then
            LoadStats()
            LoadExpiringDocs()
            ApplyRoleVisibility()
            If HasAdministrativeAccess() Then LoadRecentActivity()
        End If

        CType(Master, masterPage).lblPageTitle.Text = "Dashboard"
    End Sub

    Private Sub ApplyRoleVisibility()
        Dim isInternalStaff As Boolean = HasInternalStaffAccess()
        Dim isAdminStaff    As Boolean = HasAdministrativeAccess()

        lnkQAApplicantPool.Visible = isInternalStaff
        lnkQAPersonnelFile.Visible = isInternalStaff
        lnkQAActivityLogs.Visible  = isAdminStaff
        divRecentActivity.Visible  = isAdminStaff
    End Sub

    Private Sub LoadStats()
        Dim sql As String = "SELECT " &
            "SUM(CASE WHEN crew_status=1 THEN 1 ELSE 0 END) AS active_, " &
            "SUM(CASE WHEN crew_status=3 THEN 1 ELSE 0 END) AS onboard_, " &
            "SUM(CASE WHEN crew_status=4 THEN 1 ELSE 0 END) AS vacation_, " &
            "SUM(CASE WHEN crew_status=5 THEN 1 ELSE 0 END) AS applicant_ " &
            "FROM tbl_personnel_info"
        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                Using dr As MySqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        lblTotalCrew.Text  = If(IsDBNull(dr("active_")),   "0", dr("active_").ToString())
                        lblOnBoard.Text    = If(IsDBNull(dr("onboard_")),  "0", dr("onboard_").ToString())
                        lblOnVacation.Text = If(IsDBNull(dr("vacation_")), "0", dr("vacation_").ToString())
                        lblApplicants.Text = If(IsDBNull(dr("applicant_")),"0", dr("applicant_").ToString())
                    End If
                End Using
            End Using
        End Using
    End Sub

    Private Sub LoadRecentActivity()
        Dim sql As String = "SELECT date_time, category, activity, fullname " &
                            "FROM tbl_activity_log ORDER BY date_time DESC LIMIT 10"
        Dim dt As System.Data.DataTable = DbHelper.FillDataTable(sql, System.Data.CommandType.Text)
        gvRecentActivity.DataSource = dt
        gvRecentActivity.DataBind()
    End Sub

    Private Sub LoadExpiringDocs()
        Dim sql As String = "SELECT CONCAT(pi.lastname,', ',pi.firstname) AS crew_name, " &
                            "d.documentName, pd.date_expiry " &
                            "FROM tbl_personnel_documents pd " &
                            "JOIN tbl_personnel_info pi ON pi.id=pd.personnel_id " &
                            "JOIN tbl_documents d ON d.id=pd.document_id " &
                            "WHERE pd.date_expiry BETWEEN CURDATE() AND DATE_ADD(CURDATE(),INTERVAL 30 DAY) " &
                            "ORDER BY pd.date_expiry ASC LIMIT 20"
        Dim dt As System.Data.DataTable = DbHelper.FillDataTable(sql, System.Data.CommandType.Text)
        gvExpiringDocs.DataSource = dt
        gvExpiringDocs.DataBind()
    End Sub

End Class
