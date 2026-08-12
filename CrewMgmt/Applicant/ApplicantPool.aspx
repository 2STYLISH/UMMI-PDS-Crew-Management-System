<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="ApplicantPool.aspx.vb"
    Inherits="ApplicantPool" Title="Applicant Pool" MaintainScrollPositionOnPostback="true" %>

<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="fade-in">

<h2 style="font-size:20px;font-weight:700;color:#1a2744;margin-bottom:16px;">
    <i class="fa fa-user-clock me-2 text-primary"></i>Applicant Pool
</h2>

<asp:Label ID="lblNotify" runat="server" Text="" />

<!-- -- SEARCH FILTERS -- -->
<div class="filter-panel mb-3">
    <div class="filter-panel-title"><i class="fa fa-sliders"></i> Search Filters</div>
    <div class="row g-2">
        <div class="col-6 col-md-2"><label class="form-label-ummi">Last Name</label>
            <asp:TextBox ID="txtLastName" runat="server" CssClass="form-control-ummi" placeholder="Last name..." /></div>
        <div class="col-6 col-md-2"><label class="form-label-ummi">First Name</label>
            <asp:TextBox ID="txtFirstName" runat="server" CssClass="form-control-ummi" placeholder="First name..." /></div>
        <div class="col-6 col-md-2"><label class="form-label-ummi">Rank Type</label>
            <asp:DropDownList ID="drpdwnRankType" runat="server" CssClass="form-control-ummi"
                AutoPostBack="true" OnSelectedIndexChanged="RankTypeChanged" /></div>
        <div class="col-6 col-md-2"><label class="form-label-ummi">Rank</label>
            <asp:DropDownList ID="drpdwnRank" runat="server" CssClass="form-control-ummi" /></div>
        <div class="col-6 col-md-2"><label class="form-label-ummi">Date Applied From</label>
            <asp:TextBox ID="txtDateFrom" runat="server" CssClass="form-control-ummi" TextMode="Date" /></div>
        <div class="col-6 col-md-2"><label class="form-label-ummi">Date Applied To</label>
            <asp:TextBox ID="txtDateTo" runat="server" CssClass="form-control-ummi" TextMode="Date" /></div>
    </div>
    <div class="d-flex gap-2 mt-3">
        <asp:Button ID="btnSearch"      runat="server" Text="&#xF002; Search"       CssClass="btn-ummi-primary" OnClick="SearchApplicants" />
        <asp:Button ID="btnReset"       runat="server" Text="&#xF2EA; Reset"        CssClass="btn-ummi-secondary" OnClick="ResetFilters" />
        <asp:Button ID="btnGenerateLink" runat="server" Text="&#xF064; Generate Applicant Link"
            CssClass="btn-ummi-primary" OnClick="ShowGenerateLink"
            Style="background:#8b5cf6;" />
        <asp:Button ID="btnManageLinks" runat="server" Text="&#xF0C1; Manage Links"
            CssClass="btn-ummi-secondary" OnClick="ShowManageLinks" />
    </div>
</div>

<!-- -- SUMMARY BAR -- -->
<div class="summary-bar mb-2" id="divSummary" runat="server" visible="false">
    <div class="summary-item"><strong><asp:Label ID="lblCount" runat="server" Text="0" /></strong>Applicants</div>
    <div class="summary-item"><strong><asp:Label ID="lblAvgAge" runat="server" Text="0" /></strong>Avg. Age</div>
</div>

<!-- -- GENERATE LINK PANEL (WBS 1.3.6-1.3.10) -- -->
<asp:Panel ID="panelGenerateLink" runat="server" Visible="false" CssClass="card mb-3">
    <div class="card-header-ummi d-flex justify-content-between">
        <span><i class="fa fa-link me-2"></i>Generate Applicant Self-Encode Link</span>
        <asp:Button ID="btnCloseGenPanel" runat="server" Text="&#xF00D;" CssClass="btn btn-sm btn-close"
            OnClick="HideGenerateLink" />
    </div>
    <div class="card-body-ummi">
        <div class="row g-2 mb-3">
            <div class="col-md-4">
                <label class="form-label-ummi">Full Name *</label>
                <asp:TextBox ID="txtLinkFullname" runat="server" CssClass="form-control-ummi" placeholder="Applicant full name" />
            </div>
            <div class="col-md-4">
                <label class="form-label-ummi">Email *</label>
                <asp:TextBox ID="txtLinkEmail" runat="server" CssClass="form-control-ummi" placeholder="applicant@email.com" TextMode="Email" />
            </div>
            <div class="col-md-2">
                <label class="form-label-ummi">Position Applied</label>
                <asp:DropDownList ID="drpdwnLinkRank" runat="server" CssClass="form-control-ummi" />
            </div>
            <div class="col-md-2">
                <label class="form-label-ummi">Link Validity</label>
                <asp:TextBox ID="txtLinkValidity" runat="server" CssClass="form-control-ummi"
                    TextMode="Date" />
            </div>
        </div>
        <asp:Button ID="btnCreateLink" runat="server" Text="Generate Link" CssClass="btn-ummi-primary" OnClick="GenerateLink" />

        <!-- Generated link display (WBS 1.3.10) -->
        <asp:Panel ID="panelLinkResult" runat="server" Visible="false" Style="margin-top:16px;">
            <div style="background:#f0fdf4;border:1px solid #86efac;border-radius:8px;padding:16px;">
                <div style="font-weight:700;color:#065f46;margin-bottom:8px;">
                    <i class="fa fa-circle-check me-2"></i>Link Generated Successfully
                </div>
                <div style="margin-bottom:8px;font-size:12px;color:#047857;">
                    Share this link with the applicant. It expires on:
                    <asp:Label ID="lblGeneratedExpiry" runat="server" Text="" Style="font-weight:700;" />
                </div>
                <div class="d-flex gap-2 align-items-center">
                    <input type="text" id="txtGeneratedLink" runat="server" readonly
                        style="flex:1;font-family:monospace;font-size:12px;padding:8px;
                               border:1px solid #86efac;border-radius:6px;background:#fff;"
                        runat="server" class="form-control-ummi"
                        value="" />
                    <button type="button" class="copy-btn"
                        onclick="copyToClipboard(document.getElementById('txtGeneratedLink').value,this)"
                        style="white-space:nowrap;">
                        <i class="fa fa-copy me-1"></i>Copy Link
                    </button>
                </div>
                <div style="margin-top:8px;font-size:11px;color:#94a3b8;">
                    No SMTP configured — copy and share this link manually with the applicant.
                </div>
            </div>
        </asp:Panel>
    </div>
</asp:Panel>

<!-- -- MANAGE LINKS PANEL (WBS 1.3.11-1.3.14) -- -->
<asp:Panel ID="panelManageLinks" runat="server" Visible="false" CssClass="card mb-3">
    <div class="card-header-ummi d-flex justify-content-between">
        <span><i class="fa fa-link me-2"></i>Manage Generated Links</span>
        <asp:Button ID="btnCloseManagePanel" runat="server" Text="&#xF00D;"
            CssClass="btn btn-sm btn-close" OnClick="HideManageLinks" />
    </div>
    <div class="card-body-ummi" style="padding:0;">
        <div class="grid-wrapper">
            <asp:GridView ID="gvLinks" runat="server" AutoGenerateColumns="false"
                CssClass="ummi-table" GridLines="None" OnRowCommand="GvLinks_RowCommand"
                OnRowDataBound="GvLinks_RowDataBound">
                <Columns>
                    <asp:BoundField DataField="fullname" HeaderText="Applicant" />
                    <asp:BoundField DataField="email"    HeaderText="Email" />
                    <asp:BoundField DataField="position_applied" HeaderText="Position" />
                    <asp:BoundField DataField="date_generated" HeaderText="Generated" DataFormatString="{0:MM/dd/yyyy}" />
                    <asp:BoundField DataField="validity" HeaderText="Valid Until" DataFormatString="{0:MM/dd/yyyy}" />
                    <asp:TemplateField HeaderText="Status">
                        <ItemTemplate>
                            <asp:Label ID="lblLinkStatus" runat="server" Text='<%# Eval("status") %>' />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Actions">
                        <ItemTemplate>
                            <asp:LinkButton ID="btnExpireLink" runat="server"
                                CommandName="ExpireLink" CommandArgument='<%# Eval("id") %>'
                                CssClass="btn-ummi-danger" Style="padding:3px 8px;font-size:11px;"
                                Visible='<%# Eval("status").ToString() = "Active" %>'
                                OnClientClick="return confirm('Expire this link?')">Expire</asp:LinkButton>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
        </div>
    </div>
</asp:Panel>

<!-- -- APPLICANT RESULTS (WBS 1.3.1-1.3.5) -- -->
<div class="card">
    <div class="card-body-ummi" style="padding:0;">
        <div class="grid-wrapper">
            <asp:GridView ID="gvApplicants" runat="server"
                AutoGenerateColumns="false" CssClass="ummi-table" GridLines="None"
                AllowPaging="true" PageSize="20"
                OnPageIndexChanging="GvApplicants_PageIndexChanging"
                OnRowDataBound="GvApplicants_RowDataBound"
                OnRowCommand="GvApplicants_RowCommand"
                EmptyDataText="&lt;div style='padding:30px;text-align:center;color:#94a3b8;'&gt;No applicants found.&lt;/div&gt;">
                <Columns>
                    <asp:TemplateField HeaderText="Photo" ItemStyle-Width="60px">
                        <ItemTemplate>
                            <asp:Image ID="imgAvatar" runat="server" CssClass="applicant-avatar"
                                ImageUrl="~/images/silhouette_user.png" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Name">
                        <ItemTemplate>
                            <asp:HyperLink ID="lnkProfile" runat="server" CssClass="gv-link"
                                Text='<%# Eval("lastname") & ", " & Eval("firstname") & " " & Eval("middlename") %>'
                                NavigateUrl='<%# GetProfileUrl(Eval("id")) %>' Target="_blank" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="rank_code"  HeaderText="Applied Rank" />
                    <asp:BoundField DataField="age"        HeaderText="Age" />
                    <asp:BoundField DataField="date_hired" HeaderText="Date Applied" DataFormatString="{0:MM/dd/yyyy}" />
                    <asp:BoundField DataField="applicant_contact_num" HeaderText="Contact" />
                    <asp:TemplateField HeaderText="Vessel Exp." ItemStyle-Width="90px">
                        <ItemTemplate>
                            <asp:Label ID="lblVesselExp" runat="server" Text="" Style="font-size:11px;" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Actions">
                        <ItemTemplate>
                            <asp:LinkButton ID="btnHire" runat="server"
                                CommandName="HireApplicant" CommandArgument='<%# Eval("id") %>'
                                CssClass="btn-ummi-primary" Style="padding:3px 8px;font-size:11px;"
                                OnClientClick="return confirm('Hire this applicant? Status will be changed to Active.')">
                                <i class="fa fa-user-check"></i> Hire
                            </asp:LinkButton>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
        </div>
    </div>
</div>

</div>
</asp:Content>
