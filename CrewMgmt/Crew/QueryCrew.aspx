<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="QueryCrew.aspx.vb"
    Inherits="QueryCrew" Title="Crew Search" MaintainScrollPositionOnPostback="true" %>

<asp:Content ContentPlaceHolderID="HeadContent" runat="server">
<style>
.filter-row label { font-size:11px; font-weight:600; color:#334155; margin-bottom:2px; }
.chk-attr label { font-size:12px; font-weight:500; }
.gv-link { color:#2563eb; text-decoration:none; font-weight:500; font-size:12px; }
.gv-link:hover { text-decoration:underline; }
.vessel-link { color:#7c3aed; text-decoration:none; font-weight:500; font-size:12px; cursor:pointer; }
.vessel-link:hover { text-decoration:underline; }
.crew-photo-cell { width:50px; height:50px; border-radius:50%; object-fit:cover; border:3px solid #cbd5e1; }
.crew-photo-cell.status-onboard  { border-color:#22c55e; }
.crew-photo-cell.status-lineup   { border-color:#3b82f6; }
.crew-photo-cell.status-vacation { border-color:#f59e0b; }
.crew-photo-cell.status-active   { border-color:#10b981; }
.crew-photo-cell.status-inactive { border-color:#ef4444; }
.status-date-amber { background:#fef3c7 !important; color:#92400e !important; }
.status-date-red   { background:#fee2e2 !important; color:#991b1b !important; }
.vessel-group-header { background:#f1f5f9; padding:8px 14px; font-weight:700; font-size:13px;
    color:#334155; border-bottom:2px solid #e2e8f0; }
.vessel-group-header .vessel-count { font-weight:400; font-size:11px; color:#64748b; margin-left:8px; }
.releasing-panel { background:linear-gradient(135deg,#fafbff,#f0f4ff); border:1px solid #c7d2fe; }
.releasing-panel .card-header-ummi { background:linear-gradient(90deg,#4f46e5,#7c3aed); color:#fff; }
.chk-releasing label { font-size:12px; font-weight:500; }

/* ── Crew Search Pagination ── */
.crew-pager { display:flex; align-items:center; justify-content:center; gap:4px;
    padding:14px 0 4px; flex-wrap:wrap; }
.crew-pager .pg-btn { display:inline-flex; align-items:center; justify-content:center;
    min-width:34px; height:34px; padding:0 10px;
    border:1px solid #cbd5e1; border-radius:6px;
    background:#fff; color:#2563eb;
    font-size:13px; font-weight:500; line-height:1;
    cursor:pointer; transition:background .15s, color .15s, border-color .15s;
    text-decoration:none; }
.crew-pager .pg-btn:hover:not(:disabled):not(.pg-disabled) { background:#eff6ff; border-color:#93c5fd; }
.crew-pager .pg-btn:focus-visible { outline:2px solid #3b82f6; outline-offset:2px; }
.crew-pager .pg-btn.pg-active { background:#2563eb; color:#fff; border-color:#2563eb;
    cursor:default; font-weight:700; }
.crew-pager .pg-btn.pg-active:hover { background:#2563eb; color:#fff; }
.crew-pager .pg-btn.pg-disabled,
.crew-pager .pg-btn:disabled { color:#94a3b8; border-color:#e2e8f0;
    background:#f8fafc; cursor:not-allowed; pointer-events:none; }
.crew-pager .pg-ellipsis { display:inline-flex; align-items:center; justify-content:center;
    min-width:34px; height:34px; color:#94a3b8; font-size:13px; cursor:default; user-select:none; }
</style>
</asp:Content>

<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="fade-in">

<h2 style="font-size:20px;font-weight:700;color:#1a2744;margin-bottom:16px;">
    <i class="fa fa-magnifying-glass me-2 text-primary"></i>Crew Search
</h2>

<asp:HiddenField ID="hfPageIndex" runat="server" Value="0" />
<asp:UpdatePanel ID="UpdatePanel1" runat="server" UpdateMode="Conditional">
<ContentTemplate>

<!-- Notification -->
<asp:Label ID="lblNotify" runat="server" Text="" />

<!-- ------ FILTER PANEL ------ -->
<div class="filter-panel mb-3">
    <div class="filter-panel-title">
        <i class="fa fa-sliders"></i> Search Filters
    </div>

    <div class="row g-2">
        <!-- Name filters -->
        <div class="col-6 col-md-2">
            <label class="form-label-ummi">Last Name</label>
            <asp:TextBox ID="txtLastName" runat="server" CssClass="form-control-ummi"
                placeholder="Last name..." AutoPostBack="false" />
        </div>
        <div class="col-6 col-md-2">
            <label class="form-label-ummi">First Name</label>
            <asp:TextBox ID="txtFirstName" runat="server" CssClass="form-control-ummi"
                placeholder="First name..." AutoPostBack="false" />
        </div>

        <!-- Crew Status (FR-CM-02) -->
        <div class="col-6 col-md-2" id="divCrewStatus" runat="server">
            <label class="form-label-ummi">Crew Status</label>
            <asp:DropDownList ID="drpdwnCrewStatus" runat="server" CssClass="form-control-ummi"
                AutoPostBack="false" />
        </div>

        <!-- Availability (hidden for Principal per FR-CM-05) -->
        <div class="col-6 col-md-2" id="divAvailability" runat="server">
            <label class="form-label-ummi">Availability</label>
            <asp:DropDownList ID="drpdwnCrewAvailability" runat="server" CssClass="form-control-ummi"
                AutoPostBack="false">
                <asp:ListItem Value="">ALL</asp:ListItem>
                <asp:ListItem Value="1">Available</asp:ListItem>
                <asp:ListItem Value="0">Not Available</asp:ListItem>
            </asp:DropDownList>
        </div>

        <!-- Rank Type + Rank -->
        <div class="col-6 col-md-2">
            <label class="form-label-ummi">Rank Type</label>
            <asp:DropDownList ID="drpdwnRankType" runat="server" CssClass="form-control-ummi"
                AutoPostBack="true" OnSelectedIndexChanged="RankTypeChanged" />
        </div>
        <div class="col-6 col-md-2">
            <label class="form-label-ummi">Rank</label>
            <asp:DropDownList ID="drpdwnRank" runat="server" CssClass="form-control-ummi"
                AutoPostBack="false" />
        </div>
    </div>

    <div class="row g-2 mt-1">
        <!-- Province (FR-CM-01) -->
        <div class="col-6 col-md-2">
            <label class="form-label-ummi">Province</label>
            <asp:DropDownList ID="drpdwnProvince" runat="server" CssClass="form-control-ummi"
                AutoPostBack="true" OnSelectedIndexChanged="ProvinceChanged" />
        </div>
        <!-- City (cascades from Province) -->
        <div class="col-6 col-md-2">
            <label class="form-label-ummi">City / Municipality</label>
            <asp:DropDownList ID="drpdwnCity" runat="server" CssClass="form-control-ummi"
                AutoPostBack="false" />
        </div>

        <!-- Vessel Experience Type -->
        <div class="col-6 col-md-2">
            <label class="form-label-ummi">Vessel Experience Type</label>
            <asp:DropDownList ID="drpdwnVesselTypeExperience" runat="server" CssClass="form-control-ummi"
                AutoPostBack="false" />
        </div>
        <!-- Vessel -->
        <div class="col-6 col-md-2">
            <label class="form-label-ummi">Vessel</label>
            <asp:DropDownList ID="drpdwnVessel" runat="server" CssClass="form-control-ummi"
                AutoPostBack="false" />
        </div>

        <!-- Date filter -->
        <div class="col-6 col-md-2">
            <label class="form-label-ummi">Date Filter</label>
            <asp:TextBox ID="txtDate" runat="server" CssClass="form-control-ummi"
                TextMode="Date" AutoPostBack="false" />
        </div>

        <!-- Attribute filters (FR-CM-04) -->
        <div class="col-12 col-md-2 d-flex align-items-end gap-3 chk-attr">
            <asp:CheckBox ID="chkCadetship" runat="server" Text="Cadetship" />
            <asp:CheckBox ID="chkJOCAP"     runat="server" Text="JOCAP" />
            <asp:CheckBox ID="chkHigherLic" runat="server" Text="Higher Lic." />
        </div>
    </div>

    <div class="d-flex gap-2 mt-3 flex-wrap">
        <asp:Button ID="btnSearch" runat="server" Text="&#xF002; Search"
            CssClass="btn-ummi-primary" OnClick="SearchCrew" />
        <asp:Button ID="btnReset"  runat="server" Text="&#xF2EA; Reset"
            CssClass="btn-ummi-secondary" OnClick="ResetFilters" />
        <asp:Button ID="btnExportExcel" runat="server" Text="&#xF1C3; Export Excel"
            CssClass="btn-ummi-secondary" OnClick="ExportExcel" />
        <!-- UC-CM-25: Releasing Checklist (visible for Manning/SuperAdmin when status=LINE UP) -->
        <asp:Button ID="btnReleasingChecklist" runat="server" Text="&#xF0CB; Releasing Checklist"
            CssClass="btn-ummi-primary" OnClick="ShowReleasingChecklist" Visible="false"
            Style="background:#4f46e5;" />
    </div>
</div>

<script>
// Prevent Enter key from submitting the search while focus is inside a filter control.
// Enter is still allowed on the Search button itself (button elements are excluded).
(function () {
    function suppressEnterInFilters() {
        var panel = document.querySelector('.filter-panel');
        if (!panel) return;
        panel.addEventListener('keydown', function (e) {
            if (e.key !== 'Enter') return;
            var tag = e.target.tagName.toLowerCase();
            // Allow Enter on button and anchor elements so the Search button works normally
            if (tag === 'button' || tag === 'a') return;
            // Suppress on all other filter controls (input, select, textarea)
            e.preventDefault();
        }, false);
    }
    // Run after DOM ready and also after each UpdatePanel partial refresh
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', suppressEnterInFilters);
    } else {
        suppressEnterInFilters();
    }
    if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(suppressEnterInFilters);
    }
}());
</script>

<!-- ------ SUMMARY BAR (FR-CM-10) ------ -->
<div class="summary-bar mb-2" id="divSummary" runat="server" visible="false">
    <div class="summary-item">
        <strong><asp:Label ID="lblCrewCount" runat="server" Text="0" /></strong>
        Crew Found
    </div>
    <div class="summary-item">
        <strong><asp:Label ID="lblAverageAge" runat="server" Text="0" /></strong>
        Avg. Age
    </div>
    <div class="summary-item" style="flex:1;font-size:11px;color:#94a3b8;align-self:center;">
        <asp:Label ID="lblSearchSummary" runat="server" Text="" />
    </div>
</div>

<!-- ------ UC-CM-25/26: RELEASING CHECKLIST PANEL ------ -->
<asp:Panel ID="panelReleasingChecklist" runat="server" Visible="false" CssClass="card releasing-panel mb-3">
    <div class="card-header-ummi d-flex justify-content-between">
        <span><i class="fa fa-clipboard-list me-2"></i>Releasing Checklist Configuration</span>
        <asp:Button ID="btnCloseReleasing" runat="server" Text="&#xF00D;"
            CssClass="btn btn-sm btn-close btn-close-white" OnClick="HideReleasingChecklist" />
    </div>
    <div class="card-body-ummi">
        <asp:Label ID="lblReleasingVessel" runat="server" Text=""
            Style="font-weight:700;font-size:14px;color:#4f46e5;margin-bottom:12px;display:block;" />
        <div class="row g-2 mb-3">
            <div class="col-md-3">
                <label class="form-label-ummi">Batch Number</label>
                <asp:TextBox ID="txtBatchNumber" runat="server" CssClass="form-control-ummi" placeholder="e.g. BATCH-001" />
            </div>
            <div class="col-md-3">
                <label class="form-label-ummi">Airport Terminal</label>
                <asp:DropDownList ID="drpdwnTerminal" runat="server" CssClass="form-control-ummi">
                    <asp:ListItem Value="">Select terminal...</asp:ListItem>
                    <asp:ListItem Value="NAIA T1">NAIA Terminal 1</asp:ListItem>
                    <asp:ListItem Value="NAIA T2">NAIA Terminal 2</asp:ListItem>
                    <asp:ListItem Value="NAIA T3">NAIA Terminal 3</asp:ListItem>
                    <asp:ListItem Value="MCIA T1">MCIA Terminal 1</asp:ListItem>
                    <asp:ListItem Value="MCIA T2">MCIA Terminal 2</asp:ListItem>
                </asp:DropDownList>
            </div>
        </div>
        <div class="row g-2 mb-3">
            <div class="col-md-12"><strong style="font-size:12px;color:#475569;">Flight Booking Status</strong></div>
            <div class="col-md-3 chk-releasing">
                <asp:CheckBox ID="chkFlightOnSigners" runat="server" Text="On-Signers Booked" />
            </div>
            <div class="col-md-3 chk-releasing">
                <asp:CheckBox ID="chkFlightOffSigners" runat="server" Text="Off-Signers Booked" />
            </div>
        </div>
        <div class="row g-2 mb-3">
            <div class="col-md-12"><strong style="font-size:12px;color:#475569;">Document Checklist Items</strong></div>
            <div class="col-md-4 chk-releasing"><asp:CheckBox ID="chkGLImmigration"    runat="server" Text="GL / Immigration Clearance" /></div>
            <div class="col-md-4 chk-releasing"><asp:CheckBox ID="chkInfoSheet"        runat="server" Text="Information Sheet" /></div>
            <div class="col-md-4 chk-releasing"><asp:CheckBox ID="chkPreEmbarkation"   runat="server" Text="Pre-Embarkation Checklist" /></div>
            <div class="col-md-4 chk-releasing"><asp:CheckBox ID="chkAllotment"        runat="server" Text="Allotment" /></div>
            <div class="col-md-4 chk-releasing"><asp:CheckBox ID="chkVisa"             runat="server" Text="Visa" /></div>
            <div class="col-md-4 chk-releasing"><asp:CheckBox ID="chkEndOfContract"    runat="server" Text="End of Contract Documentation" /></div>
        </div>
        <asp:Button ID="btnExportReleasing" runat="server" Text="&#xF1C3; Export Checklist"
            CssClass="btn-ummi-primary" OnClick="ExportReleasingChecklist" Style="background:#4f46e5;" />
    </div>
</asp:Panel>

<!-- ------ RESULTS GRID (FR-CM-06/07/08/09/10) ------ -->
<div class="card">
    <div class="card-body-ummi" style="padding:0;">
        <div class="grid-wrapper">
            <asp:GridView ID="GridViewQueryCrew" runat="server"
                AutoGenerateColumns="false"
                CssClass="ummi-table" GridLines="None"
                AllowPaging="false"
                OnRowDataBound="GridViewQueryCrew_RowDataBound"
                EmptyDataText="&lt;div style='padding:30px;text-align:center;color:#94a3b8;'&gt;&lt;i class='fa fa-users-slash' style='font-size:28px;'&gt;&lt;/i&gt;&lt;div&gt;No crew found matching the search criteria.&lt;/div&gt;&lt;/div&gt;">
                <Columns>
                    <asp:TemplateField HeaderText="" ItemStyle-Width="60px">
                        <ItemTemplate>
                            <asp:Image ID="imgCrewPhoto" runat="server" CssClass="crew-photo-cell"
                                ImageUrl="~/images/silhouette_user.png" AlternateText="Photo" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Name">
                        <ItemTemplate>
                            <asp:HyperLink ID="lnkProfile" runat="server" CssClass="gv-link"
                                Text='<%# Eval("lastname") & ", " & Eval("firstname") & " " & Eval("middlename") %>'
                                NavigateUrl='<%# GetProfileUrl(Eval("id")) %>' Target="_blank" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="rank_code"        HeaderText="Rank" />
                    <asp:BoundField DataField="crew_status_text" HeaderText="Status" />
                    <asp:TemplateField HeaderText="Vessel">
                        <ItemTemplate>
                            <asp:HyperLink ID="lnkVessel" runat="server" CssClass="vessel-link" Visible="false"
                                Target="_blank" />
                            <asp:Label ID="lblVesselPlain" runat="server" Text="" Style="font-size:12px;" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="age" HeaderText="Age" ItemStyle-Width="45px" />
                    <asp:TemplateField HeaderText="Last Vessel">
                        <ItemTemplate>
                            <asp:Label ID="lblLastVessel" runat="server" Text="" Style="font-size:12px;" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Status Date">
                        <ItemTemplate>
                            <asp:Label ID="lblStatusDate" runat="server" Text="" Style="font-size:11px;" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Sea Service">
                        <ItemTemplate>
                            <asp:Label ID="lblSeaService" runat="server" Text="" Style="font-size:11px;" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Availability" ItemStyle-Width="90px">
                        <ItemTemplate>
                            <%# If(Convert.ToInt32(Eval("crew_availability")) = 1,
                                "<span class='badge-active'>Available</span>",
                                "<span class='badge-used'>Not Available</span>") %>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
            <div class="crew-pager" id="divPager" runat="server" visible="false">
                <asp:PlaceHolder ID="phPager" runat="server" />
            </div>
        </div>
    </div>
</div>

</ContentTemplate>
<Triggers>
    <asp:AsyncPostBackTrigger ControlID="btnSearch" />
    <asp:AsyncPostBackTrigger ControlID="btnReset" />
    <asp:AsyncPostBackTrigger ControlID="drpdwnRankType" />
    <asp:AsyncPostBackTrigger ControlID="drpdwnProvince" />
    <asp:AsyncPostBackTrigger ControlID="hfPageIndex" EventName="ValueChanged" />
    <asp:PostBackTrigger ControlID="btnExportExcel" />
    <asp:PostBackTrigger ControlID="btnExportReleasing" />
</Triggers>
</asp:UpdatePanel>

</div>
</asp:Content>
