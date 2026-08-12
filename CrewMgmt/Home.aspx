<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="Home.aspx.vb"
    Inherits="Home" Title="Dashboard" %>

<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

<!-- Stat Cards -->
<div class="stat-grid">
    <div class="stat-card">
        <div class="stat-icon stat-icon--navy"><i class="fa fa-users"></i></div>
        <div class="stat-info">
            <div class="stat-value"><asp:Label ID="lblTotalCrew" runat="server" Text="0" /></div>
            <div class="stat-label">Total Active Crew</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon stat-icon--blue"><i class="fa fa-ship"></i></div>
        <div class="stat-info">
            <div class="stat-value"><asp:Label ID="lblOnBoard" runat="server" Text="0" /></div>
            <div class="stat-label">On Board</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon stat-icon--purple"><i class="fa fa-umbrella-beach"></i></div>
        <div class="stat-info">
            <div class="stat-value"><asp:Label ID="lblOnVacation" runat="server" Text="0" /></div>
            <div class="stat-label">On Vacation</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon stat-icon--amber"><i class="fa fa-user-clock"></i></div>
        <div class="stat-info">
            <div class="stat-value"><asp:Label ID="lblApplicants" runat="server" Text="0" /></div>
            <div class="stat-label">Applicants</div>
        </div>
    </div>
</div>

<!-- Notification -->
<asp:Label ID="lblNotify" runat="server" Text="" Visible="false" CssClass="alert alert-info" />

<!-- Quick Actions -->
<div class="card section" id="divQuickActions" runat="server">
    <div class="card-header">
        <div class="card-header-left">
            <i class="fa fa-bolt" style="color:#2563EB;"></i>
            <span class="card-title">Quick Actions</span>
        </div>
    </div>
    <div class="card-body" style="display:flex;flex-wrap:wrap;gap:8px;">
        <a href="<%=ResolveUrl("~/Crew/QueryCrew.aspx")%>" class="btn btn-primary">
            <i class="fa fa-magnifying-glass"></i> Search Crew
        </a>
        <asp:HyperLink ID="lnkQAApplicantPool" runat="server"
            NavigateUrl="~/Applicant/ApplicantPool.aspx"
            CssClass="btn btn-secondary">
            <i class="fa fa-user-clock"></i> Applicant Pool
        </asp:HyperLink>
        <asp:HyperLink ID="lnkQAPersonnelFile" runat="server"
            NavigateUrl="~/Personnel/PersonnelFile.aspx"
            CssClass="btn btn-secondary">
            <i class="fa fa-folder-open"></i> Personnel File
        </asp:HyperLink>
        <asp:HyperLink ID="lnkQAActivityLogs" runat="server"
            NavigateUrl="~/Settings/ActivityLogs.aspx"
            CssClass="btn btn-secondary">
            <i class="fa fa-scroll"></i> Activity Logs
        </asp:HyperLink>
    </div>
</div>

<!-- Bottom cards -->
<div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;" class="section">

    <!-- Recent Activity -->
    <div class="card" id="divRecentActivity" runat="server">
        <div class="card-header">
            <div class="card-header-left">
                <i class="fa fa-clock-rotate-left" style="color:#64748B;"></i>
                <span class="card-title">Recent Activity</span>
            </div>
        </div>
        <div class="table-responsive">
            <asp:GridView ID="gvRecentActivity" runat="server"
                AutoGenerateColumns="false" CssClass="ent-gridview"
                GridLines="None" ShowHeader="false">
                <Columns>
                    <asp:BoundField DataField="date_time"  DataFormatString="{0:MM/dd HH:mm}" ItemStyle-CssClass="text-muted fs-12" ItemStyle-Width="90px" />
                    <asp:BoundField DataField="category"   ItemStyle-CssClass="fw-600 fs-12" />
                    <asp:BoundField DataField="activity"   ItemStyle-CssClass="fs-12" />
                    <asp:BoundField DataField="fullname"   ItemStyle-CssClass="text-muted fs-12" />
                </Columns>
                <EmptyDataTemplate>
                    <div class="empty-state">
                        <div class="empty-state-icon"><i class="fa fa-inbox"></i></div>
                        <div class="empty-state-title">No recent activity</div>
                    </div>
                </EmptyDataTemplate>
            </asp:GridView>
        </div>
    </div>

    <!-- Expiring Documents -->
    <div class="card">
        <div class="card-header">
            <div class="card-header-left">
                <i class="fa fa-triangle-exclamation" style="color:#D97706;"></i>
                <span class="card-title">Expiring Documents</span>
                <span class="card-subtitle">Next 30 days</span>
            </div>
        </div>
        <div class="table-responsive">
            <asp:GridView ID="gvExpiringDocs" runat="server"
                AutoGenerateColumns="false" CssClass="ent-gridview" GridLines="None">
                <Columns>
                    <asp:BoundField DataField="crew_name"    HeaderText="Crew"     ItemStyle-CssClass="fw-600" />
                    <asp:BoundField DataField="documentName" HeaderText="Document" ItemStyle-CssClass="fs-12" />
                    <asp:TemplateField HeaderText="Expiry">
                        <ItemTemplate>
                            <span class="badge badge-expiring">
                                <%# CDate(Eval("date_expiry")).ToString("MM/dd/yyyy") %>
                            </span>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
                <EmptyDataTemplate>
                    <div class="empty-state">
                        <div class="empty-state-icon" style="background:#DCFCE7;color:#16A34A;"><i class="fa fa-circle-check"></i></div>
                        <div class="empty-state-title">All documents valid</div>
                        <div class="empty-state-desc">No documents expiring in the next 30 days</div>
                    </div>
                </EmptyDataTemplate>
            </asp:GridView>
        </div>
    </div>

</div>

</asp:Content>
