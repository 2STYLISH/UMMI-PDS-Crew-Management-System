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

            Select Case printType
                Case "Personnel"
                    Dim pid As String = Decrypt(HttpUtility.UrlDecode(Request.QueryString("PersonnelID")))
                    Dim printDetail As String = Decrypt(Request.QueryString("PrintDetails"))
                    Dim showDetails As Boolean = (printDetail = "1")
                    LoadPersonnelPrint(pid, showDetails)

                Case "ReleasingChecklist"
                    LoadReleasingChecklistPrint()

                Case Else
                    LoadCrewListPrint()
            End Select
        End If
    End Sub

    ' ──────────────── Crew List Print ─────────────────────────
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

    ' ──────────────── UC-CM-11: Full Personnel Data Sheet ──────
    Private Sub LoadPersonnelPrint(pid As String, showContactDetails As Boolean)
        lblPrintTitle.Text = "Personnel Data Sheet"

        ' Main info
        Dim sql As String =
            "SELECT pi.*, r.rank_code, rel.religion, n.nationality, " &
            "TIMESTAMPDIFF(YEAR,pi.date_of_birth,CURDATE()) AS age_, " &
            "ds.meaning AS crew_status_text, pr.provinces AS province_name, ct.cities AS city_name " &
            "FROM tbl_personnel_info pi " &
            "LEFT JOIN tbl_rank r ON r.id=pi.position " &
            "LEFT JOIN tbl_religion rel ON rel.id=pi.religion " &
            "LEFT JOIN tbl_nationality n ON n.id=pi.nationality " &
            "LEFT JOIN tbl_dropdown_selection ds ON ds.type='crew_status' AND ds.sequence=pi.crew_status " &
            "LEFT JOIN tbl_provinces pr ON pr.id=pi.province " &
            "LEFT JOIN tbl_cities ct ON ct.id=pi.city " &
            "WHERE pi.id=@id"
        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text, New MySqlParameter("@id", pid))

        If dt.Rows.Count = 0 Then Return

        Dim dr As DataRow = dt.Rows(0)
        Dim fullName As String = dr("lastname").ToString() & ", " & dr("firstname").ToString() & " " & dr("middlename").ToString()

        ' Build comprehensive print output
        Dim sb As New System.Text.StringBuilder()
        sb.AppendLine("<div style='font-family:Inter,sans-serif;font-size:12px;max-width:800px;margin:auto;'>")

        ' Header
        sb.AppendLine("<div style='text-align:center;margin-bottom:16px;'>")
        sb.AppendLine("<h2 style='margin:0;font-size:18px;color:#1a2744;'>PERSONNEL DATA SHEET</h2>")
        sb.AppendLine("<div style='font-size:11px;color:#64748b;'>UMMI PDS Crew Management System</div>")
        sb.AppendLine("</div>")

        ' Personal Information Table
        sb.AppendLine("<h4 style='font-size:13px;background:#1e293b;color:#fff;padding:6px 10px;margin:0;'>PERSONAL INFORMATION</h4>")
        sb.AppendLine("<table style='width:100%;border-collapse:collapse;font-size:12px;margin-bottom:12px;'>")
        AddPrintRow(sb, "Full Name", fullName)
        AddPrintRow(sb, "Rank / Position", SafeField(dr, "rank_code"))
        AddPrintRow(sb, "Crew Status", SafeField(dr, "crew_status_text"))
        AddPrintRow(sb, "Age", SafeField(dr, "age_"))
        AddPrintRow(sb, "Date of Birth", If(IsDBNull(dr("date_of_birth")), "", CDate(dr("date_of_birth")).ToString("MMMM dd, yyyy")))
        AddPrintRow(sb, "Place of Birth", SafeField(dr, "place_of_birth"))
        AddPrintRow(sb, "Gender", SafeField(dr, "gender"))
        AddPrintRow(sb, "Civil Status", SafeField(dr, "civil_status"))
        AddPrintRow(sb, "Blood Type", SafeField(dr, "blood_type"))
        AddPrintRow(sb, "Religion", SafeField(dr, "religion"))
        AddPrintRow(sb, "Nationality", SafeField(dr, "nationality"))
        AddPrintRow(sb, "Height (cm)", SafeField(dr, "height"))
        AddPrintRow(sb, "Weight (kg)", SafeField(dr, "weight"))
        AddPrintRow(sb, "Date Hired", If(IsDBNull(dr("date_hired")), "", CDate(dr("date_hired")).ToString("MMMM dd, yyyy")))
        sb.AppendLine("</table>")

        ' Contact info (FR-CM-27/FR-CM-28: only if user has contact access)
        If showContactDetails Then
            sb.AppendLine("<h4 style='font-size:13px;background:#1e293b;color:#fff;padding:6px 10px;margin:0;'>CONTACT & ADDRESS</h4>")
            sb.AppendLine("<table style='width:100%;border-collapse:collapse;font-size:12px;margin-bottom:12px;'>")
            AddPrintRow(sb, "Address", SafeField(dr, "address"))
            AddPrintRow(sb, "Province", SafeField(dr, "province_name"))
            AddPrintRow(sb, "City", SafeField(dr, "city_name"))
            AddPrintRow(sb, "Contact No.", SafeField(dr, "applicant_contact_num"))
            AddPrintRow(sb, "Email", SafeField(dr, "email_address"))
            sb.AppendLine("</table>")

            ' Statutory
            sb.AppendLine("<h4 style='font-size:13px;background:#1e293b;color:#fff;padding:6px 10px;margin:0;'>STATUTORY BENEFITS</h4>")
            sb.AppendLine("<table style='width:100%;border-collapse:collapse;font-size:12px;margin-bottom:12px;'>")
            AddPrintRow(sb, "SSS No.", SafeField(dr, "sss"))
            AddPrintRow(sb, "TIN No.", SafeField(dr, "tin"))
            AddPrintRow(sb, "PhilHealth No.", SafeField(dr, "philhealth"))
            AddPrintRow(sb, "Pag-IBIG No.", SafeField(dr, "pagibig"))
            AddPrintRow(sb, "HMO Number", SafeField(dr, "hmo_number"))
            AddPrintRow(sb, "HMO Expiry", If(IsDBNull(dr("hmo_expiry")), "—", Convert.ToDateTime(dr("hmo_expiry")).ToString("MMMM dd, yyyy")))
            sb.AppendLine("</table>")
        End If

        ' Uniform sizes
        sb.AppendLine("<h4 style='font-size:13px;background:#1e293b;color:#fff;padding:6px 10px;margin:0;'>UNIFORM SIZES</h4>")
        sb.AppendLine("<table style='width:100%;border-collapse:collapse;font-size:12px;margin-bottom:12px;'>")
        AddPrintRow(sb, "Coverall", SafeField(dr, "uniform_coverall"))
        AddPrintRow(sb, "Shoes", SafeField(dr, "uniform_shoes"))
        AddPrintRow(sb, "Polo", SafeField(dr, "uniform_polo"))
        AddPrintRow(sb, "Pants", SafeField(dr, "uniform_pants"))
        sb.AppendLine("</table>")

        ' Sea Service
        sb.AppendLine("<h4 style='font-size:13px;background:#1e293b;color:#fff;padding:6px 10px;margin:0;'>SEA SERVICE HISTORY</h4>")
        Dim ssSql As String = "SELECT v.vesselName, r.rank_code, pss.port, pss.date_from, pss.date_to, pss.remarks " &
                              "FROM tbl_personnel_sea_service pss " &
                              "LEFT JOIN tbl_vessels v ON v.id=pss.vessel_id " &
                              "LEFT JOIN tbl_rank r ON r.id=pss.rank_id " &
                              "WHERE pss.personnel_id=@pid ORDER BY pss.date_from DESC"
        Dim dtSS As DataTable = DbHelper.FillDataTable(ssSql, CommandType.Text, New MySqlParameter("@pid", pid))
        sb.AppendLine("<table style='width:100%;border-collapse:collapse;font-size:11px;margin-bottom:12px;'>")
        sb.AppendLine("<tr style='background:#f1f5f9;font-weight:700;'><td style='padding:4px 6px;border:1px solid #e2e8f0;'>Vessel</td>" &
                      "<td style='padding:4px 6px;border:1px solid #e2e8f0;'>Rank</td>" &
                      "<td style='padding:4px 6px;border:1px solid #e2e8f0;'>Port</td>" &
                      "<td style='padding:4px 6px;border:1px solid #e2e8f0;'>Sign-On</td>" &
                      "<td style='padding:4px 6px;border:1px solid #e2e8f0;'>Sign-Off</td>" &
                      "<td style='padding:4px 6px;border:1px solid #e2e8f0;'>Remarks</td></tr>")
        For Each ssRow As DataRow In dtSS.Rows
            sb.AppendLine("<tr>")
            sb.AppendLine("<td style='padding:3px 6px;border:1px solid #e2e8f0;'>" & SafeField(ssRow, "vesselName") & "</td>")
            sb.AppendLine("<td style='padding:3px 6px;border:1px solid #e2e8f0;'>" & SafeField(ssRow, "rank_code") & "</td>")
            sb.AppendLine("<td style='padding:3px 6px;border:1px solid #e2e8f0;'>" & SafeField(ssRow, "port") & "</td>")
            sb.AppendLine("<td style='padding:3px 6px;border:1px solid #e2e8f0;'>" & If(IsDBNull(ssRow("date_from")), "", CDate(ssRow("date_from")).ToString("MM/dd/yyyy")) & "</td>")
            sb.AppendLine("<td style='padding:3px 6px;border:1px solid #e2e8f0;'>" & If(IsDBNull(ssRow("date_to")), "Present", CDate(ssRow("date_to")).ToString("MM/dd/yyyy")) & "</td>")
            sb.AppendLine("<td style='padding:3px 6px;border:1px solid #e2e8f0;'>" & SafeField(ssRow, "remarks") & "</td>")
            sb.AppendLine("</tr>")
        Next
        sb.AppendLine("</table>")

        sb.AppendLine("</div>")

        ' Output to a literal control
        lblPrintContent.Text = sb.ToString()

        ' Audit
        GetAdmin("Printed Personnel Data Sheet", CurrentUserID().ToString(), "Print", fullName)
    End Sub

    ' ──────────────── UC-CM-25/26: Releasing Checklist Print ──────
    Private Sub LoadReleasingChecklistPrint()
        lblPrintTitle.Text = "Releasing Checklist"

        Dim vesselName As String = HttpUtility.UrlDecode(Request.QueryString("VesselName"))
        Dim batch As String = HttpUtility.UrlDecode(Request.QueryString("Batch"))
        Dim terminal As String = HttpUtility.UrlDecode(Request.QueryString("Terminal"))

        Dim sb As New System.Text.StringBuilder()
        sb.AppendLine("<div style='font-family:Inter,sans-serif;font-size:12px;max-width:800px;margin:auto;'>")
        sb.AppendLine("<div style='text-align:center;margin-bottom:16px;'>")
        sb.AppendLine("<h2 style='margin:0;font-size:18px;color:#4f46e5;'>RELEASING CHECKLIST</h2>")
        sb.AppendLine("<div style='font-size:14px;font-weight:700;color:#1a2744;'>" & Server.HtmlEncode(vesselName) & "</div>")
        sb.AppendLine("<div style='font-size:11px;color:#64748b;'>Batch: " & Server.HtmlEncode(batch) & " | Terminal: " & Server.HtmlEncode(terminal) & "</div>")
        sb.AppendLine("</div>")

        ' Checklist Items
        sb.AppendLine("<table style='width:100%;border-collapse:collapse;font-size:12px;margin-bottom:12px;'>")
        AddChecklistRow(sb, "Flight Booking (On-Signers)", Request.QueryString("FlightOn") = "1")
        AddChecklistRow(sb, "Flight Booking (Off-Signers)", Request.QueryString("FlightOff") = "1")
        AddChecklistRow(sb, "GL / Immigration Clearance", Request.QueryString("GL") = "1")
        AddChecklistRow(sb, "Information Sheet", Request.QueryString("InfoSheet") = "1")
        AddChecklistRow(sb, "Pre-Embarkation Checklist", Request.QueryString("PreEmb") = "1")
        AddChecklistRow(sb, "Allotment", Request.QueryString("Allotment") = "1")
        AddChecklistRow(sb, "Visa", Request.QueryString("Visa") = "1")
        AddChecklistRow(sb, "End of Contract Documentation", Request.QueryString("EOC") = "1")
        sb.AppendLine("</table>")

        sb.AppendLine("</div>")
        lblPrintContent.Text = sb.ToString()

        GetAdmin("Printed Releasing Checklist", CurrentUserID().ToString(), "Print", vesselName & " | " & batch)
    End Sub

    ' ──────────────── Helpers ─────────────────────────────────────
    Private Sub AddPrintRow(sb As System.Text.StringBuilder, label As String, value As String)
        sb.AppendLine("<tr><th style='width:35%;padding:4px 8px;border:1px solid #e2e8f0;background:#f8fafc;text-align:left;font-weight:600;'>" &
                      label & "</th><td style='padding:4px 8px;border:1px solid #e2e8f0;'>" &
                      If(String.IsNullOrEmpty(value), "—", Server.HtmlEncode(value)) & "</td></tr>")
    End Sub

    Private Sub AddChecklistRow(sb As System.Text.StringBuilder, item As String, checked As Boolean)
        Dim icon As String = If(checked, "<span style='color:#22c55e;font-weight:700;'>&#x2714; Done</span>",
                                         "<span style='color:#ef4444;font-weight:700;'>&#x2718; Pending</span>")
        sb.AppendLine("<tr><td style='width:65%;padding:6px 10px;border:1px solid #e2e8f0;'>" & item &
                      "</td><td style='padding:6px 10px;border:1px solid #e2e8f0;text-align:center;'>" & icon & "</td></tr>")
    End Sub

    Private Function SafeField(dr As DataRow, colName As String) As String
        If Not dr.Table.Columns.Contains(colName) Then Return ""
        If IsDBNull(dr(colName)) Then Return ""
        Return dr(colName).ToString()
    End Function

End Class
