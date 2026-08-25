<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="SelfEncode.aspx.vb"
    Inherits="SelfEncode" Title="Applicant Self-Encode" MaintainScrollPositionOnPostback="true" %>
<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="fade-in">
<h2 style="font-size:20px;font-weight:700;color:#1a2744;margin-bottom:4px;">
    <i class="fa fa-pen-to-square me-2 text-primary"></i>Applicant Information Form
</h2>
<p style="font-size:13px;color:#64748b;margin-bottom:20px;">
    Please fill in all required fields accurately. Your information will be saved for review by the Manning Staff.
</p>

<asp:Label ID="lblNotify" runat="server" Text="" />
<asp:HiddenField ID="hfCurrentStep" runat="server" Value="1" />

<div x-data="{
    step: parseInt(document.getElementById('<%= hfCurrentStep.ClientID %>').value || '1'),
    maxStep: 3,
    setStep(s) {
        this.step = s;
        var hf = document.getElementById('<%= hfCurrentStep.ClientID %>');
        if (hf) hf.value = s;
    }
}">
    <!-- Step Progress -->
    <div class="d-flex gap-0 mb-4" style="border-radius:8px;overflow:hidden;">
        <div :class="step>=1 ? 'btn-ummi-primary' : 'btn-ummi-secondary'"
             @click="setStep(1)"
             style="flex:1;padding:10px;text-align:center;font-size:12px;font-weight:600;cursor:pointer;">
            <i class="fa fa-user me-1"></i>1. Personal Info
        </div>
        <div :class="step>=2 ? 'btn-ummi-primary' : 'btn-ummi-secondary'"
             @click="setStep(2)"
             style="flex:1;padding:10px;text-align:center;font-size:12px;font-weight:600;cursor:pointer;">
            <i class="fa fa-id-card me-1"></i>2. Contact &amp; Education
        </div>
        <div :class="step>=3 ? 'btn-ummi-primary' : 'btn-ummi-secondary'"
             @click="setStep(3)"
             style="flex:1;padding:10px;text-align:center;font-size:12px;font-weight:600;cursor:pointer;">
            <i class="fa fa-circle-check me-1"></i>3. Review &amp; Submit
        </div>
    </div>

    <!-- STEP 1: Personal Info -->
    <div x-show="step===1" class="card mb-3">
        <div class="card-header-ummi"><i class="fa fa-user me-2"></i>Personal Information</div>
        <div class="card-body-ummi">
            <div class="row g-3">

                <div class="col-md-3">
                    <label class="form-label-ummi">Last Name *</label>
                    <asp:TextBox ID="txtLastName" runat="server" CssClass="form-control-ummi" />
                </div>
                <div class="col-md-3">
                    <label class="form-label-ummi">First Name *</label>
                    <asp:TextBox ID="txtFirstName" runat="server" CssClass="form-control-ummi" />
                </div>
                <div class="col-md-3">
                    <label class="form-label-ummi">Middle Name</label>
                    <asp:TextBox ID="txtMiddleName" runat="server" CssClass="form-control-ummi" />
                </div>
                <div class="col-md-3">
                    <label class="form-label-ummi">Suffix</label>
                    <asp:DropDownList ID="drpdwnSuffix" runat="server" CssClass="form-control-ummi">
                        <asp:ListItem Value="">None</asp:ListItem>
                        <asp:ListItem Value="Jr.">Jr.</asp:ListItem>
                        <asp:ListItem Value="Sr.">Sr.</asp:ListItem>
                        <asp:ListItem Value="II">II</asp:ListItem>
                        <asp:ListItem Value="III">III</asp:ListItem>
                    </asp:DropDownList>
                </div>

                <div class="col-md-3">
                    <label class="form-label-ummi">Date of Birth *</label>
                    <asp:TextBox ID="txtDOB" runat="server" CssClass="form-control-ummi" TextMode="Date" />
                </div>
                <div class="col-md-3">
                    <label class="form-label-ummi">Place of Birth</label>
                    <asp:TextBox ID="txtPOB" runat="server" CssClass="form-control-ummi" />
                </div>
                <div class="col-md-3">
                    <label class="form-label-ummi">Gender</label>
                    <asp:DropDownList ID="drpdwnGender" runat="server" CssClass="form-control-ummi">
                        <asp:ListItem Value="">Select...</asp:ListItem>
                        <asp:ListItem Value="Male">Male</asp:ListItem>
                        <asp:ListItem Value="Female">Female</asp:ListItem>
                    </asp:DropDownList>
                </div>
                <div class="col-md-3">
                    <label class="form-label-ummi">Civil Status</label>
                    <asp:DropDownList ID="drpdwnCivilStatus" runat="server" CssClass="form-control-ummi">
                        <asp:ListItem Value="">Select...</asp:ListItem>
                        <asp:ListItem Value="Single">Single</asp:ListItem>
                        <asp:ListItem Value="Married">Married</asp:ListItem>
                        <asp:ListItem Value="Widowed">Widowed</asp:ListItem>
                        <asp:ListItem Value="Separated">Separated</asp:ListItem>
                    </asp:DropDownList>
                </div>

                <%-- RELIGION — "Others (Please specify)" pattern --%>
                <div class="col-md-3">
                    <label class="form-label-ummi">Religion</label>
                    <asp:DropDownList ID="drpdwnReligion" runat="server" CssClass="form-control-ummi"
                        onchange="OtherField.toggle(this)" />
                    <asp:TextBox ID="txtReligionOther" runat="server"
                        CssClass="form-control-ummi other-specify-input mt-1"
                        placeholder="Please specify your religion"
                        style="display:none;" />
                </div>

                <%-- NATIONALITY — same pattern --%>
                <div class="col-md-3">
                    <label class="form-label-ummi">Nationality</label>
                    <asp:DropDownList ID="drpdwnNationality" runat="server" CssClass="form-control-ummi"
                        onchange="OtherField.toggle(this)" />
                    <asp:TextBox ID="txtNationalityOther" runat="server"
                        CssClass="form-control-ummi other-specify-input mt-1"
                        placeholder="Please specify your nationality"
                        style="display:none;" />
                </div>

                <div class="col-md-3">
                    <label class="form-label-ummi">Height (cm)</label>
                    <asp:TextBox ID="txtHeight" runat="server" CssClass="form-control-ummi" placeholder="e.g. 172" />
                </div>
                <div class="col-md-3">
                    <label class="form-label-ummi">Weight (kg)</label>
                    <asp:TextBox ID="txtWeight" runat="server" CssClass="form-control-ummi" placeholder="e.g. 70" />
                </div>
                <div class="col-md-3">
                    <label class="form-label-ummi">Applied Rank *</label>
                    <asp:DropDownList ID="drpdwnRank" runat="server" CssClass="form-control-ummi" />
                </div>

            </div>
            <div class="d-flex justify-content-end mt-3">
                <button type="button" class="btn-ummi-primary" @click="setStep(2)">
                    Next <i class="fa fa-arrow-right ms-1"></i>
                </button>
            </div>
        </div>
    </div>

    <!-- STEP 2: Contact & Education -->
    <div x-show="step===2" class="card mb-3">
        <div class="card-header-ummi"><i class="fa fa-address-book me-2"></i>Contact &amp; Educational Background</div>
        <div class="card-body-ummi">
            <div class="row g-3">

                <div class="col-md-4">
                    <label class="form-label-ummi">Contact Number *</label>
                    <asp:TextBox ID="txtContact" runat="server" CssClass="form-control-ummi" placeholder="09XX-XXX-XXXX" />
                </div>
                <div class="col-md-4">
                    <label class="form-label-ummi">Email Address</label>
                    <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control-ummi" TextMode="Email" />
                </div>
                <div class="col-md-4">
                    <label class="form-label-ummi">Address</label>
                    <asp:TextBox ID="txtAddress" runat="server" CssClass="form-control-ummi" />
                </div>
                <div class="col-md-4">
                    <label class="form-label-ummi">Province</label>
                    <asp:DropDownList ID="drpdwnProvince" runat="server" CssClass="form-control-ummi"
                        AutoPostBack="true" OnSelectedIndexChanged="ProvinceChanged" />
                </div>
                <div class="col-md-4">
                    <label class="form-label-ummi">City / Municipality</label>
                    <asp:DropDownList ID="drpdwnCity" runat="server" CssClass="form-control-ummi" />
                </div>
                <div class="col-md-4"></div>

                <%-- SCHOOL — "Others (Please specify)" pattern --%>
                <div class="col-md-4">
                    <label class="form-label-ummi">School / University</label>
                    <asp:DropDownList ID="drpdwnSchool" runat="server" CssClass="form-control-ummi"
                        onchange="OtherField.toggle(this)" />
                    <asp:TextBox ID="txtSchoolOther" runat="server"
                        CssClass="form-control-ummi other-specify-input mt-1"
                        placeholder="Please specify your school / university"
                        style="display:none;" />
                </div>

                <%-- COURSE — "Others (Please specify)" pattern --%>
                <div class="col-md-4">
                    <label class="form-label-ummi">Course</label>
                    <asp:DropDownList ID="drpdwnCourse" runat="server" CssClass="form-control-ummi"
                        onchange="OtherField.toggle(this)" />
                    <asp:TextBox ID="txtCourseOther" runat="server"
                        CssClass="form-control-ummi other-specify-input mt-1"
                        placeholder="Please specify your course"
                        style="display:none;" />
                </div>

            </div>
            <div class="d-flex justify-content-between mt-3">
                <button type="button" class="btn-ummi-secondary" @click="setStep(1)">
                    <i class="fa fa-arrow-left me-1"></i> Back
                </button>
                <button type="button" class="btn-ummi-primary" @click="setStep(3); updateReview();">
                    Next <i class="fa fa-arrow-right ms-1"></i>
                </button>
            </div>
        </div>
    </div>

    <!-- STEP 3: Review & Submit -->
    <div x-show="step===3" class="card mb-3">
        <div class="card-header-ummi"><i class="fa fa-eye me-2"></i>Review &amp; Submit</div>
        <div class="card-body-ummi">
            <div class="alert alert-info">
                <i class="fa fa-info-circle me-2"></i>
                Please review your information before submitting. Once submitted, you will not be able to edit it without contacting the Manning Office.
            </div>
            <h6 class="mt-2 mb-1" style="color:#1a2744; font-weight:600;">Personal Information</h6>
            <div class="row g-2 mb-3" style="font-size:13px;">
                <div class="col-md-6"><strong>Name:</strong> <asp:Label ID="lblReviewName" runat="server" Text="" /></div>
                <div class="col-md-6"><strong>DOB:</strong> <asp:Label ID="lblReviewDOB" runat="server" Text="" /></div>
                <div class="col-md-6"><strong>Place of Birth:</strong> <asp:Label ID="lblReviewPOB" runat="server" Text="" /></div>
                <div class="col-md-6"><strong>Gender:</strong> <asp:Label ID="lblReviewGender" runat="server" Text="" /></div>
                <div class="col-md-6"><strong>Civil Status:</strong> <asp:Label ID="lblReviewCivilStatus" runat="server" Text="" /></div>
                <div class="col-md-6"><strong>Religion:</strong> <asp:Label ID="lblReviewReligion" runat="server" Text="" /></div>
                <div class="col-md-6"><strong>Nationality:</strong> <asp:Label ID="lblReviewNationality" runat="server" Text="" /></div>
                <div class="col-md-6"><strong>Height / Weight:</strong> <asp:Label ID="lblReviewHeightWeight" runat="server" Text="" /></div>
                <div class="col-md-6"><strong>Applied Rank:</strong> <asp:Label ID="lblReviewRank" runat="server" Text="" /></div>
            </div>
            <h6 class="mb-1" style="color:#1a2744; font-weight:600;">Contact &amp; Education</h6>
            <div class="row g-2 mb-3" style="font-size:13px;">
                <div class="col-md-6"><strong>Contact:</strong> <asp:Label ID="lblReviewContact" runat="server" Text="" /></div>
                <div class="col-md-6"><strong>Email:</strong> <asp:Label ID="lblReviewEmail" runat="server" Text="" /></div>
                <div class="col-md-6"><strong>Address:</strong> <asp:Label ID="lblReviewAddress" runat="server" Text="" /></div>
                <div class="col-md-6"><strong>Province &amp; City:</strong> <asp:Label ID="lblReviewProvCity" runat="server" Text="" /></div>
                <div class="col-md-6"><strong>School / University:</strong> <asp:Label ID="lblReviewSchool" runat="server" Text="" /></div>
                <div class="col-md-6"><strong>Course:</strong> <asp:Label ID="lblReviewCourse" runat="server" Text="" /></div>
            </div>
            <div class="d-flex justify-content-between mt-3">
                <button type="button" class="btn-ummi-secondary" @click="setStep(2)">
                    <i class="fa fa-arrow-left me-1"></i> Back
                </button>
                <%-- validateAll() cancels submit if an "Others" text box is visible but blank --%>
                <asp:Button ID="btnSubmit" runat="server" Text="Submit Application"
                    CssClass="btn-ummi-primary" OnClick="SubmitApplication"
                    OnClientClick="if(!OtherField.validateAll()){return false;} showLoading();" />
            </div>
        </div>
    </div>
</div>
</div>



<%-- ════════════════════════════════════════════════════════════════════
     OtherField — Reusable "Others (Please specify)" module
     NOTE: the typed text is shown for UX only; it is NOT saved to the DB.
     ════════════════════════════════════════════════════════════════════
--%>
<script>
var OtherField = (function () {
    "use strict";

    var SENTINEL = "other";

    function getCompanionInput(selectEl) {
        var sibling = selectEl.nextElementSibling;
        if (sibling && sibling.classList.contains("other-specify-input")) {
            return sibling;
        }
        return null;
    }

    function toggle(selectEl) {
        var input = getCompanionInput(selectEl);
        if (!input) return;

        var isOther = (selectEl.value === SENTINEL);
        if (!isOther && selectEl.selectedIndex >= 0) {
            var selectedText = selectEl.options[selectEl.selectedIndex].text || "";
            if (selectedText.toLowerCase().indexOf("others (please specify)") !== -1) {
                isOther = true;
            }
        }

        if (isOther) {
            input.style.display = "block";
            input.required      = true;
        } else {
            input.style.display = "none";
            input.required      = false;
            input.value         = "";
        }
    }

    function validateAll() {
        var inputs = document.querySelectorAll(".other-specify-input");
        for (var i = 0; i < inputs.length; i++) {
            var input = inputs[i];
            if (input.style.display !== "none" && input.value.trim() === "") {
                input.setCustomValidity(
                    "Please type your answer here, or choose a different option above."
                );
                input.reportValidity();
                input.focus();
                return false;
            }
            input.setCustomValidity("");
        }
        return true;
    }

    function initAll() {
        var selects = document.querySelectorAll("select");
        for (var i = 0; i < selects.length; i++) {
            if (selects[i].getAttribute("onchange") &&
                selects[i].getAttribute("onchange").indexOf("OtherField.toggle") !== -1) {
                toggle(selects[i]);
            }
        }
    }

    document.addEventListener("DOMContentLoaded", initAll);

    return { toggle: toggle, validateAll: validateAll, initAll: initAll };
}());
</script>

<script>
    function updateReview() {
        var getVal = function(id) {
            var el = document.getElementById(id);
            return (el && el.value.trim() !== '') ? el.value.trim() : 'N/A';
        };
        var getDdlText = function(id) {
            var el = document.getElementById(id);
            return (el && el.selectedIndex > 0) ? el.options[el.selectedIndex].text : 'N/A';
        };
        var getDdlOrOther = function(ddlId, otherId) {
            var el = document.getElementById(ddlId);
            if (!el || el.selectedIndex <= 0) return 'N/A';
            if (el.value === 'other' || el.options[el.selectedIndex].text.toLowerCase().indexOf('others') !== -1) {
                var otherEl = document.getElementById(otherId);
                return (otherEl && otherEl.value.trim() !== '') ? otherEl.value.trim() : 'N/A';
            }
            return el.options[el.selectedIndex].text;
        };
        var setLbl = function(id, text) {
            var el = document.getElementById(id);
            if (el) el.innerText = text;
        };

        var nameParts = [];
        var fName = getVal('<%= txtFirstName.ClientID %>');
        var mName = getVal('<%= txtMiddleName.ClientID %>');
        var lName = getVal('<%= txtLastName.ClientID %>');
        var suf = getVal('<%= drpdwnSuffix.ClientID %>');
        if (fName !== 'N/A') nameParts.push(fName);
        if (mName !== 'N/A') nameParts.push(mName.charAt(0) + '.');
        if (lName !== 'N/A') nameParts.push(lName);
        if (suf !== 'N/A') nameParts.push(suf);
        setLbl('<%= lblReviewName.ClientID %>', nameParts.length > 0 ? nameParts.join(' ') : 'N/A');

        setLbl('<%= lblReviewDOB.ClientID %>', getVal('<%= txtDOB.ClientID %>'));
        setLbl('<%= lblReviewPOB.ClientID %>', getVal('<%= txtPOB.ClientID %>'));
        setLbl('<%= lblReviewGender.ClientID %>', getDdlText('<%= drpdwnGender.ClientID %>'));
        setLbl('<%= lblReviewCivilStatus.ClientID %>', getDdlText('<%= drpdwnCivilStatus.ClientID %>'));
        setLbl('<%= lblReviewReligion.ClientID %>', getDdlOrOther('<%= drpdwnReligion.ClientID %>', '<%= txtReligionOther.ClientID %>'));
        setLbl('<%= lblReviewNationality.ClientID %>', getDdlOrOther('<%= drpdwnNationality.ClientID %>', '<%= txtNationalityOther.ClientID %>'));
        
        var hw = getVal('<%= txtHeight.ClientID %>') + ' cm / ' + getVal('<%= txtWeight.ClientID %>') + ' kg';
        if (hw === 'N/A cm / N/A kg') hw = 'N/A';
        setLbl('<%= lblReviewHeightWeight.ClientID %>', hw);
        
        setLbl('<%= lblReviewRank.ClientID %>', getDdlText('<%= drpdwnRank.ClientID %>'));

        setLbl('<%= lblReviewContact.ClientID %>', getVal('<%= txtContact.ClientID %>'));
        setLbl('<%= lblReviewEmail.ClientID %>', getVal('<%= txtEmail.ClientID %>'));
        setLbl('<%= lblReviewAddress.ClientID %>', getVal('<%= txtAddress.ClientID %>'));
        
        var prov = getDdlText('<%= drpdwnProvince.ClientID %>');
        var city = getDdlText('<%= drpdwnCity.ClientID %>');
        var provCity = (prov !== 'N/A' || city !== 'N/A') ? city + ', ' + prov : 'N/A';
        setLbl('<%= lblReviewProvCity.ClientID %>', provCity);

        setLbl('<%= lblReviewSchool.ClientID %>', getDdlOrOther('<%= drpdwnSchool.ClientID %>', '<%= txtSchoolOther.ClientID %>'));
        setLbl('<%= lblReviewCourse.ClientID %>', getDdlOrOther('<%= drpdwnCourse.ClientID %>', '<%= txtCourseOther.ClientID %>'));
    }
</script>


<style>
    .other-specify-input {
        border-left: 3px solid #3b6fd4 !important;
        animation: otherSlideIn 0.18s ease;
    }
    @keyframes otherSlideIn {
        from { opacity: 0; transform: translateY(-5px); }
        to   { opacity: 1; transform: translateY(0);    }
    }
    .other-specify-input:focus {
        border-color: #3b6fd4 !important;
        box-shadow: 0 0 0 3px rgba(59,111,212,.18) !important;
        outline: none;
    }
</style>
</asp:Content>
