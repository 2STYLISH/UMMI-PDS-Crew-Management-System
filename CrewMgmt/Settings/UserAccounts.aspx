<%@ Page Title="User Accounts" Language="VB" MasterPageFile="~/masterPage.Master" AutoEventWireup="false" CodeBehind="UserAccounts.aspx.vb" Inherits="Settings_UserAccounts" %>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <style>
        .ua-card { border: 1px solid #e2e8f0; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.02); background: #fff; padding: 24px; margin-bottom: 24px; }
        .ua-title { font-size: 1.25rem; font-weight: 600; color: #0f172a; margin-bottom: 20px; display: flex; align-items: center; gap: 8px; }
        .ua-search-box { display: flex; gap: 10px; max-width: 500px; margin-bottom: 24px; }
        .ua-table { border-collapse: separate; border-spacing: 0; width: 100%; border: 1px solid #e2e8f0; border-radius: 6px; overflow: hidden; }
        .ua-table th { background: #f8fafc; font-weight: 600; font-size: 13px; color: #475569; padding: 12px 16px; border-bottom: 1px solid #e2e8f0; text-transform: uppercase; letter-spacing: 0.5px; }
        .ua-table td { padding: 12px 16px; font-size: 14px; color: #1e293b; border-bottom: 1px solid #f1f5f9; vertical-align: middle; }
        .ua-table tr:last-child td { border-bottom: none; }
        .ua-table tr:hover td { background-color: #f8fafc; }
        .ua-btn-select { font-size: 12px; font-weight: 600; padding: 6px 12px; border-radius: 5px; background: #fff; color: #3b82f6; border: 1px solid #bfdbfe; transition: all 0.15s; text-decoration: none; display: inline-block; cursor: pointer; }
        .ua-btn-select:hover { background: #eff6ff; color: #2563eb; border-color: #93c5fd; }
        .ua-user-info { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 6px; padding: 16px; margin-bottom: 24px; display: flex; align-items: center; gap: 16px; }
        .ua-avatar { width: 48px; height: 48px; border-radius: 50%; background: #e2e8f0; color: #475569; display: flex; align-items: center; justify-content: center; font-size: 20px; font-weight: bold; }
        .ua-info-details h5 { margin: 0 0 4px 0; font-size: 16px; font-weight: 600; color: #0f172a; }
        .ua-info-details p { margin: 0; font-size: 13px; color: #64748b; }
        .ua-role-badge { display: inline-block; padding: 3px 8px; border-radius: 999px; background: #e0e7ff; color: #4338ca; font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.3px; margin-top: 4px; }
        .ua-switch-group { background: #fff; border: 1px solid #e2e8f0; border-radius: 6px; padding: 20px; margin-bottom: 24px; }
        .ua-switch-item { display: flex; justify-content: space-between; align-items: center; padding: 12px 0; border-bottom: 1px solid #f1f5f9; }
        .ua-switch-item:last-child { border-bottom: none; padding-bottom: 0; }
        .ua-switch-item:first-child { padding-top: 0; }
        .ua-switch-label { font-weight: 500; color: #334155; font-size: 14px; }
        .ua-switch-desc { display: block; font-size: 12px; color: #64748b; font-weight: 400; margin-top: 2px; }
        .ua-alert { background: #eff6ff; border: 1px solid #bfdbfe; color: #1e40af; padding: 12px 16px; border-radius: 6px; font-size: 13px; margin-bottom: 24px; display: flex; gap: 12px; align-items: flex-start; }
        .ua-alert i { font-size: 16px; margin-top: 2px; }
        .ua-actions { display: flex; gap: 12px; }
    </style>

    <div class="row">
        <div class="col-md-12">
            
            <asp:Panel ID="pnlSearch" runat="server" CssClass="ua-card">
                <div class="ua-title"><i class="fa fa-users-gear text-primary"></i> User Access Management</div>
                <p class="text-muted small mb-4">Search for a user to configure their individual feature access overrides.</p>
                
                <div class="ua-search-box">
                    <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control" placeholder="Search by username or name..."></asp:TextBox>
                    <asp:Button ID="btnSearch" runat="server" Text="Search" CssClass="btn btn-primary" OnClick="btnSearch_Click" />
                </div>
                
                <asp:GridView ID="gvUsers" runat="server" AutoGenerateColumns="false" CssClass="ua-table" GridLines="None"
                    DataKeyNames="id" OnSelectedIndexChanged="gvUsers_SelectedIndexChanged">
                    <Columns>
                        <asp:BoundField DataField="username" HeaderText="Username" />
                        <asp:BoundField DataField="fullname" HeaderText="Full Name" />
                        <asp:BoundField DataField="type" HeaderText="Role" />
                        <asp:CommandField ShowSelectButton="true" SelectText="Manage Access" ControlStyle-CssClass="ua-btn-select" ItemStyle-Width="120px" ItemStyle-HorizontalAlign="Right" />
                    </Columns>
                    <EmptyDataTemplate>
                        <div class="text-center text-muted py-4">No users found. Try adjusting your search.</div>
                    </EmptyDataTemplate>
                </asp:GridView>
            </asp:Panel>

            <asp:Panel ID="pnlEdit" runat="server" CssClass="ua-card" Visible="false">
                <div class="ua-title"><i class="fa fa-sliders text-primary"></i> Configure Access Overrides</div>
                
                <div class="ua-user-info">
                    <div class="ua-avatar"><i class="fa fa-user"></i></div>
                    <div class="ua-info-details">
                        <h5><asp:Label ID="lblEditUser" runat="server"></asp:Label></h5>
                        <asp:Label ID="lblEditRole" runat="server" CssClass="ua-role-badge"></asp:Label>
                    </div>
                </div>

                <div class="ua-alert">
                    <i class="fa fa-info-circle"></i>
                    <div>
                        <strong>Important Context</strong><br />
                        Enabling a feature here cannot grant access if the user's role does not normally permit it. A per-user disable will always override and block access. Changes take effect at the user's next sign-in.
                    </div>
                </div>

                <asp:HiddenField ID="hfEditUserId" runat="server" />

                <asp:Panel ID="pnlSettings" runat="server" CssClass="ua-switch-group">
                    <div class="ua-switch-item">
                        <div>
                            <span class="ua-switch-label">Allow Crew Search</span>
                            <span class="ua-switch-desc">Permit this user to search and view the main crew roster.</span>
                        </div>
                        <div class="form-check form-switch">
                            <input type="checkbox" id="chkAllowCrewSearch" runat="server" class="form-check-input fs-5 m-0" />
                        </div>
                    </div>
                    <div class="ua-switch-item">
                        <div>
                            <span class="ua-switch-label">Allow Applicant Pool</span>
                            <span class="ua-switch-desc">Permit this user to access the applicant pool and generation links.</span>
                        </div>
                        <div class="form-check form-switch">
                            <input type="checkbox" id="chkAllowApplicantPool" runat="server" class="form-check-input fs-5 m-0" />
                        </div>
                    </div>
                </asp:Panel>

                <asp:Panel ID="pnlSuperAdmin" runat="server" Visible="false" CssClass="ua-alert" style="background:#fffbeb; border-color:#fde68a; color:#b45309;">
                    <i class="fa fa-shield-halved"></i>
                    <div>
                        <strong>Super-Admin Bypass Active</strong><br />
                        This user is a Super-Admin. The legacy bypass applies, meaning both Crew Search and Applicant Pool are strictly <strong>Always allowed</strong>.
                    </div>
                </asp:Panel>

                <div class="ua-actions">
                    <asp:Button ID="btnSave" runat="server" Text="Save Configuration" CssClass="btn btn-primary px-4" OnClick="btnSave_Click" />
                    <asp:Button ID="btnCancel" runat="server" Text="Back to Search" CssClass="btn btn-light px-4" OnClick="btnCancel_Click" />
                </div>
                
                <div class="mt-3">
                    <asp:Label ID="lblMessage" runat="server" CssClass="text-success fw-bold small"></asp:Label>
                </div>
            </asp:Panel>

        </div>
    </div>
</asp:Content>
