<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="PersonnelFile.aspx.vb"
    Inherits="PersonnelFile" Title="Personnel File" %>
<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

<asp:Label ID="lblNotify" runat="server" Text="" CssClass="alert alert-info section" />

<div class="card">
    <!-- Filter Row -->
    <div class="filter-row">
        <div class="form-group" style="margin:0;flex:1;min-width:140px;">
            <div class="search-wrap">
                <asp:TextBox ID="txtLastName" runat="server" CssClass="form-control" placeholder="Last name..." />
            </div>
        </div>
        <div class="form-group" style="margin:0;flex:1;min-width:140px;">
            <asp:TextBox ID="txtFirstName" runat="server" CssClass="form-control" placeholder="First name..." />
        </div>
        <div class="form-group" style="margin:0;min-width:160px;">
            <asp:DropDownList ID="drpdwnStatus" runat="server" CssClass="form-select" />
        </div>
        <asp:Button ID="btnSearch" runat="server" Text="Search" CssClass="btn btn-primary" OnClick="SearchPersonnel" />
        <asp:Button ID="btnAddNew" runat="server" Text="+ Add New" CssClass="btn btn-secondary" OnClick="ShowAddNew" />
    </div>

    <!-- Table -->
    <div class="table-responsive">
        <asp:GridView ID="gvPersonnel" runat="server" AutoGenerateColumns="false"
            CssClass="ent-gridview" GridLines="None" AllowPaging="true" PageSize="20"
            OnPageIndexChanging="gvPersonnel_PageIndexChanging"
            PagerSettings-Mode="NumericFirstLast"
            PagerStyle-CssClass="pager-row">
            <Columns>
                <asp:TemplateField HeaderText="Name">
                    <ItemTemplate>
                        <asp:HyperLink ID="lnkProfile" runat="server" CssClass="gv-link fw-600"
                            Text='<%# Eval("lastname") & ", " & Eval("firstname") %>'
                            NavigateUrl='<%# GetProfileUrl(Eval("id")) %>' Target="_blank" />
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="rank_code" HeaderText="Rank" />
                <asp:TemplateField HeaderText="Status">
                    <ItemTemplate>
                        <span class='<%# GetStatusBadge(Eval("crew_status_text").ToString()) %>'>
                            <%# Eval("crew_status_text") %>
                        </span>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="date_hired" HeaderText="Date Hired" DataFormatString="{0:MM/dd/yyyy}" ItemStyle-CssClass="text-muted fs-12" />
                <asp:TemplateField HeaderText="Actions" ItemStyle-CssClass="row-actions">
                    <ItemTemplate>
                        <asp:HyperLink ID="lnkCOE" runat="server" CssClass="gv-link"
                            NavigateUrl='<%# GetCOEUrl(Eval("id")) %>' Target="_blank">COE</asp:HyperLink>
                        <asp:HyperLink ID="lnkCerts" runat="server" CssClass="gv-link"
                            NavigateUrl='<%# GetCertsUrl(Eval("id")) %>' Target="_blank">Certs</asp:HyperLink>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
            <EmptyDataTemplate>
                <div class="empty-state">
                    <div class="empty-state-icon"><i class="fa fa-folder-open"></i></div>
                    <div class="empty-state-title">No personnel found</div>
                    <div class="empty-state-desc">Try adjusting your search filters</div>
                </div>
            </EmptyDataTemplate>
        </asp:GridView>
    </div>
</div>

</asp:Content>
