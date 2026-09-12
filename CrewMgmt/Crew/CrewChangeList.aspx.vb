Imports MySql.Data.MySqlClient
Imports System.Data
Imports System.Web.UI.WebControls

''' <summary>
''' Change Crew List (CCL) — Complete Workflow Page
''' Handles: reliever management, approval, scheduling, finalization, EOC, bulk apply.
''' </summary>
Public Class CrewChangeList
    Inherits System.Web.UI.Page

    ' ── Server Controls ──────────────────────────────────────────
    Protected WithEvents lblNotify         As Label
    Protected WithEvents lblVesselName     As Label

    ' Summary cards
    Protected WithEvents lblCntOnboard     As Label
    Protected WithEvents lblCntPending     As Label
    Protected WithEvents lblCntNoSched     As Label
    Protected WithEvents lblCntTentative   As Label
    Protected WithEvents lblCntNext        As Label

    ' Toolbar
    Protected WithEvents chkSelectAll      As CheckBox
    Protected WithEvents btnBulkSchedule   As Button
    Protected WithEvents btnApplyAll       As Button
    Protected WithEvents btnApplyChanges   As Button
    Protected WithEvents drpFilter         As DropDownList

    ' Main data repeater
    Protected WithEvents rptCCL            As Repeater

    ' Hidden fields (context passthrough for postbacks)
    Protected WithEvents hfVesselID        As HiddenField
    Protected WithEvents hfAction          As HiddenField
    Protected WithEvents hfRelieverID      As HiddenField
    Protected WithEvents hfScheduleID      As HiddenField
    Protected WithEvents hfOutgoingCrewID  As HiddenField
    Protected WithEvents hfRelieverCrewID  As HiddenField
    Protected WithEvents hfEocID           As HiddenField
    Protected WithEvents hfSelectedIDs     As HiddenField   ' comma-separated reliever IDs

    ' Add Reliever modal fields
    Protected WithEvents txtRelieverSearch As TextBox
    Protected WithEvents drpRelieverPick   As DropDownList
    Protected WithEvents btnConfirmReliever As Button
    Protected WithEvents btnSearchReliever As Button

    ' Schedule modal fields
    Protected WithEvents txtJoiningDate    As TextBox
    Protected WithEvents txtJoiningPort    As TextBox
    Protected WithEvents txtDepartureDate  As TextBox
    Protected WithEvents txtShipOnsign     As TextBox
    Protected WithEvents drpSchedStatus    As DropDownList
    Protected WithEvents chkApplyAll       As CheckBox
    Protected WithEvents btnSaveSchedule   As Button
    Protected WithEvents lblSchedTarget    As Label

    ' Approval modal fields
    Protected WithEvents lblApprovalTarget As Label
    Protected WithEvents txtApprovalRemarks As TextBox
    Protected WithEvents btnConfirmApprove  As Button
    Protected WithEvents btnConfirmReject   As Button

    ' Finalize modal fields
    Protected WithEvents lblFinalizeTarget As Label
    Protected WithEvents btnConfirmFinalize As Button

    ' Amend/Cancel modal fields
    Protected WithEvents lblAmendTarget    As Label
    Protected WithEvents txtAmendRemarks   As TextBox
    Protected WithEvents btnConfirmAmend   As Button
    Protected WithEvents btnConfirmCancel  As Button

    ' EOC preview modal
    Protected WithEvents lblEocCrew        As Label
    Protected WithEvents lblEocRank        As Label
    Protected WithEvents lblEocVessel      As Label
    Protected WithEvents lblEocSignOn      As Label
    Protected WithEvents lblEocSignOff     As Label
    Protected WithEvents lblEocPort        As Label
    Protected WithEvents lblEocStatus      As Label
    Protected WithEvents lblEocGenerated   As Label

    ' ════════════════════════════════════════════════════════════
    ' PAGE LOAD
    ' ════════════════════════════════════════════════════════════

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        RequireLogin()
        RequireRole(ROLE_MANNING_STAFF, ROLE_DOCUMENTATION_OFFICER,
                    ROLE_SUPER_ADMIN, ROLE_ADMIN,
                    ROLE_PRINCIPAL, ROLE_VESSEL_OWNER)

        If Not IsPostBack Then
            CType(Master, masterPage).lblPageTitle.Text = "Change Crew List"

            ' Resolve vessel from query string
            Dim encVslID  As String = HttpUtility.UrlDecode(Request.QueryString("VesselID"))
            Dim vesselIDStr As String = Decrypt(encVslID)

            If Not String.IsNullOrEmpty(vesselIDStr) Then
                hfVesselID.Value = vesselIDStr
                LoadVesselName(CInt(vesselIDStr))
            End If

            GetAdmin("Visited CCL", CurrentUserID().ToString(), "CrewChangeList",
                     "VesselID=" & vesselIDStr)

            ' Role-based UI setup
            ApplyRoleVisibility()

            ' Load schedule status dropdown
            drpSchedStatus.Items.Clear()
            drpSchedStatus.Items.Add(New ListItem("Tentative", CCLHelper.SCHED_TENTATIVE))
            drpSchedStatus.Items.Add(New ListItem("Next (Finalized)", CCLHelper.SCHED_NEXT))

            ' Load filter dropdown
            drpFilter.Items.Clear()
            drpFilter.Items.Add(New ListItem("All Crew", ""))
            drpFilter.Items.Add(New ListItem("Onboard Only", "onboard"))
            drpFilter.Items.Add(New ListItem("Pending Approval", "pending"))
            drpFilter.Items.Add(New ListItem("Approved (No Schedule)", "approved"))
            drpFilter.Items.Add(New ListItem("Tentative Schedule", "tentative"))
            drpFilter.Items.Add(New ListItem("Next / Finalized", "next"))

            LoadCCLGrid()
            LoadSummaryCards()
        End If
    End Sub

    ' ════════════════════════════════════════════════════════════
    ' ROLE VISIBILITY
    ' ════════════════════════════════════════════════════════════

    Private Sub ApplyRoleVisibility()
        Dim canAct As Boolean = CanSelectCCLCrew()
        chkSelectAll.Visible   = canAct
        btnBulkSchedule.Visible = canAct
        btnApplyAll.Visible    = canAct
        btnApplyChanges.Visible = canAct
    End Sub

    ' ════════════════════════════════════════════════════════════
    ' LOAD DATA
    ' ════════════════════════════════════════════════════════════

    Private Sub LoadVesselName(vesselId As Integer)
        Dim vname As Object = DbHelper.ExecuteScalar(
            "SELECT vesselName FROM tbl_vessels WHERE id=@vid",
            New MySqlParameter("@vid", vesselId))
        If vname IsNot Nothing AndAlso Not IsDBNull(vname) Then
            lblVesselName.Text = Server.HtmlEncode(vname.ToString())
        Else
            lblVesselName.Text = "Unknown Vessel"
        End If
    End Sub

    Private Sub LoadCCLGrid()
        Dim vid As Integer = GetVesselID()
        If vid = 0 Then
            rptCCL.DataSource = Nothing
            rptCCL.DataBind()
            Return
        End If

        Dim dt As DataTable = CCLHelper.LoadCCLData(vid)

        ' Apply filter
        Dim filter As String = drpFilter.SelectedValue
        If Not String.IsNullOrEmpty(filter) Then
            Dim dv As New DataView(dt)
            Select Case filter
                Case "onboard"   : dv.RowFilter = "crew_status = 3"
                Case "pending"   : dv.RowFilter = "reliever_status = 'Pending Approval'"
                Case "approved"  : dv.RowFilter = "reliever_status = 'Approved' AND schedule_id IS NULL"
                Case "tentative" : dv.RowFilter = "schedule_status = 'Tentative'"
                Case "next"      : dv.RowFilter = "schedule_status = 'Next'"
            End Select
            rptCCL.DataSource = dv.ToTable()
        Else
            rptCCL.DataSource = dt
        End If

        rptCCL.DataBind()
    End Sub

    Private Sub LoadSummaryCards()
        Dim vid As Integer = GetVesselID()
        If vid = 0 Then Return
        Dim row As DataRow = CCLHelper.LoadCCLSummary(vid)
        If row Is Nothing Then Return
        lblCntOnboard.Text   = SafeInt(row, "cnt_onboard").ToString()
        lblCntPending.Text   = SafeInt(row, "cnt_pending").ToString()
        lblCntNoSched.Text   = SafeInt(row, "cnt_approved_no_sched").ToString()
        lblCntTentative.Text = SafeInt(row, "cnt_tentative").ToString()
        lblCntNext.Text      = SafeInt(row, "cnt_next").ToString()
    End Sub

    Private Function GetVesselID() As Integer
        Dim v As Integer = 0
        Integer.TryParse(hfVesselID.Value, v)
        Return v
    End Function

    Private Function SafeInt(row As DataRow, col As String) As Integer
        If row Is Nothing OrElse IsDBNull(row(col)) Then Return 0
        Dim i As Integer = 0
        Integer.TryParse(row(col).ToString(), i)
        Return i
    End Function

    ' ════════════════════════════════════════════════════════════
    ' REPEATER ITEM BIND — provide per-row data to ASPX
    ' ════════════════════════════════════════════════════════════

    Protected Sub rptCCL_ItemDataBound(sender As Object, e As RepeaterItemEventArgs) Handles rptCCL.ItemDataBound
        If e.Item.ItemType <> ListItemType.Item AndAlso
           e.Item.ItemType <> ListItemType.AlternatingItem Then Return

        Dim row As DataRowView = CType(e.Item.DataItem, DataRowView)

        ' Checkbox eligibility: only ON BOARD (3) crew can receive relievers
        Dim chk As CheckBox = CType(e.Item.FindControl("chkRow"), CheckBox)
        Dim ttip As Label   = CType(e.Item.FindControl("lblIneligible"), Label)

        If chk IsNot Nothing Then
            Dim crewStatus As Integer = 0
            Integer.TryParse(row("crew_status").ToString(), crewStatus)
            Dim relStatus As String = If(IsDBNull(row("reliever_status")), "", row("reliever_status").ToString())
            Dim schedStatus As String = If(IsDBNull(row("schedule_status")), "", row("schedule_status").ToString())

            Dim isSelectable As Boolean = (crewStatus = 3 AndAlso
                                           String.IsNullOrEmpty(relStatus) AndAlso
                                           CanSelectCCLCrew())

            ' Also allow selection if Approved but no schedule yet
            If crewStatus = 3 AndAlso relStatus = CCLHelper.RELIEVER_APPROVED AndAlso
               String.IsNullOrEmpty(schedStatus) AndAlso CanSelectCCLCrew() Then
                isSelectable = True
            End If

            chk.Enabled = isSelectable
            If Not isSelectable AndAlso ttip IsNot Nothing Then
                If Not CanSelectCCLCrew() Then
                    ttip.Text = "View only"
                ElseIf crewStatus = 6 Then
                    ttip.Text = "Already in LINE UP"
                ElseIf relStatus = CCLHelper.RELIEVER_PENDING Then
                    ttip.Text = "Pending approval"
                ElseIf relStatus = CCLHelper.RELIEVER_APPROVED AndAlso Not String.IsNullOrEmpty(schedStatus) Then
                    ttip.Text = "Schedule already created"
                Else
                    ttip.Text = "Not eligible"
                End If
                ttip.Visible = True
            End If
        End If
    End Sub

    ' ════════════════════════════════════════════════════════════
    ' ADD RELIEVER — SEARCH
    ' ════════════════════════════════════════════════════════════

    Protected Sub btnSearchReliever_Click(sender As Object, e As EventArgs) Handles btnSearchReliever.Click
        Dim term As String = txtRelieverSearch.Text.Trim()
        Dim dt As DataTable = CCLHelper.LoadAvailableRelievers(GetVesselID(), term)
        drpRelieverPick.Items.Clear()
        drpRelieverPick.Items.Add(New ListItem("-- Select Reliever --", ""))
        For Each row As DataRow In dt.Rows
            drpRelieverPick.Items.Add(New ListItem(
                row("rank_code").ToString() & " — " & row("crew_name").ToString(),
                row("id").ToString()))
        Next

        If dt.Rows.Count = 0 Then
            ShowNotify("No available crew found for '" & Server.HtmlEncode(term) & "'. Try a different name or rank.", "warning")
        End If
        ' Re-open modal via JS — keep modal open on postback
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "reOpenReliever",
            "setTimeout(function(){ var m = document.getElementById('modalAddReliever'); " &
            "if(m) new bootstrap.Modal(m).show(); },100);", True)
    End Sub

    ' ════════════════════════════════════════════════════════════
    ' ADD RELIEVER — CONFIRM
    ' ════════════════════════════════════════════════════════════

    Protected Sub btnConfirmReliever_Click(sender As Object, e As EventArgs) Handles btnConfirmReliever.Click
        Dim outCrewId As Integer = 0
        Dim relCrewId As Integer = 0
        Dim vid       As Integer = GetVesselID()

        Integer.TryParse(hfOutgoingCrewID.Value, outCrewId)
        Integer.TryParse(drpRelieverPick.SelectedValue, relCrewId)

        If outCrewId = 0 OrElse relCrewId = 0 OrElse vid = 0 Then
            ShowNotify("Invalid selection. Please choose a reliever.", "danger")
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "reOpenRel",
                "setTimeout(function(){ var m = document.getElementById('modalAddReliever'); " &
                "if(m) new bootstrap.Modal(m).show(); },100);", True)
            Return
        End If

        Dim newId As Integer = CCLHelper.CreateReliever(vid, outCrewId, relCrewId, CurrentUserID())
        Select Case newId
            Case -1 : ShowNotify("This crew member already has an active reliever pending or approved.", "warning")
            Case -2 : ShowNotify("The selected reliever is already assigned to another crew change.", "warning")
            Case -3 : ShowNotify("A crew member cannot be their own reliever.", "danger")
            Case Is > 0
                GetAdmin("Added Reliever", CurrentUserID().ToString(), "CrewChangeList",
                          "OutgoingCrewID=" & outCrewId & " RelieverCrewID=" & relCrewId)
                ShowNotify("Reliever added successfully. Awaiting approval.", "success")
                LoadCCLGrid()
                LoadSummaryCards()
            Case Else
                ShowNotify("Failed to add reliever. Please try again.", "danger")
        End Select
    End Sub

    ' ════════════════════════════════════════════════════════════
    ' APPROVE / REJECT RELIEVER
    ' ════════════════════════════════════════════════════════════

    Protected Sub btnConfirmApprove_Click(sender As Object, e As EventArgs) Handles btnConfirmApprove.Click
        If Not CanApproveCCL() Then
            ShowNotify("You do not have permission to approve relievers.", "danger") : Return
        End If
        Dim rid As Integer = 0
        Integer.TryParse(hfRelieverID.Value, rid)
        If rid = 0 Then ShowNotify("Invalid reliever ID.", "danger") : Return

        Dim remarks As String = txtApprovalRemarks.Text.Trim()
        If CCLHelper.ApproveReliever(rid, CurrentUserID(), remarks) Then
            GetAdmin("Approved Reliever", CurrentUserID().ToString(), "CrewChangeList", "RelieverID=" & rid)
            ShowNotify("Reliever approved. Crew status updated to RELIEVER.", "success")
            LoadCCLGrid()
            LoadSummaryCards()
        Else
            ShowNotify("Approval failed. The reliever may already have been processed.", "danger")
        End If
    End Sub

    Protected Sub btnConfirmReject_Click(sender As Object, e As EventArgs) Handles btnConfirmReject.Click
        If Not CanApproveCCL() Then
            ShowNotify("You do not have permission to reject relievers.", "danger") : Return
        End If
        Dim rid As Integer = 0
        Integer.TryParse(hfRelieverID.Value, rid)
        If rid = 0 Then ShowNotify("Invalid reliever ID.", "danger") : Return

        Dim remarks As String = txtApprovalRemarks.Text.Trim()
        If String.IsNullOrEmpty(remarks) Then
            ShowNotify("Please provide a reason for rejection.", "warning")
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "reOpenAppr",
                "setTimeout(function(){ var m = document.getElementById('modalApproval'); " &
                "if(m) new bootstrap.Modal(m).show(); },100);", True)
            Return
        End If

        If CCLHelper.RejectReliever(rid, CurrentUserID(), remarks) Then
            GetAdmin("Rejected Reliever", CurrentUserID().ToString(), "CrewChangeList", "RelieverID=" & rid)
            ShowNotify("Reliever rejected. A new reliever can be assigned.", "info")
            LoadCCLGrid()
            LoadSummaryCards()
        Else
            ShowNotify("Rejection failed. The reliever may already have been processed.", "danger")
        End If
    End Sub

    ' ════════════════════════════════════════════════════════════
    ' CCL SCHEDULE — SAVE
    ' ════════════════════════════════════════════════════════════

    Protected Sub btnSaveSchedule_Click(sender As Object, e As EventArgs) Handles btnSaveSchedule.Click
        If Not CanAddReliever() Then
            ShowNotify("You do not have permission to create schedules.", "danger") : Return
        End If

        Dim rid     As Integer = 0
        Dim sid     As Integer = 0
        Dim vid     As Integer = GetVesselID()
        Dim relCrew As Integer = 0
        Integer.TryParse(hfRelieverID.Value, rid)
        Integer.TryParse(hfScheduleID.Value, sid)
        Integer.TryParse(hfRelieverCrewID.Value, relCrew)

        Dim jd As Date, dd As Date, sod As Date
        If Not Date.TryParse(txtJoiningDate.Text, jd) Then
            ShowNotify("Invalid Joining Date.", "danger") : ReOpenScheduleModal() : Return
        End If
        If Not Date.TryParse(txtDepartureDate.Text, dd) Then
            ShowNotify("Invalid Departure Date.", "danger") : ReOpenScheduleModal() : Return
        End If
        If Not Date.TryParse(txtShipOnsign.Text, sod) Then
            ShowNotify("Invalid Ship On-Sign Date.", "danger") : ReOpenScheduleModal() : Return
        End If

        Dim dto As New CCLHelper.CCLScheduleDTO With {
            .ScheduleId = sid,
            .RelieverRecordId = rid,
            .VesselId = vid,
            .CrewId = relCrew,
            .JoiningDate = jd,
            .JoiningPort = txtJoiningPort.Text.Trim(),
            .DepartureDate = dd,
            .ShipOnsignDate = sod,
            .ScheduleStatus = CCLHelper.SCHED_TENTATIVE,
            .CreatedBy = CurrentUserID()
        }

        ' Bulk apply to all selected relievers
        If chkApplyAll.Checked Then
            Dim ids As List(Of Integer) = ParseSelectedIDs()
            If ids.Count > 0 Then
                Dim result As CCLHelper.ApplyResult = CCLHelper.ApplyScheduleToAll(ids, dto)
                Dim msg As String = "Applied to " & result.SuccessCount & " crew member(s)."
                If result.SkippedList.Count > 0 Then
                    msg &= " Skipped: " & String.Join("; ", result.SkippedList)
                End If
                ShowNotify(msg, If(result.SuccessCount > 0, "success", "warning"))
                LoadCCLGrid()
                LoadSummaryCards()
                Return
            End If
        End If

        ' Single save
        Dim errs As List(Of String) = CCLHelper.ValidateCCLSchedule(dto)
        If errs.Count > 0 Then
            ShowNotify(String.Join("<br/>", errs), "danger")
            ReOpenScheduleModal()
            Return
        End If

        Dim newSid As Integer = CCLHelper.SaveCCLSchedule(dto)
        If newSid > 0 Then
            Dim action As String = If(sid = 0, "Created", "Updated")
            GetAdmin(action & " CCL Schedule", CurrentUserID().ToString(), "CrewChangeList",
                     "ScheduleID=" & newSid & " RelieverID=" & rid)
            ShowNotify("Schedule " & action.ToLower() & " successfully.", "success")
            LoadCCLGrid()
            LoadSummaryCards()
        Else
            ShowNotify("Failed to save schedule. Please check your inputs.", "danger")
            ReOpenScheduleModal()
        End If
    End Sub

    ' ════════════════════════════════════════════════════════════
    ' FINALIZE SCHEDULE
    ' ════════════════════════════════════════════════════════════

    Protected Sub btnConfirmFinalize_Click(sender As Object, e As EventArgs) Handles btnConfirmFinalize.Click
        If Not CanFinalizeCCL() Then
            ShowNotify("You do not have permission to finalize schedules.", "danger") : Return
        End If
        Dim sid As Integer = 0
        Integer.TryParse(hfScheduleID.Value, sid)
        If sid = 0 Then ShowNotify("Invalid schedule ID.", "danger") : Return

        If CCLHelper.FinalizeSchedule(sid, CurrentUserID()) Then
            GetAdmin("Finalized CCL Schedule", CurrentUserID().ToString(), "CrewChangeList",
                     "ScheduleID=" & sid)
            ShowNotify("Schedule finalized to NEXT status. EOC has been automatically generated.", "success")
            LoadCCLGrid()
            LoadSummaryCards()
        Else
            ShowNotify("Finalization failed. The schedule may have already been finalized or cancelled.", "danger")
        End If
    End Sub

    ' ════════════════════════════════════════════════════════════
    ' AMEND / CANCEL SCHEDULE
    ' ════════════════════════════════════════════════════════════

    Protected Sub btnConfirmAmend_Click(sender As Object, e As EventArgs) Handles btnConfirmAmend.Click
        If Not CanAmendCCL() Then
            ShowNotify("Only Admin / Super Admin can amend finalized schedules.", "danger") : Return
        End If
        Dim sid As Integer = 0
        Integer.TryParse(hfScheduleID.Value, sid)
        Dim remarks As String = txtAmendRemarks.Text.Trim()

        If CCLHelper.AmendSchedule(sid, CurrentUserID(), remarks) Then
            GetAdmin("Amended CCL Schedule", CurrentUserID().ToString(), "CrewChangeList",
                     "ScheduleID=" & sid)
            ShowNotify("Schedule reverted to Tentative. The EOC has been marked Superseded.", "warning")
            LoadCCLGrid()
            LoadSummaryCards()
        Else
            ShowNotify("Amendment failed.", "danger")
        End If
    End Sub

    Protected Sub btnConfirmCancel_Click(sender As Object, e As EventArgs) Handles btnConfirmCancel.Click
        If Not CanCancelCCL() Then
            ShowNotify("Only Admin / Super Admin can cancel schedules.", "danger") : Return
        End If
        Dim sid As Integer = 0
        Integer.TryParse(hfScheduleID.Value, sid)
        Dim remarks As String = txtAmendRemarks.Text.Trim()

        If CCLHelper.CancelSchedule(sid, CurrentUserID(), remarks) Then
            GetAdmin("Cancelled CCL Schedule", CurrentUserID().ToString(), "CrewChangeList",
                     "ScheduleID=" & sid)
            ShowNotify("Schedule cancelled. Any associated EOC has also been cancelled.", "warning")
            LoadCCLGrid()
            LoadSummaryCards()
        Else
            ShowNotify("Cancellation failed.", "danger")
        End If
    End Sub

    ' ════════════════════════════════════════════════════════════
    ' EOC PREVIEW
    ' ════════════════════════════════════════════════════════════

    Protected Sub LoadEOCPreview()
        Dim eocId As Integer = 0
        Integer.TryParse(hfEocID.Value, eocId)
        If eocId = 0 Then Return

        Dim row As DataRow = CCLHelper.LoadEOCDetails(eocId)
        If row Is Nothing Then Return

        lblEocCrew.Text      = Server.HtmlEncode(row("crew_name").ToString())
        lblEocRank.Text      = Server.HtmlEncode(row("rank_code").ToString())
        lblEocVessel.Text    = Server.HtmlEncode(row("vesselName").ToString())
        lblEocSignOn.Text    = If(IsDBNull(row("sign_on_date")), "N/A",
                                  CDate(row("sign_on_date")).ToString("MMM dd, yyyy"))
        lblEocSignOff.Text   = If(IsDBNull(row("sign_off_date")), "N/A",
                                  CDate(row("sign_off_date")).ToString("MMM dd, yyyy"))
        lblEocPort.Text      = Server.HtmlEncode(row("joining_port").ToString())
        lblEocStatus.Text    = row("eoc_status").ToString()
        lblEocGenerated.Text = CDate(row("generated_at")).ToString("MMM dd, yyyy hh:mm tt")
    End Sub

    ' ════════════════════════════════════════════════════════════
    ' FILTER CHANGE
    ' ════════════════════════════════════════════════════════════

    Protected Sub drpFilter_SelectedIndexChanged(sender As Object, e As EventArgs) Handles drpFilter.SelectedIndexChanged
        LoadCCLGrid()
    End Sub

    ' ════════════════════════════════════════════════════════════
    ' HELPERS
    ' ════════════════════════════════════════════════════════════

    Private Function ParseSelectedIDs() As List(Of Integer)
        Dim ids As New List(Of Integer)()
        If String.IsNullOrEmpty(hfSelectedIDs.Value) Then Return ids
        For Each part As String In hfSelectedIDs.Value.Split(","c)
            Dim n As Integer
            If Integer.TryParse(part.Trim(), n) AndAlso n > 0 Then ids.Add(n)
        Next
        Return ids
    End Function

    Private Sub ShowNotify(msg As String, alertType As String)
        ' alertType: success | danger | warning | info
        Dim icon As String = "fa-circle-check"
        Select Case alertType
            Case "danger"  : icon = "fa-circle-xmark"
            Case "warning" : icon = "fa-triangle-exclamation"
            Case "info"    : icon = "fa-circle-info"
        End Select
        lblNotify.Text = "<div class='alert alert-" & alertType & " d-flex align-items-center gap-2 mb-3'>" &
                         "<i class='fa " & icon & "'></i><span>" & msg & "</span></div>"
    End Sub

    Private Sub ReOpenScheduleModal()
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "reOpenSched",
            "setTimeout(function(){ var m = document.getElementById('modalSchedule'); " &
            "if(m) new bootstrap.Modal(m).show(); },100);", True)
    End Sub

    ' ════════════════════════════════════════════════════════════
    ' ASPX DATABINDING UTILITY HELPERS
    ' Called from <%# %> blocks in the Repeater ItemTemplate.
    ' Keeps ASPX clean by moving all conditional logic server-side.
    ' ════════════════════════════════════════════════════════════

    ''' <summary>Safe integer: returns 0 for DBNull/Nothing.</summary>
    Protected Function NullInt(val As Object) As Integer
        If val Is Nothing OrElse IsDBNull(val) Then Return 0
        Dim i As Integer = 0
        Integer.TryParse(val.ToString(), i)
        Return i
    End Function

    ''' <summary>Safe string: returns "" for DBNull/Nothing.</summary>
    Protected Function NullStr(val As Object) As String
        If val Is Nothing OrElse IsDBNull(val) Then Return ""
        Return val.ToString()
    End Function

    ''' <summary>Short alias for Server.HtmlEncode — keeps ASPX templates concise.</summary>
    Protected Function HE(val As Object) As String
        If val Is Nothing OrElse IsDBNull(val) Then Return ""
        Return Server.HtmlEncode(val.ToString())
    End Function

    ''' <summary>Build the reliever name+rank cell HTML.</summary>
    Protected Function BuildRelieverCell(nameVal As Object, rankVal As Object) As String
        If nameVal Is Nothing OrElse IsDBNull(nameVal) OrElse String.IsNullOrEmpty(nameVal.ToString()) Then
            Return "<span style='color:#94a3b8;font-size:12px;'>&#8212;</span>"
        End If
        Dim rankHtml As String = If(rankVal Is Nothing OrElse IsDBNull(rankVal), "",
                                    Server.HtmlEncode(rankVal.ToString()))
        Return "<div class='reliever-name'><strong>" & Server.HtmlEncode(nameVal.ToString()) & "</strong></div>" &
               "<div class='reliever-rank'>" & rankHtml & "</div>"
    End Function

    ''' <summary>Build a formatted date cell, or an em-dash placeholder if null.</summary>
    Protected Function BuildDateCell(val As Object) As String
        If val Is Nothing OrElse IsDBNull(val) Then
            Return "<span style='color:#94a3b8;'>&#8212;</span>"
        End If
        Try
            Return CDate(val).ToString("MMM dd, yyyy")
        Catch
            Return "<span style='color:#94a3b8;'>&#8212;</span>"
        End Try
    End Function

    ''' <summary>Build a safe text cell (HtmlEncoded), or an em-dash placeholder if null.</summary>
    Protected Function BuildTextCell(val As Object) As String
        If val Is Nothing OrElse IsDBNull(val) OrElse String.IsNullOrEmpty(val.ToString()) Then
            Return "<span style='color:#94a3b8;'>&#8212;</span>"
        End If
        Return Server.HtmlEncode(val.ToString())
    End Function

    ' ════════════════════════════════════════════════════════════
    ' BADGE BUILDER HELPERS (called from ASPX via <%# %>)
    ' ════════════════════════════════════════════════════════════


    Protected Function BuildCrewStatusBadge(crewStatus As Integer, text As String) As String
        Select Case crewStatus
            Case 3 : Return "<span class='badge-ccl badge-onboard'><i class='fa fa-ship'></i> " & Server.HtmlEncode(text) & "</span>"
            Case 6 : Return "<span class='badge-ccl badge-lineup'><i class='fa fa-list'></i> " & Server.HtmlEncode(text) & "</span>"
            Case 7 : Return "<span class='badge-ccl badge-reliever'><i class='fa fa-user-clock'></i> " & Server.HtmlEncode(text) & "</span>"
            Case 1 : Return "<span class='badge-ccl badge-active'><i class='fa fa-circle-check'></i> " & Server.HtmlEncode(text) & "</span>"
            Case Else : Return "<span class='badge-ccl badge-cancelled'>" & Server.HtmlEncode(text) & "</span>"
        End Select
    End Function

    Protected Function BuildRelieverStatusBadge(status As String) As String
        If String.IsNullOrEmpty(status) Then
            Return "<span style='color:#94a3b8;font-size:12px;'>—</span>"
        End If
        Select Case status
            Case CCLHelper.RELIEVER_PENDING   : Return "<span class='badge-ccl badge-pending'><i class='fa fa-clock'></i> Pending</span>"
            Case CCLHelper.RELIEVER_APPROVED  : Return "<span class='badge-ccl badge-approved'><i class='fa fa-circle-check'></i> Approved</span>"
            Case CCLHelper.RELIEVER_REJECTED  : Return "<span class='badge-ccl badge-rejected'><i class='fa fa-circle-xmark'></i> Rejected</span>"
            Case CCLHelper.RELIEVER_CANCELLED : Return "<span class='badge-ccl badge-cancelled'>Cancelled</span>"
            Case Else : Return "<span class='badge-ccl badge-cancelled'>" & Server.HtmlEncode(status) & "</span>"
        End Select
    End Function

    Protected Function BuildScheduleStatusBadge(status As String) As String
        If String.IsNullOrEmpty(status) Then
            Return "<span style='color:#94a3b8;font-size:12px;'>—</span>"
        End If
        Select Case status
            Case CCLHelper.SCHED_TENTATIVE : Return "<span class='badge-ccl badge-tentative'><i class='fa fa-calendar-days'></i> Tentative</span>"
            Case CCLHelper.SCHED_NEXT      : Return "<span class='badge-ccl badge-next'><i class='fa fa-flag-checkered'></i> Next</span>"
            Case CCLHelper.SCHED_COMPLETED : Return "<span class='badge-ccl badge-completed'><i class='fa fa-circle-check'></i> Completed</span>"
            Case CCLHelper.SCHED_CANCELLED : Return "<span class='badge-ccl badge-cancelled'>Cancelled</span>"
            Case Else : Return "<span class='badge-ccl badge-cancelled'>" & Server.HtmlEncode(status) & "</span>"
        End Select
    End Function

    Protected Function BuildEocStatusBadge(status As String) As String
        If String.IsNullOrEmpty(status) Then
            Return "<span class='badge-ccl badge-eoc-no'><i class='fa fa-minus'></i> No EOC</span>"
        End If
        Select Case status
            Case CCLHelper.EOC_GENERATED  : Return "<span class='badge-ccl badge-eoc-gen'><i class='fa fa-file-circle-check'></i> Generated</span>"
            Case CCLHelper.EOC_CANCELLED  : Return "<span class='badge-ccl badge-rejected'><i class='fa fa-file-circle-xmark'></i> Cancelled</span>"
            Case CCLHelper.EOC_SUPERSEDED : Return "<span class='badge-ccl badge-eoc-sup'><i class='fa fa-file-circle-minus'></i> Superseded</span>"
            Case Else : Return "<span class='badge-ccl badge-eoc-no'>" & Server.HtmlEncode(status) & "</span>"
        End Select
    End Function

    ''' <summary>
    ''' Build per-row action buttons HTML based on current statuses and user role.
    ''' </summary>
    Protected Function BuildRowActions(crewId As Integer,
                                       crewStatus As Integer,
                                       relieverId As Integer,
                                       relieverStatus As String,
                                       scheduleId As Integer,
                                       scheduleStatus As String,
                                       eocId As Integer,
                                       relieverCrewId As Integer) As String
        Dim sb As New System.Text.StringBuilder()

        Dim canAct   As Boolean = CanAddReliever()
        Dim canApprv As Boolean = CanApproveCCL()
        Dim canFinal As Boolean = CanFinalizeCCL()
        Dim canAmend As Boolean = CanAmendCCL()

        ' Helper: JS onclick for data-row buttons
        ' All buttons are <button type="button"> so no postback occurs on click

        ' Add Reliever — show if ON BOARD and no active reliever
        If crewStatus = 3 AndAlso relieverId = 0 AndAlso canAct Then
            sb.Append("<button type='button' class='btn-ccl-act green' " &
                      "onclick=""openAddReliever(this,'" &
                      JsEsc(GetCrewNameFromGrid()) & "','')"" title='Assign Reliever'>" &
                      "<i class='fa fa-user-plus'></i> Reliever</button>")
        End If

        ' Approve / Reject — if Pending Approval
        If relieverStatus = CCLHelper.RELIEVER_PENDING AndAlso canApprv Then
            sb.Append("<button type='button' class='btn-ccl-act green' " &
                      "onclick=""openApproval(this,'','','','')""  title='Approve / Reject Reliever'>" &
                      "<i class='fa fa-user-check'></i> Approve</button>")
        End If

        ' Create Schedule — if Approved and no active schedule
        If relieverStatus = CCLHelper.RELIEVER_APPROVED AndAlso scheduleId = 0 AndAlso canAct Then
            sb.Append("<button type='button' class='btn-ccl-act blue' " &
                      "onclick=""openCreateSchedule(this,'','')""  title='Create CCL Schedule'>" &
                      "<i class='fa fa-calendar-plus'></i> Schedule</button>")
        End If

        ' Edit Schedule — if Tentative
        If scheduleStatus = CCLHelper.SCHED_TENTATIVE AndAlso canAct Then
            sb.Append("<button type='button' class='btn-ccl-act purple' " &
                      "onclick=""openEditSchedule(this,'','','','','','')""  title='Edit Schedule'>" &
                      "<i class='fa fa-calendar-pen'></i> Edit</button>")
            ' Finalize — Tentative → Next
            If canFinal Then
                sb.Append("<button type='button' class='btn-ccl-act blue' " &
                          "onclick=""openFinalize(this,'','')""  title='Finalize to Next'>" &
                          "<i class='fa fa-flag-checkered'></i> Finalize</button>")
            End If
        End If

        ' Amend / Cancel — if Next (Admin only)
        If scheduleStatus = CCLHelper.SCHED_NEXT AndAlso canAmend Then
            sb.Append("<button type='button' class='btn-ccl-act orange' " &
                      "onclick=""openAmend(this,'')""  title='Amend / Cancel Schedule'>" &
                      "<i class='fa fa-pen-to-square'></i> Amend</button>")
        End If

        ' View EOC — if EOC generated
        If eocId > 0 Then
            sb.Append("<button type='button' class='btn-ccl-act teal' " &
                      "onclick=""openEOC(this)""  title='View EOC Record'>" &
                      "<i class='fa fa-file-circle-check'></i> EOC</button>")
        End If

        If sb.Length = 0 Then
            sb.Append("<span style='color:#94a3b8;font-size:12px;'>—</span>")
        End If

        Return sb.ToString()
    End Function

    Private Function GetCrewNameFromGrid() As String
        Return ""   ' Name is passed from client-side data attributes
    End Function

    Private Function JsEsc(s As String) As String
        If String.IsNullOrEmpty(s) Then Return ""
        Return s.Replace("'", "\\'").Replace("""", "&quot;")
    End Function

End Class

