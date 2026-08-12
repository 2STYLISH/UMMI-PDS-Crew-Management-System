<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="COE.aspx.vb"
    Inherits="COE" Title="COE Generation" %>
<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="fade-in">
<h2 style="font-size:20px;font-weight:700;color:#1a2744;margin-bottom:16px;">
    <i class="fa fa-file-certificate me-2 text-primary"></i>Certificate of Employment (COE) Generation
</h2>
<asp:Label ID="lblNotify" runat="server" Text="" />
<div class="row g-3">
    <div class="col-md-6">
        <div class="card">
            <div class="card-header-ummi"><i class="fa fa-search me-2"></i>Select Crew Member</div>
            <div class="card-body-ummi">
                <label class="form-label-ummi">Search by Name</label>
                <div class="d-flex gap-2 mb-3">
                    <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control-ummi" placeholder="Last name..." />
                    <asp:Button ID="btnSearch" runat="server" Text="Search" CssClass="btn-ummi-primary" OnClick="SearchCrew" />
                </div>
                <asp:GridView ID="gvCrew" runat="server" AutoGenerateColumns="false"
                    CssClass="ummi-table" GridLines="None" OnRowCommand="gvCrew_RowCommand">
                    <Columns>
                        <asp:TemplateField HeaderText="Name">
                            <ItemTemplate><%# Eval("lastname") & ", " & Eval("firstname") %></ItemTemplate>
                        </asp:TemplateField>
                        <asp:BoundField DataField="rank_code" HeaderText="Rank" />
                        <asp:TemplateField HeaderText="">
                            <ItemTemplate>
                                <asp:LinkButton ID="btnSelect" runat="server"
                                    CommandName="SelectCrew" CommandArgument='<%# Eval("id") %>'
                                    CssClass="gv-link">Select</asp:LinkButton>
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                </asp:GridView>
            </div>
        </div>
    </div>
    <div class="col-md-6">
        <asp:Panel ID="panelCOE" runat="server" Visible="false">
            <div class="card">
                <div class="card-header-ummi"><i class="fa fa-file-alt me-2"></i>COE Preview</div>
                <div class="card-body-ummi">
                    <div style="border:1px solid #e2e8f0;border-radius:8px;padding:24px;background:#fff;">
                        <div style="text-align:center;margin-bottom:16px;">
                            <h3 style="margin:0;color:#1a2744;">UMMI MANNING CORPORATION</h3>
                            <p style="margin:4px 0;font-size:12px;color:#64748b;">
                                CERTIFICATE OF EMPLOYMENT
                            </p>
                        </div>
                        <p style="font-size:13px;line-height:1.7;">
                            This is to certify that
                            <strong><asp:Label ID="lblCOEName" runat="server" Text="" /></strong>
                            has been employed/engaged with UMMI Manning Corporation as
                            <strong><asp:Label ID="lblCOERank" runat="server" Text="" /></strong>
                            from <strong><asp:Label ID="lblCOEFrom" runat="server" Text="" /></strong>
                            to <strong><asp:Label ID="lblCOETo" runat="server" Text="" /></strong>.
                        </p>
                        <p style="font-size:12px;color:#64748b;">
                            This certification is issued upon the request of the above-named personnel
                            for whatever legal purpose it may serve.
                        </p>
                        <div style="margin-top:30px;text-align:right;font-size:13px;">
                            <div style="border-top:1px solid #334155;display:inline-block;padding-top:6px;min-width:200px;">
                                Manning Manager<br/>UMMI Manning Corporation
                            </div>
                        </div>
                    </div>
                    <div class="d-flex gap-2 mt-3">
                        <asp:Button ID="btnPrintCOE" runat="server" Text="&#xF02F; Print COE"
                            CssClass="btn-ummi-primary" OnClientClick="window.print();return false;" />
                        <asp:Button ID="btnExportCOE" runat="server" Text="&#xF019; Export"
                            CssClass="btn-ummi-secondary" OnClick="ExportCOE" />
                    </div>
                </div>
            </div>
        </asp:Panel>
    </div>
</div>
</div>
</asp:Content>
