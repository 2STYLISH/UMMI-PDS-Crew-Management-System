<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="TrainingCompliance.aspx.vb"
    Inherits="TrainingCompliance" Title="Training Compliance" %>
<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="fade-in">
<h2 style="font-size:20px;font-weight:700;color:#1a2744;margin-bottom:16px;">
    <i class="fa fa-clipboard-check me-2 text-primary"></i>Training Compliance
</h2>
<asp:Label ID="lblNotify" runat="server" Text="" />
<div class="filter-panel mb-3">
    <div class="filter-panel-title"><i class="fa fa-sliders"></i> Filter</div>
    <div class="row g-2">
        <div class="col-md-3"><label class="form-label-ummi">Rank Type</label>
            <asp:DropDownList ID="drpdwnRankType" runat="server" CssClass="form-control-ummi" /></div>
        <div class="col-md-3"><label class="form-label-ummi">Crew Name</label>
            <asp:TextBox ID="txtName" runat="server" CssClass="form-control-ummi" placeholder="Last name..." /></div>
        <div class="col-md-3 d-flex align-items-end gap-2">
            <asp:Button ID="btnSearch" runat="server" Text="Search" CssClass="btn-ummi-primary" OnClick="SearchCompliance" />
            <asp:Button ID="btnExport" runat="server" Text="Export" CssClass="btn-ummi-secondary" OnClick="ExportCompliance" />
        </div>
    </div>
</div>
<div class="card">
    <div class="card-body-ummi" style="padding:0;">
        <asp:GridView ID="gvCompliance" runat="server" AutoGenerateColumns="false"
            CssClass="ummi-table" GridLines="None" AllowPaging="true" PageSize="20"
            OnPageIndexChanging="gvCompliance_PageIndexChanging" OnRowDataBound="gvCompliance_RowDataBound">
            <Columns>
                <asp:TemplateField HeaderText="Crew Name">
                    <ItemTemplate><%# Eval("lastname") & ", " & Eval("firstname") %></ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="rank_code"    HeaderText="Rank" />
                <asp:BoundField DataField="documentName" HeaderText="Training" />
                <asp:BoundField DataField="date_expiry"  HeaderText="Expiry" DataFormatString="{0:MM/dd/yyyy}" />
                <asp:TemplateField HeaderText="Compliance Status">
                    <ItemTemplate>
                        <asp:Label ID="lblCompliance" runat="server" Text="" />
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>
</div>
</div>
</asp:Content>
