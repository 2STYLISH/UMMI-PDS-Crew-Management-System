Imports MySql.Data.MySqlClient
Imports System.Data

Public Class ApplicantPool
    Inherits System.Web.UI.Page
    Private Property CurrentPage() As Integer
        Get
            If ViewState("_CurPage") IsNot Nothing Then Return CInt(ViewState("_CurPage"))
            Return 0
        End Get
        Set(value As Integer)
            ViewState("_CurPage") = value
        End Set
    End Property


    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        RequireLogin()
        RequireRole(ROLE_MANNING_STAFF, ROLE_DOCUMENTATION_OFFICER, ROLE_SUPER_ADMIN, ROLE_ADMIN)

        If Not IsPostBack Then
            CType(Master, masterPage).lblPageTitle.Text = "Applicant Pool"
            GetAdmin("Visited", CurrentUserID().ToString(), "ApplicantPool", "Applicant Pool")
            LoadRankType()
            LoadRanks("")
            LoadLinkRanks()
            LoadVesselExpTypes()
            ' UC-CM-16: Default validity to next day (FR-CM-39)
            txtLinkValidity.Text = DateTime.Now.AddDays(1).ToString("yyyy-MM-dd")
            SearchApplicants(Nothing, Nothing)
            LoadLinks()
        End If
    End Sub

    ' ──────────────── Dropdown Loaders ───────────────────────────
    Private Sub LoadRankType()
        drpdwnRankType.Items.Clear()
        drpdwnRankType.Items.Add(New System.Web.UI.WebControls.ListItem("ALL", ""))
        Dim sql As String = "SELECT rank_type FROM tbl_rank GROUP BY rank_type ORDER BY MIN(sequence)"
        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text)
        For Each row As DataRow In dt.Rows
            drpdwnRankType.Items.Add(row("rank_type").ToString())
        Next
    End Sub

    Private Sub LoadRanks(rankType As String)
        drpdwnRank.Items.Clear()
        drpdwnRank.Items.Add(New System.Web.UI.WebControls.ListItem("ALL", ""))
        Dim sql As String = "SELECT id, rank_code FROM tbl_rank "
        If rankType <> "" AndAlso rankType <> "ALL" Then sql &= "WHERE rank_type=@rt "
        sql &= "ORDER BY sequence"
        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                If rankType <> "" AndAlso rankType <> "ALL" Then
                    cmd.Parameters.AddWithValue("@rt", rankType)
                End If
                Using dr As MySqlDataReader = cmd.ExecuteReader()
                    Do While dr.Read()
                        drpdwnRank.Items.Add(New System.Web.UI.WebControls.ListItem(dr("rank_code").ToString(), dr("id").ToString()))
                    Loop
                End Using
            End Using
        End Using
    End Sub

    Private Sub LoadLinkRanks()
        drpdwnLinkRank.Items.Clear()
        drpdwnLinkRank.Items.Add(New System.Web.UI.WebControls.ListItem("(Not specified)", ""))
        Dim sql As String = "SELECT rank_code FROM tbl_rank ORDER BY rank_type,sequence"
        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text)
        For Each row As DataRow In dt.Rows
            drpdwnLinkRank.Items.Add(row("rank_code").ToString())
        Next
    End Sub

    ' UC-CM-13: Vessel Experience Type filter (FR-CM-33)
    Private Sub LoadVesselExpTypes()
        drpdwnVesselExpType.Items.Clear()
        drpdwnVesselExpType.Items.Add(New System.Web.UI.WebControls.ListItem("ALL", ""))
        Dim sql As String = "SELECT id, typeOfVessel FROM tbl_type_of_vessel ORDER BY typeOfVessel"
        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text)
        For Each row As DataRow In dt.Rows
            drpdwnVesselExpType.Items.Add(New System.Web.UI.WebControls.ListItem(
                row("typeOfVessel").ToString(), row("id").ToString()))
        Next
    End Sub

    Protected Sub RankTypeChanged(sender As Object, e As EventArgs)
        LoadRanks(drpdwnRankType.SelectedValue)
    End Sub

    ' ──────────────── UC-CM-13/14: Search Applicants ─────────────
    Protected Sub SearchApplicants(sender As Object, e As EventArgs)
        Dim rankID As Object = If(drpdwnRank.SelectedValue = "", DBNull.Value, CObj(drpdwnRank.SelectedValue))
        Dim dateFrom As Object = DBNull.Value
        Dim dateTo   As Object = DBNull.Value
        If IsDate(txtDateFrom.Text) Then dateFrom = CDate(txtDateFrom.Text).Date
        If IsDate(txtDateTo.Text)   Then dateTo   = CDate(txtDateTo.Text).Date.AddDays(1)

        ' Persist the submitted criteria so pagination can replay them
        ViewState("sch_LastName") = txtLastName.Text.Trim()
        ViewState("sch_FirstName") = txtFirstName.Text.Trim()
        ViewState("sch_RankID") = rankID
        ViewState("sch_RankType") = drpdwnRankType.SelectedValue
        ViewState("sch_VesselExpID") = If(drpdwnVesselExpType.SelectedValue = "", DBNull.Value, CObj(drpdwnVesselExpType.SelectedValue))
        ViewState("sch_DateFrom") = dateFrom
        ViewState("sch_DateTo") = dateTo

        GetAdmin("Searched Applicants", CurrentUserID().ToString(), "ApplicantPool", txtLastName.Text & " " & txtFirstName.Text)

        ' Reset to page 0 on a new search
        CurrentPage = 0
        BindApplicantGrid()
    End Sub

    Private Sub BindApplicantGrid()
        Dim lastNameVal As String = If(ViewState("sch_LastName") IsNot Nothing, ViewState("sch_LastName").ToString(), "")
        Dim firstNameVal As String = If(ViewState("sch_FirstName") IsNot Nothing, ViewState("sch_FirstName").ToString(), "")
        Dim rankID As Object = If(ViewState("sch_RankID") IsNot Nothing, ViewState("sch_RankID"), DBNull.Value)
        Dim rankType As String = If(ViewState("sch_RankType") IsNot Nothing, ViewState("sch_RankType").ToString(), "")
        Dim vslexpID As Object = If(ViewState("sch_VesselExpID") IsNot Nothing, ViewState("sch_VesselExpID"), DBNull.Value)
        Dim dateFrom As Object = If(ViewState("sch_DateFrom") IsNot Nothing, ViewState("sch_DateFrom"), DBNull.Value)
        Dim dateTo As Object = If(ViewState("sch_DateTo") IsNot Nothing, ViewState("sch_DateTo"), DBNull.Value)

        Dim offset As Integer = CurrentPage * 20
        Dim limit As Integer = 20

        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand("spApplicantPoolSearchDisplay", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@lastname_", lastNameVal)
                cmd.Parameters.AddWithValue("@firstname_", firstNameVal)
                cmd.Parameters.AddWithValue("@rank_", rankID)
                cmd.Parameters.AddWithValue("@ranktype_", rankType)
                cmd.Parameters.AddWithValue("@vslexpID_", vslexpID)
                cmd.Parameters.AddWithValue("@datefrom_", dateFrom)
                cmd.Parameters.AddWithValue("@dateto_", dateTo)
                cmd.Parameters.AddWithValue("@offset_", offset)
                cmd.Parameters.AddWithValue("@limit_", limit)

                Dim ds As New DataSet()
                Using da As New MySqlDataAdapter(cmd)
                    da.Fill(ds)
                End Using

                If ds.Tables.Count > 0 Then
                    Dim dtRows As DataTable = ds.Tables(0)
                    gvApplicants.DataSource = dtRows

                    ' Summary data is in the second table
                    If ds.Tables.Count > 1 AndAlso ds.Tables(1).Rows.Count > 0 Then
                        Dim dtAgg As DataTable = ds.Tables(1)
                        Dim totalCount As Integer = Convert.ToInt32(If(IsDBNull(dtAgg.Rows(0)("TotalCount")), 0, dtAgg.Rows(0)("TotalCount")))
                        Dim totalAge As Integer = Convert.ToInt32(If(IsDBNull(dtAgg.Rows(0)("TotalAge")), 0, dtAgg.Rows(0)("TotalAge")))

                        lblCount.Text = totalCount.ToString()
                        lblAvgAge.Text = If(totalCount > 0, Math.Round(CDbl(totalAge) / totalCount, 0).ToString(), "0")
                        divSummary.Visible = True

                                            If totalCount > 0 Then
                        Dim totalPages As Integer = Math.Max(1, CInt(Math.Ceiling(totalCount / 20.0)))
                        BuildPager(CurrentPage, totalPages)
                    Else
                        BuildPager(0, 0)
                    End If
                    End If

                    gvApplicants.DataBind()
                End If
            End Using
        End Using
    End Sub

    Protected Sub ResetFilters(sender As Object, e As EventArgs)
        txtLastName.Text = "" : txtFirstName.Text = "" : txtDateFrom.Text = "" : txtDateTo.Text = ""
        drpdwnRankType.SelectedIndex = 0 : drpdwnRank.SelectedIndex = 0
        drpdwnVesselExpType.SelectedIndex = 0
        SearchApplicants(Nothing, Nothing)
    End Sub

    ' UC-CM-13: RowDataBound — avatar + vessel experience popover (FR-CM-34)
    Protected Sub GvApplicants_RowDataBound(sender As Object, e As System.Web.UI.WebControls.GridViewRowEventArgs)
        If e.Row.RowType <> System.Web.UI.WebControls.DataControlRowType.DataRow Then Return
        Dim dr As System.Data.DataRowView = CType(e.Row.DataItem, System.Data.DataRowView)

        ' Avatar
        Dim img As System.Web.UI.WebControls.Image = CType(e.Row.FindControl("imgAvatar"), System.Web.UI.WebControls.Image)
        If img IsNot Nothing AndAlso Not IsDBNull(dr("picture_id")) AndAlso dr("picture_id").ToString() <> "" Then
            img.ImageUrl = "~/Uploads/picture/" & dr("picture_id").ToString()
        End If

        ' Vessel Experience with popover (FR-CM-34)
        Dim lblVE As System.Web.UI.WebControls.Label = CType(e.Row.FindControl("lblVesselExp"), System.Web.UI.WebControls.Label)
        If lblVE IsNot Nothing Then
            Dim pid As String = dr("id").ToString()
            Dim sql As String = "SELECT GROUP_CONCAT(DISTINCT CONCAT(t.typeOfVessel,' (',v.vesselName,')') ORDER BY t.typeOfVessel SEPARATOR ', ') AS types " &
                                "FROM tbl_personnel_sea_service pss " &
                                "JOIN tbl_vessels v ON v.id=pss.vessel_id " &
                                "JOIN tbl_type_of_vessel t ON t.id=v.VesselType " &
                                "WHERE pss.personnel_id=@pid"
            Dim result As Object = DbHelper.ExecuteScalar(sql, New MySqlParameter("@pid", pid))
            Dim expText As String = If(result Is DBNull.Value OrElse result Is Nothing, "None", result.ToString())
            ' Truncate for display, full text in tooltip
            If expText.Length > 30 Then
                lblVE.Text = Server.HtmlEncode(expText.Substring(0, 27)) & "..."
                lblVE.ToolTip = expText
            Else
                lblVE.Text = Server.HtmlEncode(expText)
            End If
        End If
    End Sub

    ' ──────────────── UC-CM-23: Hire Applicant ────────────────────
    Protected Sub GvApplicants_RowCommand(sender As Object, e As System.Web.UI.WebControls.GridViewCommandEventArgs)
        If e.CommandName = "HireApplicant" Then
            Dim pid As String = e.CommandArgument.ToString()
            Dim sql As String = "UPDATE tbl_personnel_info SET crew_status=1 WHERE id=@id"
            DbHelper.ExecuteNonQuery(sql, New MySqlParameter("@id", pid))
            GetPortalAct("Hired Applicant", CurrentUserID().ToString(), "ApplicantPool", "Changed status to Active", pid)
            lblNotify.Text = "<div class='alert alert-success'><i class='fa fa-circle-check me-2'></i>Applicant hired successfully. Crew status changed to Active.</div>"
            BindApplicantGrid()
        End If
    End Sub

    ' ──────────────── UC-CM-15: Add Applicant Manually (FR-CM-36) ──
    Protected Sub AddApplicantManually(sender As Object, e As EventArgs)
        Response.Redirect("~/Applicant/SelfEncode.aspx?mode=add")
    End Sub

    ' ──────────────── UC-CM-16: Generate Link Panel ────────────────
    Protected Sub ShowGenerateLink(sender As Object, e As EventArgs)
        panelGenerateLink.Visible = True
        panelManageLinks.Visible  = False
    End Sub
    Protected Sub HideGenerateLink(sender As Object, e As EventArgs)
        panelGenerateLink.Visible = False
        panelLinkResult.Visible   = False
    End Sub
    Protected Sub ShowManageLinks(sender As Object, e As EventArgs)
        panelManageLinks.Visible = True
        panelGenerateLink.Visible = False
        LoadLinks()
    End Sub
    Protected Sub HideManageLinks(sender As Object, e As EventArgs)
        panelManageLinks.Visible = False
    End Sub

    ' UC-CM-16: Generate Link (FR-CM-38/39/40)
    Protected Sub GenerateLink(sender As Object, e As EventArgs)
        ' FR-CM-38: Validation
        If String.IsNullOrEmpty(txtLinkFirstName.Text.Trim()) Then
            lblNotify.Text = "<div class='alert alert-danger'>First name is required.</div>"
            Return
        End If
        If String.IsNullOrEmpty(txtLinkLastName.Text.Trim()) Then
            lblNotify.Text = "<div class='alert alert-danger'>Last name is required.</div>"
            Return
        End If
        If String.IsNullOrEmpty(txtLinkEmail.Text.Trim()) Then
            lblNotify.Text = "<div class='alert alert-danger'>Email is required.</div>"
            Return
        End If

        ' FR-CM-40: Validity date is mandatory (TC-CM-140 fix)
        If String.IsNullOrEmpty(txtLinkValidity.Text.Trim()) Then
            lblNotify.Text = "<div class='alert alert-danger'>Link validity date is required.</div>"
            Return
        End If

        ' FR-CM-40: Valid calendar date validation
        Dim validity As DateTime = DateTime.Now.AddDays(1)
        If Not IsDate(txtLinkValidity.Text) Then
            lblNotify.Text = "<div class='alert alert-danger'>Please enter a valid calendar date for link validity.</div>"
            Return
        End If
        validity = CDate(txtLinkValidity.Text).Date.AddHours(23).AddMinutes(59)

        Dim fullName As String = (txtLinkFirstName.Text.Trim() & " " & txtLinkLastName.Text.Trim()).Trim()

        ' DB Insert
        Dim sqlInsert As String = "INSERT INTO tbl_applicant_generated_link " &
            "(fullname, email, position_applied, validity, status, date_generated, generated_by) " &
            "VALUES (@fn, @em, @pos, @val, 'Active', NOW(), @uid); SELECT LAST_INSERT_ID();"

        Dim newID As Object = DbHelper.ExecuteScalar(sqlInsert,
            New MySqlParameter("@fn",  fullName),
            New MySqlParameter("@em",  txtLinkEmail.Text.Trim()),
            New MySqlParameter("@pos", drpdwnLinkRank.SelectedValue),
            New MySqlParameter("@val", validity),
            New MySqlParameter("@uid", CurrentUserID()))

        If newID Is Nothing OrElse IsDBNull(newID) Then
            lblNotify.Text = "<div class='alert alert-danger'>Error creating link. Please try again.</div>"
            Return
        End If

        ' Encrypted URL Construction with distinct first and last names
        Dim linkID As String = newID.ToString()
        Dim encryptedParams As String = Encrypt("linkid=" & linkID &
            "&fn=" & HttpUtility.UrlEncode(txtLinkFirstName.Text.Trim()) &
            "&ln=" & HttpUtility.UrlEncode(txtLinkLastName.Text.Trim()))
        ' TC-CM-187 FIX: use Request.Url.Scheme to support HTTPS environments
        Dim appUrl As String = Request.Url.Scheme & "://" & Request.Url.Host
        If Request.Url.Port <> 80 AndAlso Request.Url.Port <> 443 Then
            appUrl &= ":" & Request.Url.Port.ToString()
        End If
        Dim appPath As String = Request.ApplicationPath.TrimEnd("/"c)
        Dim fullLink As String = appUrl & appPath & "/login.aspx?e=" & HttpUtility.UrlEncode(encryptedParams)

        ' Update link_token in DB
        DbHelper.ExecuteNonQuery("UPDATE tbl_applicant_generated_link SET link_token=@tok WHERE id=@id",
            New MySqlParameter("@tok", fullLink),
            New MySqlParameter("@id", linkID))

        GetAdmin("Generated Applicant Link", CurrentUserID().ToString(), "ApplicantPool",
            fullName & " | " & txtLinkEmail.Text.Trim())

        ' Display
        txtGeneratedLink.Value = fullLink
        lblGeneratedExpiry.Text = validity.ToString("MMMM dd, yyyy HH:mm")
        panelLinkResult.Visible = True

        ' Store for resend / email
        ViewState("LastGeneratedLink") = fullLink
        ViewState("LastGeneratedEmail") = txtLinkEmail.Text.Trim()
        ViewState("LastGeneratedName") = fullName
        ViewState("LastGeneratedExpiry") = validity.ToString("MMMM dd, yyyy HH:mm")
        ViewState("LastGeneratedLinkID") = linkID
    End Sub

    ' ──────────────── UC-CM-17: Send Link via Email (FR-CM-41) ──
    Protected Sub SendLinkEmail(sender As Object, e As EventArgs)
        Dim email As String = If(ViewState("LastGeneratedEmail") IsNot Nothing, ViewState("LastGeneratedEmail").ToString(), txtLinkEmail.Text.Trim())
        Dim name As String = If(ViewState("LastGeneratedName") IsNot Nothing, ViewState("LastGeneratedName").ToString(), "")
        Dim link As String = If(ViewState("LastGeneratedLink") IsNot Nothing, ViewState("LastGeneratedLink").ToString(), txtGeneratedLink.Value)
        Dim linkId As Integer = 0
        If ViewState("LastGeneratedLinkID") IsNot Nothing Then Integer.TryParse(ViewState("LastGeneratedLinkID").ToString(), linkId)

        Dim expiryLine As String = If(ViewState("LastGeneratedExpiry") IsNot Nothing,
            "Link valid until: " & ViewState("LastGeneratedExpiry").ToString() & vbCrLf & vbCrLf, "")
        Dim body As String = EmailHelper.BuildApplicantLinkEmailBody(name, link, expiryLine)
        Dim sendResult As EmailHelper.EmailResult = EmailHelper.SendMail(email, "UMMI Manning - Application Encoding Link", body)

        If linkId > 0 Then EmailHelper.RecordApplicantLinkEmail(linkId, sendResult)

        If sendResult.Success Then
            lblNotify.Text = "<div class='alert alert-success'><i class='fa fa-circle-check me-2'></i>Encoding link emailed to " & Server.HtmlEncode(email) & ".</div>"
            GetAdmin("Sent applicant link email", CurrentUserID().ToString(), "ApplicantPool", name & " | " & email)
        Else
            lblNotify.Text = "<div class='alert alert-danger'><i class='fa fa-circle-xmark me-2'></i>" & Server.HtmlEncode(sendResult.ErrorMessage) & "</div>"
            GetAdmin("Applicant link email failed", CurrentUserID().ToString(), "ApplicantPool", sendResult.ErrorMessage)
        End If
    End Sub

    ' ──────────────── UC-CM-18: Load Links (FR-CM-42/43) ──────────
    Private Sub LoadLinks()
        Dim statusFilter As String = drpdwnLinkStatusFilter.SelectedValue
        Dim sql As String = "SELECT agl.id, agl.fullname, agl.email, agl.position_applied, " &
                            "agl.date_generated, agl.validity, agl.last_date_access, agl.status, agl.link_token, " &
                            "agl.email_status, agl.email_sent_at, agl.email_error, " &
                            "IFNULL(u.fullname,'System') AS generated_by_name " &
                            "FROM tbl_applicant_generated_link agl " &
                            "LEFT JOIN tbl_users u ON u.id=agl.generated_by "
        If statusFilter <> "" Then sql &= "WHERE agl.status=@st "
        sql &= "ORDER BY agl.date_generated DESC LIMIT 50"

        Dim dt As DataTable
        If statusFilter <> "" Then
            dt = DbHelper.FillDataTable(sql, CommandType.Text, New MySqlParameter("@st", statusFilter))
        Else
            dt = DbHelper.FillDataTable(sql, CommandType.Text)
        End If
        gvLinks.DataSource = dt
        gvLinks.DataBind()
    End Sub

    Protected Sub FilterLinksChanged(sender As Object, e As EventArgs)
        LoadLinks()
    End Sub

    ' UC-CM-18: Row styling (FR-CM-43: expired validity highlighting)
    Protected Sub GvLinks_RowDataBound(sender As Object, e As System.Web.UI.WebControls.GridViewRowEventArgs)
        If e.Row.RowType <> System.Web.UI.WebControls.DataControlRowType.DataRow Then Return
        Dim drv As System.Data.DataRowView = CType(e.Row.DataItem, System.Data.DataRowView)
        Dim status As String = drv("status").ToString()
        Dim lbl As System.Web.UI.WebControls.Label = CType(e.Row.FindControl("lblLinkStatus"), System.Web.UI.WebControls.Label)
        If lbl Is Nothing Then Return
        Select Case status
            Case "Active"  : lbl.Text = "<span class='badge-active'>Active</span>"
            Case "Expired" : lbl.Text = "<span class='badge-expired'>Expired</span>"
                             e.Row.BackColor = Drawing.ColorTranslator.FromHtml("#FFF5F5")
            Case Else      : lbl.Text = "<span class='badge-used'>" & status & "</span>"
        End Select

        Dim lblEmail As System.Web.UI.WebControls.Label = CType(e.Row.FindControl("lblEmailDelivery"), System.Web.UI.WebControls.Label)
        If lblEmail IsNot Nothing AndAlso drv.DataView.Table.Columns.Contains("email_status") Then
            Dim es As String = If(IsDBNull(drv("email_status")), "", drv("email_status").ToString())
            Select Case es
                Case "Sent" : lblEmail.Text = "<span class='badge-active'>Sent</span>"
                Case "Failed" : lblEmail.Text = "<span class='badge-expired'>Failed</span>"
                Case Else : lblEmail.Text = If(String.IsNullOrEmpty(es), "<span class='text-muted'>—</span>", Server.HtmlEncode(es))
            End Select
        End If

        ' FR-CM-43: Highlight expired validity for Active links
        If status = "Active" AndAlso Not IsDBNull(drv("validity")) Then
            Dim validity As DateTime = Convert.ToDateTime(drv("validity"))
            If validity < DateTime.Now Then
                e.Row.Cells(4).BackColor = Drawing.Color.FromArgb(254, 226, 226) ' Light red
                e.Row.Cells(4).ForeColor = Drawing.Color.FromArgb(153, 27, 27)   ' Dark red
            End If
        End If
    End Sub

    ' ──────────────── UC-CM-19: Update Link Status (FR-CM-44) ─────
    Protected Sub GvLinks_RowCommand(sender As Object, e As System.Web.UI.WebControls.GridViewCommandEventArgs)
        Select Case e.CommandName
            Case "UpdateStatus"
                Dim linkID As String = e.CommandArgument.ToString()
                Dim row As System.Web.UI.WebControls.GridViewRow = CType(CType(e.CommandSource, System.Web.UI.WebControls.LinkButton).NamingContainer, System.Web.UI.WebControls.GridViewRow)
                Dim ddl As System.Web.UI.WebControls.DropDownList = CType(row.FindControl("drpdwnNewStatus"), System.Web.UI.WebControls.DropDownList)
                If ddl IsNot Nothing AndAlso ddl.SelectedValue <> "" Then
                    DbHelper.ExecuteNonQuery("UPDATE tbl_applicant_generated_link SET status=@st WHERE id=@id",
                        New MySqlParameter("@st", ddl.SelectedValue),
                        New MySqlParameter("@id", linkID))
                    GetAdmin("Updated Link Status to " & ddl.SelectedValue, CurrentUserID().ToString(), "ApplicantPool", "LinkID=" & linkID)
                    lblNotify.Text = "<div class='alert alert-success'><i class='fa fa-circle-check me-2'></i>Link status updated.</div>"
                    LoadLinks()
                End If

            Case "ResendLink"
                Dim linkID2 As String = e.CommandArgument.ToString()
                Dim linkData As DataTable = DbHelper.FillDataTable(
                    "SELECT link_token, fullname, email, validity FROM tbl_applicant_generated_link WHERE id=@id",
                    CommandType.Text, New MySqlParameter("@id", linkID2))
                If linkData.Rows.Count > 0 Then
                    Dim token As String = linkData.Rows(0)("link_token").ToString()
                    Dim name As String = linkData.Rows(0)("fullname").ToString()
                    Dim email As String = linkData.Rows(0)("email").ToString()
                    Dim validityStr As String = ""
                    If Not IsDBNull(linkData.Rows(0)("validity")) Then
                        validityStr = "Link valid until: " & Convert.ToDateTime(linkData.Rows(0)("validity")).ToString("MMMM dd, yyyy HH:mm") & vbCrLf & vbCrLf
                    End If
                    Dim body As String = EmailHelper.BuildApplicantLinkEmailBody(name, token, validityStr)
                    Dim sendResult As EmailHelper.EmailResult = EmailHelper.SendMail(email, "UMMI Manning - Application Encoding Link (Resent)", body)
                    EmailHelper.RecordApplicantLinkEmail(CInt(linkID2), sendResult)
                    If sendResult.Success Then
                        lblNotify.Text = "<div class='alert alert-success'>Link resent via email.</div>"
                        GetAdmin("Resent applicant link email", CurrentUserID().ToString(), "ApplicantPool", name & " | " & email)
                    Else
                        lblNotify.Text = "<div class='alert alert-danger'>" & Server.HtmlEncode(sendResult.ErrorMessage) & "</div>"
                    End If
                    LoadLinks()
                End If

            Case "DeleteLink"
                ' UC-CM-21: Delete (FR-CM-46) — only non-Active
                Dim linkID3 As String = e.CommandArgument.ToString()
                DbHelper.ExecuteNonQuery("DELETE FROM tbl_applicant_generated_link WHERE id=@id AND status<>'Active'",
                    New MySqlParameter("@id", linkID3))
                GetAdmin("Deleted Link", CurrentUserID().ToString(), "ApplicantPool", "LinkID=" & linkID3)
                lblNotify.Text = "<div class='alert alert-success'><i class='fa fa-circle-check me-2'></i>Link record deleted.</div>"
                LoadLinks()

            Case "ExpireLink"
                ' Legacy: single expire
                Dim linkID4 As String = e.CommandArgument.ToString()
                DbHelper.ExecuteNonQuery("UPDATE tbl_applicant_generated_link SET status='Expired' WHERE id=@id",
                    New MySqlParameter("@id", linkID4))
                GetAdmin("Expired Link", CurrentUserID().ToString(), "ApplicantPool", "LinkID=" & linkID4)
                LoadLinks()
        End Select
    End Sub

    ' ──────────────── UC-CM-20: Move Expired Links (FR-CM-45) ─────
    Protected Sub MoveExpiredLinks(sender As Object, e As EventArgs)
        Dim affected As Integer = DbHelper.ExecuteNonQuery(
            "UPDATE tbl_applicant_generated_link SET status='Expired' " &
            "WHERE status='Active' AND validity IS NOT NULL AND validity < NOW()")
        GetAdmin("Bulk Expired Links", CurrentUserID().ToString(), "ApplicantPool",
            affected.ToString() & " links expired")
        lblNotify.Text = "<div class='alert alert-success'><i class='fa fa-circle-check me-2'></i>" &
            affected.ToString() & " link(s) moved to Expired status.</div>"
        LoadLinks()
    End Sub

    ' ──────────────── Helpers ────────────────────────────────────
    Public Function GetProfileUrl(id As Object) As String
        Dim encID As String = HttpUtility.UrlEncode(Encrypt(id.ToString()))
        Dim encType As String = HttpUtility.UrlEncode(Encrypt("Viewer"))
        Return "~/Crew/ProfileViewer.aspx?ID=" & encID & "&Type=" & encType
    End Function

    Protected Sub GoToPage_Click(sender As Object, e As EventArgs)
        Dim targetPage As Integer = 0
        If Integer.TryParse(hfTargetPage.Value, targetPage) Then
            CurrentPage = targetPage
            BindApplicantGrid()
        End If
    End Sub

    Private Sub BuildPager(currentPg As Integer, totalPages As Integer)
        phPager.Controls.Clear()
        divPager.Visible = (totalPages > 1)
        If totalPages <= 1 Then Return

        Dim goScript As String = String.Format(
            "document.getElementById('{0}').value='{{0}}';document.getElementById('{1}').click();return false;",
            hfTargetPage.ClientID, btnGoPager.ClientID)

        Dim btnPrev As New System.Web.UI.HtmlControls.HtmlButton()
        btnPrev.Attributes("type") = "button"
        btnPrev.InnerHtml = "&lsaquo;"
        btnPrev.Attributes("class") = "pg-btn" & If(currentPg = 0, " pg-disabled", "")
        btnPrev.Attributes("aria-label") = "Previous page"
        If currentPg > 0 Then
            btnPrev.Attributes("onclick") = String.Format(goScript, currentPg - 1)
        Else
            btnPrev.Disabled = True
        End If
        phPager.Controls.Add(btnPrev)

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
                btnPage.Attributes("aria-current") = "page"
            Else
                btnPage.Attributes("onclick") = String.Format(goScript, p)
            End If
            phPager.Controls.Add(btnPage)
            lastRendered = p
        Next

        Dim btnNext As New System.Web.UI.HtmlControls.HtmlButton()
        btnNext.Attributes("type") = "button"
        btnNext.InnerHtml = "&rsaquo;"
        btnNext.Attributes("class") = "pg-btn" & If(currentPg = totalPages - 1, " pg-disabled", "")
        btnNext.Attributes("aria-label") = "Next page"
        If currentPg < totalPages - 1 Then
            btnNext.Attributes("onclick") = String.Format(goScript, currentPg + 1)
        Else
            btnNext.Disabled = True
        End If
        phPager.Controls.Add(btnNext)
    End Sub
End Class