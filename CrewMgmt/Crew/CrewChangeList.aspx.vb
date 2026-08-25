Imports MySql.Data.MySqlClient
Imports System.Data

Public Class CrewChangeList
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        RequireLogin()
        RequireRole(ROLE_MANNING_STAFF, ROLE_DOCUMENTATION_OFFICER, ROLE_SUPER_ADMIN, ROLE_ADMIN, ROLE_PRINCIPAL, ROLE_VESSEL_OWNER)

        If Not IsPostBack Then
            CType(Master, masterPage).lblPageTitle.Text = "Crew Change List"
            Dim encVslID As String = HttpUtility.UrlDecode(Request.QueryString("VesselID"))
            Dim vesselID As String = Decrypt(encVslID)

            GetAdmin("Visited CCL", CurrentUserID().ToString(), "CrewChangeList", "VesselID=" & vesselID)
            LoadCCL(vesselID)
        End If
    End Sub

    Private Sub LoadCCL(vesselID As String)
        Dim whereClause As String = ""
        If Not String.IsNullOrEmpty(vesselID) Then
            whereClause = "AND (pi.assigned_vessel_id=@vid OR pss.vessel_id=@vid) "
            ' Get vessel name
            Dim vname As Object = DbHelper.ExecuteScalar(
                "SELECT vesselName FROM tbl_vessels WHERE id=@vid",
                New MySqlParameter("@vid", vesselID))
            If vname IsNot Nothing AndAlso Not IsDBNull(vname) Then
                lblVesselName.Text = Server.HtmlEncode(vname.ToString())
            End If
        End If

        Dim sql As String =
            "SELECT r.rank_code, CONCAT(pi.lastname, ', ', pi.firstname, ' ', IFNULL(pi.middlename,'')) AS crew_name, " &
            "ds.meaning AS crew_status_text, " &
            "pss.date_from, pss.date_to, v.vesselName AS vessel_name " &
            "FROM tbl_personnel_info pi " &
            "LEFT JOIN tbl_rank r ON r.id=pi.position " &
            "LEFT JOIN tbl_dropdown_selection ds ON ds.type='crew_status' AND ds.sequence=pi.crew_status " &
            "LEFT JOIN tbl_personnel_sea_service pss ON pss.personnel_id=pi.id " &
            "LEFT JOIN tbl_vessels v ON v.id=pss.vessel_id " &
            "WHERE pi.crew_status IN (3,6) " & whereClause &
            "ORDER BY r.sequence, pi.lastname"

        Dim dt As DataTable
        If Not String.IsNullOrEmpty(vesselID) Then
            dt = DbHelper.FillDataTable(sql, CommandType.Text, New MySqlParameter("@vid", vesselID))
        Else
            dt = DbHelper.FillDataTable(sql, CommandType.Text)
        End If

        gvCCL.DataSource = dt
        gvCCL.DataBind()
    End Sub

End Class
