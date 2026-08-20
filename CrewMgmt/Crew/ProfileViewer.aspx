<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="ProfileViewer.aspx.vb"
    Inherits="ProfileViewer" Title="Crew Profile" %>
<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="fade-in">

<asp:Label ID="lblNotify" runat="server" Text="" />

<!-- -- PROFILE HEADER -- -->
<div class="profile-header mb-3">
    <asp:Image ID="imgProfilePic" runat="server" CssClass="profile-avatar"
        ImageUrl="~/images/silhouette_user.png" AlternateText="Photo" />
    <div style="flex:1;">
        <div class="profile-name">
            <asp:Label ID="lblFullName" runat="server" Text="" />
        </div>
        <div class="profile-rank">
            <asp:Label ID="lblRank" runat="server" Text="" />
        </div>
        <div class="profile-meta">
            <asp:Label ID="lblEmpStatus" runat="server" Text="" />
            &nbsp;&bull;&nbsp;
            <asp:Label ID="lblCrewStatusText" runat="server" Text="" />
        </div>
        <div style="margin-top:8px;">
            <span class="stat-chip"><i class="fa fa-cake-candles me-1"></i>Age: <asp:Label ID="lblAge" runat="server" Text="" /></span>
            <span class="stat-chip"><i class="fa fa-weight-scale me-1"></i>BMI: <asp:Label ID="lblBMI" runat="server" Text="" /></span>
            <asp:Label ID="lblBMIClass" runat="server" CssClass="bmi-badge" Text="" />
            <span class="stat-chip"><i class="fa fa-briefcase me-1"></i><asp:Label ID="lblTotalService" runat="server" Text="0 yrs" /></span>
        </div>
    </div>
    <div class="d-flex flex-column gap-2">
        <asp:Button ID="btnPrint" runat="server" Text="&#xF02F; Print Data Sheet"
            CssClass="btn-ummi-secondary" OnClick="PrintCrewDetails" />
        <!-- Verify banner (WBS 1.2.21/1.2.22) -->
        <asp:Panel ID="divBtnVerify" runat="server" Visible="false">
            <asp:Button ID="btnVerify" runat="server" Text="&#xF00C; Verify"
                CssClass="btn-ummi-primary" OnClick="VerifyData" />
        </asp:Panel>
    </div>
</div>

<!-- Verify banner -->
<asp:Panel ID="divVerifyColor" runat="server">
    <asp:Panel ID="divVerifyBanner" runat="server" Visible="false" CssClass="verify-banner mb-3">
        <div>
            <div class="verify-title"><i class="fa fa-shield-halved me-2"></i>Verification Mode</div>
            <div style="font-size:12px;opacity:.8;"><asp:Label ID="lblVerifyType" runat="server" Text="" /></div>
        </div>
    </asp:Panel>
</asp:Panel>

<!-- -- MAIN TABS -- -->
<ul class="nav nav-tabs-ummi mb-3" id="profileTabs" role="tablist">
    <li class="nav-item"><button class="nav-link active" data-bs-toggle="tab" data-bs-target="#tabPersonal">Personal Info</button></li>
    <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabDocPersonal">Personal Docs</button></li>
    <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabDocLicense">Licenses</button></li>
    <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabDocMedical">Medical</button></li>
    <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabDocTraining">Training</button></li>
    <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabDocOutsource">Outsource</button></li>
    <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabDocUMMI">UMMI Certs</button></li>
    <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabSeaService">Sea Service</button></li>
    <li class="nav-item" id="liComments" runat="server"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabComments">Assessments</button></li>
    <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabFamily">Family</button></li>
</ul>

<div class="tab-content">

<!-- -- PERSONAL INFO -- -->
<div class="tab-pane fade show active" id="tabPersonal">
    <div class="row g-3">
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header-ummi"><i class="fa fa-id-card me-2"></i>Basic Information</div>
                <div class="card-body-ummi">
                    <table class="table table-sm table-borderless" style="font-size:13px;">
                        <tr><th style="width:40%;">Date of Birth</th><td><asp:Label ID="lblDOB" runat="server" Text="" /></td></tr>
                        <tr><th>Place of Birth</th><td><asp:Label ID="lblPOB" runat="server" Text="" /></td></tr>
                        <tr><th>Gender</th><td><asp:Label ID="lblGender" runat="server" Text="" /></td></tr>
                        <tr><th>Civil Status</th><td><asp:Label ID="lblCivilStatus" runat="server" Text="" /></td></tr>
                        <tr><th>Blood Type</th><td><asp:Label ID="lblBloodType" runat="server" Text="" /></td></tr>
                        <tr><th>Religion</th><td><asp:Label ID="lblReligion" runat="server" Text="" /></td></tr>
                        <tr><th>Nationality</th><td><asp:Label ID="lblNationality" runat="server" Text="" /></td></tr>
                        <tr><th>Height (cm)</th><td><asp:Label ID="lblHeight" runat="server" Text="" /></td></tr>
                        <tr><th>Weight (kg)</th><td><asp:Label ID="lblWeight" runat="server" Text="" /></td></tr>
                        <tr><th>Date Hired</th><td><asp:Label ID="lblDateHired" runat="server" Text="" /></td></tr>
                    </table>
                </div>
            </div>
        </div>
        <!-- Contact (hidden for Principal/Applicant) -->
        <div class="col-md-6" id="divContactInfo" runat="server">
            <div class="card h-100">
                <div class="card-header-ummi"><i class="fa fa-phone me-2"></i>Contact &amp; Address</div>
                <div class="card-body-ummi">
                    <table class="table table-sm table-borderless" style="font-size:13px;">
                        <tr id="trAddress" runat="server">
                            <th style="width:40%;">Address</th><td><asp:Label ID="lblAddress" runat="server" Text="" /></td>
                        </tr>
                        <tr id="trContact" runat="server">
                            <th>Contact No.</th><td><asp:Label ID="lblContact" runat="server" Text="" /></td>
                        </tr>
                        <tr id="trEmail" runat="server">
                            <th>Email</th><td><asp:Label ID="lblEmail" runat="server" Text="" /></td>
                        </tr>
                    </table>
                </div>
            </div>
        </div>
        <!-- Statutory Benefits (WBS 1.2.5/1.2.6) -->
        <div class="col-12" id="divStatutory" runat="server">
            <div class="card">
                <div class="card-header-ummi"><i class="fa fa-shield me-2"></i>Statutory Benefits</div>
                <div class="card-body-ummi">
                    <div class="row g-2">
                        <div class="col-6 col-md-3">
                            <label class="form-label-ummi">SSS No.</label>
                            <div class="d-flex gap-1 align-items-center">
                                <asp:Label ID="lblSSS" runat="server" Text="—" Style="font-family:monospace;" />
                                <button type="button" class="copy-btn" onclick="copyToClipboard('<%=lblSSS.Text%>',this)">Copy</button>
                            </div>
                        </div>
                        <div class="col-6 col-md-3">
                            <label class="form-label-ummi">TIN No.</label>
                            <div class="d-flex gap-1 align-items-center">
                                <asp:Label ID="lblTIN" runat="server" Text="—" Style="font-family:monospace;" />
                                <button type="button" class="copy-btn" onclick="copyToClipboard('<%=lblTIN.Text%>',this)">Copy</button>
                            </div>
                        </div>
                        <div class="col-6 col-md-3">
                            <label class="form-label-ummi">PhilHealth No.</label>
                            <div class="d-flex gap-1 align-items-center">
                                <asp:Label ID="lblPhilHealth" runat="server" Text="—" Style="font-family:monospace;" />
                                <button type="button" class="copy-btn" onclick="copyToClipboard('<%=lblPhilHealth.Text%>',this)">Copy</button>
                            </div>
                        </div>
                        <div class="col-6 col-md-3">
                            <label class="form-label-ummi">Pag-IBIG No.</label>
                            <div class="d-flex gap-1 align-items-center">
                                <asp:Label ID="lblPagIBIG" runat="server" Text="—" Style="font-family:monospace;" />
                                <button type="button" class="copy-btn" onclick="copyToClipboard('<%=lblPagIBIG.Text%>',this)">Copy</button>
                            </div>
                        </div>
                    </div>
                    <!-- UC-CM-07: HMO information -->
                    <div class="row g-2 mt-2">
                        <div class="col-6 col-md-3">
                            <label class="form-label-ummi">HMO Number</label>
                            <asp:Label ID="lblHMONumber" runat="server" Text="—" Style="font-family:monospace;display:block;" />
                        </div>
                        <div class="col-6 col-md-3">
                            <label class="form-label-ummi">HMO Expiry</label>
                            <asp:Label ID="lblHMOExpiry" runat="server" Text="—" Style="display:block;" />
                        </div>
                        <div class="col-6 col-md-3">
                            <label class="form-label-ummi">No. of Dependents</label>
                            <asp:Label ID="lblNumDependents" runat="server" Text="0" Style="display:block;" />
                        </div>
                    </div>
                    <div class="mt-2" style="font-size:11px;color:#64748b;">
                        <asp:Label ID="lblVerifiedBenefits" runat="server" Text="" />
                        &nbsp;<asp:Label ID="lblVerifiedTIN" runat="server" Text="" />
                    </div>
                </div>
            </div>
        </div>

        <!-- UC-CM-07: Uniform Sizes -->
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header-ummi"><i class="fa fa-shirt me-2"></i>Uniform Sizes</div>
                <div class="card-body-ummi">
                    <table class="table table-sm table-borderless" style="font-size:13px;">
                        <tr><th style="width:40%;">Coverall</th><td><asp:Label ID="lblUniformCoverall" runat="server" Text="—" /></td></tr>
                        <tr><th>Shoes</th><td><asp:Label ID="lblUniformShoes" runat="server" Text="—" /></td></tr>
                        <tr><th>Polo</th><td><asp:Label ID="lblUniformPolo" runat="server" Text="—" /></td></tr>
                        <tr><th>Pants</th><td><asp:Label ID="lblUniformPants" runat="server" Text="—" /></td></tr>
                    </table>
                </div>
            </div>
        </div>

        <!-- UC-CM-07: Personal Notes (visible only when user can view contact details) -->
        <div class="col-md-6" id="divPersonalNotes" runat="server">
            <div class="card h-100">
                <div class="card-header-ummi"><i class="fa fa-sticky-note me-2"></i>Personal Notes</div>
                <div class="card-body-ummi">
                    <asp:Label ID="lblPersonalNotes" runat="server" Text="No notes recorded."
                        Style="font-size:13px;color:#475569;white-space:pre-wrap;" />
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Document Tabs (WBS 1.2.9-1.2.14) — rendered server-side -->
<div class="tab-pane fade" id="tabDocPersonal">
    <div class="card"><div class="card-header-ummi"><i class="fa fa-file-lines me-2"></i>Personal Documents</div>
    <div class="card-body-ummi" style="padding:0;">
        <asp:GridView ID="gvDocPersonal" runat="server" AutoGenerateColumns="true"
            CssClass="ummi-table" GridLines="None"
            OnRowDataBound="DocRowDataBound">
        </asp:GridView>
    </div></div>
</div>
<div class="tab-pane fade" id="tabDocLicense">
    <div class="card"><div class="card-header-ummi"><i class="fa fa-id-badge me-2"></i>License Documents</div>
    <div class="card-body-ummi" style="padding:0;">
        <asp:GridView ID="gvDocLicense" runat="server" AutoGenerateColumns="false"
            CssClass="ummi-table" GridLines="None" OnRowDataBound="DocRowDataBound">
        </asp:GridView>
    </div></div>
</div>
<div class="tab-pane fade" id="tabDocMedical">
    <div class="card"><div class="card-header-ummi"><i class="fa fa-stethoscope me-2"></i>Medical Documents</div>
    <div class="card-body-ummi" style="padding:0;">
        <asp:GridView ID="gvDocMedical" runat="server" AutoGenerateColumns="false"
            CssClass="ummi-table" GridLines="None" OnRowDataBound="DocRowDataBound">
        </asp:GridView>
    </div></div>
</div>
<div class="tab-pane fade" id="tabDocTraining">
    <div class="card"><div class="card-header-ummi"><i class="fa fa-graduation-cap me-2"></i>Training Certificates</div>
    <div class="card-body-ummi" style="padding:0;">
        <asp:GridView ID="gvDocTraining" runat="server" AutoGenerateColumns="false"
            CssClass="ummi-table" GridLines="None" OnRowDataBound="DocRowDataBound">
        </asp:GridView>
    </div></div>
</div>
<div class="tab-pane fade" id="tabDocOutsource">
    <div class="card"><div class="card-header-ummi"><i class="fa fa-globe me-2"></i>Outsource Documents</div>
    <div class="card-body-ummi" style="padding:0;">
        <asp:GridView ID="gvDocOutsource" runat="server" AutoGenerateColumns="false"
            CssClass="ummi-table" GridLines="None" OnRowDataBound="DocRowDataBound">
        </asp:GridView>
    </div></div>
</div>
<div class="tab-pane fade" id="tabDocUMMI">
    <div class="card"><div class="card-header-ummi"><i class="fa fa-certificate me-2"></i>UMMI Certificates</div>
    <div class="card-body-ummi" style="padding:0;">
        <asp:GridView ID="gvDocUMMI" runat="server" AutoGenerateColumns="false"
            CssClass="ummi-table" GridLines="None" OnRowDataBound="DocRowDataBound">
        </asp:GridView>
    </div></div>
</div>

<!-- Sea Service (WBS 1.2.17-1.2.19) -->
<div class="tab-pane fade" id="tabSeaService">
    <div class="card">
        <div class="card-header-ummi d-flex justify-content-between align-items-center">
            <span><i class="fa fa-ship me-2"></i>Sea Service History</span>
            <span style="font-size:12px;font-weight:400;">
                <asp:Label ID="lblTotalYrsService" runat="server" Text="Total: 0 yr(s)" />
            </span>
        </div>
        <div class="card-body-ummi" style="padding:0;">
            <asp:GridView ID="gvSeaService" runat="server" AutoGenerateColumns="false"
                CssClass="ummi-table" GridLines="None" OnRowDataBound="SeaServiceRowDataBound">
                <Columns>
                    <asp:BoundField DataField="vessel_name" HeaderText="Vessel" />
                    <asp:BoundField DataField="rank_code"   HeaderText="Rank" />
                    <asp:BoundField DataField="port"        HeaderText="Port" />
                    <asp:BoundField DataField="date_from"   HeaderText="Sign-On"  DataFormatString="{0:MM/dd/yyyy}" />
                    <asp:BoundField DataField="date_to"     HeaderText="Sign-Off" DataFormatString="{0:MM/dd/yyyy}" />
                    <asp:TemplateField HeaderText="Period">
                        <ItemTemplate><asp:Label ID="lblPeriod" runat="server" Text="" /></ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="remarks"     HeaderText="Remarks" />
                </Columns>
            </asp:GridView>
        </div>
    </div>
</div>

<!-- Assessments (WBS 1.2.20) — hidden for Principal -->
<div class="tab-pane fade" id="tabComments">
    <div class="card" id="divComments" runat="server">
        <div class="card-header-ummi"><i class="fa fa-comments me-2"></i>Assessments &amp; Comments</div>
        <div class="card-body-ummi" style="padding:0;">
            <asp:GridView ID="gvComments" runat="server" AutoGenerateColumns="false"
                CssClass="ummi-table" GridLines="None" OnRowDataBound="CommentRowDataBound">
                <Columns>
                    <asp:BoundField DataField="date_sent"     HeaderText="Date"    DataFormatString="{0:MM/dd/yyyy}" ItemStyle-Width="90px" />
                    <asp:BoundField DataField="comments"      HeaderText="Assessment" />
                    <asp:BoundField DataField="added_by_name" HeaderText="By" />
                    <asp:TemplateField HeaderText="Attachment" ItemStyle-Width="80px">
                        <ItemTemplate>
                            <asp:HyperLink ID="lnkAttachment" runat="server" Visible="false"
                                CssClass="gv-link" Target="_blank"
                                Text="<i class='fa fa-paperclip me-1'></i>View" />
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
        </div>
    </div>
</div>

<!-- Family Info (WBS 1.2.7/1.2.8) — hidden for Principal -->
<div class="tab-pane fade" id="tabFamily">
    <div class="card" id="divFamilyInfo" runat="server">
        <div class="card-header-ummi"><i class="fa fa-people-group me-2"></i>Family Information</div>
        <div class="card-body-ummi" style="padding:0;">
            <asp:GridView ID="gvFamily" runat="server" AutoGenerateColumns="false"
                CssClass="ummi-table" GridLines="None">
                <Columns>
                    <asp:TemplateField HeaderText="Name">
                        <ItemTemplate><%# Eval("fname") & " " & Eval("lname") %></ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="relationship_name" HeaderText="Relationship" />
                    <asp:BoundField DataField="date_of_birth"     HeaderText="Birthday" DataFormatString="{0:MM/dd/yyyy}" />
                    <asp:BoundField DataField="contact"           HeaderText="Contact" />
                    <asp:TemplateField HeaderText="HMO Dependent">
                        <ItemTemplate>
                            <asp:Label ID="lblHMO" runat="server"
                                Text='<%# If(Convert.ToBoolean(Eval("dependent")),"&#x2714; Yes","&#x2718; No") %>'
                                CssClass='<%# If(Convert.ToBoolean(Eval("dependent")),"hmo-yes","hmo-no") %>' />
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
        </div>
    </div>
</div>

</div><!-- end tab-content -->

<!-- UC-CM-08: Image popup modal for scanned documents -->
<div id="imgPopupOverlay" style="display:none;position:fixed;top:0;left:0;right:0;bottom:0;
    background:rgba(0,0,0,.65);z-index:9999;align-items:center;justify-content:center;"
    onclick="this.style.display='none';">
    <div style="max-width:90vw;max-height:90vh;padding:16px;background:#fff;border-radius:12px;
        box-shadow:0 25px 60px rgba(0,0,0,.4);" onclick="event.stopPropagation();">
        <img id="imgPopupImage" src="" alt="Scanned Document"
            style="max-width:85vw;max-height:80vh;display:block;margin:auto;" />
        <div style="text-align:center;margin-top:8px;">
            <button type="button" onclick="document.getElementById('imgPopupOverlay').style.display='none';"
                class="btn-ummi-secondary" style="font-size:12px;">Close</button>
        </div>
    </div>
</div>
<script>
function showImagePopup(src) {
    var overlay = document.getElementById('imgPopupOverlay');
    document.getElementById('imgPopupImage').src = src;
    overlay.style.display = 'flex';
}
</script>

</div>
</asp:Content>
