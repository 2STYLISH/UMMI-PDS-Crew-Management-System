<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="SelfEncode.aspx.vb"
    Inherits="SelfEncode" Title="Applicant Self-Encode" MaintainScrollPositionOnPostback="true" %>
<asp:Content ID="ContentHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/css/applicant-ai-assist.css") %>" />
</asp:Content>
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
<asp:HiddenField ID="hfApplicantCsrfToken" runat="server" />

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

    <!-- OPTIONAL AI-ASSISTED DOCUMENT AUTOFILL FOUNDATION (Phase F) -->
    <div x-show="step===1" class="ai-assist-container">
        <div class="ai-assist-header">
            <h3 class="ai-assist-title">
                <i class="fa fa-wand-magic-sparkles"></i>
                AI-Assisted Document Autofill
            </h3>
            <span class="ai-badge-optional">Optional Assistance</span>
        </div>
        <div class="ai-assist-body">
            <!-- Data Privacy Notice (Informed by Republic Act 10173 Principles) -->
            <div class="ai-privacy-box">
                <div class="ai-privacy-title">
                    <i class="fa fa-shield-halved"></i>
                    Applicant Data Privacy &amp; AI Processing Disclosure
                </div>
                <div class="ai-privacy-text">
                    United Philippine Lines / UMMI provides this optional AI-assisted tool to assist with self-encoding by extracting text from your uploaded credentials.
                    <ul class="ai-privacy-list">
                        <li><strong>Assistive Only:</strong> This tool assists with form completion. It does <em>not</em> evaluate document authenticity, qualifications, competency, or hiring eligibility.</li>
                        <li><strong>Third-Party AI Processor:</strong> Document images are transmitted over secure HTTPS to <strong>DeepInfra</strong> (an external cloud AI infrastructure provider) to perform optical extraction using the Qwen3-VL vision-language model solely for candidate field suggestion.</li>
                        <li><strong>Local vs. Third-Party Retention:</strong> On UMMI servers, uploaded documents are placed in temporary, session-isolated storage and are purged upon job completion, cancellation, consent withdrawal, session expiration (30-minute sliding window), or via automated 7-day sweeps. Third-party processor network transit and server caching are governed under DeepInfra service terms.</li>
                        <li><strong>Unconditional Right to Withdraw:</strong> You may freely withdraw consent at any time by unchecking the box below or clicking &quot;Withdraw AI Consent&quot;. Withdrawal immediately stops active processing, deletes local staged documents, and clears suggestions without affecting your manual application.</li>
                        <li><strong>Institutional Review:</strong> Technical privacy controls are active; formal institutional approvals (Data Privacy Impact Assessment, DeepInfra Data Processing Agreement, and 7-day retention policy sign-off) are pending final UMMI DPO review.</li>
                    </ul>
                </div>
            </div>

            <!-- Server-Enforced Consent Gate & Withdrawal Control -->
            <div class="ai-consent-box d-flex justify-content-between align-items-center flex-wrap">
                <div class="d-flex align-items-center">
                    <input type="checkbox" id="chkAiConsent" name="ai_consent" />
                    <label for="chkAiConsent" class="ai-consent-label ms-2 mb-0">
                        I have read and understand the AI Processing Disclosure, and I freely give my consent to process my uploaded credentials for AI-assisted form autofill.
                    </label>
                </div>
                <button type="button" id="btnAiWithdrawConsent" class="btn btn-sm btn-link text-danger p-0 ms-auto" style="font-size:11px;text-decoration:underline;display:none;">
                    <i class="fa fa-ban me-1"></i>Withdraw AI Consent
                </button>
            </div>

            <!-- Upload Dropzone (Foundation Phase F.1) -->
            <div id="aiDropzone" class="ai-dropzone-area disabled" aria-disabled="true">
                <div class="ai-dropzone-icon">
                    <i class="fa fa-cloud-arrow-up"></i>
                </div>
                <div class="ai-dropzone-title">
                    Select or Drop Documents to Begin Autofill
                </div>
                <div class="ai-dropzone-limits">
                    Supported: PDF, JPG, PNG &bull; Max 10 files &bull; Max 5 MB per file (25 MB total) &bull; Max 10 pages per PDF
                </div>
                <input type="file" id="aiFileInput" multiple accept=".pdf,.jpg,.jpeg,.png" style="display:none;" />
            </div>

            <!-- Active Processing & Progress Container (Phase F.2) -->
            <div id="aiProgressContainer" class="ai-progress-wrap" style="display:none;">
                <div class="d-flex justify-content-between align-items-center mb-1">
                    <span id="aiProgressStatusText" style="font-size:12.5px;font-weight:600;color:#1e293b;">
                        <i class="fa fa-spinner fa-spin me-1 text-primary"></i>
                        <span id="aiProgressMessage">Uploading and staging documents...</span>
                    </span>
                    <span id="aiProgressPercent" style="font-size:12.5px;font-weight:700;color:#3b6fd4;">0%</span>
                </div>
                <div class="ai-progress-bar-bg">
                    <div id="aiProgressBarFill" class="ai-progress-bar-fill" style="width: 0%;"></div>
                </div>
                <div class="d-flex justify-content-between align-items-center mt-2">
                    <span id="aiFileCountSummary" style="font-size:11.5px;color:#64748b;">Processing files...</span>
                    <button type="button" id="btnAiCancel" class="btn btn-sm btn-outline-danger" style="font-size:11px;padding:2px 8px;">
                        <i class="fa fa-times me-1"></i>Cancel Extraction
                    </button>
                </div>
            </div>

            <!-- Error Feedback Box (Phase F.2) -->
            <div id="aiErrorBox" class="alert alert-danger mt-3 mb-0" style="display:none;font-size:12.5px;">
                <div class="d-flex align-items-start justify-content-between">
                    <div>
                        <i class="fa fa-circle-exclamation me-2"></i>
                        <span id="aiErrorMessage">Extraction encountered an error.</span>
                    </div>
                    <button type="button" id="btnAiRetry" class="btn btn-sm btn-outline-danger ms-3" style="font-size:11px;padding:2px 8px;white-space:nowrap;">
                        <i class="fa fa-arrow-rotate-right me-1"></i>Try Again
                    </button>
                </div>
            </div>

            <!-- Completion Banner (Phase F.4) -->
            <div id="aiCompletionBox" class="alert alert-success mt-3 mb-0" style="display:none;font-size:12.5px;">
                <div class="d-flex align-items-center justify-content-between">
                    <div>
                        <i class="fa fa-circle-check me-2 text-success"></i>
                        <span id="aiCompletionMessage">Document extraction complete! Suggestions are ready for review below.</span>
                    </div>
                    <span class="badge bg-primary" style="font-size:11px;font-weight:600;"><i class="fa fa-wand-magic-sparkles me-1"></i>Suggestions Ready</span>
                </div>
                <div style="font-size:11.5px;color:#1e3a8a;margin-top:4px;">
                    <i class="fa fa-info-circle me-1"></i>
                    Review each field below. Suggestions are <strong>never</strong> automatically applied. Click <strong>[Apply]</strong> on each suggestion or use batch review.
                </div>
            </div>
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
                    <div id="aiSuggestion_LastName" class="ai-suggestion-slot"></div>
                </div>
                <div class="col-md-3">
                    <label class="form-label-ummi">First Name *</label>
                    <asp:TextBox ID="txtFirstName" runat="server" CssClass="form-control-ummi" />
                    <div id="aiSuggestion_FirstName" class="ai-suggestion-slot"></div>
                </div>
                <div class="col-md-3">
                    <label class="form-label-ummi">Middle Name</label>
                    <asp:TextBox ID="txtMiddleName" runat="server" CssClass="form-control-ummi" />
                    <div id="aiSuggestion_MiddleName" class="ai-suggestion-slot"></div>
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
                    <div id="aiSuggestion_Suffix" class="ai-suggestion-slot"></div>
                </div>

                <div class="col-md-3">
                    <label class="form-label-ummi">Date of Birth *</label>
                    <asp:TextBox ID="txtDOB" runat="server" CssClass="form-control-ummi" TextMode="Date" onchange="calculateAge()" />
                    <div id="aiSuggestion_DateOfBirth" class="ai-suggestion-slot"></div>
                </div>
                <div class="col-md-2">
                    <label class="form-label-ummi">Age</label>
                    <input type="text" id="txtAge" class="form-control-ummi" readonly="readonly" placeholder="--" tabindex="-1" />
                </div>
                <div class="col-md-3">
                    <label class="form-label-ummi">Place of Birth</label>
                    <asp:TextBox ID="txtPOB" runat="server" CssClass="form-control-ummi" />
                    <div id="aiSuggestion_PlaceOfBirth" class="ai-suggestion-slot"></div>
                </div>
                <div class="col-md-3">
                    <label class="form-label-ummi">Gender</label>
                    <asp:DropDownList ID="drpdwnGender" runat="server" CssClass="form-control-ummi">
                        <asp:ListItem Value="">Select...</asp:ListItem>
                        <asp:ListItem Value="Male">Male</asp:ListItem>
                        <asp:ListItem Value="Female">Female</asp:ListItem>
                    </asp:DropDownList>
                    <div id="aiSuggestion_Gender" class="ai-suggestion-slot"></div>
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
                    <div id="aiSuggestion_CivilStatus" class="ai-suggestion-slot"></div>
                </div>

                <%-- RELIGION â€” "Others (Please specify)" pattern --%>
                <div class="col-md-3">
                    <label class="form-label-ummi">Religion</label>
                    <asp:DropDownList ID="drpdwnReligion" runat="server" CssClass="form-control-ummi"
                        onchange="OtherField.toggle(this)" />
                    <asp:TextBox ID="txtReligionOther" runat="server"
                        CssClass="form-control-ummi other-specify-input mt-1"
                        placeholder="Please specify your religion"
                        style="display:none;" />
                    <div id="aiSuggestion_Religion" class="ai-suggestion-slot"></div>
                </div>

                <%-- NATIONALITY â€” same pattern --%>
                <div class="col-md-3">
                    <label class="form-label-ummi">Nationality</label>
                    <asp:DropDownList ID="drpdwnNationality" runat="server" CssClass="form-control-ummi"
                        onchange="OtherField.toggle(this)" />
                    <asp:TextBox ID="txtNationalityOther" runat="server"
                        CssClass="form-control-ummi other-specify-input mt-1"
                        placeholder="Please specify your nationality"
                        style="display:none;" />
                    <div id="aiSuggestion_Nationality" class="ai-suggestion-slot"></div>
                </div>

                <div class="col-md-3">
                    <label class="form-label-ummi">Height (cm)</label>
                    <asp:TextBox ID="txtHeight" runat="server" CssClass="form-control-ummi" placeholder="e.g. 172" />
                    <div id="aiSuggestion_Height" class="ai-suggestion-slot"></div>
                </div>
                <div class="col-md-3">
                    <label class="form-label-ummi">Weight (kg)</label>
                    <asp:TextBox ID="txtWeight" runat="server" CssClass="form-control-ummi" placeholder="e.g. 70" />
                    <div id="aiSuggestion_Weight" class="ai-suggestion-slot"></div>
                </div>
                <div class="col-md-3">
                    <label class="form-label-ummi">Applied Rank *</label>
                    <asp:DropDownList ID="drpdwnRank" runat="server" CssClass="form-control-ummi" />
                    <div id="aiSuggestion_AppliedRank" class="ai-suggestion-slot"></div>
                </div>

            </div>
            <div class="d-flex justify-content-between align-items-center mt-3">
                <div id="aiStep1BatchContainer" style="display:none;">
                    <button type="button" id="btnAiApplyAllStep1" class="btn btn-sm ai-apply-all-btn">
                        <i class="fa fa-wand-magic-sparkles me-1"></i>Apply All Step 1 Suggestions
                    </button>
                    <span id="aiStep1BatchNote" class="text-muted ms-2" style="font-size:11px;"></span>
                </div>
                <div class="ms-auto">
                    <button type="button" class="btn-ummi-primary" @click="setStep(2)">
                        Next <i class="fa fa-arrow-right ms-1"></i>
                    </button>
                </div>
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
                    <div id="aiSuggestion_ContactNumber" class="ai-suggestion-slot"></div>
                </div>
                <div class="col-md-4">
                    <label class="form-label-ummi">Email Address</label>
                    <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control-ummi" TextMode="Email" />
                    <div id="aiSuggestion_EmailAddress" class="ai-suggestion-slot"></div>
                </div>
                <div class="col-md-4">
                    <label class="form-label-ummi">Address</label>
                    <asp:TextBox ID="txtAddress" runat="server" CssClass="form-control-ummi" />
                    <div id="aiSuggestion_Address" class="ai-suggestion-slot"></div>
                </div>
                <div class="col-md-4">
                    <label class="form-label-ummi">Province</label>
                    <asp:DropDownList ID="drpdwnProvince" runat="server" CssClass="form-control-ummi"
                        AutoPostBack="true" OnSelectedIndexChanged="ProvinceChanged" />
                    <div id="aiSuggestion_Province" class="ai-suggestion-slot"></div>
                </div>
                <div class="col-md-4">
                    <label class="form-label-ummi">City / Municipality</label>
                    <asp:DropDownList ID="drpdwnCity" runat="server" CssClass="form-control-ummi" />
                    <div id="aiSuggestion_City" class="ai-suggestion-slot"></div>
                </div>
                <div class="col-md-4"></div>

                <%-- SCHOOL â€” "Others (Please specify)" pattern --%>
                <div class="col-md-4">
                    <label class="form-label-ummi">School / University</label>
                    <asp:DropDownList ID="drpdwnSchool" runat="server" CssClass="form-control-ummi"
                        onchange="OtherField.toggle(this)" />
                    <asp:TextBox ID="txtSchoolOther" runat="server"
                        CssClass="form-control-ummi other-specify-input mt-1"
                        placeholder="Please specify your school / university"
                        style="display:none;" />
                    <div id="aiSuggestion_SchoolName" class="ai-suggestion-slot"></div>
                </div>

                <%-- COURSE â€” "Others (Please specify)" pattern --%>
                <div class="col-md-4">
                    <label class="form-label-ummi">Course</label>
                    <asp:DropDownList ID="drpdwnCourse" runat="server" CssClass="form-control-ummi"
                        onchange="OtherField.toggle(this)" />
                    <asp:TextBox ID="txtCourseOther" runat="server"
                        CssClass="form-control-ummi other-specify-input mt-1"
                        placeholder="Please specify your course"
                        style="display:none;" />
                    <div id="aiSuggestion_Course" class="ai-suggestion-slot"></div>
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

    <!-- STEP 2 (F.5): Repeating document & sea-service review â€” sibling card, session-only -->
    <div x-show="step===2">
        <div id="aiRepeatingReviewPanel" class="card mb-3 ai-repeating-panel" style="display:none;">
            <div class="card-header-ummi d-flex justify-content-between align-items-center" id="aiRepeatingHeader" style="cursor:pointer;" role="button" aria-expanded="true" aria-controls="aiRepeatingBody">
                <span><i class="fa fa-file-circle-check me-2"></i>Document &amp; Sea Service Suggestions
                    <span id="aiRepeatingCountBadge" class="ai-repeating-count-badge"></span>
                </span>
                <i class="fa fa-chevron-up" id="aiRepeatingChevron"></i>
            </div>
            <div id="aiRepeatingBody" class="card-body-ummi">
                <div class="ai-repeating-persist-notice" role="status">
                    <i class="fa fa-circle-info me-1"></i>
                    Sea service and document suggestions are for your review during this session only.
                    They are <strong>not</strong> included when you submit this application and are
                    <strong>not saved</strong> with your application. Please keep your original documents ready;
                    the Manning Office may request them separately. Use <strong>Keep for now</strong> only to mark items you have reviewed â€” this does not attach or submit them.
                </div>
                <div class="ai-repeating-section">
                    <h6 class="ai-repeating-section-title"><i class="fa fa-id-card me-1"></i>Documents, Certificates &amp; Licenses</h6>
                    <div id="aiDocumentReviewList" class="ai-repeating-list"></div>
                    <div id="aiDocumentReviewEmpty" class="ai-repeating-empty" style="display:none;">No document suggestions extracted.</div>
                </div>
                <div class="ai-repeating-section mt-3">
                    <h6 class="ai-repeating-section-title"><i class="fa fa-ship me-1"></i>Sea Service</h6>
                    <div id="aiSeaServiceReviewList" class="ai-repeating-list"></div>
                    <div id="aiSeaServiceReviewEmpty" class="ai-repeating-empty" style="display:none;">No sea service suggestions extracted.</div>
                </div>
                <div class="mt-2">
                    <button type="button" class="btn-ummi-secondary btn-sm" id="btnAiShowDiscarded" style="display:none;">
                        <i class="fa fa-eye me-1"></i>Show discarded
                    </button>
                </div>
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
                <div class="col-md-6"><strong>Age:</strong> <span id="lblReviewAge"></span></div>
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

            <!-- Phase F.5 Option B: Session-only repeating-record summary (NOT submitted) -->
            <div id="aiRepeatingStep3Summary" class="ai-repeating-step3-summary" style="display:none;">
                <div class="ai-repeating-step3-banner" role="status">
                    <i class="fa fa-triangle-exclamation me-1"></i>
                    Reviewed for reference only â€” document and sea service items below are
                    <strong>not submitted</strong> and <strong>not saved</strong> with this application.
                </div>
                <h6 class="mb-1 mt-2" style="color:#1a2744; font-weight:600;">Document &amp; Sea Service Review (session only)</h6>
                <div id="aiRepeatingStep3List" class="ai-repeating-step3-list"></div>
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



<%-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
     OtherField â€” Reusable "Others (Please specify)" module
     NOTE: the typed text is shown for UX only; it is NOT saved to the DB.
     â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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
        document.getElementById('lblReviewAge').innerText = document.getElementById('txtAge').value || 'N/A';
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

        if (window.ApplicantAiAssist && typeof window.ApplicantAiAssist.updateRepeatingStep3Summary === 'function') {
            window.ApplicantAiAssist.updateRepeatingStep3Summary();
        }
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

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptContent" runat="server">
<script type="text/javascript">
    // Phase F.4: Field client IDs mapped for external suggestion review script
    window.AiFieldIds = {
        LastName: '<%= txtLastName.ClientID %>',
        FirstName: '<%= txtFirstName.ClientID %>',
        MiddleName: '<%= txtMiddleName.ClientID %>',
        Suffix: '<%= drpdwnSuffix.ClientID %>',
        DateOfBirth: '<%= txtDOB.ClientID %>',
        PlaceOfBirth: '<%= txtPOB.ClientID %>',
        Gender: '<%= drpdwnGender.ClientID %>',
        CivilStatus: '<%= drpdwnCivilStatus.ClientID %>',
        Religion: '<%= drpdwnReligion.ClientID %>',
        ReligionOther: '<%= txtReligionOther.ClientID %>',
        Nationality: '<%= drpdwnNationality.ClientID %>',
        NationalityOther: '<%= txtNationalityOther.ClientID %>',
        Height: '<%= txtHeight.ClientID %>',
        Weight: '<%= txtWeight.ClientID %>',
        AppliedRank: '<%= drpdwnRank.ClientID %>',
        ContactNumber: '<%= txtContact.ClientID %>',
        EmailAddress: '<%= txtEmail.ClientID %>',
        Address: '<%= txtAddress.ClientID %>',
        Province: '<%= drpdwnProvince.ClientID %>',
        City: '<%= drpdwnCity.ClientID %>',
        SchoolName: '<%= drpdwnSchool.ClientID %>',
        SchoolOther: '<%= txtSchoolOther.ClientID %>',
        Course: '<%= drpdwnCourse.ClientID %>',
        CourseOther: '<%= txtCourseOther.ClientID %>'
    };

    function calculateAge() {
        var dobInput = document.getElementById('<%= txtDOB.ClientID %>').value;
        var ageInput = document.getElementById('txtAge');
        
        if (dobInput) {
            var dob = new Date(dobInput);
            var today = new Date();
            var age = today.getFullYear() - dob.getFullYear();
            var m = today.getMonth() - dob.getMonth();
            if (m < 0 || (m === 0 && today.getDate() < dob.getDate())) {
                age--;
            }
            ageInput.value = age > 0 ? age + " yrs" : "0 yrs";
        } else {
            ageInput.value = "--";
        }
    }

    // Run on load in case DOB is pre-filled
    window.onload = function() {
        calculateAge();
    };
</script>
<script src="<%= ResolveUrl("~/scripts/applicant-ai-assist.js") %>"></script>
</asp:Content>
