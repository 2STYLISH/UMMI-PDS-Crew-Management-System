<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="QueryCrew.aspx.vb"
    Inherits="QueryCrew" Title="Crew Search" MaintainScrollPositionOnPostback="true" %>

<asp:Content ContentPlaceHolderID="HeadContent" runat="server">
<style>
.filter-row label { font-size:11px; font-weight:600; color:#334155; margin-bottom:2px; }
.chk-attr label { font-size:12px; font-weight:500; }
.gv-link { color:#2563eb; text-decoration:none; font-weight:500; font-size:12px; }
.gv-link:hover { text-decoration:underline; }
</style>
</asp:Content>

<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="fade-in">

<h2 style="font-size:20px;font-weight:700;color:#1a2744;margin-bottom:16px;">
    <i class="fa fa-magnifying-glass me-2 text-primary"></i>Crew Search
</h2>

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
                placeholder="Last name..." OnTextChanged="SearchCrew" AutoPostBack="false" />
        </div>
        <div class="col-6 col-md-2">
            <label class="form-label-ummi">First Name</label>
            <asp:TextBox ID="txtFirstName" runat="server" CssClass="form-control-ummi"
                placeholder="First name..." AutoPostBack="false" />
        </div>

        <!-- Crew Status (WBS 1.1.2) -->
        <div class="col-6 col-md-2" id="divCrewStatus" runat="server">
            <label class="form-label-ummi">Crew Status</label>
            <asp:DropDownList ID="drpdwnCrewStatus" runat="server" CssClass="form-control-ummi"
                AutoPostBack="true" OnSelectedIndexChanged="SearchCrew" />
        </div>

        <!-- Availability (hidden for Principal) -->
        <div class="col-6 col-md-2" id="divAvailability" runat="server">
            <label class="form-label-ummi">Availability</label>
            <asp:DropDownList ID="drpdwnCrewAvailability" runat="server" CssClass="form-control-ummi"
                AutoPostBack="true" OnSelectedIndexChanged="SearchCrew">
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
                AutoPostBack="true" OnSelectedIndexChanged="SearchCrew" />
        </div>
    </div>

    <div class="row g-2 mt-1">
        <!-- Province (WBS 1.1.3) -->
        <div class="col-6 col-md-2">
            <label class="form-label-ummi">Province</label>
            <asp:DropDownList ID="drpdwnProvince" runat="server" CssClass="form-control-ummi"
                AutoPostBack="true" OnSelectedIndexChanged="ProvinceChanged" />
        </div>
        <!-- City (cascades from Province) -->
        <div class="col-6 col-md-2">
            <label class="form-label-ummi">City / Municipality</label>
            <asp:DropDownList ID="drpdwnCity" runat="server" CssClass="form-control-ummi"
                AutoPostBack="true" OnSelectedIndexChanged="SearchCrew" />
        </div>

        <!-- Vessel (WBS 1.1.4) -->
        <div class="col-6 col-md-2">
            <label class="form-label-ummi">Vessel Experience Type</label>
            <asp:DropDownList ID="drpdwnVesselTypeExperience" runat="server" CssClass="form-control-ummi"
                AutoPostBack="true" OnSelectedIndexChanged="SearchCrew" />
        </div>
        <div class="col-6 col-md-2">
            <label class="form-label-ummi">Vessel</label>
            <asp:DropDownList ID="drpdwnVessel" runat="server" CssClass="form-control-ummi"
                AutoPostBack="true" OnSelectedIndexChanged="SearchCrew" />
        </div>

        <!-- Date filter -->
        <div class="col-6 col-md-2">
            <label class="form-label-ummi">Date Filter</label>
            <asp:TextBox ID="txtDate" runat="server" CssClass="form-control-ummi"
                TextMode="Date" AutoPostBack="false" />
        </div>

        <!-- Attribute filters (WBS 1.1.5) -->
        <div class="col-12 col-md-2 d-flex align-items-end gap-3 chk-attr">
            <asp:CheckBox ID="chkCadetship" runat="server" Text="Cadetship" />
            <asp:CheckBox ID="chkJOCAP"     runat="server" Text="JOCAP" />
            <asp:CheckBox ID="chkHigherLic" runat="server" Text="Higher Lic." />
        </div>
    </div>

    <div class="d-flex gap-2 mt-3">
        <asp:Button ID="btnSearch" runat="server" Text="&#xF002; Search"
            CssClass="btn-ummi-primary" OnClick="SearchCrew" />
        <asp:Button ID="btnReset"  runat="server" Text="&#xF2EA; Reset"
            CssClass="btn-ummi-secondary" OnClick="ResetFilters" />
        <asp:Button ID="btnPrintResult" runat="server" Text="&#xF02F; Print List"
            CssClass="btn-ummi-secondary" OnClick="PrintResult" />
        <asp:Button ID="btnExportExcel" runat="server" Text="&#xF1C3; Export Excel"
            CssClass="btn-ummi-secondary" OnClick="ExportExcel" />
    </div>
</div>

<!-- ------ SUMMARY BAR (WBS 1.1.9) ------ -->
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

<!-- ------ RESULTS GRID (WBS 1.1.7) ------ -->
<div class="card">
    <div class="card-body-ummi" style="padding:0;">
        <div class="grid-wrapper">
            <asp:GridView ID="GridViewQueryCrew" runat="server"
                AutoGenerateColumns="false"
                CssClass="ummi-table" GridLines="None"
                AllowPaging="true" PageSize="20"
                OnPageIndexChanging="GridViewQueryCrew_PageIndexChanging"
                OnRowDataBound="GridViewQueryCrew_RowDataBound"
                EmptyDataText="&lt;div style='padding:30px;text-align:center;color:#94a3b8;'&gt;&lt;i class='fa fa-users-slash' style='font-size:28px;'&gt;&lt;/i&gt;&lt;div&gt;No crew found matching the search criteria.&lt;/div&gt;&lt;/div&gt;"
                PagerStyle-CssClass="pager-container">
                <Columns>
                    <asp:TemplateField HeaderText="#" ItemStyle-Width="40px">
                        <ItemTemplate><%# Container.DataItemIndex + 1 %></ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Name">
                        <ItemTemplate>
                            <asp:HyperLink ID="lnkProfile" runat="server" CssClass="gv-link"
                                Text='<%# Eval("lastname") & ", " & Eval("firstname") & " " & Eval("middlename") %>'
                                NavigateUrl='<%# GetProfileUrl(Eval("id")) %>' Target="_blank" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="rank_code"        HeaderText="Rank" />
                    <asp:BoundField DataField="rank_type"        HeaderText="Type" />
                    <asp:BoundField DataField="crew_status_text" HeaderText="Status" />
                    <asp:TemplateField HeaderText="Availability" ItemStyle-Width="90px">
                        <ItemTemplate>
                            <%# If(Convert.ToInt32(Eval("crew_availability")) = 1,
                                "<span class='badge-active'>Available</span>",
                                "<span class='badge-used'>Not Available</span>") %>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="age"          HeaderText="Age" ItemStyle-Width="50px" />
                    <asp:BoundField DataField="province_name" HeaderText="Province" />
                    <asp:BoundField DataField="city_name"    HeaderText="City" />
                    <asp:TemplateField HeaderText="Cadetship" ItemStyle-Width="70px">
                        <ItemTemplate><%# If(Convert.ToBoolean(Eval("cadetship")),"<span class='badge-active'>Yes</span>","") %></ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="JOCAP" ItemStyle-Width="60px">
                        <ItemTemplate><%# If(Convert.ToBoolean(Eval("jocap")),"<span class='badge-active'>Yes</span>","") %></ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
        </div>
    </div>
</div>

</ContentTemplate>
<Triggers>
    <asp:AsyncPostBackTrigger ControlID="btnSearch" />
    <asp:AsyncPostBackTrigger ControlID="btnReset" />
    <asp:AsyncPostBackTrigger ControlID="drpdwnCrewStatus" />
    <asp:AsyncPostBackTrigger ControlID="drpdwnCrewAvailability" />
    <asp:AsyncPostBackTrigger ControlID="drpdwnRankType" />
    <asp:AsyncPostBackTrigger ControlID="drpdwnRank" />
    <asp:AsyncPostBackTrigger ControlID="drpdwnProvince" />
    <asp:AsyncPostBackTrigger ControlID="drpdwnCity" />
    <asp:AsyncPostBackTrigger ControlID="drpdwnVesselTypeExperience" />
    <asp:AsyncPostBackTrigger ControlID="drpdwnVessel" />
</Triggers>
</asp:UpdatePanel>

</div>
</asp:Content>
