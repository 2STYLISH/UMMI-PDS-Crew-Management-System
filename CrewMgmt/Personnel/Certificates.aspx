<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="Certificates.aspx.vb"
    Inherits="Certificates" Title="Certificates (APAT/PDOS/PETE)" %>
<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="fade-in">
<h2 style="font-size:20px;font-weight:700;color:#1a2744;margin-bottom:16px;">
    <i class="fa fa-award me-2 text-primary"></i>Certificates — APAT / PDOS / PETE
</h2>
<asp:Label ID="lblNotify" runat="server" Text="" />

<div class="filter-panel mb-3">
    <div class="filter-panel-title"><i class="fa fa-sliders"></i> Filter</div>
    <div class="row g-2">
        <div class="col-md-3"><label class="form-label-ummi">Certificate Type</label>
            <asp:DropDownList ID="drpdwnCertType" runat="server" CssClass="form-control-ummi"
                AutoPostBack="true" OnSelectedIndexChanged="SearchCerts">
                <asp:ListItem Value="APAT">APAT</asp:ListItem>
                <asp:ListItem Value="PDOS">PDOS</asp:ListItem>
                <asp:ListItem Value="PETE">PETE</asp:ListItem>
            </asp:DropDownList></div>
        <div class="col-md-3"><label class="form-label-ummi">Crew Name</label>
            <asp:TextBox ID="txtName" runat="server" CssClass="form-control-ummi" placeholder="Last name..." /></div>
        <div class="col-md-3 d-flex align-items-end gap-2">
            <asp:Button ID="btnSearch" runat="server" Text="Search" CssClass="btn-ummi-primary" OnClick="SearchCerts" />
            <asp:Button ID="btnExport" runat="server" Text="Export" CssClass="btn-ummi-secondary" OnClick="ExportCerts" />
        </div>
    </div>
</div>

<div class="card">
    <div class="card-body-ummi" style="padding:0;">
        <asp:GridView ID="gvCerts" runat="server" AutoGenerateColumns="false"
            CssClass="ummi-table" GridLines="None" AllowPaging="true" PageSize="20"
            OnPageIndexChanging="gvCerts_PageIndexChanging" OnRowDataBound="gvCerts_RowDataBound"
            EmptyDataText="&lt;div style=''padding:30px;text-align:center;color:#94a3b8;''&gt;No certificates found.&lt;/div&gt;">
            <Columns>
                <asp:TemplateField HeaderText="Crew Name">
                    <ItemTemplate><%# Eval("lastname") & ", " & Eval("firstname") %></ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="rank_code"    HeaderText="Rank" />
                <asp:BoundField DataField="documentName" HeaderText="Certificate" />
                <asp:BoundField DataField="document_num" HeaderText="Document No." />
                <asp:BoundField DataField="date_issued"  HeaderText="Issued" DataFormatString="{0:MM/dd/yyyy}" />
                <asp:BoundField DataField="date_expiry"  HeaderText="Expiry" DataFormatString="{0:MM/dd/yyyy}" />
            </Columns>
        </asp:GridView>
    </div>
</div>
</div>
</asp:Content>
