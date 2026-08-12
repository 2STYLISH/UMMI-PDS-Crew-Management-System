Imports MySql.Data.MySqlClient
Imports System.Data

Public Class QueryCrew
    Inherits System.Web.UI.Page

    ' Store rank/province/city/vessel ID arrays in ViewState (mirrors production pattern)
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        RequireLogin()
        RequireRole("MANNING_STAFF", "SUPER_ADMIN", "PRINCIPAL")

        If Not IsPostBack Then
            CType(Master, masterPage).lblPageTitle.Text = "Crew Search"
            GetAdmin("Visited", CurrentUserID().ToString(), "QueryCrew", "Crew Search")

            LoadCrewStatus()
            LoadRankType()
            LoadRanks("ALL")
            LoadProvinces()
            LoadCities(0)
            LoadVesselTypes()
            LoadVessels()

            ' Principal defaults to ACTIVE status only
            If IsPrincipal() Then
                drpdwnCrewStatus.SelectedValue = "1"
                divAvailability.Visible = False
            End If

            ' Role-based visibility (WBS 1.1.8)
            ApplyRoleVisibility()
            SearchCrew(Nothing, Nothing)
        End If
    End Sub

    ' ──────────────── WBS 1.1.8 Role-Based Visibility ────────────────
    Private Sub ApplyRoleVisibility()
        Dim role As String = CurrentRole()
        divAvailability.Visible = (role <> "PRINCIPAL")
        btnPrintResult.Visible  = (role <> "PRINCIPAL")
        btnExportExcel.Visible  = (role <> "PRINCIPAL")
    End Sub

    ' ──────────────── Load Dropdowns ─────────────────────────────────
    Private Sub LoadCrewStatus()
        drpdwnCrewStatus.Items.Clear()
        drpdwnCrewStatus.Items.Add(New System.Web.UI.WebControls.ListItem("ALL", ""))
        Dim sql As String = "SELECT id, meaning FROM tbl_dropdown_selection " &
                            "WHERE type='crew_status' AND status='Active' ORDER BY sequence"
        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                Using dr As MySqlDataReader = cmd.ExecuteReader()
                    Dim ids As New List(Of Integer)
                    Do While dr.Read()
                        drpdwnCrewStatus.Items.Add(New System.Web.UI.WebControls.ListItem(dr("meaning").ToString(), dr("id").ToString()))
                        ids.Add(dr.GetInt32("id"))
                    Loop
                    ViewState("arr_CrewStatusID") = ids
                End Using
            End Using
        End Using
    End Sub

    Private Sub LoadRankType()
        drpdwnRankType.Items.Clear()
        drpdwnRankType.Items.Add(New System.Web.UI.WebControls.ListItem("ALL", ""))
        Dim sql As String = "SELECT rank_type FROM tbl_rank GROUP BY rank_type ORDER BY sequence"
        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text)
        For Each row As DataRow In dt.Rows
            drpdwnRankType.Items.Add(row("rank_type").ToString())
        Next
    End Sub

    Private Sub LoadRanks(rankType As String)
        drpdwnRank.Items.Clear()
        drpdwnRank.Items.Add(New System.Web.UI.WebControls.ListItem("ALL", ""))
        Dim sql As String = "SELECT id, rank_code FROM tbl_rank "
        If rankType <> "ALL" AndAlso rankType <> "" Then
            sql &= "WHERE rank_type=@rt "
        End If
        sql &= "ORDER BY sequence"
        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                If rankType <> "ALL" AndAlso rankType <> "" Then
                    cmd.Parameters.AddWithValue("@rt", rankType)
                End If
                Dim ids As New List(Of Integer)
                Using dr As MySqlDataReader = cmd.ExecuteReader()
                    Do While dr.Read()
                        drpdwnRank.Items.Add(New System.Web.UI.WebControls.ListItem(dr("rank_code").ToString(), dr("id").ToString()))
                        ids.Add(dr.GetInt32("id"))
                    Loop
                End Using
                ViewState("arr_RankID") = ids
            End Using
        End Using
    End Sub

    Private Sub LoadProvinces()
        drpdwnProvince.Items.Clear()
        drpdwnProvince.Items.Add(New System.Web.UI.WebControls.ListItem("ALL", ""))
        Dim sql As String = "SELECT id, provinces FROM tbl_provinces ORDER BY provinces"
        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                Dim ids As New List(Of Integer)
                Using dr As MySqlDataReader = cmd.ExecuteReader()
                    Do While dr.Read()
                        drpdwnProvince.Items.Add(New System.Web.UI.WebControls.ListItem(dr("provinces").ToString(), dr("id").ToString()))
                        ids.Add(dr.GetInt32("id"))
                    Loop
                End Using
                ViewState("arr_ProvinceID") = ids
            End Using
        End Using
    End Sub

    Private Sub LoadCities(provinceID As Integer)
        drpdwnCity.Items.Clear()
        drpdwnCity.Items.Add(New System.Web.UI.WebControls.ListItem("ALL", ""))
        Dim sql As String = "SELECT id, cities FROM tbl_cities "
        If provinceID > 0 Then sql &= "WHERE province=@pid "
        sql &= "ORDER BY cities"
        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                If provinceID > 0 Then cmd.Parameters.AddWithValue("@pid", provinceID)
                Dim ids As New List(Of Integer)
                Using dr As MySqlDataReader = cmd.ExecuteReader()
                    Do While dr.Read()
                        drpdwnCity.Items.Add(New System.Web.UI.WebControls.ListItem(dr("cities").ToString(), dr("id").ToString()))
                        ids.Add(dr.GetInt32("id"))
                    Loop
                End Using
                ViewState("arr_CityID") = ids
            End Using
        End Using
    End Sub

    Private Sub LoadVesselTypes()
        drpdwnVesselTypeExperience.Items.Clear()
        drpdwnVesselTypeExperience.Items.Add(New System.Web.UI.WebControls.ListItem("ALL", ""))
        Dim sql As String = "SELECT id, typeOfVessel FROM tbl_type_of_vessel ORDER BY typeOfVessel"
        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                Dim ids As New List(Of Integer)
                Using dr As MySqlDataReader = cmd.ExecuteReader()
                    Do While dr.Read()
                        drpdwnVesselTypeExperience.Items.Add(New System.Web.UI.WebControls.ListItem(
                            dr("typeOfVessel").ToString().ToUpper() & " EXPERIENCE", dr("id").ToString()))
                        ids.Add(dr.GetInt32("id"))
                    Loop
                End Using
                ViewState("arr_VesselTypeID") = ids
            End Using
        End Using
    End Sub

    Private Sub LoadVessels()
        drpdwnVessel.Items.Clear()
        drpdwnVessel.Items.Add(New System.Web.UI.WebControls.ListItem("ALL", ""))
        Dim sql As String = "SELECT id, vesselName FROM tbl_vessels WHERE active='Active' ORDER BY vesselName"
        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                Dim ids As New List(Of Integer)
                Using dr As MySqlDataReader = cmd.ExecuteReader()
                    Do While dr.Read()
                        drpdwnVessel.Items.Add(New System.Web.UI.WebControls.ListItem(dr("vesselName").ToString(), dr("id").ToString()))
                        ids.Add(dr.GetInt32("id"))
                    Loop
                End Using
                ViewState("arr_VesselID") = ids
            End Using
        End Using
    End Sub

    ' ──────────────── UC-CM-01/02/03: Search ─────────────────────────
    Protected Sub SearchCrew(sender As Object, e As EventArgs)
        ' WBS 1.1.5 Validation: Cadetship and JOCAP cannot both be selected
        If chkCadetship.Checked AndAlso chkJOCAP.Checked Then
            lblNotify.Text = "<div class='alert alert-danger'>Cannot search Cadetship and JOCAP simultaneously.</div>"
            Return
        End If

        Dim crewStatusID As Object = If(drpdwnCrewStatus.SelectedValue = "", DBNull.Value, CObj(drpdwnCrewStatus.SelectedValue))
        Dim availabilityVal As Object = If(drpdwnCrewAvailability.SelectedValue = "", DBNull.Value, CObj(drpdwnCrewAvailability.SelectedValue))
        Dim rankID As Object = If(drpdwnRank.SelectedValue = "" OrElse drpdwnRank.SelectedValue = "0", DBNull.Value, CObj(drpdwnRank.SelectedValue))
        Dim rankType As String = drpdwnRankType.SelectedValue
        Dim vesselTypeID As Object = If(drpdwnVesselTypeExperience.SelectedValue = "" , DBNull.Value, CObj(drpdwnVesselTypeExperience.SelectedValue))
        Dim vesselID As Object = If(drpdwnVessel.SelectedValue = "" , DBNull.Value, CObj(drpdwnVessel.SelectedValue))
        Dim provinceID As Object = If(drpdwnProvince.SelectedValue = "" , DBNull.Value, CObj(drpdwnProvince.SelectedValue))
        Dim cityID As Object = If(drpdwnCity.SelectedValue = "" , DBNull.Value, CObj(drpdwnCity.SelectedValue))
        Dim dateVal As Object = DBNull.Value
        If IsDate(txtDate.Text) Then dateVal = CDate(txtDate.Text)

        ' Audit log (WBS 1.1.10)
        Dim searchDesc As String = txtLastName.Text & " " & txtFirstName.Text &
            " Status:" & If(drpdwnCrewStatus.SelectedItem IsNot Nothing, drpdwnCrewStatus.SelectedItem.Text, "") &
            " Rank:" & If(drpdwnRank.SelectedItem IsNot Nothing, drpdwnRank.SelectedItem.Text, "")
        GetAdmin("Searched", CurrentUserID().ToString(), "QueryCrew", searchDesc)

        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand("spQueryCrewSearchDisplay", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@lastname_",        If(txtLastName.Text.Trim() = "", "", txtLastName.Text.Trim()))
                cmd.Parameters.AddWithValue("@firstname_",       If(txtFirstName.Text.Trim() = "", "", txtFirstName.Text.Trim()))
                cmd.Parameters.AddWithValue("@crewstatusID_",    crewStatusID)
                cmd.Parameters.AddWithValue("@crewavailbility_", availabilityVal)
                cmd.Parameters.AddWithValue("@activeInactive_",  "")
                cmd.Parameters.AddWithValue("@rankID_",          rankID)
                cmd.Parameters.AddWithValue("@ranktypeID_",      rankType)
                cmd.Parameters.AddWithValue("@vesselID_",        vesselID)
                cmd.Parameters.AddWithValue("@vesselTypeExpID_", vesselTypeID)
                cmd.Parameters.AddWithValue("@provinceID_",      provinceID)
                cmd.Parameters.AddWithValue("@cityID_",          cityID)
                cmd.Parameters.AddWithValue("@cadetship_",       If(chkCadetship.Checked, 1, 0))
                cmd.Parameters.AddWithValue("@jocap_",           If(chkJOCAP.Checked, 1, 0))
                cmd.Parameters.AddWithValue("@higherlic_",       If(chkHigherLic.Checked, 1, 0))
                cmd.Parameters.AddWithValue("@date_",            dateVal)
                cmd.Parameters.AddWithValue("@userID_",          CurrentUserID())
                cmd.Parameters.AddWithValue("@userType_",        CurrentRole())

                Dim dt As New DataTable()
                Using da As New MySqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using

                ' WBS 1.1.9 Summary
                Dim totalCount As Integer = dt.Rows.Count
                Dim totalAge As Integer = 0
                For Each row As DataRow In dt.Rows
                    If Not IsDBNull(row("age")) Then totalAge += CInt(row("age"))
                Next
                lblCrewCount.Text  = totalCount.ToString()
                lblAverageAge.Text = If(totalCount > 0, Math.Round(CDbl(totalAge) / totalCount, 0).ToString(), "0")
                lblSearchSummary.Text = If(drpdwnCrewStatus.SelectedItem IsNot Nothing, drpdwnCrewStatus.SelectedItem.Text, "") & " &bull; " & If(drpdwnRank.SelectedItem IsNot Nothing, drpdwnRank.SelectedItem.Text, "")
                divSummary.Visible = True

                GridViewQueryCrew.DataSource = dt
                GridViewQueryCrew.PageIndex = 0
                GridViewQueryCrew.DataBind()
            End Using
        End Using
    End Sub

    ' ──────────────── UC-CM-02: Reset ────────────────────────────────
    Protected Sub ResetFilters(sender As Object, e As EventArgs)
        txtLastName.Text  = ""
        txtFirstName.Text = ""
        txtDate.Text      = ""
        drpdwnCrewStatus.SelectedIndex           = 0
        drpdwnCrewAvailability.SelectedIndex     = 0
        drpdwnRankType.SelectedIndex             = 0
        drpdwnRank.SelectedIndex                 = 0
        drpdwnProvince.SelectedIndex             = 0
        drpdwnCity.SelectedIndex                 = 0
        drpdwnVesselTypeExperience.SelectedIndex = 0
        drpdwnVessel.SelectedIndex               = 0
        chkCadetship.Checked = False
        chkJOCAP.Checked     = False
        chkHigherLic.Checked = False
        lblNotify.Text = ""
        divSummary.Visible = False
        GridViewQueryCrew.DataSource = Nothing
        GridViewQueryCrew.DataBind()
    End Sub

    ' ──────────────── Province Cascade (WBS 1.1.3) ───────────────────
    Protected Sub ProvinceChanged(sender As Object, e As EventArgs)
        Dim pid As Integer = 0
        Integer.TryParse(drpdwnProvince.SelectedValue, pid)
        LoadCities(pid)
        SearchCrew(Nothing, Nothing)
    End Sub

    Protected Sub RankTypeChanged(sender As Object, e As EventArgs)
        LoadRanks(drpdwnRankType.SelectedValue)
        SearchCrew(Nothing, Nothing)
    End Sub

    ' ──────────────── RowDataBound (WBS 1.1.8 role visibility) ───────
    Protected Sub GridViewQueryCrew_RowDataBound(sender As Object, e As System.Web.UI.WebControls.GridViewRowEventArgs)
        ' Nothing extra needed; profile link is built in GetProfileUrl
    End Sub

    Protected Sub GridViewQueryCrew_PageIndexChanging(sender As Object, e As System.Web.UI.WebControls.GridViewPageEventArgs)
        GridViewQueryCrew.PageIndex = e.NewPageIndex
        SearchCrew(Nothing, Nothing)
    End Sub

    ' ──────────────── UC-CM-04/05 Export + Print ─────────────────────
    Protected Sub PrintResult(sender As Object, e As EventArgs)
        ' Pass current search context via session to Print page (WBS 1.1.11)
        Session("PrintFilters") = BuildFilterDesc()
        Response.Redirect("~/Crew/Print.aspx", True)
    End Sub

    Protected Sub ExportExcel(sender As Object, e As EventArgs)
        Dim dt As DataTable = GetCurrentResultDataTable()
        ExportToExcel(dt, "CrewList_" & DateTime.Now.ToString("yyyyMMdd"), "UMMI Crew List", Response)
    End Sub

    ' ──────────────── Helper Functions ───────────────────────────────
    Public Function GetProfileUrl(id As Object) As String
        Dim encID As String = HttpUtility.UrlEncode(Encrypt(id.ToString()))
        Dim encType As String = HttpUtility.UrlEncode(Encrypt("Viewer"))
        Return "~/Crew/ProfileViewer.aspx?ID=" & encID & "&Type=" & encType
    End Function

    Private Function BuildFilterDesc() As String
        Return "Status:" & If(drpdwnCrewStatus.SelectedItem IsNot Nothing, drpdwnCrewStatus.SelectedItem.Text, "") &
               "|Rank:" & If(drpdwnRank.SelectedItem IsNot Nothing, drpdwnRank.SelectedItem.Text, "") &
               "|Province:" & If(drpdwnProvince.SelectedItem IsNot Nothing, drpdwnProvince.SelectedItem.Text, "")
    End Function

    Private Function GetCurrentResultDataTable() As DataTable
        ' Re-run query for export
        SearchCrew(Nothing, Nothing)
        Return TryCast(GridViewQueryCrew.DataSource, DataTable)
    End Function

End Class
