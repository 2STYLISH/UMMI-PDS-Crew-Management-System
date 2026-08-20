<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="CrewChangeList.aspx.vb"
    Inherits="CrewChangeList" Title="Crew Change List" MaintainScrollPositionOnPostback="true" %>

<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="fade-in">
    <h2 style="font-size:20px;font-weight:700;color:#1a2744;margin-bottom:16px;">
        <i class="fa fa-arrows-rotate me-2 text-primary"></i>Crew Change List
    </h2>

    <asp:Label ID="lblNotify" runat="server" Text="" />

    <div class="card mb-3">
        <div class="card-header-ummi d-flex justify-content-between">
            <span><i class="fa fa-ship me-2"></i><asp:Label ID="lblVesselName" runat="server" Text="All Vessels" /></span>
        </div>
        <div class="card-body-ummi" style="padding:0;">
            <div class="grid-wrapper">
                <asp:GridView ID="gvCCL" runat="server" AutoGenerateColumns="false"
                    CssClass="ummi-table" GridLines="None"
                    EmptyDataText="&lt;div style='padding:30px;text-align:center;color:#94a3b8;'&gt;No crew change records found.&lt;/div&gt;">
                    <Columns>
                        <asp:BoundField DataField="rank_code"  HeaderText="Rank" />
                        <asp:BoundField DataField="crew_name"  HeaderText="Crew Name" />
                        <asp:BoundField DataField="crew_status_text" HeaderText="Status" />
                        <asp:BoundField DataField="date_from"  HeaderText="Sign-On" DataFormatString="{0:MM/dd/yyyy}" />
                        <asp:BoundField DataField="date_to"    HeaderText="Sign-Off" DataFormatString="{0:MM/dd/yyyy}" />
                        <asp:BoundField DataField="vessel_name" HeaderText="Vessel" />
                    </Columns>
                </asp:GridView>
            </div>
        </div>
    </div>
</div>
</asp:Content>
