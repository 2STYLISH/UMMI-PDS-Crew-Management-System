Imports MySql.Data.MySqlClient
Imports System.Data

Public Class ContractTracing
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(s As Object, e As EventArgs) Handles Me.Load
        RequireLogin()
        RequireRole("MANNING_STAFF", "SUPER_ADMIN")
        If Not IsPostBack Then
            CType(Master, masterPage).lblPageTitle.Text = "Contract Tracing"
            LoadVessels()
            SearchContracts(Nothing, Nothing)
        End If
    End Sub

    Private Sub LoadVessels()
        drpdwnVessel.Items.Clear()
        drpdwnVessel.Items.Add(New System.Web.UI.WebControls.ListItem("ALL", ""))
        Dim dt As DataTable = DbHelper.FillDataTable(
            "SELECT id, vesselName FROM tbl_vessels ORDER BY vesselName", CommandType.Text)
        For Each row As DataRow In dt.Rows
            drpdwnVessel.Items.Add(New System.Web.UI.WebControls.ListItem(
                row("vesselName").ToString(), row("id").ToString()))
        Next
    End Sub

    Protected Sub SearchContracts(s As Object, e As EventArgs)
        ' Build WHERE clauses dynamically based on filter values
        Dim whereParts As New List(Of String)
        Dim parms As New List(Of MySqlParameter)

        If drpdwnVessel.SelectedValue <> "" Then
            whereParts.Add("c.vessel_id = @vsl")
            parms.Add(New MySqlParameter("@vsl", drpdwnVessel.SelectedValue))
        End If
        If drpdwnStatus.SelectedValue <> "" Then
            whereParts.Add("c.status = @st")
            parms.Add(New MySqlParameter("@st", drpdwnStatus.SelectedValue))
        End If

        Dim whereSQL As String = If(whereParts.Count > 0,
            "WHERE " & String.Join(" AND ", whereParts), "")

        Dim sql As String =
            "SELECT pi.lastname, pi.firstname, r.rank_code, v.vesselName AS vessel_name, " &
            "c.date_from, c.date_to, c.status, c.remarks " &
            "FROM tbl_contracts c " &
            "JOIN tbl_personnel_info pi ON pi.id=c.personnel_id " &
            "LEFT JOIN tbl_rank r ON r.id=c.rank_id " &
            "LEFT JOIN tbl_vessels v ON v.id=c.vessel_id " &
            whereSQL & " ORDER BY c.date_from DESC"

        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text, parms.ToArray())
        ViewState("ContractData") = dt
        gvContracts.DataSource = dt
        gvContracts.PageIndex = 0
        gvContracts.DataBind()
    End Sub

    Protected Sub gvContracts_PageIndexChanging(s As Object, e As System.Web.UI.WebControls.GridViewPageEventArgs)
        gvContracts.PageIndex = e.NewPageIndex
        Dim dt As DataTable = TryCast(ViewState("ContractData"), DataTable)
        gvContracts.DataSource = dt
        gvContracts.DataBind()
    End Sub

    Protected Sub ExportContracts(s As Object, e As EventArgs)
        Dim dt As DataTable = TryCast(ViewState("ContractData"), DataTable)
        If dt Is Nothing Then
            SearchContracts(Nothing, Nothing)
            dt = TryCast(ViewState("ContractData"), DataTable)
        End If
        ExportToExcel(dt, "Contracts_" & DateTime.Now.ToString("yyyyMMdd"),
                      "UMMI Contract Tracing", Response)
    End Sub

    ' WBS 1.4.5 Gantt helpers
    Public Function GetGanttWidth(dateFrom As Object, dateTo As Object) As Integer
        Dim d1 As Date = Date.Now.AddMonths(-9)
        Dim d2 As Date = Date.Now
        If Not IsDBNull(dateFrom) AndAlso dateFrom IsNot Nothing Then Date.TryParse(dateFrom.ToString(), d1)
        If Not IsDBNull(dateTo) AndAlso dateTo IsNot Nothing Then Date.TryParse(dateTo.ToString(), d2)
        Dim days As Integer = CInt(Math.Abs((d2 - d1).TotalDays))
        Return Math.Min(Math.Max(CInt(days / 3.5), 30), 180)
    End Function

    Public Function GetDatePeriod(dateFrom As Object, dateTo As Object) As String
        Dim d1 As Date = Date.Now.AddMonths(-9)
        Dim d2 As Date = Date.Now
        If Not IsDBNull(dateFrom) AndAlso dateFrom IsNot Nothing Then Date.TryParse(dateFrom.ToString(), d1)
        If Not IsDBNull(dateTo) AndAlso dateTo IsNot Nothing Then Date.TryParse(dateTo.ToString(), d2)
        Dim months As Integer = CInt(Math.Abs((d2 - d1).TotalDays) / 30)
        Return months.ToString() & " mo(s)"
    End Function

End Class
