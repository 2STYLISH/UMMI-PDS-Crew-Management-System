Imports MySql.Data.MySqlClient
Imports System.Data

Public Class ApplicantPool
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        RequireLogin()
        RequireRole("MANNING_STAFF", "SUPER_ADMIN")

        If Not IsPostBack Then
            CType(Master, masterPage).lblPageTitle.Text = "Applicant Pool"
            GetAdmin("Visited", CurrentUserID().ToString(), "ApplicantPool", "Applicant Pool")
            LoadRankType()
            LoadRanks("")
            LoadLinkRanks()
            txtLinkValidity.Text = DateTime.Now.AddDays(30).ToString("yyyy-MM-dd")
            SearchApplicants(Nothing, Nothing)
            LoadLinks()
        End If
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

    Protected Sub RankTypeChanged(sender As Object, e As EventArgs)
        LoadRanks(drpdwnRankType.SelectedValue)
    End Sub

    ' UC-CM-13/14: Search Applicants
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
                cmd.Parameters.AddWithValue("@vslexpID_",  DBNull.Value)
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
        SearchApplicants(Nothing, Nothing)
    End Sub

    ' WBS 1.3.4 RowDataBound — avatar + vessel experience
    Protected Sub GvApplicants_RowDataBound(sender As Object, e As System.Web.UI.WebControls.GridViewRowEventArgs)
        If e.Row.RowType <> System.Web.UI.WebControls.DataControlRowType.DataRow Then Return
        Dim dr As System.Data.DataRowView = CType(e.Row.DataItem, System.Data.DataRowView)

        ' Avatar (WBS 1.3.3)
        Dim img As System.Web.UI.WebControls.Image = CType(e.Row.FindControl("imgAvatar"), System.Web.UI.WebControls.Image)
        If img IsNot Nothing AndAlso Not IsDBNull(dr("picture_id")) AndAlso dr("picture_id").ToString() <> "" Then
            img.ImageUrl = "~/Uploads/picture/" & dr("picture_id").ToString()
        End If

        ' Vessel Experience (WBS 1.3.4)
        Dim lblVE As System.Web.UI.WebControls.Label = CType(e.Row.FindControl("lblVesselExp"), System.Web.UI.WebControls.Label)
        If lblVE IsNot Nothing Then
            Dim pid As String = dr("id").ToString()
            Dim sql As String = "SELECT GROUP_CONCAT(DISTINCT t.typeOfVessel ORDER BY t.typeOfVessel SEPARATOR ', ') AS types " &
                                "FROM tbl_personnel_sea_service pss " &
                                "JOIN tbl_vessels v ON v.id=pss.vessel_id " &
                                "JOIN tbl_type_of_vessel t ON t.id=v.VesselType " &
                                "WHERE pss.personnel_id=@pid"
            Dim result As Object = DbHelper.ExecuteScalar(sql, New MySqlParameter("@pid", pid))
            lblVE.Text = If(result Is DBNull.Value OrElse result Is Nothing, "None", result.ToString())
        End If
    End Sub

    Protected Sub GvApplicants_PageIndexChanging(sender As Object, e As System.Web.UI.WebControls.GridViewPageEventArgs)
        gvApplicants.PageIndex = e.NewPageIndex
        SearchApplicants(Nothing, Nothing)
    End Sub

    ' UC-CM-22 — Hire Applicant
    Protected Sub GvApplicants_RowCommand(sender As Object, e As System.Web.UI.WebControls.GridViewCommandEventArgs)
        If e.CommandName = "HireApplicant" Then
            Dim pid As String = e.CommandArgument.ToString()
            Dim sql As String = "UPDATE tbl_personnel_info SET crew_status=1 WHERE id=@id"
            DbHelper.ExecuteNonQuery(sql, New MySqlParameter("@id", pid))
            GetPortalAct("Hired Applicant", CurrentUserID().ToString(), "ApplicantPool", "Changed status to Active", pid)
            lblNotify.Text = "<div class='alert alert-success'><i class='fa fa-circle-check me-2'></i>Applicant hired. Status changed to Active.</div>"
            SearchApplicants(Nothing, Nothing)
        End If
    End Sub

    ' UC-CM-18: Show Generate Link
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

    ' WBS 1.3.6-1.3.10: Generate Link
    Protected Sub GenerateLink(sender As Object, e As EventArgs)
        ' WBS 1.3.7 Validation
        If String.IsNullOrEmpty(txtLinkFullname.Text.Trim()) Then
            lblNotify.Text = "<div class='alert alert-danger'>Full name is required.</div>"
            Return
        End If
        If String.IsNullOrEmpty(txtLinkEmail.Text.Trim()) Then
            lblNotify.Text = "<div class='alert alert-danger'>Email is required.</div>"
            Return
        End If

        Dim validity As DateTime = DateTime.Now.AddDays(30)
        If IsDate(txtLinkValidity.Text) Then validity = CDate(txtLinkValidity.Text).Date.AddHours(23).AddMinutes(59)

        ' WBS 1.3.9 DB Insert
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

        ' WBS 1.3.8 Encrypted URL Construction
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

        ' WBS 1.3.10 Display
        txtGeneratedLink.Value = fullLink
        lblGeneratedExpiry.Text = validity.ToString("MMMM dd, yyyy HH:mm")
        panelLinkResult.Visible = True
    End Sub

    ' WBS 1.3.11 Load Links
    Private Sub LoadLinks()
        Dim sql As String = "SELECT id, fullname, email, position_applied, date_generated, validity, status " &
                            "FROM tbl_applicant_generated_link ORDER BY date_generated DESC LIMIT 50"
        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text)
        gvLinks.DataSource = dt
        gvLinks.DataBind()
    End Sub

    ' WBS 1.3.12/1.3.14 Link row data bound (color expired)
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
    End Sub

    ' WBS 1.3.13 Expire link
    Protected Sub GvLinks_RowCommand(sender As Object, e As System.Web.UI.WebControls.GridViewCommandEventArgs)
        If e.CommandName = "ExpireLink" Then
            Dim linkID As String = e.CommandArgument.ToString()
            DbHelper.ExecuteNonQuery("UPDATE tbl_applicant_generated_link SET status='Expired' WHERE id=@id",
                New MySqlParameter("@id", linkID))
            GetAdmin("Expired Link", CurrentUserID().ToString(), "ApplicantPool", "LinkID=" & linkID)
            LoadLinks()
        End If
    End Sub

    Public Function GetProfileUrl(id As Object) As String
        Dim encID As String = HttpUtility.UrlEncode(Encrypt(id.ToString()))
        Dim encType As String = HttpUtility.UrlEncode(Encrypt("Viewer"))
        Return "~/Crew/ProfileViewer.aspx?ID=" & encID & "&Type=" & encType
    End Function

End Class
