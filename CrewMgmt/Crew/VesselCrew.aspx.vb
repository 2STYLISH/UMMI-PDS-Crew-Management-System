Imports MySql.Data.MySqlClient
Imports System.Data
Imports System.Web.UI.WebControls

''' <summary>
''' Vessel Crew View — displays all crew/personnel currently assigned to a specific vessel.
''' Accessed by clicking the vessel link in Crew Search (QueryCrew.aspx).
''' The vessel is identified by encrypted VesselID in the query string.
''' No CCL workflow is performed here; this is a read-only crew roster for the selected vessel.
''' </summary>
Public Class VesselCrew
    Inherits System.Web.UI.Page

    Private Const PageSize As Integer = 15

    ' ── Server control declarations (no designer file — declared explicitly, same pattern as CrewChangeList) ──
    Protected WithEvents lblVesselTitle    As Label
    Protected WithEvents lblVesselSubtitle As Label
    Protected WithEvents lblNotify         As Label
    Protected WithEvents lblCntOnboard     As Label
    Protected WithEvents lblCntLineup      As Label
    Protected WithEvents lblCntVacation    As Label
    Protected WithEvents lblCntTotal       As Label
    Protected WithEvents gvVesselCrew      As GridView
    Protected WithEvents lnkOpenCCL        As HyperLink
    Protected divPager                     As System.Web.UI.HtmlControls.HtmlGenericControl
    Protected WithEvents hfTargetPage      As HiddenField
    Protected WithEvents btnGoPager        As Button
    Protected WithEvents phPager           As PlaceHolder

    Private Property CurrentPage() As Integer
        Get
            If ViewState("_CurPage") IsNot Nothing Then Return CInt(ViewState("_CurPage"))
            Return 0
        End Get
        Set(value As Integer)
            ViewState("_CurPage") = value
        End Set
    End Property

    ' ════════════════════════════════════════════════════════
    ' PAGE LOAD
    ' ════════════════════════════════════════════════════════

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        RequireLogin()
        RequireRole(ROLE_MANNING_STAFF, ROLE_DOCUMENTATION_OFFICER,
                    ROLE_SUPER_ADMIN, ROLE_ADMIN,
                    ROLE_PRINCIPAL, ROLE_VESSEL_OWNER)

        If Not IsPostBack Then
            ' Resolve vessel from query string (encrypted VesselID)
            Dim encVslID As String = If(Request.QueryString("VesselID") IsNot Nothing,
                                         HttpUtility.UrlDecode(Request.QueryString("VesselID")), "")
            Dim vesselIDStr As String = If(Not String.IsNullOrEmpty(encVslID), Decrypt(encVslID), "")

            Dim vid As Integer = 0
            If Not String.IsNullOrEmpty(vesselIDStr) AndAlso Integer.TryParse(vesselIDStr, vid) AndAlso vid > 0 Then
                ViewState("VesselID") = vid
                LoadVesselInfo(vid)
                CurrentPage = 0
                BindGrid()

                ' CCL link — only for users with CCL permission
                If HasCCLPermission() Then
                    lnkOpenCCL.Visible = True
                    Dim encID As String = HttpUtility.UrlEncode(Encrypt(vid.ToString()))
                    lnkOpenCCL.NavigateUrl = "~/Crew/CrewChangeList.aspx?VesselID=" & encID
                End If

                GetAdmin("Viewed Vessel Crew", CurrentUserID().ToString(), "VesselCrew",
                         "VesselID=" & vid)
            Else
                ' No valid VesselID — redirect back to Crew Search
                GetAdmin("Invalid VesselID on VesselCrew", CurrentUserID().ToString(), "VesselCrew", encVslID)
                Response.Redirect("~/Crew/QueryCrew.aspx", True)
            End If

            CType(Master, masterPage).lblPageTitle.Text = "Vessel Crew"
        End If
    End Sub

    ' ════════════════════════════════════════════════════════
    ' LOAD VESSEL INFO
    ' ════════════════════════════════════════════════════════

    Private Sub LoadVesselInfo(vesselId As Integer)
        Dim sql As String = "SELECT vesselName FROM tbl_vessels WHERE id=@vid"
        Dim vname As Object = DbHelper.ExecuteScalar(sql, New MySqlParameter("@vid", vesselId))
        Dim displayName As String = If(vname IsNot Nothing AndAlso Not IsDBNull(vname),
                                        vname.ToString(), "Unknown Vessel")
        lblVesselTitle.Text = Server.HtmlEncode(displayName)
        lblVesselSubtitle.Text = Server.HtmlEncode(displayName)
        CType(Master, masterPage).lblPageTitle.Text = "Vessel Crew — " & displayName
    End Sub

    ' ════════════════════════════════════════════════════════
    ' DATA RETRIEVAL
    ' ════════════════════════════════════════════════════════

    ''' <summary>
    ''' Returns all crew (ON BOARD=3, LINE UP=6, ON VACATION=4) assigned to the vessel.
    ''' Uses parameterized query — no stored procedure required (existing SP is for full search).
    ''' Ordered by crew status (ON BOARD first), then by rank sequence, then by lastname.
    ''' </summary>
    Private Function GetVesselCrewDataTable(vesselId As Integer) As DataTable
        Dim sql As String =
            "SELECT " &
            "  pi.id, " &
            "  pi.lastname, pi.firstname, pi.middlename, pi.gender, " &
            "  pi.crew_status, pi.crew_availability, " &
            "  pi.picture_id, " &
            "  pi.status_date, " &
            "  r.rank_code, r.rank_type, r.sequence AS rank_seq, " &
            "  ds.meaning AS crew_status_text, " &
            "  pr.provinces AS province_name, " &
            "  ct.cities AS city_name, " &
            "  ROUND( " &
            "    (SELECT SUM(DATEDIFF(IFNULL(pss.date_to, CURDATE()), pss.date_from)) / 365.25 " &
            "     FROM tbl_personnel_sea_service pss WHERE pss.personnel_id = pi.id), 1 " &
            "  ) AS total_sea_service " &
            "FROM tbl_personnel_info pi " &
            "LEFT JOIN tbl_rank r ON r.id = pi.position " &
            "LEFT JOIN tbl_dropdown_selection ds " &
            "       ON ds.type = 'crew_status' AND ds.sequence = pi.crew_status " &
            "LEFT JOIN tbl_provinces pr ON pr.id = pi.province " &
            "LEFT JOIN tbl_cities ct    ON ct.id = pi.city " &
            "WHERE pi.assigned_vessel_id = @vid " &
            "  AND pi.crew_status IN (3, 4, 6) " &
            "ORDER BY " &
            "  FIELD(pi.crew_status, 3, 6, 4), " &
            "  r.sequence, pi.lastname"

        Return DbHelper.FillDataTable(sql, CommandType.Text, New MySqlParameter("@vid", vesselId))
    End Function

    ' ════════════════════════════════════════════════════════
    ' BIND GRID & PAGINATION
    ' ════════════════════════════════════════════════════════

    Private Sub BindGrid()
        Dim vid As Integer = 0
        If ViewState("VesselID") IsNot Nothing Then vid = CInt(ViewState("VesselID"))
        If vid = 0 Then Return

        Dim fullDt As DataTable = GetVesselCrewDataTable(vid)
        Dim totalCount As Integer = fullDt.Rows.Count

        ' ── Summary counts ──
        Dim cntOnboard  As Integer = 0
        Dim cntLineup   As Integer = 0
        Dim cntVacation As Integer = 0
        For Each row As DataRow In fullDt.Rows
            Dim s As Integer = If(IsDBNull(row("crew_status")), 0, CInt(row("crew_status")))
            Select Case s
                Case 3 : cntOnboard  += 1
                Case 6 : cntLineup   += 1
                Case 4 : cntVacation += 1
            End Select
        Next
        lblCntOnboard.Text  = cntOnboard.ToString()
        lblCntLineup.Text   = cntLineup.ToString()
        lblCntVacation.Text = cntVacation.ToString()
        lblCntTotal.Text    = totalCount.ToString()

        ' ── Pagination ──
        Dim totalPages As Integer = Math.Max(1, CInt(Math.Ceiling(totalCount / PageSize)))
        Dim pg As Integer = Math.Max(0, Math.Min(CurrentPage, totalPages - 1))
        CurrentPage = pg

        Dim startRow As Integer = pg * PageSize
        Dim pageDt As DataTable = fullDt.Clone()
        Dim endRow  As Integer = Math.Min(startRow + PageSize, totalCount)
        For i As Integer = startRow To endRow - 1
            pageDt.ImportRow(fullDt.Rows(i))
        Next

        gvVesselCrew.DataSource = pageDt
        gvVesselCrew.DataBind()

        ViewState("sch_TotalPages") = totalPages
        BuildPager(pg, totalPages)
    End Sub

    ' ════════════════════════════════════════════════════════
    ' ROW DATA BOUND
    ' ════════════════════════════════════════════════════════

    Protected Sub gvVesselCrew_RowDataBound(sender As Object, e As GridViewRowEventArgs)
        If e.Row.RowType <> DataControlRowType.DataRow Then Return
        Dim drv As DataRowView = CType(e.Row.DataItem, DataRowView)

        ' ── Photo ──
        Dim imgPhoto As Image = CType(e.Row.FindControl("imgPhoto"), Image)
        If imgPhoto IsNot Nothing Then
            If Not IsDBNull(drv("picture_id")) AndAlso drv("picture_id").ToString() <> "" Then
                imgPhoto.ImageUrl = "~/Uploads/picture/" & drv("picture_id").ToString()
            Else
                Dim gender As String = If(drv.Row.Table.Columns.Contains("gender") AndAlso Not IsDBNull(drv("gender")),
                                          drv("gender").ToString(), "")
                imgPhoto.ImageUrl = If(gender = "Female", "~/images/silhouette_female.png", "~/images/silhouette_user.png")
            End If
            Dim crewStatus As Integer = If(IsDBNull(drv("crew_status")), 0, CInt(drv("crew_status")))
            Select Case crewStatus
                Case 3 : imgPhoto.CssClass = "crew-photo-vc status-onboard"
                Case 6 : imgPhoto.CssClass = "crew-photo-vc status-lineup"
                Case 4 : imgPhoto.CssClass = "crew-photo-vc status-vacation"
                Case Else : imgPhoto.CssClass = "crew-photo-vc"
            End Select
        End If

        ' ── Status Date with elapsed-time color ──
        Dim lblStatusDate As Label = CType(e.Row.FindControl("lblStatusDate"), Label)
        If lblStatusDate IsNot Nothing AndAlso drv.Row.Table.Columns.Contains("status_date") Then
            If Not IsDBNull(drv("status_date")) Then
                Dim sd As Date = CDate(drv("status_date"))
                lblStatusDate.Text = sd.ToString("MM/dd/yyyy")
                Dim crewStat As Integer = If(IsDBNull(drv("crew_status")), 0, CInt(drv("crew_status")))
                Dim elapsed As Integer = (DateTime.Now.Year - sd.Year) * 12 + DateTime.Now.Month - sd.Month
                If crewStat = 1 OrElse crewStat = 4 OrElse crewStat = 2 Then
                    If elapsed > 8 Then
                        lblStatusDate.CssClass = "status-date-red-vc"
                    ElseIf elapsed >= 4 Then
                        lblStatusDate.CssClass = "status-date-amber-vc"
                    End If
                End If
            End If
        End If

        ' ── Sea Service ──
        Dim lblSS As Label = CType(e.Row.FindControl("lblSeaService"), Label)
        If lblSS IsNot Nothing AndAlso drv.Row.Table.Columns.Contains("total_sea_service") Then
            lblSS.Text = If(IsDBNull(drv("total_sea_service")), "0 yr(s)",
                             drv("total_sea_service").ToString() & " yr(s)")
        End If

        ' ── Province / City ──
        Dim lblPC As Label = CType(e.Row.FindControl("lblProvCity"), Label)
        If lblPC IsNot Nothing Then
            Dim prov As String = If(drv.Row.Table.Columns.Contains("province_name") AndAlso Not IsDBNull(drv("province_name")),
                                     drv("province_name").ToString(), "")
            Dim city As String = If(drv.Row.Table.Columns.Contains("city_name") AndAlso Not IsDBNull(drv("city_name")),
                                     drv("city_name").ToString(), "")
            Dim parts() As String = New String() {city, prov}
            Dim filtered As IEnumerable(Of String) = parts.Where(Function(x) x <> "")
            Dim loc As String = String.Join(", ", filtered)
            lblPC.Text = Server.HtmlEncode(If(loc = "", "-", loc))
        End If
    End Sub

    ' ════════════════════════════════════════════════════════
    ' PAGER
    ' ════════════════════════════════════════════════════════

    Private Sub BuildPager(currentPg As Integer, totalPages As Integer)
        phPager.Controls.Clear()
        divPager.Visible = (totalPages > 1)
        If totalPages <= 1 Then Return

        Dim goScript As String = String.Format(
            "document.getElementById('{0}').value='{{0}}';document.getElementById('{1}').click();return false;",
            hfTargetPage.ClientID, btnGoPager.ClientID)

        ' Previous
        Dim btnPrev As New System.Web.UI.HtmlControls.HtmlButton()
        btnPrev.Attributes("type") = "button"
        btnPrev.InnerHtml = "&lsaquo;"
        btnPrev.Attributes("class") = "pg-btn" & If(currentPg = 0, " pg-disabled", "")
        If currentPg > 0 Then
            btnPrev.Attributes("onclick") = String.Format(goScript, currentPg - 1)
        Else
            btnPrev.Disabled = True
        End If
        phPager.Controls.Add(btnPrev)

        ' Pages
        Dim windowSize As Integer = 1
        Dim pages As New List(Of Integer)
        pages.Add(0)
        pages.Add(totalPages - 1)
        For p As Integer = Math.Max(0, currentPg - windowSize) To Math.Min(totalPages - 1, currentPg + windowSize)
            If Not pages.Contains(p) Then pages.Add(p)
        Next
        pages.Sort()

        Dim lastRendered As Integer = -1
        For Each p As Integer In pages
            If lastRendered >= 0 AndAlso p > lastRendered + 1 Then
                Dim ellipsis As New System.Web.UI.HtmlControls.HtmlGenericControl("span")
                ellipsis.Attributes("class") = "pg-ellipsis"
                ellipsis.InnerText = "..."
                phPager.Controls.Add(ellipsis)
            End If
            Dim isActive As Boolean = (p = currentPg)
            Dim btnPage As New System.Web.UI.HtmlControls.HtmlButton()
            btnPage.Attributes("type") = "button"
            btnPage.InnerText = (p + 1).ToString()
            btnPage.Attributes("class") = "pg-btn" & If(isActive, " pg-active", "")
            If isActive Then
                btnPage.Disabled = True
            Else
                btnPage.Attributes("onclick") = String.Format(goScript, p)
            End If
            phPager.Controls.Add(btnPage)
            lastRendered = p
        Next

        ' Next
        Dim btnNext As New System.Web.UI.HtmlControls.HtmlButton()
        btnNext.Attributes("type") = "button"
        btnNext.InnerHtml = "&rsaquo;"
        btnNext.Attributes("class") = "pg-btn" & If(currentPg >= totalPages - 1, " pg-disabled", "")
        If currentPg < totalPages - 1 Then
            btnNext.Attributes("onclick") = String.Format(goScript, currentPg + 1)
        Else
            btnNext.Disabled = True
        End If
        phPager.Controls.Add(btnNext)
    End Sub

    Protected Sub GoToPage_Click(sender As Object, e As EventArgs)
        Dim targetPage As Integer = 0
        If Integer.TryParse(hfTargetPage.Value, targetPage) Then
            CurrentPage = targetPage
            BindGrid()
        End If
    End Sub

    ' ════════════════════════════════════════════════════════
    ' HELPER
    ' ════════════════════════════════════════════════════════

    Public Function GetProfileUrl(id As Object) As String
        Dim encID   As String = HttpUtility.UrlEncode(Encrypt(id.ToString()))
        Dim encType As String = HttpUtility.UrlEncode(Encrypt("Viewer"))
        Return "~/Crew/ProfileViewer.aspx?ID=" & encID & "&Type=" & encType
    End Function

End Class
