Imports MySql.Data.MySqlClient
Imports System.Data

Public Class ApplicantPool
    Inherits System.Web.UI.Page

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
        If IsDate(txtDateFrom.Text) Then dateFrom = CDate(txtDateFrom.Text)
        If IsDate(txtDateTo.Text)   Then dateTo   = CDate(txtDateTo.Text)

        GetAdmin("Searched Applicants", CurrentUserID().ToString(), "ApplicantPool",
            txtLastName.Text & " " & txtFirstName.Text)

        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand("spApplicantPoolSearchDisplay", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@lastname_",  txtLastName.Text.Trim())
                cmd.Parameters.AddWithValue("@firstname_", txtFirstName.Text.Trim())
                cmd.Parameters.AddWithValue("@rank_",      rankID)
                cmd.Parameters.AddWithValue("@ranktype_",  drpdwnRankType.SelectedValue)
                cmd.Parameters.AddWithValue("@vslexpID_",  If(drpdwnVesselExpType.SelectedValue = "", DBNull.Value, CObj(drpdwnVesselExpType.SelectedValue)))
                cmd.Parameters.AddWithValue("@datefrom_",  dateFrom)
                cmd.Parameters.AddWithValue("@dateto_",    dateTo)

                Dim dt As New DataTable()
                Using da As New MySqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using

                ' Summary
                Dim total As Integer = dt.Rows.Count
                Dim totalAge As Integer = 0
                For Each row As DataRow In dt.Rows
                    If Not IsDBNull(row("age")) Then totalAge += CInt(row("age"))
                Next
                lblCount.Text  = total.ToString()
                lblAvgAge.Text = If(total > 0, Math.Round(CDbl(totalAge) / total, 0).ToString(), "0")
                divSummary.Visible = True

                gvApplicants.DataSource = dt
                gvApplicants.PageIndex = 0
                gvApplicants.DataBind()
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

    Protected Sub GvApplicants_PageIndexChanging(sender As Object, e As System.Web.UI.WebControls.GridViewPageEventArgs)
        gvApplicants.PageIndex = e.NewPageIndex
        SearchApplicants(Nothing, Nothing)
    End Sub

    ' ──────────────── UC-CM-23: Hire Applicant ────────────────────
    Protected Sub GvApplicants_RowCommand(sender As Object, e As System.Web.UI.WebControls.GridViewCommandEventArgs)
        If e.CommandName = "HireApplicant" Then
            Dim pid As String = e.CommandArgument.ToString()
            Dim sql As String = "UPDATE tbl_personnel_info SET crew_status=1 WHERE id=@id"
            DbHelper.ExecuteNonQuery(sql, New MySqlParameter("@id", pid))
            GetPortalAct("Hired Applicant", CurrentUserID().ToString(), "ApplicantPool", "Changed status to Active", pid)
            lblNotify.Text = "<div class='alert alert-success'><i class='fa fa-circle-check me-2'></i>Applicant hired successfully. Crew status changed to Active.</div>"
            SearchApplicants(Nothing, Nothing)
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
        If String.IsNullOrEmpty(txtLinkFullname.Text.Trim()) Then
            lblNotify.Text = "<div class='alert alert-danger'>Full name is required.</div>"
            Return
        End If
        If String.IsNullOrEmpty(txtLinkEmail.Text.Trim()) Then
            lblNotify.Text = "<div class='alert alert-danger'>Email is required.</div>"
            Return
        End If

        ' FR-CM-40: Valid calendar date validation
        Dim validity As DateTime = DateTime.Now.AddDays(1)
        If Not String.IsNullOrEmpty(txtLinkValidity.Text) Then
            If Not IsDate(txtLinkValidity.Text) Then
                lblNotify.Text = "<div class='alert alert-danger'>Please enter a valid calendar date for link validity.</div>"
                Return
            End If
            validity = CDate(txtLinkValidity.Text).Date.AddHours(23).AddMinutes(59)
        End If

        ' DB Insert
        Dim sqlInsert As String = "INSERT INTO tbl_applicant_generated_link " &
            "(fullname, email, position_applied, validity, status, date_generated, generated_by) " &
            "VALUES (@fn, @em, @pos, @val, 'Active', NOW(), @uid); SELECT LAST_INSERT_ID();"

        Dim newID As Object = DbHelper.ExecuteScalar(sqlInsert,
            New MySqlParameter("@fn",  txtLinkFullname.Text.Trim()),
            New MySqlParameter("@em",  txtLinkEmail.Text.Trim()),
            New MySqlParameter("@pos", drpdwnLinkRank.SelectedValue),
            New MySqlParameter("@val", validity),
            New MySqlParameter("@uid", CurrentUserID()))

        If newID Is Nothing OrElse IsDBNull(newID) Then
            lblNotify.Text = "<div class='alert alert-danger'>Error creating link. Please try again.</div>"
            Return
        End If

        ' Encrypted URL Construction
        Dim linkID As String = newID.ToString()
        Dim encryptedParams As String = Encrypt("linkid=" & linkID)
        Dim appUrl As String = "http://" & Request.Url.Host
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
            txtLinkFullname.Text.Trim() & " | " & txtLinkEmail.Text.Trim())

        ' Display
        txtGeneratedLink.Value = fullLink
        lblGeneratedExpiry.Text = validity.ToString("MMMM dd, yyyy HH:mm")
        panelLinkResult.Visible = True

        ' Store for resend
        ViewState("LastGeneratedLink") = fullLink
        ViewState("LastGeneratedEmail") = txtLinkEmail.Text.Trim()
        ViewState("LastGeneratedName") = txtLinkFullname.Text.Trim()
    End Sub

    ' ──────────────── UC-CM-17: Send Link via Email (FR-CM-41) ──
    Protected Sub SendLinkEmail(sender As Object, e As EventArgs)
        Dim email As String = If(ViewState("LastGeneratedEmail") IsNot Nothing, ViewState("LastGeneratedEmail").ToString(), txtLinkEmail.Text.Trim())
        Dim name As String = If(ViewState("LastGeneratedName") IsNot Nothing, ViewState("LastGeneratedName").ToString(), txtLinkFullname.Text.Trim())
        Dim link As String = If(ViewState("LastGeneratedLink") IsNot Nothing, ViewState("LastGeneratedLink").ToString(), txtGeneratedLink.Value)

        Dim subject As String = HttpUtility.UrlEncode("UMMI Manning - Application Encoding Link")
        Dim body As String = HttpUtility.UrlEncode("Dear " & name & "," & vbCrLf & vbCrLf &
            "Please use the link below to encode your application information:" & vbCrLf & vbCrLf &
            link & vbCrLf & vbCrLf &
            "Thank you," & vbCrLf & "UMMI Manning Office")
        Dim mailto As String = "mailto:" & HttpUtility.UrlEncode(email) & "?subject=" & subject & "&body=" & body

        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "mailto", "window.location.href='" & mailto & "';", True)
        GetAdmin("Sent Applicant Link Email", CurrentUserID().ToString(), "ApplicantPool", name & " | " & email)
    End Sub

    ' ──────────────── UC-CM-18: Load Links (FR-CM-42/43) ──────────
    Private Sub LoadLinks()
        Dim statusFilter As String = drpdwnLinkStatusFilter.SelectedValue
        Dim sql As String = "SELECT agl.id, agl.fullname, agl.email, agl.position_applied, " &
                            "agl.date_generated, agl.validity, agl.last_date_access, agl.status, agl.link_token, " &
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
                ' UC-CM-22: Resend (FR-CM-47)
                Dim linkID2 As String = e.CommandArgument.ToString()
                Dim linkData As DataTable = DbHelper.FillDataTable(
                    "SELECT link_token, fullname, email FROM tbl_applicant_generated_link WHERE id=@id",
                    CommandType.Text, New MySqlParameter("@id", linkID2))
                If linkData.Rows.Count > 0 Then
                    Dim token As String = linkData.Rows(0)("link_token").ToString()
                    Dim name As String = linkData.Rows(0)("fullname").ToString()
                    Dim email As String = linkData.Rows(0)("email").ToString()
                    Dim subject As String = HttpUtility.UrlEncode("UMMI Manning - Application Encoding Link (Resent)")
                    Dim body As String = HttpUtility.UrlEncode("Dear " & name & "," & vbCrLf & vbCrLf &
                        "Here is your encoding link again:" & vbCrLf & token & vbCrLf & vbCrLf & "UMMI Manning Office")
                    Dim mailto As String = "mailto:" & HttpUtility.UrlEncode(email) & "?subject=" & subject & "&body=" & body
                    ScriptManager.RegisterStartupScript(Me, Me.GetType(), "resend", "window.location.href='" & mailto & "';", True)
                    GetAdmin("Resent Applicant Link", CurrentUserID().ToString(), "ApplicantPool", name & " | " & email)
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

End Class
