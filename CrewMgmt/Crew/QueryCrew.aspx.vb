Imports MySql.Data.MySqlClient
Imports System.Data
Imports System.Web.UI.WebControls

Public Class QueryCrew
    Inherits System.Web.UI.Page

    Private Const PageSize As Integer = 10

    ' Read/write the current page index through the hidden field.
    Private Property CurrentPage() As Integer
        Get
            Dim v As Integer = 0
            Integer.TryParse(hfPageIndex.Value, v)
            Return v
        End Get
        Set(value As Integer)
            hfPageIndex.Value = value.ToString()
        End Set
    End Property

    ' Store rank/province/city/vessel ID arrays in ViewState (mirrors production pattern)
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        RequireLogin()
        RequireRole(ROLE_MANNING_STAFF, ROLE_DOCUMENTATION_OFFICER, ROLE_SUPER_ADMIN, ROLE_ADMIN, ROLE_PRINCIPAL, ROLE_VESSEL_OWNER)

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

            ' Principal / Vessel Owner defaults to ACTIVE status only (FR-CM-02)
            If HasPrincipalAccess() Then
                drpdwnCrewStatus.SelectedValue = "1"
                divAvailability.Visible = False
            End If

            ' Role-based visibility (FR-CM-05/FR-CM-30)
            ApplyRoleVisibility()
            SearchCrew(Nothing, Nothing)
        Else
            ' Recreate pager LinkButton controls early in the page lifecycle so that
            ' ASP.NET can match the clicked button's postback ID and fire GoToPage.
            ' Without this, dynamic controls added only inside BindGrid/BuildPager do
            ' not exist during the event-dispatch phase and the click is silently lost.
            Dim storedPages As Integer = 0
            If ViewState("sch_TotalPages") IsNot Nothing Then
                storedPages = CInt(ViewState("sch_TotalPages"))
            End If
            If storedPages > 1 Then
                BuildPager(CurrentPage, storedPages)
            End If
        End If
    End Sub

    ' ──────────────── Role-Based Visibility ────────────────
    Private Sub ApplyRoleVisibility()
        Dim isPrincipalAccess As Boolean = HasPrincipalAccess()
        divAvailability.Visible = Not isPrincipalAccess
        ' UC-CM-02 FR-CM-05: Reset not available for Principal / Vessel Owner
        btnReset.Visible = Not isPrincipalAccess
        ' UC-CM-04 FR-CM-25: Export not available for Principal / Vessel Owner
        btnExportExcel.Visible = Not isPrincipalAccess
        ' UC-CM-25 FR-CM-30: Releasing Checklist only for Manning/Admin staff
        btnReleasingChecklist.Visible = CanViewReleasingChecklist()
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

    ' ──────────────── UC-CM-01/03: Search ─────────────────────────
    ' Called only by btnSearch, btnReset, and the initial Page_Load (IsPostBack=False).
    ' Always resets the grid to Page 1 and saves the submitted criteria to ViewState
    ' so that pagination can re-run the same query without touching the filter controls.
    Protected Sub SearchCrew(sender As Object, e As EventArgs)
        ' FR-CM-04: Cadetship and JOCAP cannot both be selected
        If chkCadetship.Checked AndAlso chkJOCAP.Checked Then
            lblNotify.Text = "<div class='alert alert-danger'>Cannot search Cadetship and JOCAP simultaneously.</div>"
            Return
        End If

        lblNotify.Text = ""

        Dim crewStatusID As Object = If(drpdwnCrewStatus.SelectedValue = "", DBNull.Value, CObj(drpdwnCrewStatus.SelectedValue))
        Dim availabilityVal As Object = If(drpdwnCrewAvailability.SelectedValue = "", DBNull.Value, CObj(drpdwnCrewAvailability.SelectedValue))
        Dim rankID As Object = If(drpdwnRank.SelectedValue = "" OrElse drpdwnRank.SelectedValue = "0", DBNull.Value, CObj(drpdwnRank.SelectedValue))
        Dim rankType As String = drpdwnRankType.SelectedValue
        Dim vesselTypeID As Object = If(drpdwnVesselTypeExperience.SelectedValue = "", DBNull.Value, CObj(drpdwnVesselTypeExperience.SelectedValue))
        Dim vesselID As Object = If(drpdwnVessel.SelectedValue = "", DBNull.Value, CObj(drpdwnVessel.SelectedValue))
        Dim provinceID As Object = If(drpdwnProvince.SelectedValue = "", DBNull.Value, CObj(drpdwnProvince.SelectedValue))
        Dim cityID As Object = If(drpdwnCity.SelectedValue = "", DBNull.Value, CObj(drpdwnCity.SelectedValue))
        Dim dateVal As Object = DBNull.Value
        If IsDate(txtDate.Text) Then dateVal = CDate(txtDate.Text)

        ' Persist the submitted criteria so pagination can replay them
        ViewState("sch_LastName") = txtLastName.Text.Trim()
        ViewState("sch_FirstName") = txtFirstName.Text.Trim()
        ViewState("sch_StatusID") = crewStatusID
        ViewState("sch_Avail") = availabilityVal
        ViewState("sch_RankType") = rankType
        ViewState("sch_RankID") = rankID
        ViewState("sch_VesselTypeID") = vesselTypeID
        ViewState("sch_VesselID") = vesselID
        ViewState("sch_ProvinceID") = provinceID
        ViewState("sch_CityID") = cityID
        ViewState("sch_Cadetship") = If(chkCadetship.Checked, 1, 0)
        ViewState("sch_JOCAP") = If(chkJOCAP.Checked, 1, 0)
        ViewState("sch_HigherLic") = If(chkHigherLic.Checked, 1, 0)
        ViewState("sch_Date") = dateVal
        ViewState("sch_StatusText") = If(drpdwnCrewStatus.SelectedItem IsNot Nothing, drpdwnCrewStatus.SelectedItem.Text, "")
        ViewState("sch_RankText") = If(drpdwnRank.SelectedItem IsNot Nothing, drpdwnRank.SelectedItem.Text, "")
        ViewState("sch_StatusVal") = drpdwnCrewStatus.SelectedValue

        ' Audit log (FR-CM-53)
        Dim searchDesc As String = txtLastName.Text & " " & txtFirstName.Text &
            " Status:" & If(drpdwnCrewStatus.SelectedItem IsNot Nothing, drpdwnCrewStatus.SelectedItem.Text, "") &
            " Rank:" & If(drpdwnRank.SelectedItem IsNot Nothing, drpdwnRank.SelectedItem.Text, "")
        GetAdmin("Searched", CurrentUserID().ToString(), "QueryCrew", searchDesc)

        ' Reset to page 1 only on a new explicit search
        CurrentPage = 0

        BindGrid()
    End Sub

    ' ──────────────── Query helper: executes SP using last-submitted ViewState criteria ──
    Private Function GetFullSearchResultDataTable() As DataTable
        Dim lastNameVal As String = If(ViewState("sch_LastName") IsNot Nothing, ViewState("sch_LastName").ToString(), "")
        Dim firstNameVal As String = If(ViewState("sch_FirstName") IsNot Nothing, ViewState("sch_FirstName").ToString(), "")
        Dim crewStatusID As Object = If(ViewState("sch_StatusID") IsNot Nothing, ViewState("sch_StatusID"), DBNull.Value)
        Dim availVal As Object = If(ViewState("sch_Avail") IsNot Nothing, ViewState("sch_Avail"), DBNull.Value)
        Dim rankType As String = If(ViewState("sch_RankType") IsNot Nothing, ViewState("sch_RankType").ToString(), "")
        Dim rankID As Object = If(ViewState("sch_RankID") IsNot Nothing, ViewState("sch_RankID"), DBNull.Value)
        Dim vesselTypeID As Object = If(ViewState("sch_VesselTypeID") IsNot Nothing, ViewState("sch_VesselTypeID"), DBNull.Value)
        Dim vesselID As Object = If(ViewState("sch_VesselID") IsNot Nothing, ViewState("sch_VesselID"), DBNull.Value)
        Dim provinceID As Object = If(ViewState("sch_ProvinceID") IsNot Nothing, ViewState("sch_ProvinceID"), DBNull.Value)
        Dim cityID As Object = If(ViewState("sch_CityID") IsNot Nothing, ViewState("sch_CityID"), DBNull.Value)
        Dim cadetship As Integer = If(ViewState("sch_Cadetship") IsNot Nothing, CInt(ViewState("sch_Cadetship")), 0)
        Dim jocap As Integer = If(ViewState("sch_JOCAP") IsNot Nothing, CInt(ViewState("sch_JOCAP")), 0)
        Dim higherLic As Integer = If(ViewState("sch_HigherLic") IsNot Nothing, CInt(ViewState("sch_HigherLic")), 0)
        Dim dateVal As Object = If(ViewState("sch_Date") IsNot Nothing, ViewState("sch_Date"), DBNull.Value)

        Dim fullDt As New DataTable()
        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand("spQueryCrewSearchDisplay", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@lastname_", lastNameVal)
                cmd.Parameters.AddWithValue("@firstname_", firstNameVal)
                cmd.Parameters.AddWithValue("@crewstatusID_", crewStatusID)
                cmd.Parameters.AddWithValue("@crewavailbility_", availVal)
                cmd.Parameters.AddWithValue("@activeInactive_", "")
                cmd.Parameters.AddWithValue("@rankID_", rankID)
                cmd.Parameters.AddWithValue("@ranktypeID_", rankType)
                cmd.Parameters.AddWithValue("@vesselID_", vesselID)
                cmd.Parameters.AddWithValue("@vesselTypeExpID_", vesselTypeID)
                cmd.Parameters.AddWithValue("@provinceID_", provinceID)
                cmd.Parameters.AddWithValue("@cityID_", cityID)
                cmd.Parameters.AddWithValue("@cadetship_", cadetship)
                cmd.Parameters.AddWithValue("@jocap_", jocap)
                cmd.Parameters.AddWithValue("@higherlic_", higherLic)
                cmd.Parameters.AddWithValue("@date_", dateVal)
                cmd.Parameters.AddWithValue("@userID_", CurrentUserID())
                cmd.Parameters.AddWithValue("@userType_", CurrentRole())
                Using da As New MySqlDataAdapter(cmd)
                    da.Fill(fullDt)
                End Using
            End Using
        End Using
        Return fullDt
    End Function

    ' ──────────────── BindGrid: bind results and update summary/pagination ──
    Private Sub BindGrid()
        Dim statusText As String = If(ViewState("sch_StatusText") IsNot Nothing, ViewState("sch_StatusText").ToString(), "")
        Dim rankText As String = If(ViewState("sch_RankText") IsNot Nothing, ViewState("sch_RankText").ToString(), "")
        Dim statusVal As String = If(ViewState("sch_StatusVal") IsNot Nothing, ViewState("sch_StatusVal").ToString(), "")

        Dim fullDt As DataTable = GetFullSearchResultDataTable()

        ' FR-CM-10: Summary counts are over ALL matching rows, not just the current page
        Dim totalCount As Integer = fullDt.Rows.Count
        Dim totalAge As Integer = 0
        For Each row As DataRow In fullDt.Rows
            If Not IsDBNull(row("age")) Then totalAge += CInt(row("age"))
        Next
        lblCrewCount.Text = totalCount.ToString()
        lblAverageAge.Text = If(totalCount > 0, Math.Round(CDbl(totalAge) / totalCount, 0).ToString(), "0")
        lblSearchSummary.Text = statusText & " &bull; " & rankText
        divSummary.Visible = True

        ' UC-CM-25: Show releasing checklist button only when status=LINE UP (status 6)
        If CanViewReleasingChecklist() Then
            btnReleasingChecklist.Visible = (statusVal = "6")
        End If

        ' UC-CM-04 FR-CM-25: Hide export when status is Applicant (status 5)
        If Not IsPrincipal() Then
            btnExportExcel.Visible = (statusVal <> "5")
        End If

        ' ── Manual pagination: clamp current page then slice the DataTable ──
        Dim totalPages As Integer = Math.Max(1, CInt(Math.Ceiling(totalCount / PageSize)))
        Dim pg As Integer = Math.Max(0, Math.Min(CurrentPage, totalPages - 1))
        CurrentPage = pg  ' write back clamped value

        Dim startRow As Integer = pg * PageSize
        Dim pageDt As DataTable = fullDt.Clone()
        Dim endRow As Integer = Math.Min(startRow + PageSize, totalCount)
        For i As Integer = startRow To endRow - 1
            pageDt.ImportRow(fullDt.Rows(i))
        Next

        GridViewQueryCrew.DataSource = pageDt
        GridViewQueryCrew.DataBind()

        ' Persist totalPages so Page_Load can recreate pager controls early on the
        ' next postback, before ASP.NET's event-dispatch phase runs.
        ViewState("sch_TotalPages") = totalPages

        ' Build the styled pager below the grid
        BuildPager(pg, totalPages)
    End Sub

    ' ──────────────── Custom pager builder ────────────────────────────
    ' Renders [‹] [1] [2] [3] […] [›] into phPager.
    ' Uses LinkButton so the UpdatePanel trigger (hfPageIndex ValueChanged) fires cleanly.
    Private Sub BuildPager(currentPg As Integer, totalPages As Integer)
        phPager.Controls.Clear()
        divPager.Visible = (totalPages > 1)
        If totalPages <= 1 Then Return

        ' ── Previous arrow ──
        Dim btnPrev As New LinkButton()
        btnPrev.Text = "&#x2039;"  ' ‹
        btnPrev.CssClass = "pg-btn" & If(currentPg = 0, " pg-disabled", "")
        btnPrev.Enabled = (currentPg > 0)
        btnPrev.Attributes("aria-label") = "Previous page"
        If currentPg > 0 Then
            btnPrev.CommandArgument = (currentPg - 1).ToString()
            AddHandler btnPrev.Click, AddressOf GoToPage
        End If
        phPager.Controls.Add(btnPrev)

        ' ── Page number window with ellipsis ──
        ' Always show first page, last page, current page ±1, with ellipsis for gaps.
        Dim windowSize As Integer = 1  ' pages shown each side of current
        Dim pages As New List(Of Integer)  ' sorted set of page numbers to render
        pages.Add(0)
        pages.Add(totalPages - 1)
        For p As Integer = Math.Max(0, currentPg - windowSize) To Math.Min(totalPages - 1, currentPg + windowSize)
            If Not pages.Contains(p) Then pages.Add(p)
        Next
        pages.Sort()

        Dim lastRendered As Integer = -1
        For Each p As Integer In pages
            If lastRendered >= 0 AndAlso p > lastRendered + 1 Then
                ' Gap — render ellipsis
                Dim ellipsis As New System.Web.UI.HtmlControls.HtmlGenericControl("span")
                ellipsis.Attributes("class") = "pg-ellipsis"
                ellipsis.InnerText = "..."
                phPager.Controls.Add(ellipsis)
            End If

            Dim isActive As Boolean = (p = currentPg)
            Dim btnPage As New LinkButton()
            btnPage.Text = (p + 1).ToString()  ' 1-based display
            btnPage.CssClass = "pg-btn" & If(isActive, " pg-active", "")
            btnPage.Enabled = Not isActive
            btnPage.CommandArgument = p.ToString()
            If isActive Then
                btnPage.Attributes("aria-current") = "page"
            Else
                AddHandler btnPage.Click, AddressOf GoToPage
            End If
            phPager.Controls.Add(btnPage)
            lastRendered = p
        Next

        ' ── Next arrow ──
        Dim btnNext As New LinkButton()
        btnNext.Text = "&#x203A;"  ' ›
        btnNext.CssClass = "pg-btn" & If(currentPg >= totalPages - 1, " pg-disabled", "")
        btnNext.Enabled = (currentPg < totalPages - 1)
        btnNext.Attributes("aria-label") = "Next page"
        If currentPg < totalPages - 1 Then
            btnNext.CommandArgument = (currentPg + 1).ToString()
            AddHandler btnNext.Click, AddressOf GoToPage
        End If
        phPager.Controls.Add(btnNext)
    End Sub

    ' ──────────────── Pager button click handler ─────────────────────
    Protected Sub GoToPage(sender As Object, e As EventArgs)
        Dim btn As LinkButton = CType(sender, LinkButton)
        Dim targetPage As Integer = 0
        If Integer.TryParse(btn.CommandArgument, targetPage) Then
            CurrentPage = targetPage
            BindGrid()
        End If
    End Sub

    ' ──────────────── hfPageIndex ValueChanged (UpdatePanel trigger) ─
    Protected Sub hfPageIndex_ValueChanged(sender As Object, e As EventArgs) Handles hfPageIndex.ValueChanged
        BindGrid()
    End Sub

    ' ──────────────── UC-CM-02: Reset Filters (FR-CM-05) ──────────
    Protected Sub ResetFilters(sender As Object, e As EventArgs)
        txtLastName.Text = ""
        txtFirstName.Text = ""
        txtDate.Text = ""
        drpdwnCrewStatus.SelectedIndex = 0
        drpdwnCrewAvailability.SelectedIndex = 0
        drpdwnRankType.SelectedIndex = 0
        LoadRanks("ALL")
        drpdwnRank.SelectedIndex = 0
        drpdwnProvince.SelectedIndex = 0
        LoadCities(0)
        drpdwnCity.SelectedIndex = 0
        drpdwnVesselTypeExperience.SelectedIndex = 0
        drpdwnVessel.SelectedIndex = 0
        chkCadetship.Checked = False
        chkJOCAP.Checked = False
        chkHigherLic.Checked = False
        lblNotify.Text = ""

        ' FR-CM-05: Reload active crew statuses
        LoadCrewStatus()

        ' FR-CM-05: Re-execute search with defaults
        SearchCrew(Nothing, Nothing)
    End Sub

    ' ──────────────── Province Cascade ───────────────────
    ' Bug 2 fix: only repopulate the city dropdown — do NOT execute a search.
    Protected Sub ProvinceChanged(sender As Object, e As EventArgs)
        Dim pid As Integer = 0
        Integer.TryParse(drpdwnProvince.SelectedValue, pid)
        LoadCities(pid)
    End Sub

    ' Bug 2 fix: only repopulate the rank dropdown — do NOT execute a search.
    Protected Sub RankTypeChanged(sender As Object, e As EventArgs)
        LoadRanks(drpdwnRankType.SelectedValue)
    End Sub

    ' ──────────────── UC-CM-03/06/07: RowDataBound ───────
    Protected Sub GridViewQueryCrew_RowDataBound(sender As Object, e As System.Web.UI.WebControls.GridViewRowEventArgs)
        If e.Row.RowType <> System.Web.UI.WebControls.DataControlRowType.DataRow Then Return
        Dim drv As DataRowView = CType(e.Row.DataItem, DataRowView)

        ' ── Crew photo with status border (FR-CM-06) ──
        Dim imgPhoto As System.Web.UI.WebControls.Image = CType(e.Row.FindControl("imgCrewPhoto"), System.Web.UI.WebControls.Image)
        If imgPhoto IsNot Nothing Then
            If Not IsDBNull(drv("picture_id")) AndAlso drv("picture_id").ToString() <> "" Then
                imgPhoto.ImageUrl = "~/Uploads/picture/" & drv("picture_id").ToString()
            Else
                ' UC-CM-07: Gender-appropriate placeholder
                Dim gender As String = If(drv.Row.Table.Columns.Contains("gender"), drv("gender").ToString(), "")
                imgPhoto.ImageUrl = If(gender = "Female", "~/images/silhouette_female.png", "~/images/silhouette_user.png")
            End If
            ' Status border color
            Dim crewStatus As Integer = 0
            If Not IsDBNull(drv("crew_status")) Then crewStatus = CInt(drv("crew_status"))
            Select Case crewStatus
                Case 3 : imgPhoto.CssClass = "crew-photo-cell status-onboard"  ' ON BOARD
                Case 6 : imgPhoto.CssClass = "crew-photo-cell status-lineup"   ' LINE UP
                Case 4 : imgPhoto.CssClass = "crew-photo-cell status-vacation" ' ON VACATION
                Case 1 : imgPhoto.CssClass = "crew-photo-cell status-active"   ' ACTIVE
                Case 2 : imgPhoto.CssClass = "crew-photo-cell status-inactive" ' INACTIVE
                Case Else : imgPhoto.CssClass = "crew-photo-cell"
            End Select
        End If

        ' ── UC-CM-06 FR-CM-08: Vessel as CCL link for ON-BOARD/LINE UP ──
        Dim lnkVessel As System.Web.UI.WebControls.HyperLink = CType(e.Row.FindControl("lnkVessel"), System.Web.UI.WebControls.HyperLink)
        Dim lblVesselPlain As System.Web.UI.WebControls.Label = CType(e.Row.FindControl("lblVesselPlain"), System.Web.UI.WebControls.Label)
        Dim vesselName As String = ""
        Dim vesselId As String = ""
        If drv.Row.Table.Columns.Contains("vessel_name") AndAlso Not IsDBNull(drv("vessel_name")) Then
            vesselName = drv("vessel_name").ToString()
        End If
        If drv.Row.Table.Columns.Contains("assigned_vessel_id") AndAlso Not IsDBNull(drv("assigned_vessel_id")) Then
            vesselId = drv("assigned_vessel_id").ToString()
        End If

        Dim crewStat As Integer = 0
        If Not IsDBNull(drv("crew_status")) Then crewStat = CInt(drv("crew_status"))

        If (crewStat = 3 OrElse crewStat = 6) AndAlso HasCCLPermission() AndAlso vesselName <> "" Then
            lnkVessel.Visible = True
            lnkVessel.Text = Server.HtmlEncode(vesselName)
            ' Link to CCL stub page with vessel parameter
            If vesselId <> "" Then
                Dim encVslID As String = HttpUtility.UrlEncode(Encrypt(vesselId))
                lnkVessel.NavigateUrl = "~/Crew/CrewChangeList.aspx?VesselID=" & encVslID
            End If
            lblVesselPlain.Visible = False
        Else
            lnkVessel.Visible = False
            lblVesselPlain.Visible = True
            lblVesselPlain.Text = Server.HtmlEncode(vesselName)
        End If

        ' ── Last Vessel ──
        Dim lblLastVessel As System.Web.UI.WebControls.Label = CType(e.Row.FindControl("lblLastVessel"), System.Web.UI.WebControls.Label)
        If lblLastVessel IsNot Nothing Then
            If drv.Row.Table.Columns.Contains("last_vessel_name") AndAlso Not IsDBNull(drv("last_vessel_name")) Then
                lblLastVessel.Text = Server.HtmlEncode(drv("last_vessel_name").ToString())
            End If
        End If

        ' ── FR-CM-07: Status date with elapsed-time color highlighting ──
        Dim lblStatusDate As System.Web.UI.WebControls.Label = CType(e.Row.FindControl("lblStatusDate"), System.Web.UI.WebControls.Label)
        If lblStatusDate IsNot Nothing AndAlso drv.Row.Table.Columns.Contains("status_date") Then
            If Not IsDBNull(drv("status_date")) Then
                Dim sd As Date = CDate(drv("status_date"))
                lblStatusDate.Text = sd.ToString("MM/dd/yyyy")
                Dim elapsedMonths As Integer = (DateTime.Now.Year - sd.Year) * 12 + DateTime.Now.Month - sd.Month
                ' Amber: 4-8 months, Red: >8 months (only for specific statuses)
                If crewStat = 1 OrElse crewStat = 4 OrElse crewStat = 2 Then
                    If elapsedMonths > 8 Then
                        lblStatusDate.CssClass = "status-date-red"
                        lblStatusDate.Style.Add("padding", "2px 6px")
                        lblStatusDate.Style.Add("border-radius", "4px")
                    ElseIf elapsedMonths >= 4 Then
                        lblStatusDate.CssClass = "status-date-amber"
                        lblStatusDate.Style.Add("padding", "2px 6px")
                        lblStatusDate.Style.Add("border-radius", "4px")
                    End If
                End If
            End If
        End If

        ' ── Sea Service Duration (total UMMI service) ──
        Dim lblSeaService As System.Web.UI.WebControls.Label = CType(e.Row.FindControl("lblSeaService"), System.Web.UI.WebControls.Label)
        If lblSeaService IsNot Nothing AndAlso drv.Row.Table.Columns.Contains("total_sea_service") Then
            If Not IsDBNull(drv("total_sea_service")) Then
                lblSeaService.Text = drv("total_sea_service").ToString() & " yr(s)"
            Else
                lblSeaService.Text = "0 yr(s)"
            End If
        End If
    End Sub

    ' GridViewQueryCrew_PageIndexChanging removed — pagination is now handled
    ' by the custom BuildPager / GoToPage / hfPageIndex mechanism.

    ' ──────────────── UC-CM-04: Export Excel (FR-CM-25/FR-CM-26) ──
    Protected Sub ExportExcel(sender As Object, e As EventArgs)
        ' Role check: Principal is not authorized to export
        If IsPrincipal() Then
            lblNotify.Text = "<div class='alert alert-danger'>Access Denied.</div>"
            Return
        End If

        ' FR-CM-25: Not available for Applicant status (based on last submitted search or filter)
        Dim statusVal As String = If(ViewState("sch_StatusVal") IsNot Nothing, ViewState("sch_StatusVal").ToString(), drpdwnCrewStatus.SelectedValue)
        If statusVal = "5" Then
            lblNotify.Text = "<div class='alert alert-warning'>Export is not available for Applicant status.</div>"
            Return
        End If

        Try
            ' Retrieve all matching records for the submitted search (not just the current page)
            Dim fullDt As DataTable = GetFullSearchResultDataTable()
            If fullDt Is Nothing OrElse fullDt.Rows.Count = 0 Then
                lblNotify.Text = "<div class='alert alert-info'>No records found to export.</div>"
                Return
            End If

            Dim exportDt As DataTable = GetExportDataTable(fullDt)

            ' FR-CM-25: Filename includes status filter and timestamp
            Dim statusText As String = If(ViewState("sch_StatusText") IsNot Nothing AndAlso ViewState("sch_StatusText").ToString() <> "", ViewState("sch_StatusText").ToString(), "ALL")
            Dim fileName As String = "CrewList_" & statusText.Replace(" ", "") & "_" & DateTime.Now.ToString("yyyyMMdd_HHmm")

            ' FR-CM-26: Audit log with filter parameters upon successful export preparation
            Dim filterDesc As String = BuildFilterDesc()
            GetAdmin("Exported Crew List", CurrentUserID().ToString(), "QueryCrew", filterDesc)

            ExportToExcel(exportDt, fileName, "UMMI Crew List", Response)
        Catch ex As System.Threading.ThreadAbortException
            ' Normal completion for ASP.NET response file download
            Return
        Catch ex As Exception
            GetAdmin("Export Error", CurrentUserID().ToString(), "QueryCrew", "Error exporting crew list: " & ex.Message)
            lblNotify.Text = "<div class='alert alert-danger'><i class='fa fa-circle-exclamation me-2'></i>An error occurred while generating the Excel export. Please try again.</div>"
        End Try
    End Sub

    Private Function GetExportDataTable(fullDt As DataTable) As DataTable
        Dim exportDt As New DataTable()
        exportDt.Columns.Add("Name", GetType(String))
        exportDt.Columns.Add("Rank", GetType(String))
        exportDt.Columns.Add("Rank Type", GetType(String))
        exportDt.Columns.Add("Status", GetType(String))
        If fullDt.Columns.Contains("vessel_name") Then exportDt.Columns.Add("Vessel", GetType(String))
        exportDt.Columns.Add("Age", GetType(String))
        If fullDt.Columns.Contains("last_vessel_name") Then exportDt.Columns.Add("Last Vessel", GetType(String))
        If fullDt.Columns.Contains("status_date") Then exportDt.Columns.Add("Status Date", GetType(String))
        If fullDt.Columns.Contains("total_sea_service") Then exportDt.Columns.Add("Sea Service", GetType(String))
        exportDt.Columns.Add("Availability", GetType(String))
        exportDt.Columns.Add("Province", GetType(String))
        exportDt.Columns.Add("City / Municipality", GetType(String))
        exportDt.Columns.Add("Cadetship", GetType(String))
        exportDt.Columns.Add("JOCAP", GetType(String))
        exportDt.Columns.Add("Higher License", GetType(String))

        For Each row As DataRow In fullDt.Rows
            Dim nr As DataRow = exportDt.NewRow()
            Dim lastN As String = If(Not IsDBNull(row("lastname")), row("lastname").ToString(), "")
            Dim firstN As String = If(Not IsDBNull(row("firstname")), row("firstname").ToString(), "")
            Dim midN As String = If(Not IsDBNull(row("middlename")), row("middlename").ToString(), "")
            nr("Name") = (lastN & ", " & firstN & " " & midN).Trim()
            nr("Rank") = If(Not IsDBNull(row("rank_code")), row("rank_code").ToString(), "")
            nr("Rank Type") = If(Not IsDBNull(row("rank_type")), row("rank_type").ToString(), "")
            nr("Status") = If(Not IsDBNull(row("crew_status_text")), row("crew_status_text").ToString(), "")
            If fullDt.Columns.Contains("vessel_name") Then
                nr("Vessel") = If(Not IsDBNull(row("vessel_name")), row("vessel_name").ToString(), "")
            End If
            nr("Age") = If(Not IsDBNull(row("age")), row("age").ToString(), "")
            If fullDt.Columns.Contains("last_vessel_name") Then
                nr("Last Vessel") = If(Not IsDBNull(row("last_vessel_name")), row("last_vessel_name").ToString(), "")
            End If
            If fullDt.Columns.Contains("status_date") Then
                If Not IsDBNull(row("status_date")) AndAlso IsDate(row("status_date")) Then
                    nr("Status Date") = CDate(row("status_date")).ToString("MM/dd/yyyy")
                Else
                    nr("Status Date") = ""
                End If
            End If
            If fullDt.Columns.Contains("total_sea_service") Then
                nr("Sea Service") = If(Not IsDBNull(row("total_sea_service")), row("total_sea_service").ToString() & " yr(s)", "0 yr(s)")
            End If
            Dim avail As Integer = 0
            If Not IsDBNull(row("crew_availability")) Then Integer.TryParse(row("crew_availability").ToString(), avail)
            nr("Availability") = If(avail = 1, "Available", "Not Available")
            nr("Province") = If(Not IsDBNull(row("province_name")), row("province_name").ToString(), "")
            nr("City / Municipality") = If(Not IsDBNull(row("city_name")), row("city_name").ToString(), "")
            nr("Cadetship") = If(Not IsDBNull(row("cadetship")) AndAlso CInt(row("cadetship")) = 1, "Yes", "No")
            nr("JOCAP") = If(Not IsDBNull(row("jocap")) AndAlso CInt(row("jocap")) = 1, "Yes", "No")
            nr("Higher License") = If(Not IsDBNull(row("higher_license")) AndAlso CInt(row("higher_license")) = 1, "Yes", "No")
            exportDt.Rows.Add(nr)
        Next

        Return exportDt
    End Function

    ' ──────────────── UC-CM-25: Releasing Checklist ────────────────
    Protected Sub ShowReleasingChecklist(sender As Object, e As EventArgs)
        ' FR-CM-31: Require specific vessel selection
        If drpdwnVessel.SelectedValue = "" Then
            lblNotify.Text = "<div class='alert alert-warning'><i class='fa fa-triangle-exclamation me-2'></i>Please select a specific vessel before opening the Releasing Checklist.</div>"
            Return
        End If
        lblNotify.Text = ""
        lblReleasingVessel.Text = "<i class='fa fa-ship me-2'></i>" & Server.HtmlEncode(drpdwnVessel.SelectedItem.Text)
        panelReleasingChecklist.Visible = True

        ' Pre-populate flight booking checkboxes (FR-CM-29)
        LoadFlightBookings()
    End Sub

    Protected Sub HideReleasingChecklist(sender As Object, e As EventArgs)
        panelReleasingChecklist.Visible = False
    End Sub

    Private Sub LoadFlightBookings()
        If drpdwnVessel.SelectedValue = "" Then Return
        Dim vesselID As Integer = CInt(drpdwnVessel.SelectedValue)

        ' Check on-signers
        Dim onCount As Object = DbHelper.ExecuteScalar(
            "SELECT COUNT(*) FROM tbl_flight_booking WHERE vessel_id=@vid AND booking_type='on_signer' AND is_booked=1",
            New MySqlParameter("@vid", vesselID))
        chkFlightOnSigners.Checked = (CInt(If(onCount, 0)) > 0)

        ' Check off-signers
        Dim offCount As Object = DbHelper.ExecuteScalar(
            "SELECT COUNT(*) FROM tbl_flight_booking WHERE vessel_id=@vid AND booking_type='off_signer' AND is_booked=1",
            New MySqlParameter("@vid", vesselID))
        chkFlightOffSigners.Checked = (CInt(If(offCount, 0)) > 0)
    End Sub

    ' ──────────────── UC-CM-26: Export Releasing Checklist (FR-CM-32) ──
    Protected Sub ExportReleasingChecklist(sender As Object, e As EventArgs)
        ' Build parameter string and redirect to report page
        Dim params As String = "printType=ReleasingChecklist" &
            "&VesselID=" & HttpUtility.UrlEncode(Encrypt(drpdwnVessel.SelectedValue)) &
            "&VesselName=" & HttpUtility.UrlEncode(drpdwnVessel.SelectedItem.Text) &
            "&Batch=" & HttpUtility.UrlEncode(txtBatchNumber.Text.Trim()) &
            "&Terminal=" & HttpUtility.UrlEncode(drpdwnTerminal.SelectedValue) &
            "&FlightOn=" & If(chkFlightOnSigners.Checked, "1", "0") &
            "&FlightOff=" & If(chkFlightOffSigners.Checked, "1", "0") &
            "&GL=" & If(chkGLImmigration.Checked, "1", "0") &
            "&InfoSheet=" & If(chkInfoSheet.Checked, "1", "0") &
            "&PreEmb=" & If(chkPreEmbarkation.Checked, "1", "0") &
            "&Allotment=" & If(chkAllotment.Checked, "1", "0") &
            "&Visa=" & If(chkVisa.Checked, "1", "0") &
            "&EOC=" & If(chkEndOfContract.Checked, "1", "0")

        GetAdmin("Exported Releasing Checklist", CurrentUserID().ToString(), "QueryCrew",
            "Vessel:" & drpdwnVessel.SelectedItem.Text & " Batch:" & txtBatchNumber.Text.Trim())

        Response.Redirect("~/Crew/Print.aspx?" & params, True)
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
               "|Province:" & If(drpdwnProvince.SelectedItem IsNot Nothing, drpdwnProvince.SelectedItem.Text, "") &
               "|Vessel:" & If(drpdwnVessel.SelectedItem IsNot Nothing, drpdwnVessel.SelectedItem.Text, "")
    End Function



End Class
