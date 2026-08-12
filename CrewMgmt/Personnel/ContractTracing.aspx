<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="ContractTracing.aspx.vb"
    Inherits="ContractTracing" Title="Contract Tracing" %>
<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="fade-in">
<h2 style="font-size:20px;font-weight:700;color:#1a2744;margin-bottom:16px;">
    <i class="fa fa-timeline me-2 text-primary"></i>Contract Tracing (Gantt View)
</h2>
<asp:Label ID="lblNotify" runat="server" Text="" />
<div class="filter-panel mb-3">
    <div class="filter-panel-title"><i class="fa fa-sliders"></i> Filter</div>
    <div class="row g-2">
        <div class="col-md-3"><label class="form-label-ummi">Vessel</label>
            <asp:DropDownList ID="drpdwnVessel" runat="server" CssClass="form-control-ummi" /></div>
        <div class="col-md-3"><label class="form-label-ummi">Contract Status</label>
            <asp:DropDownList ID="drpdwnStatus" runat="server" CssClass="form-control-ummi">
                <asp:ListItem Value="">ALL</asp:ListItem>
                <asp:ListItem Value="Active">Active</asp:ListItem>
                <asp:ListItem Value="Completed">Completed</asp:ListItem>
                <asp:ListItem Value="Terminated">Terminated</asp:ListItem>
            </asp:DropDownList></div>
        <div class="col-md-3 d-flex align-items-end gap-2">
            <asp:Button ID="btnSearch" runat="server" Text="Search" CssClass="btn-ummi-primary" OnClick="SearchContracts" />
            <asp:Button ID="btnExport" runat="server" Text="Export" CssClass="btn-ummi-secondary" OnClick="ExportContracts" />
        </div>
    </div>
</div>
<div class="card">
    <div class="card-body-ummi" style="padding:0;">
        <asp:GridView ID="gvContracts" runat="server" AutoGenerateColumns="false"
            CssClass="ummi-table" GridLines="None" AllowPaging="true" PageSize="20"
            OnPageIndexChanging="gvContracts_PageIndexChanging">
            <Columns>
                <asp:TemplateField HeaderText="Crew">
                    <ItemTemplate><%# Eval("lastname") & ", " & Eval("firstname") %></ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="rank_code"   HeaderText="Rank" />
                <asp:BoundField DataField="vessel_name" HeaderText="Vessel" />
                <asp:BoundField DataField="date_from"   HeaderText="Sign-On"  DataFormatString="{0:MM/dd/yyyy}" />
                <asp:BoundField DataField="date_to"     HeaderText="Sign-Off" DataFormatString="{0:MM/dd/yyyy}" />
                <asp:BoundField DataField="status"      HeaderText="Status" />
                <asp:TemplateField HeaderText="Duration (Gantt)" ItemStyle-Width="200px">
                    <ItemTemplate>
                        <div class="gantt-bar" style="width:<%# GetGanttWidth(Eval("date_from"), Eval("date_to")) %>px;min-width:30px;">
                            <%# GetDatePeriod(Eval("date_from"), Eval("date_to")) %>
                        </div>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>
</div>
</div>
</asp:Content>
