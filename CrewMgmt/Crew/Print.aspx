<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="Print.aspx.vb"
    Inherits="PrintPage" Title="Print" %>
<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div id="printArea">
    <div style="text-align:center;margin-bottom:16px;border-bottom:2px solid #1a2744;padding-bottom:12px;">
        <h3 style="margin:0;color:#1a2744;font-size:18px;">UMMI Manning - Crew Management</h3>
        <p style="margin:4px 0;font-size:12px;color:#64748b;">
            <asp:Label ID="lblPrintTitle" runat="server" Text="Crew List" />
            &nbsp;&mdash;&nbsp;Generated: <%=DateTime.Now.ToString("MMMM dd, yyyy HH:mm")%>
        </p>
        <p style="margin:0;font-size:11px;color:#94a3b8;">
            <asp:Label ID="lblPrintFilters" runat="server" Text="" />
        </p>
    </div>
    <asp:GridView ID="gvPrint" runat="server" AutoGenerateColumns="false"
        CssClass="ummi-table" GridLines="Both" Width="100%">
        <Columns>
            <asp:TemplateField HeaderText="#">
                <ItemTemplate><%# Container.DataItemIndex + 1 %></ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Name">
                <ItemTemplate><%# Eval("lastname") & ", " & Eval("firstname") & " " & Eval("middlename") %></ItemTemplate>
            </asp:TemplateField>
            <asp:BoundField DataField="rank_code"        HeaderText="Rank" />
            <asp:BoundField DataField="crew_status_text" HeaderText="Status" />
            <asp:BoundField DataField="age"              HeaderText="Age" />
            <asp:BoundField DataField="province_name"    HeaderText="Province" />
        </Columns>
    </asp:GridView>
    <!-- UC-CM-11/UC-CM-25: Rich print content area -->
    <asp:Literal ID="lblPrintContent" runat="server" Text="" />
    <div style="margin-top:24px;font-size:11px;color:#94a3b8;display:flex;justify-content:space-between;">
        <span>UMMI Manning - Confidential</span>
        <span>Printed by: <asp:Label ID="lblPrintedBy" runat="server" Text="" /></span>
    </div>
</div>
<div class="no-print" style="margin-top:16px;display:flex;gap:8px;">
    <button type="button" onclick="window.print()" class="btn-ummi-primary">
        <i class="fa fa-print"></i> Print
    </button>
    <button type="button" onclick="if(window.opener||window.history.length<=1){window.close();}else{window.history.back();}" class="btn-ummi-secondary">
        <i class="fa fa-xmark"></i> Close
    </button>
</div>
</asp:Content>
