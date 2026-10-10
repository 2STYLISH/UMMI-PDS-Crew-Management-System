Imports MySql.Data.MySqlClient
Imports System.Data
Imports System.Web
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

    ' Vessel picker panel (standalone entry point, no VesselID in querystring)
    Protected WithEvents panelVesselPicker As System.Web.UI.WebControls.Panel
    Protected WithEvents drpVesselPicker   As DropDownList
    Protected WithEvents panelCCLContent   As System.Web.UI.WebControls.Panel

    ' Add Reliever modal fields
    Protected WithEvents drpRelieverPick   As DropDownList
    Protected WithEvents btnConfirmReliever As Button

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

    ' Manual Sign-On modal fields (TC-CM-203)
    Protected WithEvents lblSignOnTarget    As Label
    Protected WithEvents btnConfirmSignOn   As Button

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
    Protected WithEvents btnLoadEOC        As Button

    Protected WithEvents divLineupActions As System.Web.UI.HtmlControls.HtmlGenericControl
    Protected WithEvents lblLineupStatus As Label
    Protected WithEvents btnSubmitForPrincipal As Button
    Protected WithEvents btnPrincipalApprove As Button
    Protected WithEvents btnPrincipalReject As Button
    Protected WithEvents btnExportScheduleExcel As Button
    Protected WithEvents btnExportSchedulePdf As Button
    Protected WithEvents btnFinalizeBatch As Button
    Protected WithEvents drpRelChangeType As DropDownList
    Protected WithEvents drpTargetRank As DropDownList
    Protected WithEvents txtPrincipalRejectNotes As TextBox

    Protected WithEvents drpFlightSide As DropDownList
    Protected WithEvents txtAirline As TextBox
    Protected WithEvents txtFlightNo As TextBox
    Protected WithEvents txtPnr As TextBox
    Protected WithEvents txtDepTerm As TextBox
    Protected WithEvents txtArrTerm As TextBox
    Protected WithEvents txtEtd As TextBox
    Protected WithEvents txtEta As TextBox
    Protected WithEvents drpTransitStatus As DropDownList
    Protected WithEvents btnSaveFlight As Button

    Protected WithEvents drpCostSide As DropDownList
    Protected WithEvents drpCostCategory As DropDownList
    Protected WithEvents txtCostAmount As TextBox
    Protected WithEvents drpChargeAccount As DropDownList
    Protected WithEvents txtCostRemarks As TextBox
    Protected WithEvents btnSaveCost As Button

    Protected WithEvents txtBasicWage As TextBox
    Protected WithEvents txtFixedOt As TextBox
    Protected WithEvents txtHourlyOt As TextBox
    Protected WithEvents txtCmdAllow As TextBox
    Protected WithEvents txtTankAllow As TextBox
    Protected WithEvents txtSpecAllow As TextBox
    Protected WithEvents txtLeavePay As TextBox
    Protected WithEvents txtAllotment As TextBox
    Protected WithEvents btnSaveContract As Button
    Protected WithEvents btnPrintContractCoe As Button
    Protected WithEvents hfCostPersonnelId As HiddenField

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

            ' Resolve vessel from query string (may be absent for standalone entry)
            Dim encVslID  As String = If(Request.QueryString("VesselID") IsNot Nothing,
                                         HttpUtility.UrlDecode(Request.QueryString("VesselID")), "")
            Dim vesselIDStr As String = If(Not String.IsNullOrEmpty(encVslID), Decrypt(encVslID), "")

            If Not String.IsNullOrEmpty(vesselIDStr) Then
                ' Arrived from a vessel link — load directly
                hfVesselID.Value = vesselIDStr
                LoadVesselName(CInt(vesselIDStr))
                panelVesselPicker.Visible = False
                panelCCLContent.Visible = True
                LoadCCLGrid()
                LoadSummaryCards()
            Else
                ' Standalone entry — show vessel picker
                panelVesselPicker.Visible = True
                LoadVesselPicker()
            End If

            GetAdmin("Visited CCL", CurrentUserID().ToString(), "CrewChangeList",
                     "VesselID=" & vesselIDStr)

            ' Role-based UI setup
            ApplyRoleVisibility()

            ' Schedules are always created as Tentative; finalizing to Next is a
            ' separate action (Finalize) because it generates the outgoing EOC.
            drpSchedStatus.Items.Clear()
            drpSchedStatus.Items.Add(New ListItem("Tentative", CCLHelper.SCHED_TENTATIVE))
            drpSchedStatus.Enabled = False

            ' Load filter dropdown
            drpFilter.Items.Clear()
            drpFilter.Items.Add(New ListItem("All Crew", ""))
            drpFilter.Items.Add(New ListItem("Onboard Only", "onboard"))
            drpFilter.Items.Add(New ListItem("Pending Approval", "pending"))
            drpFilter.Items.Add(New ListItem("Approved (No Schedule)", "approved"))
            drpFilter.Items.Add(New ListItem("Tentative Schedule", "tentative"))
            drpFilter.Items.Add(New ListItem("Next / Finalized", "next"))

            ' Pre-populate Reliever Dropdown with available crew
            Dim dtRelievers As DataTable = CCLHelper.LoadAvailableRelievers(0, "")
            drpRelieverPick.Items.Clear()
            If dtRelievers IsNot Nothing AndAlso dtRelievers.Rows.Count > 0 Then
                drpRelieverPick.Items.Add(New ListItem("-- Select Reliever --", ""))
                For Each row As DataRow In dtRelievers.Rows
                    Dim text As String = $"{row("crew_name")} ({NullStr(row("rank_code"))})"
                    drpRelieverPick.Items.Add(New ListItem(text, row("id").ToString()))
                Next
            Else
                drpRelieverPick.Items.Add(New ListItem("No available crew found", ""))
            End If

            LoadTargetRanks()
            RefreshLineupStatus()
        End If
    End Sub

    Private Sub LoadTargetRanks()
        drpTargetRank.Items.Clear()
        drpTargetRank.Items.Add(New ListItem("-- Select target rank --", ""))
        Dim dt As DataTable = DbHelper.FillDataTable(
            "SELECT id, rank_code FROM tbl_rank ORDER BY sequence", CommandType.Text)
        For Each row As DataRow In dt.Rows
            drpTargetRank.Items.Add(New ListItem(row("rank_code").ToString(), row("id").ToString()))
        Next
    End Sub

    Private Sub RefreshLineupStatus()
        Dim vid As Integer = GetVesselID()
        If vid <= 0 Then Return
        Dim st As String = CCLHelper.GetLineupSubmissionStatus(vid)
        lblLineupStatus.Text = "Line-Up: " & st
        btnSubmitForPrincipal.Visible = CanSubmitLineupForPrincipal() AndAlso (st = "Draft" OrElse st = "Rejected")
        btnPrincipalApprove.Visible = CanPrincipalApproveLineup() AndAlso st = "Pending Principal"
        btnPrincipalReject.Visible = CanPrincipalApproveLineup() AndAlso st = "Pending Principal"
        If txtPrincipalRejectNotes IsNot Nothing Then
            txtPrincipalRejectNotes.Visible = btnPrincipalReject.Visible
        End If
        btnFinalizeBatch.Visible = CanFinalizeCCL() AndAlso Not IsCCLLineupFrozen(vid)
        btnExportScheduleExcel.Visible = HasInternalStaffAccess() OrElse HasPrincipalAccess()
        btnExportSchedulePdf.Visible = btnExportScheduleExcel.Visible
    End Sub

    ' ════════════════════════════════════════════════════════════
    ' ROLE VISIBILITY
    ' ════════════════════════════════════════════════════════════

    Private Sub ApplyRoleVisibility()
        Dim canAct As Boolean = CanSelectCCLCrew()
        chkSelectAll.Visible   = canAct
        btnBulkSchedule.Visible = canAct
        btnApplyAll.Visible    = canAct
        ' "Apply Changes" has no server handler (every CCL action saves immediately)
        btnApplyChanges.Visible = False
        If divLineupActions IsNot Nothing Then
            divLineupActions.Visible = (GetVesselID() > 0)
        End If
    End Sub

    ' ════════════════════════════════════════════════════════════
    ' VESSEL PICKER (standalone mode — no VesselID querystring)
    ' ════════════════════════════════════════════════════════════

    ''' <summary>
    ''' Populate the vessel picker dropdown with only vessels that have
    ''' at least one ON BOARD (3) or LINE UP (6) crew member.
    ''' This keeps the list focused and operationally relevant.
    ''' </summary>
    Private Sub LoadVesselPicker()
        Dim sql As String =
            "SELECT v.id, v.vesselName " &
            "FROM tbl_vessels v " &
            "WHERE v.active = 'Active' " &
            "  AND EXISTS ( " &
            "      SELECT 1 FROM tbl_personnel_info pi " &
            "      WHERE pi.assigned_vessel_id = v.id " &
            "        AND pi.crew_status IN (3, 6) " &
            "  ) " &
            "ORDER BY v.vesselName"
        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text)
        drpVesselPicker.Items.Clear()
        drpVesselPicker.Items.Add(New ListItem("-- Select a Vessel --", ""))
        For Each row As DataRow In dt.Rows
            drpVesselPicker.Items.Add(New ListItem(
                row("vesselName").ToString(), row("id").ToString()))
        Next
        If dt.Rows.Count = 0 Then
            ShowNotify("No vessels currently have ON BOARD or LINE UP crew.", "info")
        End If
    End Sub

    ''' <summary>
    ''' Handles the vessel picker button click.
    ''' Validates selection, sets hfVesselID, hides the picker, and loads the CCL grid.
    ''' </summary>
    Protected Sub PickVessel_Click(sender As Object, e As EventArgs)
        Dim selectedVesselID As String = drpVesselPicker.SelectedValue
        If String.IsNullOrEmpty(selectedVesselID) Then
            ShowNotify("Please select a vessel to continue.", "warning")
            Return
        End If

        Dim vid As Integer = 0
        If Not Integer.TryParse(selectedVesselID, vid) OrElse vid <= 0 Then
            ShowNotify("Invalid vessel selection.", "danger")
            Return
        End If

        ' Commit selection to hidden field and load data
        hfVesselID.Value = vid.ToString()
        LoadVesselName(vid)
        panelCCLContent.Visible = True
        LoadCCLGrid()
        LoadSummaryCards()

        GetAdmin("Selected Vessel for CCL", CurrentUserID().ToString(), "CrewChangeList",
                 "VesselID=" & vid)
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
                Case "approved"  : dv.RowFilter = "reliever_status = 'Approved' AND (schedule_id IS NULL OR schedule_status = 'Cancelled')"
                Case "tentative" : dv.RowFilter = "schedule_status = 'Tentative'"
                Case "next"      : dv.RowFilter = "schedule_status = 'Next'"
            End Select
            rptCCL.DataSource = dv.ToTable()
        Else
            rptCCL.DataSource = dt
        End If

        rptCCL.DataBind()
        RefreshLineupStatus()
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

            ' Selection exists only to bulk-create schedules, so only rows with an
            ' Approved reliever and no active schedule are selectable.
            Dim isSelectable As Boolean = (relStatus = CCLHelper.RELIEVER_APPROVED AndAlso
                                           (String.IsNullOrEmpty(schedStatus) OrElse schedStatus = CCLHelper.SCHED_CANCELLED) AndAlso
                                           CanSelectCCLCrew())

            chk.Enabled = isSelectable
            If Not isSelectable AndAlso ttip IsNot Nothing Then
                If Not CanSelectCCLCrew() Then
                    ttip.Text = "View only"
                ElseIf crewStatus = 6 Then
                    ttip.Text = "Line Up"
                ElseIf String.IsNullOrEmpty(relStatus) Then
                    ttip.Text = "No reliever"
                ElseIf relStatus = CCLHelper.RELIEVER_PENDING Then
                    ttip.Text = "Pending approval"
                ElseIf relStatus = CCLHelper.RELIEVER_APPROVED AndAlso Not String.IsNullOrEmpty(schedStatus) Then
                    ttip.Text = "Scheduled"
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



    ' ════════════════════════════════════════════════════════════
    ' ADD RELIEVER — CONFIRM
    ' ════════════════════════════════════════════════════════════

    Protected Sub btnConfirmReliever_Click(sender As Object, e As EventArgs) Handles btnConfirmReliever.Click
        Dim outCrewId As Integer = 0
        Dim relCrewId As Integer = 0
        Dim vid       As Integer = GetVesselID()

        Integer.TryParse(hfOutgoingCrewID.Value, outCrewId)
        Integer.TryParse(drpRelieverPick.SelectedValue, relCrewId)
        Dim changeType As String = If(drpRelChangeType IsNot Nothing, drpRelChangeType.SelectedValue, CCLHelper.CHANGE_STANDARD)
        Dim targetRank As Integer = 0
        If drpTargetRank IsNot Nothing Then Integer.TryParse(drpTargetRank.SelectedValue, targetRank)

        If IsCCLLineupFrozen(vid) Then
            ShowNotify("Line-up is frozen while pending or after principal approval.", "warning") : Return
        End If

        If changeType = CCLHelper.CHANGE_PROMO_NO_OFF Then
            relCrewId = outCrewId
        End If

        If outCrewId = 0 OrElse relCrewId = 0 OrElse vid = 0 Then
            ShowNotify("Invalid selection. Please choose a reliever.", "danger")
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "reOpenRel",
                "setTimeout(function(){ var m = document.getElementById('modalAddReliever'); " &
                "if(m) new bootstrap.Modal(m).show(); },100);", True)
            Return
        End If

        If (changeType = CCLHelper.CHANGE_FOR_PROMOTION OrElse changeType = CCLHelper.CHANGE_PROMO_NO_OFF) AndAlso targetRank <= 0 Then
            ShowNotify("Select a target rank for promotion.", "warning") : Return
        End If

        Dim newId As Integer = CCLHelper.CreateReliever(vid, outCrewId, relCrewId, CurrentUserID(), "", changeType, targetRank)
        Select Case newId
            Case -1 : ShowNotify("This crew member already has an active reliever pending or approved.", "warning")
            Case -2 : ShowNotify("The selected reliever is already assigned to another crew change.", "warning")
            Case -3 : ShowNotify("A crew member cannot be their own reliever.", "danger")
            Case -4 : ShowNotify("Target rank is required for promotion.", "warning")
            Case -5 : ShowNotify("Promotion rank eligibility check failed.", "warning")
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
            ShowNotify("Reliever approved. Crew status updated to LINE UP and vessel assigned.", "success")
            LoadCCLGrid()
            LoadSummaryCards()
        Else
            ShowNotify("Approval failed. The reliever may already have been processed, " &
                       "is already ON BOARD, or is assigned to another vessel.", "danger")
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
        If IsCCLLineupFrozen(GetVesselID()) Then
            ShowNotify("Line-up is frozen — cannot modify schedules.", "warning") : Return
        End If

        Dim rid     As Integer = 0
        Dim sid     As Integer = 0
        Dim vid     As Integer = GetVesselID()
        Dim relCrew As Integer = 0
        Integer.TryParse(hfRelieverID.Value, rid)
        Integer.TryParse(hfScheduleID.Value, sid)
        Integer.TryParse(hfRelieverCrewID.Value, relCrew)

        Dim jd As Date, dd As Date, sod As Date
        If Not TryParseInputDate(txtJoiningDate.Text, jd) Then
            ShowNotify("Invalid Joining Date.", "danger") : ReOpenScheduleModal() : Return
        End If
        If Not TryParseInputDate(txtDepartureDate.Text, dd) Then
            ShowNotify("Invalid Departure Date.", "danger") : ReOpenScheduleModal() : Return
        End If
        If Not TryParseInputDate(txtShipOnsign.Text, sod) Then
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

        ' Bulk path: rows ticked in the grid (toolbar "Create Schedule" / "Apply to All").
        ' Used whenever the modal was opened from the toolbar (no single reliever set).
        If sid = 0 AndAlso (chkApplyAll.Checked OrElse rid = 0) Then
            Dim ids As List(Of Integer) = ParseSelectedIDs()
            If ids.Count > 0 Then
                ' Validate the date template once so the user gets a clear message
                Dim tmplErrs As New List(Of String)
                If String.IsNullOrWhiteSpace(dto.JoiningPort) Then tmplErrs.Add("Joining Port is required.")
                If jd < Date.Today Then tmplErrs.Add("Joining Date must be today or a future date.")
                If dd < jd Then tmplErrs.Add("Departure Date must be on or after Joining Date.")
                If sod > jd Then tmplErrs.Add("Ship On-Sign Date must be on or before Joining Date.")
                If tmplErrs.Count > 0 Then
                    ShowNotify(String.Join("<br/>", tmplErrs), "danger") : ReOpenScheduleModal() : Return
                End If

                Dim result As CCLHelper.ApplyResult = CCLHelper.ApplyScheduleToAll(ids, dto)
                Dim msg As String = "Schedule created for " & result.SuccessCount & " crew member(s)."
                If result.SkippedList.Count > 0 Then
                    msg &= " Skipped: " & Server.HtmlEncode(String.Join("; ", result.SkippedList))
                End If
                If result.Errors.Count > 0 Then
                    msg &= " Errors: " & Server.HtmlEncode(String.Join("; ", result.Errors))
                End If
                GetAdmin("Bulk Created CCL Schedule", CurrentUserID().ToString(), "CrewChangeList",
                         "Count=" & result.SuccessCount)
                ShowNotify(msg, If(result.SuccessCount > 0, "success", "warning"))
                LoadCCLGrid()
                LoadSummaryCards()
                Return
            ElseIf rid = 0 Then
                ShowNotify("No eligible crew selected. Only rows with an Approved reliever and no active schedule can be scheduled.", "warning")
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
    ' MANUAL SIGN-ON — TC-CM-203
    ' ════════════════════════════════════════════════════════════

    Protected Sub btnConfirmSignOn_Click(sender As Object, e As EventArgs) Handles btnConfirmSignOn.Click
        If Not CanAddReliever() Then
            ShowNotify("You do not have permission to record a manual sign-on.", "danger") : Return
        End If
        Dim sid As Integer = 0
        Integer.TryParse(hfScheduleID.Value, sid)
        If sid = 0 Then ShowNotify("Invalid schedule ID.", "danger") : Return

        Dim result As Integer = CCLHelper.ManualSignOn(sid, CurrentUserID(), CurrentRole())
        Select Case result
            Case 0
                GetAdmin("Manual Sign-On", CurrentUserID().ToString(), "CrewChangeList",
                         "ScheduleID=" & sid)
                ShowNotify("Manual sign-on recorded. Crew status updated to ON BOARD. " &
                           "No other automatic changes were applied.", "success")
                LoadCCLGrid()
                LoadSummaryCards()
            Case -2
                ShowNotify("Access denied: your role cannot perform a manual sign-on.", "danger")
            Case -3
                ShowNotify("Sign-on blocked: this crew member already has an active assignment on a different vessel.", "danger")
            Case Else
                ShowNotify("Sign-on failed. The schedule may already be signed on or is no longer in Next status.", "danger")
        End Select
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
            ShowNotify("Amendment failed. A schedule cannot be reverted after the reliever has signed on.", "danger")
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
            ShowNotify("Cancellation failed. A schedule cannot be cancelled after the reliever has signed on.", "danger")
        End If
    End Sub

    ' ════════════════════════════════════════════════════════════
    ' EOC PREVIEW
    ' ════════════════════════════════════════════════════════════

    Protected Sub btnLoadEOC_Click(sender As Object, e As EventArgs) Handles btnLoadEOC.Click
        LoadEOCPreview()
        LoadCCLGrid()
        LoadSummaryCards()
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "openEOC",
            "setTimeout(function(){ var m = document.getElementById('modalEOC'); " &
            "if(m) new bootstrap.Modal(m).show(); },100);", True)
    End Sub

    Protected Sub LoadEOCPreview()
        Dim eocId As Integer = 0
        Integer.TryParse(hfEocID.Value, eocId)
        If eocId = 0 Then Return

        Dim row As DataRow = CCLHelper.LoadEOCDetails(eocId)
        If row Is Nothing Then Return

        lblEocCrew.Text      = Server.HtmlEncode(row("crew_name").ToString())
        lblEocRank.Text      = Server.HtmlEncode(NullStr(row("rank_code")))
        lblEocVessel.Text    = Server.HtmlEncode(row("vesselName").ToString())
        lblEocSignOn.Text    = If(IsDBNull(row("sign_on_date")), "N/A",
                                  CDate(row("sign_on_date")).ToString("MMM dd, yyyy"))
        lblEocSignOff.Text   = If(IsDBNull(row("sign_off_date")), "N/A",
                                  CDate(row("sign_off_date")).ToString("MMM dd, yyyy"))
        lblEocPort.Text      = Server.HtmlEncode(row("joining_port").ToString())
        lblEocStatus.Text    = Server.HtmlEncode(row("eoc_status").ToString())
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

    ''' <summary>Culture-invariant parse of HTML5 date inputs (yyyy-MM-dd), with fallback.</summary>
    Private Function TryParseInputDate(s As String, ByRef result As Date) As Boolean
        If String.IsNullOrWhiteSpace(s) Then Return False
        If Date.TryParseExact(s.Trim(), "yyyy-MM-dd",
                              System.Globalization.CultureInfo.InvariantCulture,
                              System.Globalization.DateTimeStyles.None, result) Then Return True
        Return Date.TryParse(s.Trim(), System.Globalization.CultureInfo.InvariantCulture,
                             System.Globalization.DateTimeStyles.None, result)
    End Function

    ''' <summary>yyyy-MM-dd for HTML5 date inputs (used by Edit Schedule).</summary>
    Protected Function IsoDate(val As Object) As String
        If val Is Nothing OrElse IsDBNull(val) Then Return ""
        Try
            Return CDate(val).ToString("yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture)
        Catch
            Return ""
        End Try
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

    Protected Function BuildFlightStatusBadge(status As String) As String
        If String.IsNullOrEmpty(status) Then
            Return "<span style='color:#94a3b8;font-size:12px;'>&#8212;</span>"
        End If
        Select Case status
            Case "Booked" : Return "<span class='badge-ccl badge-tentative'>Booked</span>"
            Case "In-Transit" : Return "<span class='badge-ccl badge-next'>In-Transit</span>"
            Case "Landed" : Return "<span class='badge-ccl badge-approved'>Landed</span>"
            Case "Delayed" : Return "<span class='badge-ccl badge-rejected'>Delayed</span>"
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
    ''' TC-CM-203: Added signedOnAt parameter to suppress the Sign On button once already used.
    ''' </summary>
    Protected Function BuildRowActions(crewId As Integer,
                                       crewStatus As Integer,
                                       relieverId As Integer,
                                       relieverStatus As String,
                                       scheduleId As Integer,
                                       scheduleStatus As String,
                                       eocId As Integer,
                                       relieverCrewId As Integer,
                                       Optional signedOnAt As Object = Nothing) As String
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
                      "onclick=""openAddReliever(this)"" title='Assign Reliever'>" &
                      "Reliever</button>")
            sb.Append("<button type='button' class='btn-ccl-act purple' " &
                      "onclick=""openAddRelieverPromo(this)"" title='Promotion without off-signer'>" &
                      "Promote</button>")
        End If

        ' Approve / Reject — if Pending Approval
        If relieverStatus = CCLHelper.RELIEVER_PENDING AndAlso canApprv Then
            sb.Append("<button type='button' class='btn-ccl-act green' " &
                      "onclick=""openApproval(this)""  title='Approve / Reject Reliever'>" &
                      "Approve</button>")
        End If

        ' Create Schedule — if Approved and no active schedule
        If relieverStatus = CCLHelper.RELIEVER_APPROVED AndAlso (scheduleId = 0 OrElse scheduleStatus = CCLHelper.SCHED_CANCELLED) AndAlso canAct Then
            sb.Append("<button type='button' class='btn-ccl-act blue' " &
                      "onclick=""openCreateSchedule(this)""  title='Create CCL Schedule'>" &
                      "Schedule</button>")
        End If

        ' Edit Schedule — if Tentative (dates are read from the row's data-* attributes)
        If scheduleStatus = CCLHelper.SCHED_TENTATIVE AndAlso canAct Then
            sb.Append("<button type='button' class='btn-ccl-act purple' " &
                      "onclick=""openEditSchedule(this)""  title='Edit Schedule'>" &
                      "Edit</button>")
            ' Finalize — Tentative → Next
            If canFinal Then
                sb.Append("<button type='button' class='btn-ccl-act blue' " &
                          "onclick=""openFinalize(this)""  title='Finalize to Next'>" &
                          "Finalize</button>")
            End If
        End If

        Dim alreadySignedOn As Boolean = (signedOnAt IsNot Nothing AndAlso
                                          signedOnAt IsNot DBNull.Value AndAlso
                                          signedOnAt.ToString() <> "")

        ' TC-CM-203: Manual Sign-On — shown for Next schedules not yet signed on
        ' Only Manning/Documentation/Admin staff can perform this (Principals excluded)
        If scheduleStatus = CCLHelper.SCHED_NEXT AndAlso canAct Then
            If Not alreadySignedOn Then
                sb.Append("<button type='button' class='btn-ccl-act green' " &
                          "onclick=""openSignOn(this,'" & scheduleId.ToString() & "')""  title='Record Manual Sign-On (TC-CM-203)'>Sign On</button>")
            Else
                sb.Append("<span class='badge-ccl badge-completed' title='Already signed on'>Signed On</span>")
            End If
        End If

        ' Amend / Cancel — if Next (Admin only) and the reliever has not yet signed on
        If scheduleStatus = CCLHelper.SCHED_NEXT AndAlso canAmend AndAlso Not alreadySignedOn Then
            sb.Append("<button type='button' class='btn-ccl-act orange' " &
                      "onclick=""openAmend(this)""  title='Amend / Cancel Schedule'>" &
                      "Amend</button>")
        End If

        If scheduleId > 0 AndAlso canAct Then
            sb.Append("<button type='button' class='btn-ccl-act blue' onclick=""openFlight(this)"" title='Flight details'>Flights</button>")
            sb.Append("<button type='button' class='btn-ccl-act orange' onclick=""openCost(this)"" title='Deployment costs'>Costs</button>")
            sb.Append("<button type='button' class='btn-ccl-act purple' onclick=""openContract(this)"" title='Contract wages / COE'>Terms</button>")
        End If

        ' View EOC — if EOC generated
        If eocId > 0 Then
            sb.Append("<button type='button' class='btn-ccl-act teal' " &
                      "onclick=""openEOC(this)""  title='View EOC Record'>" &
                      "EOC</button>")
        End If

        If sb.Length = 0 Then
            sb.Append("<span style='color:#94a3b8;font-size:12px;'>—</span>")
        End If

        Return sb.ToString()
    End Function

    Protected Sub btnSubmitForPrincipal_Click(sender As Object, e As EventArgs) Handles btnSubmitForPrincipal.Click
        Dim vid As Integer = GetVesselID()
        If vid <= 0 Then Return
        If CCLHelper.SubmitLineupForPrincipal(vid, CurrentUserID()) Then
            ShowNotify("Line-up submitted to Principal for approval.", "success")
            RefreshLineupStatus()
        Else
            ShowNotify("Could not submit — line-up may already be pending or frozen.", "warning")
        End If
    End Sub

    Protected Sub btnPrincipalApprove_Click(sender As Object, e As EventArgs) Handles btnPrincipalApprove.Click
        Dim vid As Integer = GetVesselID()
        If CCLHelper.PrincipalReviewLineup(vid, True, CurrentUserID()) Then
            ShowNotify("Line-up approved by Principal.", "success")
            RefreshLineupStatus()
        Else
            ShowNotify("Approval failed — no pending submission found.", "danger")
        End If
    End Sub

    Protected Sub btnPrincipalReject_Click(sender As Object, e As EventArgs) Handles btnPrincipalReject.Click
        Dim notes As String = If(txtPrincipalRejectNotes IsNot Nothing, txtPrincipalRejectNotes.Text.Trim(), "")
        If String.IsNullOrEmpty(notes) Then
            ShowNotify("Provide rejection notes.", "warning") : Return
        End If
        Dim vid As Integer = GetVesselID()
        If CCLHelper.PrincipalReviewLineup(vid, False, CurrentUserID(), notes) Then
            ShowNotify("Line-up disapproved. Manning staff may revise and resubmit.", "info")
            RefreshLineupStatus()
        Else
            ShowNotify("Rejection failed.", "danger")
        End If
    End Sub

    Protected Sub btnFinalizeBatch_Click(sender As Object, e As EventArgs) Handles btnFinalizeBatch.Click
        If Not CanFinalizeCCL() Then Return
        Dim vid As Integer = GetVesselID()
        If IsCCLLineupFrozen(vid) Then
            ShowNotify("Finalize batch is blocked while line-up is frozen.", "warning") : Return
        End If
        Dim dt As DataTable = CCLHelper.LoadCCLData(vid)
        Dim ids As New List(Of Integer)
        For Each row As DataRow In dt.Rows
            If Not IsDBNull(row("schedule_id")) AndAlso NullStr(row("schedule_status")) = CCLHelper.SCHED_TENTATIVE Then
                ids.Add(CInt(row("schedule_id")))
            End If
        Next
        If ids.Count = 0 Then
            ShowNotify("No Tentative schedules to finalize.", "info") : Return
        End If
        Dim result As CCLHelper.ApplyResult = CCLHelper.FinalizeBatch(ids, CurrentUserID())
        If result.IsSuccess Then
            GetAdmin("CCL Batch Finalize", CurrentUserID().ToString(), "CrewChangeList", "Count=" & result.SuccessCount.ToString())
            ShowNotify("Batch finalized " & result.SuccessCount.ToString() & " schedule(s); contracts updated.", "success")
            LoadCCLGrid()
            LoadSummaryCards()
            RefreshLineupStatus()
        Else
            ShowNotify(String.Join("<br/>", result.Errors), "danger")
        End If
    End Sub

    Protected Sub btnExportScheduleExcel_Click(sender As Object, e As EventArgs) Handles btnExportScheduleExcel.Click
        Dim vid As Integer = GetVesselID()
        If vid <= 0 Then Return
        ExportHelper.ExportToExcel(CCLHelper.BuildCCLExportTable(vid),
            "CCL-Vessel-" & vid.ToString() & ".xlsx", "Crew Change Matrix", Response)
    End Sub

    Protected Sub btnExportSchedulePdf_Click(sender As Object, e As EventArgs) Handles btnExportSchedulePdf.Click
        Dim vid As Integer = GetVesselID()
        If vid <= 0 Then Return
        Response.Redirect("~/Crew/Print.aspx?printType=CCLMatrix&VesselID=" &
            HttpUtility.UrlEncode(Encrypt(vid.ToString())), True)
    End Sub

    Protected Sub btnSaveFlight_Click(sender As Object, e As EventArgs) Handles btnSaveFlight.Click
        Dim sid As Integer = 0
        Dim pid As Integer = 0
        Integer.TryParse(hfScheduleID.Value, sid)
        Integer.TryParse(hfRelieverCrewID.Value, pid)
        If sid <= 0 OrElse pid <= 0 Then ShowNotify("Invalid flight context.", "danger") : Return
        Dim etd As Date? = Nothing
        Dim eta As Date? = Nothing
        Dim etdD As Date
        Dim etaD As Date
        If Date.TryParse(txtEtd.Text, etdD) Then etd = etdD
        If Date.TryParse(txtEta.Text, etaD) Then eta = etaD
        CCLHelper.SaveFlightBooking(sid, GetVesselID(), pid, drpFlightSide.SelectedValue,
            txtAirline.Text.Trim(), txtFlightNo.Text.Trim(), txtPnr.Text.Trim(),
            txtDepTerm.Text.Trim(), txtArrTerm.Text.Trim(), etd, eta, drpTransitStatus.SelectedValue)
        ShowNotify("Flight details saved.", "success")
        LoadCCLGrid()
    End Sub

    Protected Sub btnSaveCost_Click(sender As Object, e As EventArgs) Handles btnSaveCost.Click
        Dim sid As Integer = 0
        Dim pid As Integer = 0
        Integer.TryParse(hfScheduleID.Value, sid)
        If hfCostPersonnelId IsNot Nothing Then Integer.TryParse(hfCostPersonnelId.Value, pid)
        If pid <= 0 Then Integer.TryParse(hfRelieverCrewID.Value, pid)
        If pid <= 0 Then ShowNotify("Invalid cost context.", "danger") : Return
        Dim amt As Decimal = 0
        If Not Decimal.TryParse(txtCostAmount.Text.Trim(), amt) Then
            ShowNotify("Enter a valid amount.", "warning") : Return
        End If
        CCLHelper.SaveDeploymentCost(GetVesselID(), sid, pid, drpCostSide.SelectedValue,
            drpCostCategory.SelectedValue, amt, drpChargeAccount.SelectedValue,
            txtCostRemarks.Text.Trim(), CurrentUserID())
        ShowNotify("Deployment cost recorded.", "success")
    End Sub

    Protected Sub btnSaveContract_Click(sender As Object, e As EventArgs) Handles btnSaveContract.Click
        Dim sid As Integer = 0
        Integer.TryParse(hfScheduleID.Value, sid)
        If sid <= 0 Then Return
        Dim bw As Decimal = ParseDec(txtBasicWage.Text)
        CCLHelper.SaveContractFinancial(sid, bw, ParseDec(txtFixedOt.Text), ParseDec(txtHourlyOt.Text),
            ParseDec(txtCmdAllow.Text), ParseDec(txtTankAllow.Text), ParseDec(txtSpecAllow.Text),
            ParseDec(txtLeavePay.Text), ParseDec(txtAllotment.Text), CurrentUserID())
        ShowNotify("Contract financial terms saved.", "success")
    End Sub

    Protected Sub btnPrintContractCoe_Click(sender As Object, e As EventArgs) Handles btnPrintContractCoe.Click
        Dim sid As Integer = 0
        Integer.TryParse(hfScheduleID.Value, sid)
        If sid <= 0 Then Return
        Response.Redirect("~/Personnel/CCLContractCOE.aspx?ScheduleID=" &
            HttpUtility.UrlEncode(Encrypt(sid.ToString())), True)
    End Sub

    Private Function ParseDec(raw As String) As Decimal
        Dim v As Decimal = 0
        Decimal.TryParse(raw.Trim(), v)
        Return v
    End Function

    Private Function GetCrewNameFromGrid() As String
        Return ""   ' Name is passed from client-side data attributes
    End Function

    Private Function JsEsc(s As String) As String
        If String.IsNullOrEmpty(s) Then Return ""
        Return s.Replace("'", "\\'").Replace("""", "&quot;")
    End Function

End Class
