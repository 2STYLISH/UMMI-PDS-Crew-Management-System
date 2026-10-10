<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="CCLContractCOE.aspx.vb"
    Inherits="CCLContractCOE" Title="Contract of Employment (POEA/DMW)" %>
<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="fade-in" id="printArea">
    <asp:Label ID="lblNotify" runat="server" Text="" />
    <asp:Literal ID="litContract" runat="server" />
    <div class="no-print mt-3 d-flex gap-2">
        <button type="button" class="btn-ummi-primary" onclick="window.print();"><i class="fa fa-print"></i> Print COE</button>
        <asp:HyperLink ID="lnkBack" runat="server" CssClass="btn-ummi-secondary" NavigateUrl="~/Crew/CrewChangeList.aspx" Text="Back to CCL" />
    </div>
</div>
</asp:Content>
