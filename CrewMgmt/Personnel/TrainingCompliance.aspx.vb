Imports MySql.Data.MySqlClient
Imports System.Data

Public Class TrainingCompliance
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(s As Object, e As EventArgs) Handles Me.Load
        RequireLogin()
        RequireRole(ROLE_MANNING_STAFF, ROLE_DOCUMENTATION_OFFICER, ROLE_SUPER_ADMIN, ROLE_ADMIN)
        If Not IsPostBack Then
            CType(Master, masterPage).lblPageTitle.Text = "Training Compliance"
            LoadRankTypes()
            SearchCompliance(Nothing, Nothing)
        End If
    End Sub

    Private Sub LoadRankTypes()
        drpdwnRankType.Items.Clear()
        drpdwnRankType.Items.Add(New System.Web.UI.WebControls.ListItem("ALL", ""))
        Dim dt As DataTable = DbHelper.FillDataTable(
            "SELECT rank_type FROM tbl_rank GROUP BY rank_type ORDER BY MIN(sequence)", CommandType.Text)
        For Each row As DataRow In dt.Rows
            drpdwnRankType.Items.Add(row("rank_type").ToString())
        Next
    End Sub

    Protected Sub SearchCompliance(s As Object, e As EventArgs)
        Dim sql As String =
            "SELECT pi.lastname, pi.firstname, r.rank_code, d.documentName, pd.date_expiry " &
            "FROM tbl_personnel_documents pd " &
            "JOIN tbl_personnel_info pi ON pi.id=pd.personnel_id " &
            "JOIN tbl_documents d ON d.id=pd.document_id " &
            "LEFT JOIN tbl_rank r ON r.id=pi.position " &
            "WHERE d.docType = 'Training' " &
            "AND (@rt = '' OR r.rank_type = @rt) " &
            "AND (@nm = '' OR pi.lastname LIKE CONCAT('%', @nm, '%')) " &
            "ORDER BY pi.lastname, d.sequence"

        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text,
            New MySqlParameter("@rt", drpdwnRankType.SelectedValue),
            New MySqlParameter("@nm", txtName.Text.Trim()))
        ViewState("ComplianceData") = dt
        gvCompliance.DataSource = dt
        gvCompliance.PageIndex = 0
        gvCompliance.DataBind()
    End Sub

    Protected Sub gvCompliance_RowDataBound(s As Object, e As System.Web.UI.WebControls.GridViewRowEventArgs)
        If e.Row.RowType <> System.Web.UI.WebControls.DataControlRowType.DataRow Then Return
        Dim lbl As System.Web.UI.WebControls.Label =
            CType(e.Row.FindControl("lblCompliance"), System.Web.UI.WebControls.Label)
        If lbl Is Nothing Then Return
        Dim expiryText As String = e.Row.Cells(3).Text
        Dim expiryDate As Date
        If Not Date.TryParse(expiryText, expiryDate) Then
            lbl.Text = "<span class='compliance-fail'>&#x2718; No Record</span>"
            Return
        End If
        If Date.Now >= expiryDate Then
            lbl.Text = "<span class='compliance-fail'>&#x2718; Expired</span>"
        ElseIf Date.Now.AddMonths(3) >= expiryDate Then
            lbl.Text = "<span class='compliance-warn'>&#x26A0; Expiring Soon</span>"
        Else
            lbl.Text = "<span class='compliance-ok'>&#x2714; Valid</span>"
        End If
    End Sub

    Protected Sub gvCompliance_PageIndexChanging(s As Object, e As System.Web.UI.WebControls.GridViewPageEventArgs)
        gvCompliance.PageIndex = e.NewPageIndex
        Dim dt As DataTable = TryCast(ViewState("ComplianceData"), DataTable)
        gvCompliance.DataSource = dt
        gvCompliance.DataBind()
    End Sub

    Protected Sub ExportCompliance(s As Object, e As EventArgs)
        Dim dt As DataTable = TryCast(ViewState("ComplianceData"), DataTable)
        If dt Is Nothing Then
            SearchCompliance(Nothing, Nothing)
            dt = TryCast(ViewState("ComplianceData"), DataTable)
        End If
        ExportToExcel(dt, "TrainingCompliance_" & DateTime.Now.ToString("yyyyMMdd"),
                      "UMMI Training Compliance", Response)
    End Sub

End Class
