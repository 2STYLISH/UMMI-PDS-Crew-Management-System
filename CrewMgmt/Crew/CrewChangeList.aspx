<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="CrewChangeList.aspx.vb"
    Inherits="CrewChangeList" Title="Change Crew List" MaintainScrollPositionOnPostback="true" %>

<asp:Content ContentPlaceHolderID="HeadContent" runat="server">
<style>
/* ── CCL-specific additions only — all else uses site.css system classes ── */

/* Stat grid row */
.ccl-stat-row { display:flex; gap:14px; flex-wrap:wrap; margin-bottom:18px; }
.ccl-stat-row .stat-card { flex:1; min-width:140px; cursor:default; }

/* CCL status badges — extend system .badge */
.badge-ccl-reliever  { background:#EDE9FE; color:#5b21b6; }
.badge-ccl-pending   { background:#FEF9C3; color:#854d0e; }
.badge-ccl-approved  { background:#DCFCE7; color:#166534; }
.badge-ccl-rejected  { background:#FEE2E2; color:#991b1b; }
.badge-ccl-tentative { background:#F3E8FF; color:#6d28d9; }
.badge-ccl-next      { background:#CFFAFE; color:#0e7490; }
.badge-ccl-completed { background:#DCFCE7; color:#15803d; }
.badge-ccl-cancelled { background:#F1F5F9; color:#64748b; }
.badge-ccl-eoc-gen   { background:#CCFBF1; color:#065f46; }
.badge-ccl-eoc-no    { background:#F1F5F9; color:#94a3b8; }
.badge-ccl-eoc-sup   { background:#FEF3C7; color:#92400e; }

/* Row-action micro-links (similar to .gv-link but colored) */
.ccl-act { display:inline-flex;align-items:center;gap:4px;font-size:12px;font-weight:500;
    padding:3px 9px;border-radius:6px;cursor:pointer;border:1px solid transparent;
    transition:background .12s,border-color .12s;white-space:nowrap;font-family:var(--font); }
.ccl-act-green  { background:#dcfce7;color:#166534;border-color:#bbf7d0; }
.ccl-act-green:hover  { background:#bbf7d0; }
.ccl-act-blue   { background:#dbeafe;color:#1e40af;border-color:#bfdbfe; }
.ccl-act-blue:hover   { background:#bfdbfe; }
.ccl-act-purple { background:#ede9fe;color:#5b21b6;border-color:#ddd6fe; }
.ccl-act-purple:hover { background:#ddd6fe; }
.ccl-act-amber  { background:#ffedd5;color:#9a3412;border-color:#fed7aa; }
.ccl-act-amber:hover  { background:#fed7aa; }
.ccl-act-teal   { background:#ccfbf1;color:#065f46;border-color:#99f6e4; }
.ccl-act-teal:hover   { background:#99f6e4; }

/* Crew/Reliever cell */
.crew-name   { font-weight:600;color:#111827; }
.crew-rank   { font-size:11px;color:#64748b; }
.rel-name    { font-size:12px;font-weight:600;color:#111827; }
.rel-rank    { font-size:11px;color:#64748b; }
.ineligible-tip { font-size:10px;color:#94a3b8;font-style:italic; }

/* Selection counter badge */
.ccl-sel-badge { background:#EFF6FF;color:#1d4ed8;border-radius:9999px;
    padding:2px 10px;font-size:12px;font-weight:600;display:none; }
.ccl-sel-badge.visible { display:inline-block; }

/* Row-actions container */
.ccl-row-actions { display:flex;gap:4px;flex-wrap:wrap; }

/* Modal accent header */
.modal-header-ccl { background:linear-gradient(135deg,#1E3A5F,#2563EB); }
.modal-header-ccl .modal-title { color:#fff; }
.modal-header-ccl .btn-close    { filter:invert(1) brightness(2); }

/* Info rows in EOC modal */
.info-row { display:flex;justify-content:space-between;align-items:center;
    padding:8px 0;border-bottom:1px solid #E2E8F0; }
.info-row:last-child { border-bottom:none; }
.info-lbl { color:#64748b;font-size:12px; }
.info-val  { font-weight:600;font-size:13px;color:#111827; }

@media(max-width:768px){
    .ccl-stat-row { flex-direction:column; }
    .ccl-stat-row .stat-card { min-width:auto; }
}
</style>
</asp:Content>

<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

<%-- Hidden fields --%>
<asp:HiddenField ID="hfVesselID"       runat="server" />
<asp:HiddenField ID="hfAction"         runat="server" />
<asp:HiddenField ID="hfRelieverID"     runat="server" />
<asp:HiddenField ID="hfScheduleID"     runat="server" />
<asp:HiddenField ID="hfOutgoingCrewID" runat="server" />
<asp:HiddenField ID="hfRelieverCrewID" runat="server" />
<asp:HiddenField ID="hfEocID"          runat="server" />
<asp:HiddenField ID="hfSelectedIDs"    runat="server" />

<div class="fade-in">

<%-- Page Header --%>
<h2 style="font-size:20px;font-weight:700;color:#1a2744;margin-bottom:4px;">
    <i class="fa fa-arrows-rotate me-2 text-primary"></i>Change Crew List
</h2>
<p style="font-size:13px;color:#64748b;margin-bottom:16px;">
    <i class="fa fa-ship me-1"></i>
    <asp:Label ID="lblVesselName" runat="server" Text="All Vessels" />
</p>

<%-- Notification --%>
<asp:Label ID="lblNotify" runat="server" Text="" />

<%-- Summary Cards — uses system .stat-card pattern --%>
<div class="ccl-stat-row">
    <div class="stat-card">
        <div class="stat-icon stat-icon--blue"><i class="fa fa-ship"></i></div>
        <div class="stat-info">
            <div class="stat-value"><asp:Label ID="lblCntOnboard"   runat="server" Text="0" /></div>
            <div class="stat-label">Onboard</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon stat-icon--amber"><i class="fa fa-clock"></i></div>
        <div class="stat-info">
            <div class="stat-value"><asp:Label ID="lblCntPending"   runat="server" Text="0" /></div>
            <div class="stat-label">Pending Approval</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon stat-icon--green"><i class="fa fa-check"></i></div>
        <div class="stat-info">
            <div class="stat-value"><asp:Label ID="lblCntNoSched"   runat="server" Text="0" /></div>
            <div class="stat-label">Approved / No Schedule</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon stat-icon--purple"><i class="fa fa-calendar-days"></i></div>
        <div class="stat-info">
            <div class="stat-value"><asp:Label ID="lblCntTentative" runat="server" Text="0" /></div>
            <div class="stat-label">Tentative</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon stat-icon--navy"><i class="fa fa-flag-checkered"></i></div>
        <div class="stat-info">
            <div class="stat-value"><asp:Label ID="lblCntNext"      runat="server" Text="0" /></div>
            <div class="stat-label">Next / Finalized</div>
        </div>
    </div>
</div>

<%-- Main Card --%>
<div class="card">
    <div class="card-header-ummi" style="justify-content:space-between;">
        <span><i class="fa fa-list-check"></i> Crew Change Management</span>
        <asp:DropDownList ID="drpFilter" runat="server" CssClass="form-control-ummi"
            style="width:auto;height:32px;font-size:12px;padding:0 8px;"
            AutoPostBack="true" OnSelectedIndexChanged="drpFilter_SelectedIndexChanged" />
    </div>

    <%-- Toolbar --%>
    <div style="display:flex;align-items:center;gap:8px;padding:10px 16px;border-bottom:1px solid #E2E8F0;flex-wrap:wrap;">
        <div style="display:flex;align-items:center;gap:8px;flex:1;">
            <asp:CheckBox ID="chkSelectAll" runat="server" title="Select All Eligible" />
            <span id="spanSelCount" class="ccl-sel-badge">0 selected</span>
            <asp:Button ID="btnBulkSchedule" runat="server" Text="&#xF073; Create Schedule"
                CssClass="btn-ummi-primary btn-sm"
                OnClientClick="return validateSelected('modalSchedule');"
                UseSubmitBehavior="false" />
            <asp:Button ID="btnApplyAll" runat="server" Text="&#xF0C5; Apply to All"
                CssClass="btn-ummi-secondary btn-sm"
                OnClientClick="return applyAllClick();"
                UseSubmitBehavior="false" />
        </div>
        <div>
            <asp:Button ID="btnApplyChanges" runat="server" Text="&#xF0C7; Apply Changes"
                CssClass="btn-ummi-primary"
                UseSubmitBehavior="true" />
        </div>
    </div>

    <%-- CCL Grid --%>
    <div class="table-responsive">
    <table class="ummi-table" id="tblCCL">
        <thead>
            <tr>
                <th style="width:36px;text-align:center;">
                    <asp:CheckBox ID="chkAllHeader" runat="server" CssClass="chk-all-header" />
                </th>
                <th>Rank / Crew</th>
                <th>Status</th>
                <th>Reliever</th>
                <th>Reliever Status</th>
                <th>Joining Date</th>
                <th>Joining Port</th>
                <th>Departure</th>
                <th>Ship On-Sign</th>
                <th>Schedule</th>
                <th>EOC</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            <asp:Repeater ID="rptCCL" runat="server" OnItemDataBound="rptCCL_ItemDataBound">
                <ItemTemplate>
                    <tr data-crew-id="<%# Eval("crew_id") %>"
                        data-reliever-id="<%# NullInt(Eval("reliever_record_id")) %>"
                        data-schedule-id="<%# NullInt(Eval("schedule_id")) %>"
                        data-eoc-id="<%# NullInt(Eval("eoc_id")) %>"
                        data-reliever-crew="<%# NullInt(Eval("reliever_crew_id")) %>">

                        <td style="text-align:center;width:36px;">
                            <asp:CheckBox ID="chkRow" runat="server" CssClass="ccl-row-chk" Enabled="false" />
                            <asp:Label ID="lblIneligible" runat="server" CssClass="ineligible-tip" Text="" Visible="false" />
                        </td>
                        <td>
                            <div class="crew-name"><%# HE(Eval("crew_name")) %></div>
                            <div class="crew-rank"><%# HE(Eval("rank_code")) %></div>
                        </td>
                        <td><%# BuildCrewStatusBadge(NullInt(Eval("crew_status")), NullStr(Eval("crew_status_text"))) %></td>
                        <td><%# BuildRelieverCell(Eval("reliever_name"), Eval("reliever_rank")) %></td>
                        <td><%# BuildRelieverStatusBadge(NullStr(Eval("reliever_status"))) %></td>
                        <td><%# BuildDateCell(Eval("joining_date")) %></td>
                        <td><%# BuildTextCell(Eval("joining_port")) %></td>
                        <td><%# BuildDateCell(Eval("departure_date")) %></td>
                        <td><%# BuildDateCell(Eval("ship_onsign_date")) %></td>
                        <td><%# BuildScheduleStatusBadge(NullStr(Eval("schedule_status"))) %></td>
                        <td><%# BuildEocStatusBadge(NullStr(Eval("eoc_status"))) %></td>
                        <td style="min-width:160px;">
                            <div class="ccl-row-actions">
                                <%# BuildRowActions(NullInt(Eval("crew_id")), NullInt(Eval("crew_status")), NullInt(Eval("reliever_record_id")), NullStr(Eval("reliever_status")), NullInt(Eval("schedule_id")), NullStr(Eval("schedule_status")), NullInt(Eval("eoc_id")), NullInt(Eval("reliever_crew_id"))) %>
                            </div>
                        </td>
                    </tr>
                </ItemTemplate>
                <FooterTemplate></FooterTemplate>
            </asp:Repeater>
        </tbody>
    </table>
    </div>
</div>

<%-- Back link --%>
<div style="margin-top:12px;">
    <a href="<%= ResolveUrl("~/Crew/QueryCrew.aspx") %>" class="gv-link">
        <i class="fa fa-arrow-left"></i> Back to Crew Search
    </a>
</div>

</div><%-- /fade-in --%>

<%-- ══════════════════════════════════════════════════════
     MODAL 1 — ADD RELIEVER
     ══════════════════════════════════════════════════════ --%>
<div class="modal fade" id="modalAddReliever" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header modal-header-ccl">
        <h5 class="modal-title"><i class="fa fa-user-plus me-2"></i>Add Reliever</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div style="background:#F8FAFC;border:1px solid #E2E8F0;border-radius:8px;padding:10px 14px;margin-bottom:12px;font-size:13px;">
            <strong>Outgoing Crew:</strong> <span id="spanOutgoingName">&#8212;</span>
            &nbsp;&nbsp;<strong>Rank:</strong> <span id="spanOutgoingRank">&#8212;</span>
        </div>
        <div class="row g-2 mb-3">
            <div class="col-md-8">
                <label class="form-label-ummi">Search by Name or Rank</label>
                <asp:TextBox ID="txtRelieverSearch" runat="server" CssClass="form-control-ummi"
                    placeholder="e.g. Santos, Chief Officer..." />
            </div>
            <div class="col-md-4 d-flex align-items-end">
                <asp:Button ID="btnSearchReliever" runat="server" Text="Search"
                    CssClass="btn-ummi-primary w-100" OnClick="btnSearchReliever_Click" />
            </div>
        </div>
        <label class="form-label-ummi">Select Reliever</label>
        <asp:DropDownList ID="drpRelieverPick" runat="server" CssClass="form-control-ummi">
            <asp:ListItem Text="-- Search to populate --" Value="" />
        </asp:DropDownList>
        <p style="font-size:11px;color:#64748b;margin-top:6px;">
            <i class="fa fa-circle-info me-1"></i>
            Only active, available crew with no current vessel assignment are shown.
        </p>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
        <asp:Button ID="btnConfirmReliever" runat="server" Text="Assign Reliever"
            CssClass="btn-ummi-primary" OnClick="btnConfirmReliever_Click"
            OnClientClick="return confirmRelieverAssign();" />
      </div>
    </div>
  </div>
</div>

<%-- ══════════════════════════════════════════════════════
     MODAL 2 — CCL SCHEDULE
     ══════════════════════════════════════════════════════ --%>
<div class="modal fade" id="modalSchedule" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header modal-header-ccl">
        <h5 class="modal-title" id="schedModalTitle"><i class="fa fa-calendar-plus me-2"></i>Create CCL Schedule</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div style="background:#F8FAFC;border:1px solid #E2E8F0;border-radius:8px;padding:10px 14px;margin-bottom:14px;font-size:13px;">
            <asp:Label ID="lblSchedTarget" runat="server" Text="No crew selected." />
        </div>
        <div class="row g-3">
            <div class="col-md-6">
                <label class="form-label-ummi">Joining Date <span style="color:#dc2626;">*</span></label>
                <asp:TextBox ID="txtJoiningDate" runat="server" CssClass="form-control-ummi" TextMode="Date" />
                <p style="font-size:11px;color:#64748b;margin-top:3px;">Must be today or a future date.</p>
            </div>
            <div class="col-md-6">
                <label class="form-label-ummi">Joining Port <span style="color:#dc2626;">*</span></label>
                <asp:TextBox ID="txtJoiningPort" runat="server" CssClass="form-control-ummi"
                    placeholder="e.g. Manila, Singapore..." MaxLength="200" />
            </div>
            <div class="col-md-6">
                <label class="form-label-ummi">Departure Date <span style="color:#dc2626;">*</span></label>
                <asp:TextBox ID="txtDepartureDate" runat="server" CssClass="form-control-ummi" TextMode="Date" />
                <p style="font-size:11px;color:#64748b;margin-top:3px;">Must be on or after Joining Date.</p>
            </div>
            <div class="col-md-6">
                <label class="form-label-ummi">Ship On-Sign Date <span style="color:#dc2626;">*</span></label>
                <asp:TextBox ID="txtShipOnsign" runat="server" CssClass="form-control-ummi" TextMode="Date" />
                <p style="font-size:11px;color:#64748b;margin-top:3px;">Must be on or before Joining Date.</p>
            </div>
            <div class="col-md-6">
                <label class="form-label-ummi">Schedule Status</label>
                <asp:DropDownList ID="drpSchedStatus" runat="server" CssClass="form-control-ummi" />
            </div>
        </div>

        <%-- Apply All section --%>
        <div id="divApplyAll" style="display:none;margin-top:14px;background:#EFF6FF;border:1px solid #BFDBFE;border-radius:8px;padding:12px;">
            <div style="display:flex;align-items:center;gap:8px;">
                <asp:CheckBox ID="chkApplyAll" runat="server" CssClass="form-check-input" />
                <span style="font-size:13px;font-weight:600;color:#1e40af;">
                    Apply these dates to all <span id="spanApplyCount">0</span> selected crew members
                </span>
            </div>
            <p style="font-size:11px;color:#64748b;margin:6px 0 0 24px;">
                <i class="fa fa-circle-info me-1"></i>
                Ineligible crew (e.g. not yet approved) will be skipped automatically.
            </p>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
        <asp:Button ID="btnSaveSchedule" runat="server" Text="&#xF0C7; Save Schedule"
            CssClass="btn-ummi-primary" OnClick="btnSaveSchedule_Click"
            OnClientClick="return validateScheduleForm();" />
      </div>
    </div>
  </div>
</div>

<%-- ══════════════════════════════════════════════════════
     MODAL 3 — APPROVE / REJECT RELIEVER
     ══════════════════════════════════════════════════════ --%>
<div class="modal fade" id="modalApproval" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header modal-header-ccl">
        <h5 class="modal-title"><i class="fa fa-user-check me-2"></i>Reliever Approval</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div style="background:#F8FAFC;border:1px solid #E2E8F0;border-radius:8px;padding:12px;margin-bottom:12px;font-size:13px;">
            <asp:Label ID="lblApprovalTarget" runat="server" Text="" />
        </div>
        <label class="form-label-ummi">Remarks <span style="color:#64748b;font-weight:400;">(required for rejection)</span></label>
        <asp:TextBox ID="txtApprovalRemarks" runat="server" CssClass="form-control-ummi"
            TextMode="MultiLine" Rows="3" MaxLength="500"
            placeholder="Optional for approval. Required for rejection." />
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
        <asp:Button ID="btnConfirmReject" runat="server" Text="Reject"
            CssClass="btn btn-danger" OnClick="btnConfirmReject_Click"
            OnClientClick="return confirm('Confirm rejection of this reliever?');" />
        <asp:Button ID="btnConfirmApprove" runat="server" Text="&#xF00C; Approve"
            CssClass="btn-ummi-primary" OnClick="btnConfirmApprove_Click"
            OnClientClick="return confirm('Confirm approval of this reliever?');" />
      </div>
    </div>
  </div>
</div>

<%-- ══════════════════════════════════════════════════════
     MODAL 4 — FINALIZE SCHEDULE
     ══════════════════════════════════════════════════════ --%>
<div class="modal fade" id="modalFinalize" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header modal-header-ccl">
        <h5 class="modal-title"><i class="fa fa-flag-checkered me-2"></i>Finalize Schedule</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div style="background:#F8FAFC;border:1px solid #E2E8F0;border-radius:8px;padding:12px;margin-bottom:12px;font-size:13px;">
            <asp:Label ID="lblFinalizeTarget" runat="server" Text="" />
        </div>
        <div class="alert alert-warning">
            <i class="fa fa-triangle-exclamation"></i>
            <div>
                <strong>Finalization will:</strong>
                <ul style="margin:6px 0 0;padding-left:18px;font-size:13px;">
                    <li>Lock the schedule to <strong>NEXT</strong> status</li>
                    <li>Auto-generate an <strong>EOC</strong> for the outgoing crew</li>
                    <li>Only Admin can revert or cancel afterward</li>
                </ul>
            </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
        <asp:Button ID="btnConfirmFinalize" runat="server" Text="&#xF11E; Confirm Finalize"
            CssClass="btn-ummi-primary" OnClick="btnConfirmFinalize_Click" />
      </div>
    </div>
  </div>
</div>

<%-- ══════════════════════════════════════════════════════
     MODAL 5 — AMEND / CANCEL (Admin Only)
     ══════════════════════════════════════════════════════ --%>
<div class="modal fade" id="modalAmend" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header" style="background:#FEF2F2;border-bottom:1px solid #FECACA;">
        <h5 class="modal-title" style="color:#991b1b;"><i class="fa fa-pen-to-square me-2"></i>Amend / Cancel Schedule</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div style="background:#F8FAFC;border:1px solid #E2E8F0;border-radius:8px;padding:12px;margin-bottom:12px;font-size:13px;">
            <asp:Label ID="lblAmendTarget" runat="server" Text="" />
        </div>
        <label class="form-label-ummi">Reason / Remarks <span style="color:#dc2626;">*</span></label>
        <asp:TextBox ID="txtAmendRemarks" runat="server" CssClass="form-control-ummi"
            TextMode="MultiLine" Rows="3" MaxLength="500"
            placeholder="Provide reason for amendment or cancellation..." />
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
        <asp:Button ID="btnConfirmCancel" runat="server" Text="Cancel Schedule"
            CssClass="btn btn-danger" OnClick="btnConfirmCancel_Click"
            OnClientClick="return confirm('Cancel this schedule? This cannot be undone.');" />
        <asp:Button ID="btnConfirmAmend" runat="server" Text="Revert to Tentative"
            CssClass="btn-ummi-secondary" OnClick="btnConfirmAmend_Click"
            OnClientClick="return confirm('Revert schedule to Tentative? The EOC will be superseded.');" />
      </div>
    </div>
  </div>
</div>

<%-- ══════════════════════════════════════════════════════
     MODAL 6 — EOC PREVIEW
     ══════════════════════════════════════════════════════ --%>
<div class="modal fade" id="modalEOC" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header" style="background:#CCFBF1;border-bottom:1px solid #99F6E4;">
        <h5 class="modal-title" style="color:#065f46;"><i class="fa fa-file-circle-check me-2"></i>EOC Record</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div class="info-row"><span class="info-lbl">Crew Member</span>  <span class="info-val"><asp:Label ID="lblEocCrew"      runat="server" Text="&#8212;" /></span></div>
        <div class="info-row"><span class="info-lbl">Rank</span>        <span class="info-val"><asp:Label ID="lblEocRank"      runat="server" Text="&#8212;" /></span></div>
        <div class="info-row"><span class="info-lbl">Vessel</span>      <span class="info-val"><asp:Label ID="lblEocVessel"    runat="server" Text="&#8212;" /></span></div>
        <div class="info-row"><span class="info-lbl">Sign-On Date</span><span class="info-val"><asp:Label ID="lblEocSignOn"    runat="server" Text="&#8212;" /></span></div>
        <div class="info-row"><span class="info-lbl">Sign-Off (EOC)</span><span class="info-val"><asp:Label ID="lblEocSignOff" runat="server" Text="&#8212;" /></span></div>
        <div class="info-row"><span class="info-lbl">Joining Port</span><span class="info-val"><asp:Label ID="lblEocPort"      runat="server" Text="&#8212;" /></span></div>
        <div class="info-row"><span class="info-lbl">EOC Status</span>  <span class="info-val"><asp:Label ID="lblEocStatus"    runat="server" Text="&#8212;" /></span></div>
        <div class="info-row"><span class="info-lbl">Generated At</span><span class="info-val"><asp:Label ID="lblEocGenerated" runat="server" Text="&#8212;" /></span></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
      </div>
    </div>
  </div>
</div>

</asp:Content>

<%-- ══════════════════════════════════════════════════════
     SCRIPTS
     ══════════════════════════════════════════════════════ --%>
<asp:Content ContentPlaceHolderID="ScriptContent" runat="server">
<script>
// ── Row data helper ────────────────────────────────────
function getRowData(btn) {
    var row = btn.closest('tr');
    return {
        crewId:       row.dataset.crewId      || '0',
        relieverId:   row.dataset.relieverId  || '0',
        scheduleId:   row.dataset.scheduleId  || '0',
        eocId:        row.dataset.eocId       || '0',
        relieverCrew: row.dataset.relieverCrew || '0'
    };
}
function setHidden(id, val) { var el = document.getElementById(id); if (el) el.value = val; }
function getVal(id)  { var el = document.getElementById(id); return el ? el.value.trim() : ''; }
function setVal(id, v) { var el = document.getElementById(id); if (el) el.value = v || ''; }
function escHtml(s) {
    return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

// ── Open: Add Reliever ─────────────────────────────────
function openAddReliever(btn, crewName, rankCode) {
    var d = getRowData(btn);
    setHidden('<%= hfOutgoingCrewID.ClientID %>', d.crewId);
    document.getElementById('spanOutgoingName').textContent = crewName || '—';
    document.getElementById('spanOutgoingRank').textContent = rankCode || '—';
    setVal('<%= txtRelieverSearch.ClientID %>', '');
    var pick = document.getElementById('<%= drpRelieverPick.ClientID %>');
    if (pick) pick.innerHTML = '<option value="">-- Search to populate --</option>';
    new bootstrap.Modal(document.getElementById('modalAddReliever')).show();
}
function confirmRelieverAssign() {
    var pick = document.getElementById('<%= drpRelieverPick.ClientID %>');
    if (!pick || !pick.value) { alert('Please search and select a reliever first.'); return false; }
    return confirm('Assign ' + pick.options[pick.selectedIndex].text + ' as reliever?');
}

// ── Open: Approval ─────────────────────────────────────
function openApproval(btn, outName, rankCode, relName, relRank) {
    var d = getRowData(btn);
    setHidden('<%= hfRelieverID.ClientID %>', d.relieverId);
    var lbl = document.getElementById('<%= lblApprovalTarget.ClientID %>');
    if (lbl) {
        lbl.innerHTML =
            '<b>Outgoing:</b> ' + escHtml(outName) + ' <span class="badge badge-onboard ms-1">' + escHtml(rankCode) + '</span><br>' +
            '<b>Reliever:</b> ' + escHtml(relName)  + ' <span class="badge badge-ccl-reliever ms-1">' + escHtml(relRank) + '</span>';
    }
    setVal('<%= txtApprovalRemarks.ClientID %>', '');
    new bootstrap.Modal(document.getElementById('modalApproval')).show();
}

// ── Open: Create Schedule ──────────────────────────────
function openCreateSchedule(btn, crewName, relCrewId) {
    var d = getRowData(btn);
    setHidden('<%= hfRelieverID.ClientID %>',     d.relieverId);
    setHidden('<%= hfScheduleID.ClientID %>',     '0');
    setHidden('<%= hfRelieverCrewID.ClientID %>', relCrewId || d.relieverCrew);
    var lbl = document.getElementById('<%= lblSchedTarget.ClientID %>');
    if (lbl) lbl.innerHTML = '<b>Outgoing Crew:</b> ' + escHtml(crewName);
    document.getElementById('schedModalTitle').innerHTML = '<i class="fa fa-calendar-plus me-2"></i>Create CCL Schedule';
    clearScheduleForm();
    document.getElementById('divApplyAll').style.display = 'none';
    new bootstrap.Modal(document.getElementById('modalSchedule')).show();
}

// ── Open: Edit Schedule ────────────────────────────────
function openEditSchedule(btn, crewName, jd, port, dd, sod, relCrewId) {
    var d = getRowData(btn);
    setHidden('<%= hfRelieverID.ClientID %>',     d.relieverId);
    setHidden('<%= hfScheduleID.ClientID %>',     d.scheduleId);
    setHidden('<%= hfRelieverCrewID.ClientID %>', relCrewId || d.relieverCrew);
    var lbl = document.getElementById('<%= lblSchedTarget.ClientID %>');
    if (lbl) lbl.innerHTML = '<b>Outgoing Crew:</b> ' + escHtml(crewName);
    document.getElementById('schedModalTitle').innerHTML = '<i class="fa fa-calendar-pen me-2"></i>Edit CCL Schedule';
    setVal('<%= txtJoiningDate.ClientID %>',   jd);
    setVal('<%= txtJoiningPort.ClientID %>',   port);
    setVal('<%= txtDepartureDate.ClientID %>', dd);
    setVal('<%= txtShipOnsign.ClientID %>',    sod);
    document.getElementById('divApplyAll').style.display = 'none';
    new bootstrap.Modal(document.getElementById('modalSchedule')).show();
}

// ── Bulk: Create Schedule for selected ────────────────
function validateSelected(modalId) {
    var count = getSelectedCount();
    if (count === 0) { alert('Please select at least one crew member first.'); return false; }
    var ids = getSelectedRelieverIds();
    setHidden('<%= hfSelectedIDs.ClientID %>', ids.join(','));
    setHidden('<%= hfScheduleID.ClientID %>',  '0');
    var lbl = document.getElementById('<%= lblSchedTarget.ClientID %>');
    if (lbl) lbl.innerHTML = '<b>' + count + ' crew member(s) selected</b>';
    clearScheduleForm();
    if (count > 1) {
        document.getElementById('divApplyAll').style.display = 'block';
        document.getElementById('spanApplyCount').textContent = count;
    } else {
        document.getElementById('divApplyAll').style.display = 'none';
    }
    new bootstrap.Modal(document.getElementById(modalId)).show();
    return false;
}

// ── Bulk: Apply to all ─────────────────────────────────
function applyAllClick() {
    var count = getSelectedCount();
    if (count === 0) { alert('Please select at least one crew member.'); return false; }
    var ids = getSelectedRelieverIds();
    setHidden('<%= hfSelectedIDs.ClientID %>', ids.join(','));
    setHidden('<%= hfScheduleID.ClientID %>',  '0');
    var lbl = document.getElementById('<%= lblSchedTarget.ClientID %>');
    if (lbl) lbl.innerHTML = '<b>' + count + ' crew member(s) — Apply to All</b>';
    clearScheduleForm();
    document.getElementById('divApplyAll').style.display = 'block';
    document.getElementById('spanApplyCount').textContent = count;
    var chk = document.getElementById('<%= chkApplyAll.ClientID %>');
    if (chk) chk.checked = true;
    new bootstrap.Modal(document.getElementById('modalSchedule')).show();
    return false;
}

// ── Validate schedule form ─────────────────────────────
function validateScheduleForm() {
    var jd  = getVal('<%= txtJoiningDate.ClientID %>');
    var jp  = getVal('<%= txtJoiningPort.ClientID %>');
    var dd  = getVal('<%= txtDepartureDate.ClientID %>');
    var sod = getVal('<%= txtShipOnsign.ClientID %>');
    if (!jd || !jp || !dd || !sod) { alert('All schedule fields are required.'); return false; }
    var jdD  = new Date(jd), ddD = new Date(dd), sodD = new Date(sod);
    var today = new Date(); today.setHours(0,0,0,0);
    if (jdD < today)  { alert('Joining Date must be today or a future date.'); return false; }
    if (ddD < jdD)    { alert('Departure Date must be on or after Joining Date.'); return false; }
    if (sodD > jdD)   { alert('Ship On-Sign Date must be on or before Joining Date.'); return false; }
    return true;
}
function clearScheduleForm() {
    ['<%= txtJoiningDate.ClientID %>', '<%= txtJoiningPort.ClientID %>',
     '<%= txtDepartureDate.ClientID %>', '<%= txtShipOnsign.ClientID %>'].forEach(function(id){
        var el = document.getElementById(id); if (el) el.value = '';
    });
    var chk = document.getElementById('<%= chkApplyAll.ClientID %>');
    if (chk) chk.checked = false;
}

// ── Open: Finalize ─────────────────────────────────────
function openFinalize(btn, crewName, relName) {
    var d = getRowData(btn);
    setHidden('<%= hfScheduleID.ClientID %>', d.scheduleId);
    var lbl = document.getElementById('<%= lblFinalizeTarget.ClientID %>');
    if (lbl) {
        lbl.innerHTML = '<b>Outgoing:</b> ' + escHtml(crewName) + '<br>' +
                        '<b>Incoming Reliever:</b> ' + escHtml(relName);
    }
    new bootstrap.Modal(document.getElementById('modalFinalize')).show();
}

// ── Open: Amend / Cancel ───────────────────────────────
function openAmend(btn, crewName) {
    var d = getRowData(btn);
    setHidden('<%= hfScheduleID.ClientID %>', d.scheduleId);
    var lbl = document.getElementById('<%= lblAmendTarget.ClientID %>');
    if (lbl) lbl.innerHTML = '<b>Schedule for:</b> ' + escHtml(crewName);
    setVal('<%= txtAmendRemarks.ClientID %>', '');
    new bootstrap.Modal(document.getElementById('modalAmend')).show();
}

// ── Open: EOC Preview ──────────────────────────────────
function openEOC(btn) {
    var d = getRowData(btn);
    setHidden('<%= hfEocID.ClientID %>',  d.eocId);
    setHidden('<%= hfAction.ClientID %>', 'loadEOC');
    new bootstrap.Modal(document.getElementById('modalEOC')).show();
}

// ── Checkbox selection ─────────────────────────────────
document.addEventListener('DOMContentLoaded', function () {
    // Header select-all
    document.querySelectorAll('.chk-all-header input[type=checkbox]').forEach(function (el) {
        el.addEventListener('change', function () {
            document.querySelectorAll('.ccl-row-chk input[type=checkbox]:not([disabled])').forEach(function (c) {
                c.checked = el.checked;
            });
            updateSelCount();
        });
    });
    // Individual rows
    document.addEventListener('change', function (e) {
        if (e.target && e.target.closest && e.target.closest('.ccl-row-chk')) updateSelCount();
    });
    updateSelCount();
});
function updateSelCount() {
    var n = document.querySelectorAll('.ccl-row-chk input[type=checkbox]:checked').length;
    var badge = document.getElementById('spanSelCount');
    if (badge) { badge.textContent = n + ' selected'; badge.classList.toggle('visible', n > 0); }
}
function getSelectedCount() {
    return document.querySelectorAll('.ccl-row-chk input[type=checkbox]:checked').length;
}
function getSelectedRelieverIds() {
    var ids = [];
    document.querySelectorAll('.ccl-row-chk input[type=checkbox]:checked').forEach(function (c) {
        var row = c.closest('tr');
        if (row && row.dataset.relieverId && row.dataset.relieverId !== '0') ids.push(row.dataset.relieverId);
    });
    return ids;
}
</script>
</asp:Content>
