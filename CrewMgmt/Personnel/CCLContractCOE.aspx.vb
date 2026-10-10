Imports MySql.Data.MySqlClient
Imports System.Data
Imports System.Web

Public Class CCLContractCOE
    Inherits System.Web.UI.Page

    Protected lblNotify As Label
    Protected litContract As Literal
    Protected lnkBack As HyperLink

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        RequireLogin()
        RequireRole(ROLE_MANNING_STAFF, ROLE_DOCUMENTATION_OFFICER, ROLE_SUPER_ADMIN, ROLE_ADMIN)
        If Not IsPostBack Then
            CType(Master, masterPage).lblPageTitle.Text = "Contract of Employment (COE)"
            Dim enc As String = HttpUtility.UrlDecode(Request.QueryString("ScheduleID"))
            Dim sid As Integer = 0
            If Not String.IsNullOrEmpty(enc) Then Integer.TryParse(Decrypt(enc), sid)
            If sid <= 0 Then
                lblNotify.Text = "<div class='alert alert-danger'>Invalid schedule reference.</div>"
                Return
            End If
            RenderContract(sid)
            GetPortalAct("Opened CCL Contract COE", CurrentUserID().ToString(), "CCLContractCOE", "ScheduleID=" & sid.ToString())
        End If
    End Sub

    Private Sub RenderContract(scheduleId As Integer)
        Dim sql As String =
            "SELECT s.id AS schedule_id, s.joining_date, s.joining_port, " &
            "v.vesselName, pi.lastname, pi.firstname, pi.middlename, r.rank_code, " &
            "f.basic_monthly_wage, f.fixed_overtime, f.hourly_overtime_rate, " &
            "f.commanding_allowance, f.tanker_allowance, f.special_allowance, f.leave_pay, f.allotment_deduction " &
            "FROM tbl_ccl_schedules s " &
            "JOIN tbl_ccl_relievers rel ON rel.id = s.reliever_id " &
            "JOIN tbl_personnel_info pi ON pi.id = s.crew_id " &
            "LEFT JOIN tbl_rank r ON r.id = pi.position " &
            "JOIN tbl_vessels v ON v.id = s.vessel_id " &
            "LEFT JOIN tbl_ccl_contract_financial f ON f.schedule_id = s.id " &
            "WHERE s.id = @sid LIMIT 1"
        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text, New MySqlParameter("@sid", scheduleId))
        If dt.Rows.Count = 0 Then
            lblNotify.Text = "<div class='alert alert-warning'>Schedule not found.</div>"
            Return
        End If
        Dim dr As DataRow = dt.Rows(0)
        Dim name As String = dr("lastname").ToString() & ", " & dr("firstname").ToString() & " " &
            If(IsDBNull(dr("middlename")), "", dr("middlename").ToString())
        Dim sb As New System.Text.StringBuilder()
        sb.AppendLine("<div style='font-family:Inter,sans-serif;font-size:12px;max-width:820px;margin:auto;'>")
        sb.AppendLine("<div style='text-align:center;margin-bottom:16px;'>")
        sb.AppendLine("<h2 style='margin:0;color:#1a2744;'>STANDARD CONTRACT OF EMPLOYMENT (SEAFARERS)</h2>")
        sb.AppendLine("<div style='font-size:11px;color:#64748b;'>POEA / DMW Format — UMMI Manning</div></div>")
        sb.AppendLine("<table style='width:100%;border-collapse:collapse;font-size:12px;'>")
        AddRow(sb, "Seafarer", name.Trim())
        AddRow(sb, "Rank", Safe(dr, "rank_code"))
        AddRow(sb, "Vessel", Safe(dr, "vesselName"))
        AddRow(sb, "Joining Date", If(IsDBNull(dr("joining_date")), "", CDate(dr("joining_date")).ToString("MMMM dd, yyyy")))
        AddRow(sb, "Joining Port", Safe(dr, "joining_port"))
        AddRow(sb, "Basic Monthly Wage (USD)", Money(dr, "basic_monthly_wage"))
        AddRow(sb, "Fixed Overtime", Money(dr, "fixed_overtime"))
        AddRow(sb, "Hourly Overtime Rate", Money(dr, "hourly_overtime_rate"))
        AddRow(sb, "Commanding Allowance", Money(dr, "commanding_allowance"))
        AddRow(sb, "Tanker Allowance", Money(dr, "tanker_allowance"))
        AddRow(sb, "Special Allowance", Money(dr, "special_allowance"))
        AddRow(sb, "Leave Pay", Money(dr, "leave_pay"))
        AddRow(sb, "Allotment Deduction", Money(dr, "allotment_deduction"))
        sb.AppendLine("</table>")
        sb.AppendLine("<p style='margin-top:20px;font-size:11px;color:#64748b;'>Generated " &
                      DateTime.Now.ToString("MMMM dd, yyyy HH:mm") & " — for official signing after review.</p>")
        sb.AppendLine("</div>")
        litContract.Text = sb.ToString()
    End Sub

    Private Sub AddRow(sb As System.Text.StringBuilder, label As String, value As String)
        sb.AppendLine("<tr><th style='width:38%;padding:6px 8px;border:1px solid #e2e8f0;background:#f8fafc;text-align:left;'>" &
                      Server.HtmlEncode(label) & "</th><td style='padding:6px 8px;border:1px solid #e2e8f0;'>" &
                      If(String.IsNullOrEmpty(value), "—", Server.HtmlEncode(value)) & "</td></tr>")
    End Sub

    Private Function Safe(dr As DataRow, col As String) As String
        If IsDBNull(dr(col)) Then Return ""
        Return dr(col).ToString()
    End Function

    Private Function Money(dr As DataRow, col As String) As String
        If IsDBNull(dr(col)) Then Return ""
        Return Convert.ToDecimal(dr(col)).ToString("N2")
    End Function

End Class
