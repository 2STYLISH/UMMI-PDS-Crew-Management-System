<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="VesselCrew.aspx.vb"
    Inherits="VesselCrew" Title="Vessel Crew" MaintainScrollPositionOnPostback="true" %>

<asp:Content ContentPlaceHolderID="HeadContent" runat="server">
<style>
/* ── VesselCrew page-local styles (re-uses system design tokens) ── */
.vessel-banner {
    background: linear-gradient(135deg, #1e3a5f, #2563eb);
    border-radius: 10px;
    padding: 18px 24px;
    margin-bottom: 20px;
    color: #fff;
    display: flex;
    align-items: center;
    gap: 16px;
}
.vessel-banner .vb-icon {
    font-size: 32px;
    opacity: .85;
    flex-shrink: 0;
}
.vessel-banner .vb-info h2 {
    font-size: 20px;
    font-weight: 700;
    margin: 0 0 2px;
}
.vessel-banner .vb-info p {
    font-size: 12px;
    opacity: .8;
    margin: 0;
}
.vc-stats { display:flex; gap:12px; flex-wrap:wrap; margin-bottom:18px; }
.vc-stats .stat-card { flex:1; min-width:120px; }
.crew-photo-vc { width:46px; height:46px; border-radius:50%; object-fit:cover;
    border:3px solid #cbd5e1; }
.crew-photo-vc.status-onboard  { border-color:#22c55e; }
.crew-photo-vc.status-lineup   { border-color:#3b82f6; }
.crew-photo-vc.status-vacation { border-color:#f59e0b; }
.gv-link-vc { color:#2563eb; text-decoration:none; font-weight:500; font-size:12px; }
.gv-link-vc:hover { text-decoration:underline; }
.status-date-amber-vc { background:#fef3c7 !important; color:#92400e !important; padding:2px 6px; border-radius:4px; }
.status-date-red-vc   { background:#fee2e2 !important; color:#991b1b !important; padding:2px 6px; border-radius:4px; }
/* Pagination (reuses QueryCrew pager tokens) */
.vc-pager { display:flex; align-items:center; justify-content:center; gap:4px;
    padding:14px 0 4px; flex-wrap:wrap; }
.vc-pager .pg-btn { display:inline-flex; align-items:center; justify-content:center;
    min-width:34px; height:34px; padding:0 10px;
    border:1px solid #cbd5e1; border-radius:6px;
    background:#fff; color:#2563eb;
    font-size:13px; font-weight:500;
    cursor:pointer; transition:background .15s, color .15s, border-color .15s; }
.vc-pager .pg-btn:hover:not(:disabled) { background:#eff6ff; border-color:#93c5fd; }
.vc-pager .pg-btn.pg-active { background:#2563eb; color:#fff; border-color:#2563eb; cursor:default; }
.vc-pager .pg-btn.pg-disabled,
.vc-pager .pg-btn:disabled { color:#94a3b8; border-color:#e2e8f0; background:#f8fafc; cursor:not-allowed; pointer-events:none; }
.vc-pager .pg-ellipsis { display:inline-flex; align-items:center; justify-content:center;
    min-width:34px; height:34px; color:#94a3b8; font-size:13px; user-select:none; }
@media(max-width:600px){
    .vessel-banner { flex-direction:column; gap:8px; }
}
</style>
</asp:Content>

<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="fade-in">

<%-- Vessel Banner --%>
<div class="vessel-banner" style="justify-content:space-between; flex-wrap:wrap;">
    <div style="display:flex; align-items:center; gap:16px;">
        <div class="vb-icon"><i class="fa fa-ship"></i></div>
        <div class="vb-info">
            <h2><asp:Label ID="lblVesselTitle" runat="server" Text="Vessel" /></h2>
            <p>Crew &amp; personnel currently assigned to this vessel</p>
        </div>
    </div>
    <div>
        <a href="<%= ResolveUrl("~/Crew/QueryCrew.aspx") %>" class="btn btn-sm" style="background:rgba(255,255,255,0.2); color:#fff; border:1px solid rgba(255,255,255,0.4); text-decoration:none; display:inline-flex; align-items:center; gap:6px;">
            <i class="fa fa-arrow-left"></i> Back to Search
        </a>
    </div>
</div>

<%-- Notification --%>
<asp:Label ID="lblNotify" runat="server" Text="" />

<%-- Summary Cards --%>
<div class="vc-stats">
    <div class="stat-card">
        <div class="stat-icon stat-icon--blue"><i class="fa fa-ship"></i></div>
        <div class="stat-info">
            <div class="stat-value"><asp:Label ID="lblCntOnboard" runat="server" Text="0" /></div>
            <div class="stat-label">On Board</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon stat-icon--blue"><i class="fa fa-list"></i></div>
        <div class="stat-info">
            <div class="stat-value"><asp:Label ID="lblCntLineup" runat="server" Text="0" /></div>
            <div class="stat-label">Line Up</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon stat-icon--amber"><i class="fa fa-umbrella-beach"></i></div>
        <div class="stat-info">
            <div class="stat-value"><asp:Label ID="lblCntVacation" runat="server" Text="0" /></div>
            <div class="stat-label">On Vacation</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon stat-icon--green"><i class="fa fa-users"></i></div>
        <div class="stat-info">
            <div class="stat-value"><asp:Label ID="lblCntTotal" runat="server" Text="0" /></div>
            <div class="stat-label">Total</div>
        </div>
    </div>
</div>

<%-- Crew Grid --%>
<div class="card">
    <div class="card-header-ummi">
        <span><i class="fa fa-users me-2"></i>Assigned Crew</span>
        <asp:Label ID="lblVesselSubtitle" runat="server" Text=""
            Style="font-size:12px;font-weight:400;opacity:.8;" />
    </div>
    <div class="card-body-ummi" style="padding:0;">
        <div class="grid-wrapper">
            <asp:GridView ID="gvVesselCrew" runat="server"
                AutoGenerateColumns="false"
                CssClass="ummi-table" GridLines="None"
                AllowPaging="false"
                OnRowDataBound="gvVesselCrew_RowDataBound"
                EmptyDataText="&lt;div style='padding:30px;text-align:center;color:#94a3b8;'&gt;&lt;i class='fa fa-users-slash' style='font-size:28px;'&gt;&lt;/i&gt;&lt;div&gt;No crew found for this vessel.&lt;/div&gt;&lt;/div&gt;">
                <Columns>
                    <asp:TemplateField HeaderText="" ItemStyle-Width="60px">
                        <ItemTemplate>
                            <asp:Image ID="imgPhoto" runat="server"
                                CssClass="crew-photo-vc"
                                ImageUrl="~/images/silhouette_user.png"
                                AlternateText="Photo" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Name">
                        <ItemTemplate>
                            <asp:HyperLink ID="lnkProfile" runat="server" CssClass="gv-link-vc"
                                Text='<%# Eval("lastname") & ", " & Eval("firstname") & " " & Eval("middlename") %>'
                                NavigateUrl='<%# GetProfileUrl(Eval("id")) %>' Target="_blank" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="rank_code"        HeaderText="Rank" />
                    <asp:BoundField DataField="crew_status_text" HeaderText="Status" />
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
                    <asp:TemplateField HeaderText="Province / City">
                        <ItemTemplate>
                            <asp:Label ID="lblProvCity" runat="server" Text="" Style="font-size:11px;" />
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
            <div class="vc-pager" id="divPager" runat="server" visible="false">
                <asp:HiddenField ID="hfTargetPage" runat="server" Value="0" />
                <asp:Button ID="btnGoPager" runat="server" Text="" Style="display:none"
                    OnClick="GoToPage_Click" CausesValidation="false" />
                <asp:PlaceHolder ID="phPager" runat="server" />
            </div>
        </div>
    </div>
</div>

<%-- Navigation --%>
<div style="margin-top:14px;display:flex;gap:14px;align-items:center;flex-wrap:wrap;">
    <a href="<%= ResolveUrl("~/Crew/QueryCrew.aspx") %>" class="gv-link-vc">
        <i class="fa fa-arrow-left me-1"></i>Back to Crew Search
    </a>
    <asp:HyperLink ID="lnkOpenCCL" runat="server"
        CssClass="gv-link-vc"
        Style="color:#0e7490;"
        Visible="false">
        <i class="fa fa-arrows-rotate me-1"></i>Open Crew Change List for this vessel
    </asp:HyperLink>
</div>

</div><%-- /fade-in --%>
</asp:Content>
