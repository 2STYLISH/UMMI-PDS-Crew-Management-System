Imports MySql.Data.MySqlClient
Imports System.Data

Public Class ActivityLogs
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        RequireLogin()
        RequireRole("SUPER_ADMIN")
        If Not IsPostBack Then
            CType(Master, masterPage).lblPageTitle.Text = "Activity Logs"
            txtDateFrom.Text = DateTime.Now.AddDays(-7).ToString("yyyy-MM-dd")
            txtDateTo.Text = DateTime.Now.ToString("yyyy-MM-dd")
            SearchLogs(Nothing, Nothing)
        End If
    End Sub

    Protected Sub SearchLogs(sender As Object, e As EventArgs)
        Dim whereClauses As New List(Of String)
        Dim parms As New List(Of MySqlParameter)
        If drpdwnCategory.SelectedValue <> "" Then
            whereClauses.Add("category=@cat")
            parms.Add(New MySqlParameter("@cat", drpdwnCategory.SelectedValue))
        End If
        If IsDate(txtDateFrom.Text) Then
            whereClauses.Add("DATE(date_time)>=@df")
            parms.Add(New MySqlParameter("@df", CDate(txtDateFrom.Text)))
        End If
        If IsDate(txtDateTo.Text) Then
            whereClauses.Add("DATE(date_time)<=@dt")
            parms.Add(New MySqlParameter("@dt", CDate(txtDateTo.Text)))
        End If
        If txtUser.Text.Trim() <> "" Then
            whereClauses.Add("fullname LIKE @usr")
            parms.Add(New MySqlParameter("@usr", "%" & txtUser.Text.Trim() & "%"))
        End If

        Dim whereSQL As String = If(whereClauses.Count > 0, "WHERE " & String.Join(" AND ", whereClauses), "")
        Dim sql As String = "SELECT date_time, fullname, category, activity, ip_address " &
            "FROM tbl_activity_log " & whereSQL & " ORDER BY date_time DESC LIMIT 1000"

        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text, parms.ToArray())
        lblCount.Text = dt.Rows.Count.ToString()
        ViewState("LogData") = dt
        gvLogs.DataSource = dt
        gvLogs.PageIndex = 0
        gvLogs.DataBind()
    End Sub

    Protected Sub ResetLogs(sender As Object, e As EventArgs)
        drpdwnCategory.SelectedIndex = 0
        txtDateFrom.Text = DateTime.Now.AddDays(-7).ToString("yyyy-MM-dd")
        txtDateTo.Text = DateTime.Now.ToString("yyyy-MM-dd")
        txtUser.Text = ""
        SearchLogs(Nothing, Nothing)
    End Sub

    Protected Sub ExportLogs(sender As Object, e As EventArgs)
        Dim dt As DataTable = TryCast(ViewState("LogData"), DataTable)
        If dt Is Nothing Then SearchLogs(Nothing, Nothing) : dt = TryCast(ViewState("LogData"), DataTable)
        ExportToExcel(dt, "ActivityLogs_" & DateTime.Now.ToString("yyyyMMdd"), "UMMI Crew Mgmt — Activity Logs", Response)
    End Sub

    Protected Sub gvLogs_PageIndexChanging(sender As Object, e As System.Web.UI.WebControls.GridViewPageEventArgs)
        gvLogs.PageIndex = e.NewPageIndex
        Dim dt As DataTable = TryCast(ViewState("LogData"), DataTable)
        gvLogs.DataSource = dt
        gvLogs.DataBind()
    End Sub

End Class
