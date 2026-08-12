<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="ActivityLogs.aspx.vb"
    Inherits="ActivityLogs" Title="Activity Logs" %>
<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

<div class="card">
    <!-- Filters -->
    <div class="filter-row">
        <asp:DropDownList ID="drpdwnCategory" runat="server" CssClass="form-select" style="width:160px;">
            <asp:ListItem Value="">All Categories</asp:ListItem>
            <asp:ListItem Value="Login">Login</asp:ListItem>
            <asp:ListItem Value="QueryCrew">Query Crew</asp:ListItem>
            <asp:ListItem Value="ApplicantPool">Applicant Pool</asp:ListItem>
            <asp:ListItem Value="ProfileViewer">Profile Viewer</asp:ListItem>
            <asp:ListItem Value="PersonnelFile">Personnel File</asp:ListItem>
            <asp:ListItem Value="Security">Security</asp:ListItem>
        </asp:DropDownList>
        <asp:TextBox ID="txtDateFrom" runat="server" CssClass="form-control" TextMode="Date" style="width:140px;" />
        <asp:TextBox ID="txtDateTo"   runat="server" CssClass="form-control" TextMode="Date" style="width:140px;" />
        <div class="search-wrap" style="flex:1;min-width:160px;">
            <asp:TextBox ID="txtUser" runat="server" CssClass="form-control" placeholder="Filter by user..." />
        </div>
        <asp:Button ID="btnSearch" runat="server" Text="Search"       CssClass="btn btn-primary"   OnClick="SearchLogs" />
        <asp:Button ID="btnReset"  runat="server" Text="Reset"        CssClass="btn btn-secondary" OnClick="ResetLogs" />
        <asp:Button ID="btnExport" runat="server" Text="Export Excel" CssClass="btn btn-secondary" OnClick="ExportLogs" />
    </div>

    <!-- Count bar -->
    <div style="padding:8px 18px;border-bottom:1px solid #E2E8F0;font-size:12px;color:#64748B;">
        <asp:Label ID="lblCount" runat="server" Text="0" CssClass="fw-600" style="color:#111827;" /> records found
    </div>

    <!-- Table -->
    <div class="table-responsive">
        <asp:GridView ID="gvLogs" runat="server" AutoGenerateColumns="false"
            CssClass="ent-gridview" GridLines="None" AllowPaging="true" PageSize="30"
            OnPageIndexChanging="gvLogs_PageIndexChanging"
            PagerSettings-Mode="NumericFirstLast"
            PagerStyle-CssClass="pager-row">
            <Columns>
                <asp:BoundField DataField="date_time"  HeaderText="Timestamp"  DataFormatString="{0:MM/dd/yyyy HH:mm:ss}" ItemStyle-Width="160px" ItemStyle-CssClass="fs-12 text-muted" />
                <asp:BoundField DataField="fullname"   HeaderText="User"       ItemStyle-CssClass="fw-600" />
                <asp:TemplateField HeaderText="Category">
                    <ItemTemplate>
                        <span class="badge badge-gray"><%# Eval("category") %></span>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="activity"   HeaderText="Activity"   ItemStyle-CssClass="fs-12" />
                <asp:BoundField DataField="ip_address" HeaderText="IP Address" ItemStyle-Width="120px" ItemStyle-CssClass="fs-12 text-muted" />
            </Columns>
            <EmptyDataTemplate>
                <div class="empty-state">
                    <div class="empty-state-icon"><i class="fa fa-scroll"></i></div>
                    <div class="empty-state-title">No activity logs found</div>
                    <div class="empty-state-desc">Try adjusting your filters</div>
                </div>
            </EmptyDataTemplate>
        </asp:GridView>
    </div>
</div>

</asp:Content>
