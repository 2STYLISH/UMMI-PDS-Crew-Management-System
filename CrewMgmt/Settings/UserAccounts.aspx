<%@ Page Title="User Accounts" Language="VB" MasterPageFile="~/masterPage.Master" AutoEventWireup="false" CodeBehind="UserAccounts.aspx.vb" Inherits="Settings_UserAccounts" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <div class="row">
        <div class="col-md-12">
            <h4 class="mb-4">User Accounts Management</h4>
            
            <asp:Panel ID="pnlSearch" runat="server" CssClass="card mb-4">
                <div class="card-body">
                    <h5 class="card-title">Search User</h5>
                    <div class="row align-items-end">
                        <div class="col-md-4">
                            <label class="form-label">Username or Name</label>
                            <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control"></asp:TextBox>
                        </div>
                        <div class="col-md-2">
                            <asp:Button ID="btnSearch" runat="server" Text="Search" CssClass="btn btn-primary" OnClick="btnSearch_Click" />
                        </div>
                    </div>
                    
                    <asp:GridView ID="gvUsers" runat="server" AutoGenerateColumns="false" CssClass="table table-striped mt-3"
                        DataKeyNames="id" OnSelectedIndexChanged="gvUsers_SelectedIndexChanged">
                        <Columns>
                            <asp:BoundField DataField="username" HeaderText="Username" />
                            <asp:BoundField DataField="fullname" HeaderText="Full Name" />
                            <asp:BoundField DataField="type" HeaderText="Role" />
                            <asp:CommandField ShowSelectButton="true" SelectText="Manage Access" ControlStyle-CssClass="btn btn-sm btn-outline-primary" />
                        </Columns>
                    </asp:GridView>
                </div>
            </asp:Panel>

            <asp:Panel ID="pnlEdit" runat="server" CssClass="card" Visible="false">
                <div class="card-body">
                    <h5 class="card-title">Manage Access Settings</h5>
                    
                    <div class="mb-3">
                        <strong>User: </strong> <asp:Label ID="lblEditUser" runat="server" CssClass="text-primary fw-bold"></asp:Label><br />
                        <strong>Role: </strong> <asp:Label ID="lblEditRole" runat="server" CssClass="badge bg-secondary"></asp:Label>
                    </div>

                    <div class="alert alert-info">
                        <i class="fa fa-info-circle"></i> <strong>Note:</strong> Enabling a feature here cannot grant access if the user's role does not normally permit it. Changes take effect at the user's next sign-in.
                    </div>

                    <asp:HiddenField ID="hfEditUserId" runat="server" />

                    <asp:Panel ID="pnlSettings" runat="server">
                        <div class="form-check form-switch mb-3">
                            <asp:CheckBox ID="chkAllowCrewSearch" runat="server" CssClass="form-check-input" />
                            <label class="form-check-label">Allow Crew Search</label>
                        </div>
                        <div class="form-check form-switch mb-4">
                            <asp:CheckBox ID="chkAllowApplicantPool" runat="server" CssClass="form-check-input" />
                            <label class="form-check-label">Allow Applicant Pool</label>
                        </div>
                        <asp:Button ID="btnSave" runat="server" Text="Save Changes" CssClass="btn btn-success" OnClick="btnSave_Click" />
                        <asp:Button ID="btnCancel" runat="server" Text="Cancel" CssClass="btn btn-light ms-2" OnClick="btnCancel_Click" />
                    </asp:Panel>

                    <asp:Panel ID="pnlSuperAdmin" runat="server" Visible="false">
                        <div class="alert alert-warning">
                            <i class="fa fa-shield"></i> This user is a Super-Admin. The legacy bypass applies, and both Crew Search and Applicant Pool are <strong>Always allowed</strong>.
                        </div>
                        <asp:Button ID="btnCancelSA" runat="server" Text="Back" CssClass="btn btn-light" OnClick="btnCancel_Click" />
                    </asp:Panel>

                    <div class="mt-3">
                        <asp:Label ID="lblMessage" runat="server" CssClass="text-success fw-bold"></asp:Label>
                    </div>
                </div>
            </asp:Panel>

        </div>
    </div>
</asp:Content>
