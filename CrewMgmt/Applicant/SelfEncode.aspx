<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="SelfEncode.aspx.vb"
    Inherits="SelfEncode" Title="Applicant Self-Encode" %>
<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="fade-in">
<h2 style="font-size:20px;font-weight:700;color:#1a2744;margin-bottom:4px;">
    <i class="fa fa-pen-to-square me-2 text-primary"></i>Applicant Information Form
</h2>
<p style="font-size:13px;color:#64748b;margin-bottom:20px;">
    Please fill in all required fields accurately. Your information will be saved for review by the Manning Staff.
</p>

<asp:Label ID="lblNotify" runat="server" Text="" />

<div x-data="{ step: 1, maxStep: 3 }">
    <!-- Step Progress -->
    <div class="d-flex gap-0 mb-4" style="border-radius:8px;overflow:hidden;">
        <div :class="step>=1 ? 'btn-ummi-primary' : 'btn-ummi-secondary'"
             style="flex:1;padding:10px;text-align:center;font-size:12px;font-weight:600;">
            <i class="fa fa-user me-1"></i>1. Personal Info
        </div>
        <div :class="step>=2 ? 'btn-ummi-primary' : 'btn-ummi-secondary'"
             style="flex:1;padding:10px;text-align:center;font-size:12px;font-weight:600;">
            <i class="fa fa-id-card me-1"></i>2. Contact &amp; Education
        </div>
        <div :class="step>=3 ? 'btn-ummi-primary' : 'btn-ummi-secondary'"
             style="flex:1;padding:10px;text-align:center;font-size:12px;font-weight:600;">
            <i class="fa fa-circle-check me-1"></i>3. Review &amp; Submit
        </div>
    </div>

    <!-- STEP 1: Personal Info -->
    <div x-show="step===1" class="card mb-3">
        <div class="card-header-ummi"><i class="fa fa-user me-2"></i>Personal Information</div>
        <div class="card-body-ummi">
            <div class="row g-3">
                <div class="col-md-3"><label class="form-label-ummi">Last Name *</label>
                    <asp:TextBox ID="txtLastName" runat="server" CssClass="form-control-ummi" /></div>
                <div class="col-md-3"><label class="form-label-ummi">First Name *</label>
                    <asp:TextBox ID="txtFirstName" runat="server" CssClass="form-control-ummi" /></div>
                <div class="col-md-3"><label class="form-label-ummi">Middle Name</label>
                    <asp:TextBox ID="txtMiddleName" runat="server" CssClass="form-control-ummi" /></div>
                <div class="col-md-3"><label class="form-label-ummi">Suffix</label>
                    <asp:DropDownList ID="drpdwnSuffix" runat="server" CssClass="form-control-ummi">
                        <asp:ListItem Value="">None</asp:ListItem>
                        <asp:ListItem Value="Jr.">Jr.</asp:ListItem>
                        <asp:ListItem Value="Sr.">Sr.</asp:ListItem>
                        <asp:ListItem Value="II">II</asp:ListItem>
                        <asp:ListItem Value="III">III</asp:ListItem>
                    </asp:DropDownList></div>
                <div class="col-md-3"><label class="form-label-ummi">Date of Birth *</label>
                    <asp:TextBox ID="txtDOB" runat="server" CssClass="form-control-ummi" TextMode="Date" /></div>
                <div class="col-md-3"><label class="form-label-ummi">Place of Birth</label>
                    <asp:TextBox ID="txtPOB" runat="server" CssClass="form-control-ummi" /></div>
                <div class="col-md-3"><label class="form-label-ummi">Gender</label>
                    <asp:DropDownList ID="drpdwnGender" runat="server" CssClass="form-control-ummi">
                        <asp:ListItem Value="">Select...</asp:ListItem>
                        <asp:ListItem Value="Male">Male</asp:ListItem>
                        <asp:ListItem Value="Female">Female</asp:ListItem>
                    </asp:DropDownList></div>
                <div class="col-md-3"><label class="form-label-ummi">Civil Status</label>
                    <asp:DropDownList ID="drpdwnCivilStatus" runat="server" CssClass="form-control-ummi">
                        <asp:ListItem Value="">Select...</asp:ListItem>
                        <asp:ListItem Value="Single">Single</asp:ListItem>
                        <asp:ListItem Value="Married">Married</asp:ListItem>
                        <asp:ListItem Value="Widowed">Widowed</asp:ListItem>
                        <asp:ListItem Value="Separated">Separated</asp:ListItem>
                    </asp:DropDownList></div>
                <div class="col-md-3"><label class="form-label-ummi">Religion</label>
                    <asp:DropDownList ID="drpdwnReligion" runat="server" CssClass="form-control-ummi" /></div>
                <div class="col-md-3"><label class="form-label-ummi">Nationality</label>
                    <asp:DropDownList ID="drpdwnNationality" runat="server" CssClass="form-control-ummi" /></div>
                <div class="col-md-3"><label class="form-label-ummi">Height (cm)</label>
                    <asp:TextBox ID="txtHeight" runat="server" CssClass="form-control-ummi" placeholder="e.g. 172" /></div>
                <div class="col-md-3"><label class="form-label-ummi">Weight (kg)</label>
                    <asp:TextBox ID="txtWeight" runat="server" CssClass="form-control-ummi" placeholder="e.g. 70" /></div>
                <div class="col-md-3"><label class="form-label-ummi">Applied Rank *</label>
                    <asp:DropDownList ID="drpdwnRank" runat="server" CssClass="form-control-ummi" /></div>
            </div>
            <div class="d-flex justify-content-end mt-3">
                <button type="button" class="btn-ummi-primary" @click="step=2">Next <i class="fa fa-arrow-right ms-1"></i></button>
            </div>
        </div>
    </div>

    <!-- STEP 2: Contact & Education -->
    <div x-show="step===2" class="card mb-3">
        <div class="card-header-ummi"><i class="fa fa-address-book me-2"></i>Contact &amp; Educational Background</div>
        <div class="card-body-ummi">
            <div class="row g-3">
                <div class="col-md-4"><label class="form-label-ummi">Contact Number *</label>
                    <asp:TextBox ID="txtContact" runat="server" CssClass="form-control-ummi" placeholder="09XX-XXX-XXXX" /></div>
                <div class="col-md-4"><label class="form-label-ummi">Email Address</label>
                    <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control-ummi" TextMode="Email" /></div>
                <div class="col-md-4"><label class="form-label-ummi">Address</label>
                    <asp:TextBox ID="txtAddress" runat="server" CssClass="form-control-ummi" /></div>
                <div class="col-md-4"><label class="form-label-ummi">Province</label>
                    <asp:DropDownList ID="drpdwnProvince" runat="server" CssClass="form-control-ummi"
                        AutoPostBack="true" OnSelectedIndexChanged="ProvinceChanged" /></div>
                <div class="col-md-4"><label class="form-label-ummi">City / Municipality</label>
                    <asp:DropDownList ID="drpdwnCity" runat="server" CssClass="form-control-ummi" /></div>
                <div class="col-md-4"></div>
                <div class="col-md-4"><label class="form-label-ummi">School / University</label>
                    <asp:DropDownList ID="drpdwnSchool" runat="server" CssClass="form-control-ummi" /></div>
                <div class="col-md-4"><label class="form-label-ummi">Course</label>
                    <asp:DropDownList ID="drpdwnCourse" runat="server" CssClass="form-control-ummi" /></div>
            </div>
            <div class="d-flex justify-content-between mt-3">
                <button type="button" class="btn-ummi-secondary" @click="step=1"><i class="fa fa-arrow-left me-1"></i> Back</button>
                <button type="button" class="btn-ummi-primary" @click="step=3">Next <i class="fa fa-arrow-right ms-1"></i></button>
            </div>
        </div>
    </div>

    <!-- STEP 3: Review -->
    <div x-show="step===3" class="card mb-3">
        <div class="card-header-ummi"><i class="fa fa-eye me-2"></i>Review &amp; Submit</div>
        <div class="card-body-ummi">
            <div class="alert alert-info">
                <i class="fa fa-info-circle me-2"></i>
                Please review your information before submitting. Once submitted, you will not be able to edit it without contacting the Manning Office.
            </div>
            <div class="row g-2" style="font-size:13px;">
                <div class="col-md-6"><strong>Name:</strong> <asp:Label ID="lblReviewName" runat="server" Text="" /></div>
                <div class="col-md-6"><strong>DOB:</strong> <asp:Label ID="lblReviewDOB" runat="server" Text="" /></div>
                <div class="col-md-6"><strong>Contact:</strong> <asp:Label ID="lblReviewContact" runat="server" Text="" /></div>
                <div class="col-md-6"><strong>Applied Rank:</strong> <asp:Label ID="lblReviewRank" runat="server" Text="" /></div>
            </div>
            <div class="d-flex justify-content-between mt-3">
                <button type="button" class="btn-ummi-secondary" @click="step=2"><i class="fa fa-arrow-left me-1"></i> Back</button>
                <asp:Button ID="btnSubmit" runat="server" Text="Submit Application"
                    CssClass="btn-ummi-primary" OnClick="SubmitApplication"
                    OnClientClick="showLoading();" />
            </div>
        </div>
    </div>
</div>
</div>
</asp:Content>
