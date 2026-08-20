<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="ApplicantPool.aspx.vb"
    Inherits="ApplicantPool" Title="Applicant Pool" MaintainScrollPositionOnPostback="true" %>

<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="fade-in">

<h2 style="font-size:20px;font-weight:700;color:#1a2744;margin-bottom:16px;">
    <i class="fa fa-user-clock me-2 text-primary"></i>Applicant Pool
</h2>

<asp:Label ID="lblNotify" runat="server" Text="" />

<!-- -- SEARCH FILTERS (UC-CM-13) -- -->
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
        <!-- UC-CM-13: Vessel Experience Type filter (FR-CM-33) -->
        <div class="col-6 col-md-2"><label class="form-label-ummi">Vessel Exp. Type</label>
            <asp:DropDownList ID="drpdwnVesselExpType" runat="server" CssClass="form-control-ummi" /></div>
        <div class="col-6 col-md-2"><label class="form-label-ummi">Date Applied From</label>
            <asp:TextBox ID="txtDateFrom" runat="server" CssClass="form-control-ummi" TextMode="Date" /></div>
    </div>
    <div class="row g-2 mt-1">
        <div class="col-6 col-md-2"><label class="form-label-ummi">Date Applied To</label>
            <asp:TextBox ID="txtDateTo" runat="server" CssClass="form-control-ummi" TextMode="Date" /></div>
    </div>
    <div class="d-flex gap-2 mt-3 flex-wrap">
        <asp:Button ID="btnSearch"      runat="server" Text="&#xF002; Search"       CssClass="btn-ummi-primary" OnClick="SearchApplicants" />
        <asp:Button ID="btnReset"       runat="server" Text="&#xF2EA; Reset"        CssClass="btn-ummi-secondary" OnClick="ResetFilters" />
        <!-- UC-CM-15: Add Applicant Manually (FR-CM-36) -->
        <asp:Button ID="btnAddApplicant" runat="server" Text="&#xF234; Add Applicant"
            CssClass="btn-ummi-primary" OnClick="AddApplicantManually"
            Style="background:#059669;" />
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

<!-- -- GENERATE LINK PANEL (UC-CM-16/17) -- -->
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
                <!-- UC-CM-16: Default to next day (FR-CM-39) -->
                <label class="form-label-ummi">Link Validity</label>
                <asp:TextBox ID="txtLinkValidity" runat="server" CssClass="form-control-ummi" TextMode="Date" />
            </div>
        </div>
        <asp:Button ID="btnCreateLink" runat="server" Text="Generate Link" CssClass="btn-ummi-primary" OnClick="GenerateLink" />

        <!-- Generated link display -->
        <asp:Panel ID="panelLinkResult" runat="server" Visible="false" Style="margin-top:16px;">
            <div style="background:#f0fdf4;border:1px solid #86efac;border-radius:8px;padding:16px;">
                <div style="font-weight:700;color:#065f46;margin-bottom:8px;">
                    <i class="fa fa-circle-check me-2"></i>Link Generated Successfully
                </div>
                <div style="margin-bottom:8px;font-size:12px;color:#047857;">
                    Share this link with the applicant. It expires on:
                    <asp:Label ID="lblGeneratedExpiry" runat="server" Text="" Style="font-weight:700;" />
                </div>
                <div class="d-flex gap-2 align-items-center flex-wrap">
                    <input type="text" id="txtGeneratedLink" runat="server" readonly
                        style="flex:1;font-family:monospace;font-size:12px;padding:8px;
                               border:1px solid #86efac;border-radius:6px;background:#fff;min-width:250px;"
                        class="form-control-ummi" value="" />
                    <button type="button" class="copy-btn"
                        onclick="copyToClipboard(document.getElementById('<%= txtGeneratedLink.ClientID %>').value,this)"
                        style="white-space:nowrap;">
                        <i class="fa fa-copy me-1"></i>Copy Link
                    </button>
                    <!-- UC-CM-17: Send Link via Email (FR-CM-41) -->
                    <asp:Button ID="btnSendLinkEmail" runat="server" Text="&#xF0E0; Send via Email"
                        CssClass="btn-ummi-primary" OnClick="SendLinkEmail"
                        Style="background:#0284c7;font-size:12px;padding:6px 12px;" />
                </div>
                <div style="margin-top:8px;font-size:11px;color:#94a3b8;">
                    No SMTP configured — copy and share this link manually, or click "Send via Email" to open your email client.
                </div>
            </div>
        </asp:Panel>
    </div>
</asp:Panel>

<!-- -- MANAGE LINKS PANEL (UC-CM-18/19/20/21/22) -- -->
<asp:Panel ID="panelManageLinks" runat="server" Visible="false" CssClass="card mb-3">
    <div class="card-header-ummi d-flex justify-content-between">
        <span><i class="fa fa-link me-2"></i>Manage Generated Links</span>
        <asp:Button ID="btnCloseManagePanel" runat="server" Text="&#xF00D;"
            CssClass="btn btn-sm btn-close" OnClick="HideManageLinks" />
    </div>
    <div class="card-body-ummi">
        <!-- UC-CM-18: Status filter (FR-CM-42) -->
        <div class="d-flex gap-2 mb-3 align-items-center flex-wrap">
            <label class="form-label-ummi" style="margin-bottom:0;">Filter by Status:</label>
            <asp:DropDownList ID="drpdwnLinkStatusFilter" runat="server" CssClass="form-control-ummi"
                AutoPostBack="true" OnSelectedIndexChanged="FilterLinksChanged" Style="width:auto;">
                <asp:ListItem Value="">ALL</asp:ListItem>
                <asp:ListItem Value="Active">Active</asp:ListItem>
                <asp:ListItem Value="Expired">Expired</asp:ListItem>
                <asp:ListItem Value="Used">Used</asp:ListItem>
            </asp:DropDownList>
            <!-- UC-CM-20: Bulk expire action (FR-CM-45) -->
            <asp:Button ID="btnBulkExpire" runat="server" Text="&#xF071; Move Expired Links"
                CssClass="btn-ummi-secondary" OnClick="MoveExpiredLinks"
                OnClientClick="return confirm('Move all Active links with expired validity to Expired status?')"
                Style="font-size:11px;" />
        </div>
        <div style="padding:0;">
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
                        <asp:BoundField DataField="last_date_access" HeaderText="Last Access" DataFormatString="{0:MM/dd/yyyy HH:mm}" />
                        <asp:BoundField DataField="generated_by_name" HeaderText="Generated By" />
                        <asp:TemplateField HeaderText="Status">
                            <ItemTemplate>
                                <asp:Label ID="lblLinkStatus" runat="server" Text='<%# Eval("status") %>' />
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Actions">
                            <ItemTemplate>
                                <div class="d-flex gap-1 flex-wrap">
                                    <!-- UC-CM-19: Inline status update (FR-CM-44) -->
                                    <asp:DropDownList ID="drpdwnNewStatus" runat="server" CssClass="form-control-ummi"
                                        Style="width:auto;font-size:11px;padding:2px 6px;"
                                        Visible='<%# Eval("status").ToString() = "Active" %>'>
                                        <asp:ListItem Value="">Change...</asp:ListItem>
                                        <asp:ListItem Value="Expired">Expire</asp:ListItem>
                                    </asp:DropDownList>
                                    <asp:LinkButton ID="btnUpdateStatus" runat="server"
                                        CommandName="UpdateStatus" CommandArgument='<%# Eval("id") %>'
                                        CssClass="btn-ummi-secondary" Style="padding:2px 6px;font-size:11px;"
                                        Visible='<%# Eval("status").ToString() = "Active" %>'
                                        OnClientClick="return confirm('Update this link status?')">Apply</asp:LinkButton>
                                    <!-- UC-CM-22: Resend link (FR-CM-47) -->
                                    <asp:LinkButton ID="btnResend" runat="server"
                                        CommandName="ResendLink" CommandArgument='<%# Eval("id") %>'
                                        CssClass="btn-ummi-primary" Style="padding:2px 6px;font-size:11px;background:#0284c7;"
                                        Visible='<%# Eval("status").ToString() = "Active" %>'>
                                        <i class="fa fa-paper-plane"></i> Resend
                                    </asp:LinkButton>
                                    <!-- UC-CM-21: Delete (FR-CM-46) — only for non-Active -->
                                    <asp:LinkButton ID="btnDeleteLink" runat="server"
                                        CommandName="DeleteLink" CommandArgument='<%# Eval("id") %>'
                                        CssClass="btn-ummi-danger" Style="padding:2px 6px;font-size:11px;"
                                        Visible='<%# Eval("status").ToString() <> "Active" %>'
                                        OnClientClick="return confirm('Permanently delete this link record?')">
                                        <i class="fa fa-trash"></i> Delete
                                    </asp:LinkButton>
                                </div>
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                </asp:GridView>
            </div>
        </div>
    </div>
</asp:Panel>

<!-- -- APPLICANT RESULTS (UC-CM-13/14) -- -->
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
                    <asp:TemplateField HeaderText="Vessel Exp." ItemStyle-Width="120px">
                        <ItemTemplate>
                            <asp:Label ID="lblVesselExp" runat="server" Text="" Style="font-size:11px;cursor:help;"
                                data-bs-toggle="tooltip" data-bs-placement="top" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Actions">
                        <ItemTemplate>
                            <asp:LinkButton ID="btnHire" runat="server"
                                CommandName="HireApplicant" CommandArgument='<%# Eval("id") %>'
                                CssClass="btn-ummi-primary" Style="padding:3px 8px;font-size:11px;"
                                OnClientClick="return confirm('Do you really want to Hire this applicant? Status will be changed to Active.')">
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
