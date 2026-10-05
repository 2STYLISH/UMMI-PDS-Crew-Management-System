<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="SelfEncode.aspx.vb"
    Inherits="SelfEncode" Title="Applicant Self-Encode" MaintainScrollPositionOnPostback="true" %>
<asp:Content ID="ContentHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/css/applicant-ai-assist.css") %>" />
</asp:Content>
<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="fade-in">

    <!-- Page Heading -->
    <div class="mb-3">
        <h2 class="applicant-page-title">Applicant Information Form</h2>
        <p class="applicant-page-subtitle">Complete your information and review AI-assisted suggestions before submission.</p>
    </div>

    <asp:Label ID="lblNotify" runat="server" Text="" />
    <asp:HiddenField ID="hfCurrentStep" runat="server" Value="1" />
    <asp:HiddenField ID="hfApplicantCsrfToken" runat="server" ClientIDMode="Static" />
    <asp:HiddenField ID="hfAiJobId" runat="server" ClientIDMode="Static" />
    <asp:HiddenField ID="hfAiRepeatingDecisions" runat="server" ClientIDMode="Static" />

    <div x-data="{
        step: parseInt(document.getElementById('<%= hfCurrentStep.ClientID %>').value || '1'),
        maxStep: 3,
        showPrivacy: false,
        setStep(s) {
            if (s > this.step) {
                if (this.step === 1 && !validateStep1()) return;
                if (this.step === 2 && !validateStep2()) return;
                if (s === 3 && this.step < 2) {
                    if (!validateStep1() || !validateStep2()) return;
                }
            }
            this.step = s;
            var hf = document.getElementById('<%= hfCurrentStep.ClientID %>');
            if (hf) hf.value = s;
            if (s === 3 && typeof updateReview === 'function') {
                updateReview();
            }
        }
    }">
        <!-- Horizontal Application Stepper -->
        <div class="stepper-bar mb-3">
            <div class="stepper-step" :class="step === 1 ? 'is-active' : (step > 1 ? 'is-complete' : 'is-upcoming')" @click="setStep(1)" role="button" tabindex="0">
                <span class="stepper-circle">
                    <span x-show="step <= 1">1</span>
                    <i x-show="step > 1" class="fa fa-check" style="font-size:10px;"></i>
                </span>
                <span class="stepper-label">Personal Info</span>
            </div>
            <div class="stepper-line" :class="{'is-complete': step > 1}"></div>
            <div class="stepper-step" :class="step === 2 ? 'is-active' : (step > 2 ? 'is-complete' : 'is-upcoming')" @click="setStep(2)" role="button" tabindex="0">
                <span class="stepper-circle">
                    <span x-show="step <= 2">2</span>
                    <i x-show="step > 2" class="fa fa-check" style="font-size:10px;"></i>
                </span>
                <span class="stepper-label">Contact &amp; Education</span>
            </div>
            <div class="stepper-line" :class="{'is-complete': step > 2}"></div>
            <div class="stepper-step" :class="step === 3 ? 'is-active' : (step > 3 ? 'is-complete' : 'is-upcoming')" @click="setStep(3)" role="button" tabindex="0">
                <span class="stepper-circle">
                    <span x-show="step <= 3">3</span>
                    <i x-show="step > 3" class="fa fa-check" style="font-size:10px;"></i>
                </span>
                <span class="stepper-label">Review &amp; Submit</span>
            </div>
        </div>

        <!-- AI-Assisted Document Autofill Section (Compact & Integrated) -->
        <div x-show="step===1" class="ai-assist-box mb-3">
            <div class="ai-assist-bar">
                <div class="d-flex align-items-center gap-2">
                    <i class="fa fa-file-lines text-primary" style="font-size:13px;"></i>
                    <span class="ai-assist-title">AI-Assisted Document Autofill</span>
                    <span class="ai-assist-sub d-none d-md-inline">&bull; Upload your credentials to receive optional form suggestions.</span>
                </div>
                <span class="ai-badge-optional">Optional</span>
            </div>

            <div class="ai-assist-content">
                <!-- Dropzone Area -->
                <div id="aiDropzone" class="ai-dropzone-compact disabled" aria-disabled="true">
                    <div class="d-flex align-items-center justify-content-between flex-wrap gap-2">
                        <div class="d-flex align-items-center gap-2">
                            <i class="fa fa-cloud-arrow-up text-primary" style="font-size:16px;"></i>
                            <div>
                                <span class="ai-dropzone-main">Select or drop credentials here</span>
                                <span class="ai-dropzone-sub text-muted ms-2">PDF, JPG, PNG &bull; Max 10 files &bull; Max 5 MB / file (25 MB total)</span>
                            </div>
                        </div>
                        <span class="btn btn-sm btn-outline-primary" style="font-size:11.5px;padding:2px 10px;pointer-events:none;">
                            Browse Files
                        </span>
                    </div>
                    <input type="file" id="aiFileInput" multiple accept=".pdf,.jpg,.jpeg,.png" style="display:none;" />
                </div>

                <!-- Privacy & Consent Row -->
                <div class="mt-2 pt-1">
                    <div class="d-flex align-items-center justify-content-between flex-wrap gap-2">
                        <label for="chkAiConsent" class="ai-consent-checkbox-label">
                            <input type="checkbox" id="chkAiConsent" name="ai_consent" class="ai-consent-chk" />
                            <span>I have read and understood the AI Processing Disclosure and consent to AI-assisted document processing.</span>
                        </label>
                        <div class="d-flex align-items-center gap-2 ms-auto">
                            <button type="button" class="btn-link-subtle" @click="showPrivacy = !showPrivacy">
                                <span x-text="showPrivacy ? 'Hide privacy details' : 'View privacy details'">View privacy details</span>
                                <i class="fa fa-chevron-down ms-1" style="font-size:9px;" :style="showPrivacy ? 'transform:rotate(180deg)' : ''"></i>
                            </button>
                            <button type="button" id="btnAiWithdrawConsent" class="ai-withdraw-link ms-2" style="display:none;">
                                Withdraw AI Consent
                            </button>
                        </div>
                    </div>

                    <!-- Collapsible Privacy Notice (RA 10173) -->
                    <div x-show="showPrivacy" x-cloak class="ai-privacy-details mt-2">
                        <p class="mb-1"><strong>Applicant Data Privacy &amp; AI Processing Disclosure:</strong> United Philippine Lines / UMMI provides this optional AI-assisted tool to assist with self-encoding by extracting text from your uploaded credentials.</p>
                        <ul class="ai-privacy-list mb-0">
                            <li><strong>Assistive Only:</strong> This tool assists with form completion. It does <em>not</em> evaluate document authenticity, qualifications, competency, or hiring eligibility.</li>
                            <li><strong>Third-Party AI Processor:</strong> Document images are transmitted over secure HTTPS to <strong>DeepInfra</strong> (an external cloud AI infrastructure provider) to perform optical extraction using the Qwen3-VL vision-language model solely for candidate field suggestion.</li>
                            <li><strong>Local vs. Third-Party Retention:</strong> On UMMI servers, uploaded documents are placed in temporary, session-isolated storage and are purged upon job completion, cancellation, consent withdrawal, session expiration (30-minute sliding window), or via automated 7-day sweeps. Third-party processor network transit and server caching are governed under DeepInfra service terms.</li>
                            <li><strong>Unconditional Right to Withdraw:</strong> You may freely withdraw consent at any time by unchecking the box below or clicking &quot;Withdraw AI Consent&quot;. Withdrawal immediately stops active processing, deletes local staged documents, and clears suggestions without affecting your manual application.</li>
                            <li><strong>Institutional Review:</strong> Technical privacy controls are active; formal institutional approvals (Data Privacy Impact Assessment, DeepInfra Data Processing Agreement, and 7-day retention policy sign-off) are pending final UMMI DPO review.</li>
                        </ul>
                    </div>
                </div>

                <!-- Active Progress State -->
                <div id="aiProgressContainer" class="ai-progress-wrap mt-2" style="display:none;">
                    <div class="d-flex justify-content-between align-items-center mb-1">
                        <span id="aiProgressStatusText" style="font-size:12px;font-weight:600;color:#1e293b;">
                            <i class="fa fa-spinner fa-spin me-1 text-primary"></i>
                            <span id="aiProgressMessage">Uploading and staging documents...</span>
                        </span>
                        <span id="aiProgressPercent" style="font-size:12px;font-weight:700;color:#2563eb;">0%</span>
                    </div>
                    <div class="ai-progress-bar-bg">
                        <div id="aiProgressBarFill" class="ai-progress-bar-fill" style="width: 0%;"></div>
                    </div>
                    <div class="d-flex justify-content-between align-items-center mt-1">
                        <span id="aiFileCountSummary" style="font-size:11px;color:#64748b;">Processing files...</span>
                        <button type="button" id="btnAiCancel" class="btn btn-sm btn-outline-danger" style="font-size:10.5px;padding:1px 6px;">
                            Cancel
                        </button>
                    </div>
                </div>

                <!-- Error Feedback Box -->
                <div id="aiErrorBox" class="alert alert-danger mt-2 mb-0" style="display:none;font-size:12px;padding:6px 10px;">
                    <div class="d-flex align-items-center justify-content-between">
                        <div>
                            <i class="fa fa-circle-exclamation me-1"></i>
                            <span id="aiErrorMessage">Extraction encountered an error.</span>
                        </div>
                        <button type="button" id="btnAiRetry" class="btn btn-sm btn-outline-danger ms-2" style="font-size:10.5px;padding:1px 6px;">
                            Try Again
                        </button>
                    </div>
                </div>

                <!-- Completion Banner -->
                <div id="aiCompletionBox" class="alert alert-success ai-completion-bar mt-2 mb-0" style="display:none;">
                    <div class="d-flex align-items-center justify-content-between flex-wrap gap-2">
                        <div class="d-flex align-items-center gap-2">
                            <i class="fa fa-check text-success"></i>
                            <span class="fw-semibold text-success">Document extraction complete</span>
                            <span class="text-muted">&bull;</span>
                            <span id="aiCompletionMessage" class="text-muted" style="font-size:12px;">Suggestions are ready for review below.</span>
                        </div>
                        <span class="ai-ready-badge">Suggestions Ready</span>
                    </div>
                    <div class="text-muted mt-1" style="font-size:11.5px;">
                        Suggestions are never applied automatically. Review each field below before applying.
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
                        <label class="form-label-ummi">Last Name <span class="text-danger">*</span></label>
                        <asp:TextBox ID="txtLastName" runat="server" CssClass="form-control-ummi" />
                        <div id="aiSuggestion_LastName" class="ai-suggestion-slot"></div>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label-ummi">First Name <span class="text-danger">*</span></label>
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
                        <label class="form-label-ummi">Date of Birth <span class="text-danger">*</span></label>
                        <asp:TextBox ID="txtDOB" runat="server" CssClass="form-control-ummi" TextMode="Date" onchange="calculateAge()" />
                        <div id="aiSuggestion_DateOfBirth" class="ai-suggestion-slot"></div>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label-ummi">Age</label>
                        <input type="text" id="txtAge" class="form-control-ummi" readonly="readonly" placeholder="--" tabindex="-1" />
                    </div>
                    <div class="col-md-4">
                        <label class="form-label-ummi">Place of Birth <span class="text-danger">*</span></label>
                        <asp:TextBox ID="txtPOB" runat="server" CssClass="form-control-ummi" />
                        <div id="aiSuggestion_PlaceOfBirth" class="ai-suggestion-slot"></div>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label-ummi">Gender <span class="text-danger">*</span></label>
                        <asp:DropDownList ID="drpdwnGender" runat="server" CssClass="form-control-ummi">
                            <asp:ListItem Value="">Select...</asp:ListItem>
                            <asp:ListItem Value="Male">Male</asp:ListItem>
                            <asp:ListItem Value="Female">Female</asp:ListItem>
                        </asp:DropDownList>
                        <div id="aiSuggestion_Gender" class="ai-suggestion-slot"></div>
                    </div>

                    <div class="col-md-3">
                        <label class="form-label-ummi">Civil Status <span class="text-danger">*</span></label>
                        <asp:DropDownList ID="drpdwnCivilStatus" runat="server" CssClass="form-control-ummi">
                            <asp:ListItem Value="">Select...</asp:ListItem>
                            <asp:ListItem Value="Single">Single</asp:ListItem>
                            <asp:ListItem Value="Married">Married</asp:ListItem>
                            <asp:ListItem Value="Widowed">Widowed</asp:ListItem>
                            <asp:ListItem Value="Separated">Separated</asp:ListItem>
                        </asp:DropDownList>
                        <div id="aiSuggestion_CivilStatus" class="ai-suggestion-slot"></div>
                    </div>

                    <%-- RELIGION — "Others (Please specify)" pattern --%>
                    <div class="col-md-3">
                        <label class="form-label-ummi">Religion <span class="text-danger">*</span></label>
                        <asp:DropDownList ID="drpdwnReligion" runat="server" CssClass="form-control-ummi"
                            onchange="OtherField.toggle(this)" />
                        <asp:TextBox ID="txtReligionOther" runat="server"
                            CssClass="form-control-ummi other-specify-input mt-1"
                            placeholder="Please specify your religion"
                            style="display:none;" />
                        <div id="aiSuggestion_Religion" class="ai-suggestion-slot"></div>
                    </div>

                    <%-- NATIONALITY — same pattern --%>
                    <div class="col-md-3">
                        <label class="form-label-ummi">Nationality <span class="text-danger">*</span></label>
                        <asp:DropDownList ID="drpdwnNationality" runat="server" CssClass="form-control-ummi"
                            onchange="OtherField.toggle(this)" />
                        <asp:TextBox ID="txtNationalityOther" runat="server"
                            CssClass="form-control-ummi other-specify-input mt-1"
                            placeholder="Please specify your nationality"
                            style="display:none;" />
                        <div id="aiSuggestion_Nationality" class="ai-suggestion-slot"></div>
                    </div>

                    <div class="col-md-3">
                        <label class="form-label-ummi">Height (cm) <span class="text-danger">*</span></label>
                        <asp:TextBox ID="txtHeight" runat="server" CssClass="form-control-ummi" placeholder="e.g. 172" />
                        <div id="aiSuggestion_Height" class="ai-suggestion-slot"></div>
                    </div>

                    <div class="col-md-3">
                        <label class="form-label-ummi">Weight (kg) <span class="text-danger">*</span></label>
                        <asp:TextBox ID="txtWeight" runat="server" CssClass="form-control-ummi" placeholder="e.g. 70" />
                        <div id="aiSuggestion_Weight" class="ai-suggestion-slot"></div>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label-ummi">Blood Type <span class="text-danger">*</span></label>
                        <asp:DropDownList ID="drpdwnBloodType" runat="server" CssClass="form-control-ummi">
                            <asp:ListItem Value="">-- Select --</asp:ListItem>
                            <asp:ListItem Value="A+">A+</asp:ListItem>
                            <asp:ListItem Value="A-">A-</asp:ListItem>
                            <asp:ListItem Value="B+">B+</asp:ListItem>
                            <asp:ListItem Value="B-">B-</asp:ListItem>
                            <asp:ListItem Value="AB+">AB+</asp:ListItem>
                            <asp:ListItem Value="AB-">AB-</asp:ListItem>
                            <asp:ListItem Value="O+">O+</asp:ListItem>
                            <asp:ListItem Value="O-">O-</asp:ListItem>
                            <asp:ListItem Value="Unknown">Unknown</asp:ListItem>
                        </asp:DropDownList>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label-ummi">Applied Rank <span class="text-danger">*</span></label>
                        <asp:DropDownList ID="drpdwnRank" runat="server" CssClass="form-control-ummi" />
                        <div id="aiSuggestion_AppliedRank" class="ai-suggestion-slot"></div>
                    </div>

                </div>

                <!-- Step 1 Bottom Action Toolbar -->
                <div class="d-flex justify-content-between align-items-center mt-3 pt-3 border-top">
                    <div>
                        <div id="aiStep1BatchContainer" style="display:none;">
                            <button type="button" id="btnAiApplyAllStep1" class="btn btn-sm btn-outline-primary ai-apply-all-btn">
                                Apply all suggestions
                            </button>
                            <span id="aiStep1BatchNote" class="text-muted ms-2" style="font-size:12px;"></span>
                        </div>
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
                        <label class="form-label-ummi">Contact Number <span class="text-danger">*</span></label>
                        <asp:TextBox ID="txtContact" runat="server" CssClass="form-control-ummi" placeholder="09XX-XXX-XXXX" />
                        <div id="aiSuggestion_ContactNumber" class="ai-suggestion-slot"></div>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label-ummi">Email Address <span class="text-danger">*</span></label>
                        <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control-ummi" TextMode="Email" />
                        <div id="aiSuggestion_EmailAddress" class="ai-suggestion-slot"></div>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label-ummi">Address <span class="text-danger">*</span></label>
                        <asp:TextBox ID="txtAddress" runat="server" CssClass="form-control-ummi" />
                        <div id="aiSuggestion_Address" class="ai-suggestion-slot"></div>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label-ummi">Province <span class="text-danger">*</span></label>
                        <asp:DropDownList ID="drpdwnProvince" runat="server" CssClass="form-control-ummi"
                            AutoPostBack="true" OnSelectedIndexChanged="ProvinceChanged" />
                        <div id="aiSuggestion_Province" class="ai-suggestion-slot"></div>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label-ummi">City / Municipality <span class="text-danger">*</span></label>
                        <asp:DropDownList ID="drpdwnCity" runat="server" CssClass="form-control-ummi" />
                        <div id="aiSuggestion_City" class="ai-suggestion-slot"></div>
                    </div>
                    <div class="col-md-4"></div>

                    <%-- SCHOOL — "Others (Please specify)" pattern --%>
                    <div class="col-md-6">
                        <label class="form-label-ummi">School / University <span class="text-danger">*</span></label>
                        <asp:DropDownList ID="drpdwnSchool" runat="server" CssClass="form-control-ummi"
                            onchange="OtherField.toggle(this)" />
                        <asp:TextBox ID="txtSchoolOther" runat="server"
                            CssClass="form-control-ummi other-specify-input mt-1"
                            placeholder="Please specify your school / university"
                            style="display:none;" />
                        <div id="aiSuggestion_SchoolName" class="ai-suggestion-slot"></div>
                    </div>

                    <%-- COURSE — "Others (Please specify)" pattern --%>
                    <div class="col-md-6">
                        <label class="form-label-ummi">Course <span class="text-danger">*</span></label>
                        <asp:DropDownList ID="drpdwnCourse" runat="server" CssClass="form-control-ummi"
                            onchange="OtherField.toggle(this)" />
                        <asp:TextBox ID="txtCourseOther" runat="server"
                            CssClass="form-control-ummi other-specify-input mt-1"
                            placeholder="Please specify your course"
                            style="display:none;" />
                        <div id="aiSuggestion_Course" class="ai-suggestion-slot"></div>
                    </div>

                </div>
                <div class="d-flex justify-content-between mt-3 pt-3 border-top">
                    <button type="button" class="btn-ummi-secondary" @click="setStep(1)">
                        <i class="fa fa-arrow-left me-1"></i> Back
                    </button>
                    <button type="button" class="btn-ummi-primary" @click="setStep(3); updateReview();">
                        Next <i class="fa fa-arrow-right ms-1"></i>
                    </button>
                </div>
            </div>
        </div>

        <!-- STEP 2 (F.5): Repeating document & sea-service review — session-only -->
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
                        Review each suggestion below. Items you <strong>Keep</strong> will be saved upon submission. Items you <strong>Discard</strong> will not be saved.
                    </div>
                    <div class="mb-3">
                        <h6 style="font-size:13px;font-weight:600;color:#1e293b;margin-bottom:8px;"><i class="fa fa-id-card me-1 text-primary"></i>Documents &amp; Certificates</h6>
                        <div id="aiDocumentReviewList"></div>
                        <div id="aiDocumentReviewEmpty" class="text-muted" style="display:none;font-size:12px;font-style:italic;">No document suggestions extracted.</div>
                    </div>
                    <div class="mb-2">
                        <h6 style="font-size:13px;font-weight:600;color:#1e293b;margin-bottom:8px;"><i class="fa fa-ship me-1 text-primary"></i>Sea Service Records</h6>
                        <div id="aiSeaServiceReviewList"></div>
                        <div id="aiSeaServiceReviewEmpty" class="text-muted" style="display:none;font-size:12px;font-style:italic;">No sea service suggestions extracted.</div>
                    </div>
                    <div class="mt-2">
                        <button type="button" class="btn btn-sm btn-outline-secondary" id="btnAiShowDiscarded" style="display:none;font-size:11px;">
                            Show discarded
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- STEP 3: Review & Submit -->
        <div x-show="step===3" class="card mb-3">
            <div class="card-header-ummi"><i class="fa fa-eye me-2"></i>Review &amp; Submit</div>
            <div class="card-body-ummi">
                <div class="alert alert-info py-2 px-3 mb-3" style="font-size:12.5px;">
                    <i class="fa fa-info-circle me-1"></i>
                    Please review your information carefully before submitting. Once submitted, changes require contacting the Manning Office.
                </div>

                <div class="row g-4">
                    <!-- Personal Info Review -->
                    <div class="col-md-6">
                        <div class="review-group-title"><i class="fa fa-user me-1 text-primary"></i>Personal Information</div>
                        <table class="review-table">
                            <tr><td class="review-key">Full Name:</td><td class="review-val"><asp:Label ID="lblReviewName" runat="server" Text="" /></td></tr>
                            <tr><td class="review-key">Date of Birth:</td><td class="review-val"><asp:Label ID="lblReviewDOB" runat="server" Text="" /></td></tr>
                            <tr><td class="review-key">Age:</td><td class="review-val" id="lblReviewAge"></td></tr>
                            <tr><td class="review-key">Place of Birth:</td><td class="review-val"><asp:Label ID="lblReviewPOB" runat="server" Text="" /></td></tr>
                            <tr><td class="review-key">Gender:</td><td class="review-val"><asp:Label ID="lblReviewGender" runat="server" Text="" /></td></tr>
                            <tr><td class="review-key">Civil Status:</td><td class="review-val"><asp:Label ID="lblReviewCivilStatus" runat="server" Text="" /></td></tr>
                            <tr><td class="review-key">Religion:</td><td class="review-val"><asp:Label ID="lblReviewReligion" runat="server" Text="" /></td></tr>
                            <tr><td class="review-key">Nationality:</td><td class="review-val"><asp:Label ID="lblReviewNationality" runat="server" Text="" /></td></tr>
                            <tr><td class="review-key">Height / Weight:</td><td class="review-val"><asp:Label ID="lblReviewHeightWeight" runat="server" Text="" /></td></tr>
                            <tr><td class="review-key">Blood Type:</td><td class="review-val"><asp:Label ID="lblReviewBloodType" runat="server" Text="" /></td></tr>
                            <tr><td class="review-key">Applied Rank:</td><td class="review-val"><asp:Label ID="lblReviewRank" runat="server" Text="" /></td></tr>
                        </table>
                    </div>

                    <!-- Contact & Education Review -->
                    <div class="col-md-6">
                        <div class="review-group-title"><i class="fa fa-address-book me-1 text-primary"></i>Contact &amp; Education</div>
                        <table class="review-table">
                            <tr><td class="review-key">Contact Number:</td><td class="review-val"><asp:Label ID="lblReviewContact" runat="server" Text="" /></td></tr>
                            <tr><td class="review-key">Email Address:</td><td class="review-val"><asp:Label ID="lblReviewEmail" runat="server" Text="" /></td></tr>
                            <tr><td class="review-key">Address:</td><td class="review-val"><asp:Label ID="lblReviewAddress" runat="server" Text="" /></td></tr>
                            <tr><td class="review-key">Province &amp; City:</td><td class="review-val"><asp:Label ID="lblReviewProvCity" runat="server" Text="" /></td></tr>
                            <tr><td class="review-key">School / University:</td><td class="review-val"><asp:Label ID="lblReviewSchool" runat="server" Text="" /></td></tr>
                            <tr><td class="review-key">Course:</td><td class="review-val"><asp:Label ID="lblReviewCourse" runat="server" Text="" /></td></tr>
                        </table>
                    </div>
                </div>

                <!-- Repeating Records Review -->
                <div id="aiRepeatingStep3Summary" class="mt-3 pt-3 border-top" style="display:none;">
                    <div class="review-group-title"><i class="fa fa-file-circle-check me-1 text-primary"></i>Accepted Documents &amp; Sea Service</div>
                    <div id="aiRepeatingStep3List" style="font-size:12.5px;"></div>
                </div>

                <div class="d-flex justify-content-between mt-4 pt-3 border-top">
                    <button type="button" class="btn-ummi-secondary" @click="setStep(2)">
                        <i class="fa fa-arrow-left me-1"></i> Back
                    </button>
                    <%-- validateAllForm() validates Step 1, Step 2, and any visible Other textboxes --%>
                    <asp:Button ID="btnSubmit" runat="server" Text="Submit Application"
                        CssClass="btn-ummi-primary" OnClick="SubmitApplication"
                        OnClientClick="if(!validateAllForm()){return false;} showLoading();" />
                </div>
            </div>
        </div>
    </div>
</div>

<%-- ═══════════════════════════════════════════════════════════════════════════
     OtherField — Reusable "Others (Please specify)" module
     NOTE: the typed text is shown for UX only; it is NOT saved to the DB.
     ═══════════════════════════════════════════════════════════════════════════ --%>
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
        var ageEl = document.getElementById('txtAge');
        setLbl('lblReviewAge', (ageEl && ageEl.value) ? ageEl.value : 'N/A');
        setLbl('<%= lblReviewPOB.ClientID %>', getVal('<%= txtPOB.ClientID %>'));
        setLbl('<%= lblReviewGender.ClientID %>', getDdlText('<%= drpdwnGender.ClientID %>'));
        setLbl('<%= lblReviewCivilStatus.ClientID %>', getDdlText('<%= drpdwnCivilStatus.ClientID %>'));
        setLbl('<%= lblReviewReligion.ClientID %>', getDdlOrOther('<%= drpdwnReligion.ClientID %>', '<%= txtReligionOther.ClientID %>'));
        setLbl('<%= lblReviewNationality.ClientID %>', getDdlOrOther('<%= drpdwnNationality.ClientID %>', '<%= txtNationalityOther.ClientID %>'));
        
        var hw = getVal('<%= txtHeight.ClientID %>') + ' cm / ' + getVal('<%= txtWeight.ClientID %>') + ' kg';
        if (hw === 'N/A cm / N/A kg') hw = 'N/A';
        setLbl('<%= lblReviewHeightWeight.ClientID %>', hw);
        setLbl('<%= lblReviewBloodType.ClientID %>', getDdlText('<%= drpdwnBloodType.ClientID %>'));
        
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
        border-left: 3px solid #2563eb !important;
        animation: otherSlideIn 0.18s ease;
    }
    @keyframes otherSlideIn {
        from { opacity: 0; transform: translateY(-5px); }
        to   { opacity: 1; transform: translateY(0);    }
    }
    .other-specify-input:focus {
        border-color: #2563eb !important;
        box-shadow: 0 0 0 3px rgba(37,99,235,.15) !important;
        outline: none;
    }
</style>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptContent" runat="server">
<script type="text/javascript">
    // Phase F.4: Field client IDs mapped for external suggestion review script
    window.AiCsrfToken = '<%= hfApplicantCsrfToken.Value %>';
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

    function parseDateString(str) {
        if (!str || !str.trim()) return null;
        str = str.trim();
        var parts;
        if (/^\d{4}-\d{1,2}-\d{1,2}$/.test(str)) {
            parts = str.split('-');
            var y = parseInt(parts[0], 10);
            var m = parseInt(parts[1], 10) - 1;
            var d = parseInt(parts[2], 10);
            return new Date(y, m, d);
        }
        if (/^\d{1,2}\/\d{1,2}\/\d{4}$/.test(str)) {
            parts = str.split('/');
            var m = parseInt(parts[0], 10) - 1;
            var d = parseInt(parts[1], 10);
            var y = parseInt(parts[2], 10);
            return new Date(y, m, d);
        }
        var dt = new Date(str);
        return isNaN(dt.getTime()) ? null : dt;
    }

    function calculateApplicantAge(dob, today) {
        if (!dob) return -1;
        if (!today) {
            today = new Date();
            today.setHours(0, 0, 0, 0);
        }
        var age = today.getFullYear() - dob.getFullYear();
        var m = today.getMonth() - dob.getMonth();
        if (m < 0 || (m === 0 && today.getDate() < dob.getDate())) {
            age--;
        }
        return age;
    }

    function calculateAge() {
        var dobInput = document.getElementById('<%= txtDOB.ClientID %>');
        var ageInput = document.getElementById('txtAge');
        if (!dobInput || !ageInput) return;

        var val = dobInput.value;
        if (val) {
            var dob = parseDateString(val);
            var today = new Date();
            today.setHours(0, 0, 0, 0);
            if (!dob) {
                ageInput.value = "Invalid Date";
                return;
            }
            if (dob > today) {
                ageInput.value = "Invalid (Future)";
                return;
            }
            var age = calculateApplicantAge(dob, today);
            if (age < 18) {
                ageInput.value = (age >= 0 ? age : 0) + " yrs (Under 18)";
            } else {
                ageInput.value = age + " yrs";
            }
        } else {
            ageInput.value = "--";
        }
    }

    function reportFieldError(el, message) {
        if (!el) return;
        el.focus();
        if (typeof el.reportValidity === 'function') {
            el.setCustomValidity(message);
            el.reportValidity();
            var clearHandler = function() {
                el.setCustomValidity('');
                el.removeEventListener('input', clearHandler);
                el.removeEventListener('change', clearHandler);
            };
            el.addEventListener('input', clearHandler);
            el.addEventListener('change', clearHandler);
        } else {
            alert(message);
        }
    }

    function validateStep1() {
        var elLast = document.getElementById('<%= txtLastName.ClientID %>');
        if (!elLast || !elLast.value.trim()) {
            reportFieldError(elLast, "Last Name is required.");
            return false;
        }

        var elFirst = document.getElementById('<%= txtFirstName.ClientID %>');
        if (!elFirst || !elFirst.value.trim()) {
            reportFieldError(elFirst, "First Name is required.");
            return false;
        }

        var elDob = document.getElementById('<%= txtDOB.ClientID %>');
        if (!elDob || !elDob.value.trim()) {
            reportFieldError(elDob, "Date of Birth is required.");
            return false;
        }
        var dob = parseDateString(elDob.value);
        var today = new Date();
        today.setHours(0, 0, 0, 0);
        if (!dob) {
            reportFieldError(elDob, "Please enter a valid Date of Birth.");
            return false;
        }
        if (dob > today) {
            reportFieldError(elDob, "Date of birth cannot be in the future.");
            return false;
        }
        var age = calculateApplicantAge(dob, today);
        if (age < 18) {
            reportFieldError(elDob, "Applicant must be at least 18 years old to apply.");
            return false;
        }

        var elPob = document.getElementById('<%= txtPOB.ClientID %>');
        if (!elPob || !elPob.value.trim()) {
            reportFieldError(elPob, "Place of Birth is required.");
            return false;
        }

        var ddlGender = document.getElementById('<%= drpdwnGender.ClientID %>');
        if (!ddlGender || ddlGender.selectedIndex <= 0 || !ddlGender.value) {
            reportFieldError(ddlGender, "Please select your Gender.");
            return false;
        }

        var ddlCivil = document.getElementById('<%= drpdwnCivilStatus.ClientID %>');
        if (!ddlCivil || ddlCivil.selectedIndex <= 0 || !ddlCivil.value) {
            reportFieldError(ddlCivil, "Please select your Civil Status.");
            return false;
        }

        var ddlRel = document.getElementById('<%= drpdwnReligion.ClientID %>');
        if (!ddlRel || ddlRel.selectedIndex <= 0 || !ddlRel.value) {
            reportFieldError(ddlRel, "Please select your Religion.");
            return false;
        }
        if (ddlRel.value === 'other' || (ddlRel.options[ddlRel.selectedIndex] && ddlRel.options[ddlRel.selectedIndex].text.toLowerCase().indexOf('others') !== -1)) {
            var txtRel = document.getElementById('<%= txtReligionOther.ClientID %>');
            if (!txtRel || !txtRel.value.trim()) {
                reportFieldError(txtRel, "Please specify your Religion.");
                return false;
            }
        }

        var ddlNat = document.getElementById('<%= drpdwnNationality.ClientID %>');
        if (!ddlNat || ddlNat.selectedIndex <= 0 || !ddlNat.value) {
            reportFieldError(ddlNat, "Please select your Nationality.");
            return false;
        }
        if (ddlNat.value === 'other' || (ddlNat.options[ddlNat.selectedIndex] && ddlNat.options[ddlNat.selectedIndex].text.toLowerCase().indexOf('others') !== -1)) {
            var txtNat = document.getElementById('<%= txtNationalityOther.ClientID %>');
            if (!txtNat || !txtNat.value.trim()) {
                reportFieldError(txtNat, "Please specify your Nationality.");
                return false;
            }
        }

        var elHeight = document.getElementById('<%= txtHeight.ClientID %>');
        if (!elHeight || !elHeight.value.trim() || isNaN(parseFloat(elHeight.value)) || parseFloat(elHeight.value) <= 0) {
            reportFieldError(elHeight, "Please enter a valid Height (cm).");
            return false;
        }

        var elWeight = document.getElementById('<%= txtWeight.ClientID %>');
        if (!elWeight || !elWeight.value.trim() || isNaN(parseFloat(elWeight.value)) || parseFloat(elWeight.value) <= 0) {
            reportFieldError(elWeight, "Please enter a valid Weight (kg).");
            return false;
        }

        var ddlBlood = document.getElementById('<%= drpdwnBloodType.ClientID %>');
        if (!ddlBlood || ddlBlood.selectedIndex <= 0 || !ddlBlood.value) {
            reportFieldError(ddlBlood, "Please select your Blood Type.");
            return false;
        }

        var ddlRank = document.getElementById('<%= drpdwnRank.ClientID %>');
        if (!ddlRank || ddlRank.selectedIndex <= 0 || !ddlRank.value) {
            reportFieldError(ddlRank, "Please select the Applied Rank.");
            return false;
        }

        return true;
    }

    function validateStep2() {
        var elContact = document.getElementById('<%= txtContact.ClientID %>');
        if (!elContact || !elContact.value.trim()) {
            reportFieldError(elContact, "Contact Number is required.");
            return false;
        }

        var elEmail = document.getElementById('<%= txtEmail.ClientID %>');
        if (!elEmail || !elEmail.value.trim()) {
            reportFieldError(elEmail, "Email Address is required.");
            return false;
        }
        var emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailPattern.test(elEmail.value.trim())) {
            reportFieldError(elEmail, "Please enter a valid Email Address.");
            return false;
        }

        var elAddr = document.getElementById('<%= txtAddress.ClientID %>');
        if (!elAddr || !elAddr.value.trim()) {
            reportFieldError(elAddr, "Address is required.");
            return false;
        }

        var ddlProv = document.getElementById('<%= drpdwnProvince.ClientID %>');
        if (!ddlProv || ddlProv.selectedIndex <= 0 || !ddlProv.value) {
            reportFieldError(ddlProv, "Please select your Province.");
            return false;
        }

        var ddlCity = document.getElementById('<%= drpdwnCity.ClientID %>');
        if (!ddlCity || ddlCity.selectedIndex <= 0 || !ddlCity.value) {
            reportFieldError(ddlCity, "Please select your City / Municipality.");
            return false;
        }

        var ddlSchool = document.getElementById('<%= drpdwnSchool.ClientID %>');
        if (!ddlSchool || ddlSchool.selectedIndex <= 0 || !ddlSchool.value) {
            reportFieldError(ddlSchool, "Please select your School / University.");
            return false;
        }
        if (ddlSchool.value === 'other' || (ddlSchool.options[ddlSchool.selectedIndex] && ddlSchool.options[ddlSchool.selectedIndex].text.toLowerCase().indexOf('others') !== -1)) {
            var txtSchool = document.getElementById('<%= txtSchoolOther.ClientID %>');
            if (!txtSchool || !txtSchool.value.trim()) {
                reportFieldError(txtSchool, "Please specify your School / University.");
                return false;
            }
        }

        var ddlCourse = document.getElementById('<%= drpdwnCourse.ClientID %>');
        if (!ddlCourse || ddlCourse.selectedIndex <= 0 || !ddlCourse.value) {
            reportFieldError(ddlCourse, "Please select your Course.");
            return false;
        }
        if (ddlCourse.value === 'other' || (ddlCourse.options[ddlCourse.selectedIndex] && ddlCourse.options[ddlCourse.selectedIndex].text.toLowerCase().indexOf('others') !== -1)) {
            var txtCourse = document.getElementById('<%= txtCourseOther.ClientID %>');
            if (!txtCourse || !txtCourse.value.trim()) {
                reportFieldError(txtCourse, "Please specify your Course.");
                return false;
            }
        }

        return true;
    }

    function validateAllForm() {
        if (!validateStep1()) {
            var root = document.querySelector('[x-data]');
            if (root && root._x_dataStack && root._x_dataStack[0]) {
                root._x_dataStack[0].step = 1;
            }
            return false;
        }
        if (!validateStep2()) {
            var root = document.querySelector('[x-data]');
            if (root && root._x_dataStack && root._x_dataStack[0]) {
                root._x_dataStack[0].step = 2;
            }
            return false;
        }
        if (typeof OtherField !== 'undefined' && typeof OtherField.validateAll === 'function') {
            if (!OtherField.validateAll()) return false;
        }
        return true;
    }

    // Run on load in case DOB is pre-filled
    window.addEventListener('load', calculateAge);
</script>
<script src="<%= ResolveUrl("~/scripts/applicant-ai-assist.js") %>"></script>
</asp:Content>
