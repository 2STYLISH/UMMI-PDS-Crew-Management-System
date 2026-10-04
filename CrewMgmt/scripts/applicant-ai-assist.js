/**
 * Applicant AI-Assisted Self-Encoding Controller (Phase F)
 * Compliant with UMMI Security Architecture & Republic Act 10173
 * Milestone F.2 & F.3: Pipeline Execution, Lifecycle Management & Privacy Hardening
 */
(function (window, document) {
    'use strict';

    var ApplicantAiAssist = {
        config: {
            handlerUrl: 'ApplicantExtractionHandler.ashx',
            maxFiles: 10,
            maxFileSizeBytes: 5 * 1024 * 1024,      // 5 MB
            maxSessionSizeBytes: 25 * 1024 * 1024,  // 25 MB
            allowedExtensions: ['.pdf', '.jpg', '.jpeg', '.png'],
            pollIntervalMs: 1500,
            maxNetworkRetries: 5,                   // MT-RES-02: Bounded retry limit for network drops / cold restarts
            retryBackoffMs: 2000                    // MT-RES-02: Backoff interval between network retries
        },

        state: {
            hasConsent: false,
            activeJobId: null,
            pollingTimer: null,
            isPollingActive: false,                 // MT-RES-02: Strict guard against stale responses / multi-timer overlap
            networkRetryCount: 0,                   // MT-RES-02: Counter for transient network failures
            selectedFiles: [],
            suggestionPackage: null,
            fieldDecisions: {},
            isPostBackInProgress: false,
            // Phase F.5: session-only repeating-record review decisions (never submitted/saved)
            repeatingReview: { documents: {}, seaService: {} },
            showDiscardedRepeating: false
        },

        init: function () {
            var notifyEl = document.getElementById('lblNotify') || document.querySelector('[id$="lblNotify"]');
            var successAlert = notifyEl ? notifyEl.querySelector('.alert-success') : null;
            if (successAlert) {
                this.clearScopedSessionStorage();
                return;
            }

            this.cleanOldSessionStorage();
            this.bindEvents();
            this.restorePostbackState();
            this.updateConsentState();
        },

        restorePostbackState: function () {
            try {
                var raw = sessionStorage.getItem(this.getStorageKey('suggestions')) ||
                          sessionStorage.getItem('ummi_ai_suggestions');
                if (raw) {
                    var saved = JSON.parse(raw);
                    if (saved && saved.PersonalDetails) {
                        this.state.suggestionPackage = saved;
                        this.state.hasConsent = true;
                        this.state.activeJobId = sessionStorage.getItem(this.getStorageKey('active_job')) ||
                                                 sessionStorage.getItem('ummi_ai_active_job') || null;

                        try {
                            var revRaw = sessionStorage.getItem(this.getStorageKey('repeating_review')) ||
                                         sessionStorage.getItem('ummi_ai_repeating_review');
                            if (revRaw) {
                                var rev = JSON.parse(revRaw);
                                if (rev && typeof rev === 'object') {
                                    this.state.repeatingReview = {
                                        documents: rev.documents || {},
                                        seaService: rev.seaService || {}
                                    };
                                }
                            }
                        } catch (revEx) {
                            this.state.repeatingReview = { documents: {}, seaService: {} };
                        }

                        try {
                            var decRaw = sessionStorage.getItem(this.getStorageKey('field_decisions')) ||
                                         sessionStorage.getItem('ummi_ai_field_decisions');
                            if (decRaw) {
                                this.state.fieldDecisions = JSON.parse(decRaw) || {};
                            }
                        } catch (decEx) {
                            this.state.fieldDecisions = {};
                        }

                        var consentChk = document.getElementById('chkAiConsent');
                        if (consentChk) consentChk.checked = true;

                        var dropzone = document.getElementById('aiDropzone');
                        if (dropzone) {
                            dropzone.classList.remove('disabled');
                            dropzone.removeAttribute('aria-disabled');
                        }

                        var btnWithdraw = document.getElementById('btnAiWithdrawConsent');
                        if (btnWithdraw) btnWithdraw.style.display = 'inline-block';

                        this.showCompletion(saved);
                        this.restoreCitySelectionAfterPostback();
                    }
                }
            } catch (e) {
                if (window.console && console.error) {
                    console.error('Error restoring postback state:', e);
                }
            }
        },

        bindEvents: function () {
            var self = this;
            var consentChk = document.getElementById('chkAiConsent');
            if (consentChk) {
                consentChk.addEventListener('change', function () {
                    self.updateConsentState();
                });
            }

            var dropzone = document.getElementById('aiDropzone');
            var fileInput = document.getElementById('aiFileInput');

            if (dropzone && fileInput) {
                dropzone.addEventListener('click', function () {
                    if (!self.state.hasConsent) {
                        alert('Please review the Data Privacy Notice and accept the consent agreement before selecting documents.');
                        if (consentChk) consentChk.focus();
                        return;
                    }
                    fileInput.click();
                });

                fileInput.addEventListener('change', function (e) {
                    if (e.target.files && e.target.files.length > 0) {
                        self.handleFilesSelected(e.target.files);
                    }
                });

                // Drag and drop support
                dropzone.addEventListener('dragover', function (e) {
                    e.preventDefault();
                    if (self.state.hasConsent) {
                        dropzone.classList.add('dragover');
                    }
                });

                dropzone.addEventListener('dragleave', function (e) {
                    e.preventDefault();
                    dropzone.classList.remove('dragover');
                });

                dropzone.addEventListener('drop', function (e) {
                    e.preventDefault();
                    dropzone.classList.remove('dragover');
                    if (!self.state.hasConsent) {
                        alert('Please review the Data Privacy Notice and accept the consent agreement before dropping documents.');
                        return;
                    }
                    if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files.length > 0) {
                        self.handleFilesSelected(e.dataTransfer.files);
                    }
                });
            }

            // Cancel button
            var btnCancel = document.getElementById('btnAiCancel');
            if (btnCancel) {
                btnCancel.addEventListener('click', function () {
                    self.cancelActiveJob();
                });
            }

            // Retry button
            var btnRetry = document.getElementById('btnAiRetry');
            if (btnRetry) {
                btnRetry.addEventListener('click', function () {
                    self.resetUploadState();
                });
            }

            // F.3 Supplemental: Explicit Withdraw Consent button
            var btnWithdraw = document.getElementById('btnAiWithdrawConsent');
            if (btnWithdraw) {
                btnWithdraw.addEventListener('click', function () {
                    self.withdrawConsent();
                });
            }

            // Best-effort voluntary purge on application form submit
            // Phase G.1: Before postback, serialize accepted repeating decisions into hidden field
            var form = document.forms[0];
            if (form) {
                form.addEventListener('submit', function () {
                    self.isPostBackInProgress = true;
                    self.syncRepeatingDecisionsToForm();
                });
            }

            // Hook __doPostBack to prevent postbacks (like ProvinceChanged) from triggering unload cleanup
            var hookDoPostBack = function () {
                if (typeof window.__doPostBack === 'function' && !window.__ummiPostBackHooked) {
                    var origDoPostBack = window.__doPostBack;
                    window.__doPostBack = function (eventTarget, eventArgument) {
                        self.isPostBackInProgress = true;
                        return origDoPostBack.apply(this, arguments);
                    };
                    window.__ummiPostBackHooked = true;
                }
            };
            hookDoPostBack();
            if (typeof window.addEventListener === 'function') {
                window.addEventListener('load', hookDoPostBack);
            }

            // Purge staged files if applicant navigates away before completing
            window.addEventListener('beforeunload', function () {
                if (self.isPostBackInProgress) {
                    return;
                }
                if (self.state.activeJobId && !self.state.suggestionPackage) {
                    self.voluntaryCleanup();
                }
            });

            // Phase F.4: Suggestion review click delegation
            document.addEventListener('click', function (e) {
                var target = e.target;

                // Handle Apply button on standard suggestion pill
                var btnApply = target.closest('.btn-apply-suggestion');
                if (btnApply) {
                    var fieldKey = btnApply.getAttribute('data-field');
                    var val = btnApply.getAttribute('data-val');
                    var fkey = btnApply.getAttribute('data-fkey');
                    if (fieldKey) {
                        self.applySuggestion(fieldKey, val, fkey);
                    }
                    return;
                }

                // Handle Reject button on standard suggestion pill
                var btnReject = target.closest('.btn-reject-suggestion');
                if (btnReject) {
                    var fieldKey = btnReject.getAttribute('data-field');
                    if (fieldKey) {
                        self.rejectSuggestion(fieldKey);
                    }
                    return;
                }

                // Handle Apply Selected on conflict card
                var btnConflict = target.closest('.btn-apply-conflict');
                if (btnConflict) {
                    var fieldKey = btnConflict.getAttribute('data-field');
                    var slot = self.getSlot(fieldKey);
                    if (slot) {
                        var radio = slot.querySelector('input[name="conflict_' + fieldKey + '"]:checked');
                        if (radio) {
                            if (radio.value === '__KEEP_CURRENT__') {
                                self.recordFieldDecision(fieldKey, 'keep_current', '');
                                slot.innerHTML = '<div class="ai-suggestion-pill"><i class="fa fa-circle-check text-muted"></i> <span class="ai-sug-label text-muted">Current value retained</span></div>';
                            } else {
                                self.applySuggestion(fieldKey, radio.value);
                            }
                        }
                    }
                    return;
                }

                // Handle Select candidate button
                var btnCand = target.closest('.btn-select-candidate');
                if (btnCand) {
                    var fieldKey = btnCand.getAttribute('data-field');
                    var candId = btnCand.getAttribute('data-id');
                    var candText = btnCand.getAttribute('data-text');
                    if (fieldKey) {
                        self.applySuggestion(fieldKey, candText, candId);
                    }
                    return;
                }

                // Phase F.5: Repeating-record actions
                var btnKeep = target.closest('.btn-ai-keep');
                if (btnKeep) {
                    self.keepRepeatingRecord(
                        btnKeep.getAttribute('data-kind'),
                        parseInt(btnKeep.getAttribute('data-index'), 10)
                    );
                    return;
                }
                var btnDiscard = target.closest('.btn-ai-discard');
                if (btnDiscard) {
                    self.discardRepeatingRecord(
                        btnDiscard.getAttribute('data-kind'),
                        parseInt(btnDiscard.getAttribute('data-index'), 10)
                    );
                    return;
                }
                var btnRestore = target.closest('.btn-ai-restore');
                if (btnRestore) {
                    self.restoreRepeatingRecord(
                        btnRestore.getAttribute('data-kind'),
                        parseInt(btnRestore.getAttribute('data-index'), 10)
                    );
                    return;
                }
                var btnEdit = target.closest('.btn-ai-edit');
                if (btnEdit) {
                    self.toggleEditRepeatingRecord(
                        btnEdit.getAttribute('data-kind'),
                        parseInt(btnEdit.getAttribute('data-index'), 10),
                        true
                    );
                    return;
                }
                var btnSaveEdit = target.closest('.btn-ai-save-edit');
                if (btnSaveEdit) {
                    self.saveEditRepeatingRecord(
                        btnSaveEdit.getAttribute('data-kind'),
                        parseInt(btnSaveEdit.getAttribute('data-index'), 10)
                    );
                    return;
                }
                var btnCancelEdit = target.closest('.btn-ai-cancel-edit');
                if (btnCancelEdit) {
                    self.toggleEditRepeatingRecord(
                        btnCancelEdit.getAttribute('data-kind'),
                        parseInt(btnCancelEdit.getAttribute('data-index'), 10),
                        false
                    );
                    return;
                }

                // Handle Specify Other button
                var btnOther = target.closest('.btn-specify-other');
                if (btnOther) {
                    var fieldKeyOther = btnOther.getAttribute('data-field');
                    var rawVal = btnOther.getAttribute('data-raw');
                    if (fieldKeyOther) {
                        self.applySuggestion(fieldKeyOther, 'other', 'other', rawVal);
                    }
                    return;
                }

                // Handle Apply All Step 1 button
                var btnApplyAll = target.closest('#btnAiApplyAllStep1');
                if (btnApplyAll) {
                    self.applyAllStep1();
                    return;
                }
            });

            // Phase F.5: Collapsible repeating panel header
            var repeatingHeader = document.getElementById('aiRepeatingHeader');
            if (repeatingHeader) {
                repeatingHeader.addEventListener('click', function () {
                    self.toggleRepeatingPanelBody();
                });
            }

            var btnShowDiscarded = document.getElementById('btnAiShowDiscarded');
            if (btnShowDiscarded) {
                btnShowDiscarded.addEventListener('click', function () {
                    self.state.showDiscardedRepeating = !self.state.showDiscardedRepeating;
                    btnShowDiscarded.innerHTML = self.state.showDiscardedRepeating
                        ? '<i class="fa fa-eye-slash me-1"></i>Hide discarded'
                        : '<i class="fa fa-eye me-1"></i>Show discarded';
                    self.renderRepeatingRecords(self.state.suggestionPackage);
                });
            }
        },

        updateConsentState: function () {
            var consentChk = document.getElementById('chkAiConsent');
            var isChecked = consentChk ? consentChk.checked : false;

            // If user explicitly unchecks the consent box after previously granting consent,
            // immediately trigger consent withdrawal (cancels processing, purges staged files)
            if (!isChecked && this.state.hasConsent) {
                this.withdrawConsent();
                return;
            }

            this.state.hasConsent = isChecked;

            var dropzone = document.getElementById('aiDropzone');
            var btnWithdraw = document.getElementById('btnAiWithdrawConsent');

            if (dropzone) {
                if (this.state.hasConsent) {
                    dropzone.classList.remove('disabled');
                    dropzone.setAttribute('aria-disabled', 'false');
                    if (btnWithdraw) btnWithdraw.style.display = 'inline-block';
                } else {
                    dropzone.classList.add('disabled');
                    dropzone.setAttribute('aria-disabled', 'true');
                    if (btnWithdraw) btnWithdraw.style.display = 'none';
                }
            }
        },

        getCsrfToken: function () {
            if (typeof window !== 'undefined' && window.AiCsrfToken) {
                return window.AiCsrfToken;
            }
            // Master pages may prefix the client ID (ctl00$...$hfApplicantCsrfToken).
            var hf = document.getElementById('hfApplicantCsrfToken') ||
                document.querySelector('[id$="hfApplicantCsrfToken"]');
            if (hf && hf.value) {
                return hf.value;
            }
            return '';
        },

        refreshCsrfTokenAndRetry: function (callback) {
            var self = this;
            var csrfXhr = new XMLHttpRequest();
            csrfXhr.open('GET', this.config.handlerUrl + '?action=csrf', true);
            csrfXhr.onload = function () {
                if (csrfXhr.status === 200) {
                    try {
                        var res = JSON.parse(csrfXhr.responseText);
                        if (res && res.success && res.csrfToken) {
                            if (typeof window !== 'undefined') {
                                window.AiCsrfToken = res.csrfToken;
                            }
                            var hf = document.getElementById('hfApplicantCsrfToken') ||
                                document.querySelector('[id$="hfApplicantCsrfToken"]');
                            if (hf) {
                                hf.value = res.csrfToken;
                            }
                            if (callback) callback(true);
                            return;
                        }
                    } catch (e) {}
                }
                if (callback) callback(false);
            };
            csrfXhr.onerror = function () {
                if (callback) callback(false);
            };
            csrfXhr.send();
        },

        getStorageKey: function (key) {
            var token = this.getCsrfToken();
            if (!token) return 'ummi_ai_' + key;
            return 'ummi_ai_' + token + '_' + key;
        },

        cleanOldSessionStorage: function () {
            try {
                var currentToken = this.getCsrfToken();
                if (!currentToken) return;
                var currentPrefix = 'ummi_ai_' + currentToken + '_';
                var keysToRemove = [];
                for (var i = 0; i < sessionStorage.length; i++) {
                    var k = sessionStorage.key(i);
                    if (k && k.indexOf('ummi_ai_') === 0) {
                        // Protect unscoped backward-compatibility keys
                        if (k === 'ummi_ai_suggestions' || k === 'ummi_ai_active_job' ||
                            k === 'ummi_ai_repeating_review' || k === 'ummi_ai_field_decisions') {
                            continue;
                        }
                        if (k.length > 20 && k.indexOf(currentPrefix) !== 0) {
                            keysToRemove.push(k);
                        }
                    }
                }
                for (var j = 0; j < keysToRemove.length; j++) {
                    sessionStorage.removeItem(keysToRemove[j]);
                }
            } catch (e) {}
        },

        clearScopedSessionStorage: function () {
            try {
                sessionStorage.removeItem(this.getStorageKey('suggestions'));
                sessionStorage.removeItem(this.getStorageKey('active_job'));
                sessionStorage.removeItem(this.getStorageKey('repeating_review'));
                sessionStorage.removeItem(this.getStorageKey('field_decisions'));
                sessionStorage.removeItem('ummi_ai_suggestions');
                sessionStorage.removeItem('ummi_ai_active_job');
                sessionStorage.removeItem('ummi_ai_repeating_review');
                sessionStorage.removeItem('ummi_ai_field_decisions');
            } catch (e) {}
        },

        recordFieldDecision: function (fieldKey, action, value) {
            if (!this.state.fieldDecisions) this.state.fieldDecisions = {};
            this.state.fieldDecisions[fieldKey] = {
                action: action,
                value: value,
                timestamp: (new Date()).getTime()
            };
            this.persistFieldDecisions();
        },

        persistFieldDecisions: function () {
            try {
                var serialized = JSON.stringify(this.state.fieldDecisions);
                sessionStorage.setItem(this.getStorageKey('field_decisions'), serialized);
                sessionStorage.setItem('ummi_ai_field_decisions', serialized);
            } catch (e) {}
        },

        validateFiles: function (fileList) {
            if (!fileList || fileList.length === 0) {
                return { isValid: false, error: 'No files selected.' };
            }

            if (fileList.length > this.config.maxFiles) {
                return {
                    isValid: false,
                    error: 'You may upload a maximum of ' + this.config.maxFiles + ' documents per session.'
                };
            }

            var totalBytes = 0;
            for (var i = 0; i < fileList.length; i++) {
                var file = fileList[i];
                var ext = '.' + file.name.split('.').pop().toLowerCase();

                if (this.config.allowedExtensions.indexOf(ext) === -1) {
                    return {
                        isValid: false,
                        error: 'File "' + file.name + '" has an unsupported file format. Allowed formats: PDF, JPG, PNG.'
                    };
                }

                if (file.size > this.config.maxFileSizeBytes) {
                    return {
                        isValid: false,
                        error: 'File "' + file.name + '" (' + (file.size / (1024 * 1024)).toFixed(1) + ' MB) exceeds the 5 MB limit.'
                    };
                }

                totalBytes += file.size;
            }

            if (totalBytes > this.config.maxSessionSizeBytes) {
                return {
                    isValid: false,
                    error: 'Total upload size (' + (totalBytes / (1024 * 1024)).toFixed(1) + ' MB) exceeds the 25 MB limit.'
                };
            }

            return { isValid: true, totalBytes: totalBytes };
        },

        handleFilesSelected: function (files) {
            var validation = this.validateFiles(files);
            if (!validation.isValid) {
                this.showError(validation.error);
                return;
            }

            this.uploadFiles(files);
        },

        uploadFiles: function (files, isRetry) {
            var self = this;
            isRetry = !!isRetry;
            var csrfToken = this.getCsrfToken();

            var formData = new FormData();
            formData.append('action', 'upload');
            formData.append('consent', '1');
            formData.append('csrf_token', csrfToken);

            for (var i = 0; i < files.length; i++) {
                formData.append('files', files[i]);
            }

            this.showProgress('Uploading and staging documents...', 5);
            var countSummary = document.getElementById('aiFileCountSummary');
            if (countSummary) {
                countSummary.innerText = 'Staging ' + files.length + ' file(s)...';
            }

            var xhr = new XMLHttpRequest();
            xhr.open('POST', this.config.handlerUrl, true);
            xhr.setRequestHeader('X-CSRF-Token', csrfToken);

            xhr.onload = function () {
                if (xhr.status === 200) {
                    try {
                        var resp = JSON.parse(xhr.responseText);
                        if (resp.success && resp.jobId) {
                            self.state.activeJobId = resp.jobId;
                            self.showProgress('Extraction queued...', 10);
                            self.startPolling(resp.jobId);
                        } else {
                            self.showError(resp.message || 'Upload staging failed.');
                        }
                    } catch (e) {
                        self.showError('Unable to parse server response.');
                    }
                } else if (xhr.status === 409) {
                    self.showError('An extraction job is already in progress for your session. Please wait for it to complete or try again.');
                } else if (xhr.status === 403) {
                    var authErr = 'Authorization error: your applicant link may be expired or invalid. Please refresh or re-open your link.';
                    try {
                        var parsedErr = JSON.parse(xhr.responseText);
                        if (parsedErr && (parsedErr.message || parsedErr.error)) {
                            authErr = parsedErr.message || parsedErr.error;
                        }
                    } catch (e) {}

                    // Specifically identify anti-CSRF token failure (e.g. session rehydration or multi-tab link re-entry)
                    var isCsrfError = (authErr && authErr.indexOf('anti-CSRF token') !== -1);
                    if (isCsrfError && !isRetry) {
                        self.refreshCsrfTokenAndRetry(function (refreshed) {
                            if (refreshed) {
                                self.uploadFiles(files, true);
                            } else {
                                self.showError(authErr);
                            }
                        });
                        return;
                    }

                    self.showError(authErr);
                } else {
                    try {
                        var errResp = JSON.parse(xhr.responseText);
                        self.showError(errResp.message || ('Upload failed with status ' + xhr.status));
                    } catch (e) {
                        self.showError('Upload failed with status ' + xhr.status);
                    }
                }
            };

            xhr.onerror = function () {
                self.showError('Network error occurred while uploading documents. Your entered form data is intact. Please try again.');
            };

            xhr.send(formData);
        },

        startPolling: function (jobId) {
            this.stopPolling();
            this.state.isPollingActive = true;
            this.state.activeJobId = jobId;
            this.state.networkRetryCount = 0;

            // MT-RES-02: Sequential polling begins with immediate first dispatch
            this.pollStatus(jobId);
        },

        scheduleNextPoll: function (jobId, delayMs) {
            var self = this;
            if (!this.state.isPollingActive || this.state.activeJobId !== jobId) {
                return;
            }
            if (this.state.pollingTimer) {
                clearTimeout(this.state.pollingTimer);
                this.state.pollingTimer = null;
            }
            var wait = (typeof delayMs === 'number') ? delayMs : this.config.pollIntervalMs;
            this.state.pollingTimer = setTimeout(function () {
                self.pollStatus(jobId);
            }, wait);
        },

        stopPolling: function () {
            this.state.isPollingActive = false;
            if (this.state.pollingTimer) {
                clearTimeout(this.state.pollingTimer);
                this.state.pollingTimer = null;
            }
        },

        handleNetworkRetry: function (jobId, detailMessage) {
            if (!this.state.isPollingActive || this.state.activeJobId !== jobId) {
                return;
            }
            this.state.networkRetryCount++;
            if (this.state.networkRetryCount > this.config.maxNetworkRetries) {
                this.stopPolling();
                this.state.activeJobId = null;
                this.showError('Server connection was interrupted. Your manually entered form values remain intact. You can continue filling out the form manually or retry uploading documents.');
            } else {
                this.scheduleNextPoll(jobId, this.config.retryBackoffMs);
            }
        },

        pollStatus: function (jobId) {
            var self = this;
            if (!this.state.isPollingActive || this.state.activeJobId !== jobId) {
                return;
            }

            var url = this.config.handlerUrl + '?action=status&jobId=' + encodeURIComponent(jobId);
            var xhr = new XMLHttpRequest();
            xhr.open('GET', url, true);

            xhr.onload = function () {
                // MT-RES-02: Guard against stale or out-of-order responses from cancelled/superseded jobs
                if (!self.state.isPollingActive || self.state.activeJobId !== jobId) {
                    return;
                }

                if (xhr.status === 200) {
                    self.state.networkRetryCount = 0; // Reset network retry counter on valid HTTP 200
                    try {
                        var resp = JSON.parse(xhr.responseText);
                        if (resp.success) {
                            self.updateProgressUI(resp);

                            if (resp.status === 'Completed') {
                                self.stopPolling();
                                self.fetchResult(jobId);
                            } else if (resp.status === 'Failed') {
                                self.stopPolling();
                                self.state.activeJobId = null;
                                self.showError(resp.error || resp.message || 'Document extraction encountered an error.');
                            } else if (resp.status === 'Cancelled') {
                                self.stopPolling();
                                self.state.activeJobId = null;
                                self.showError('Document extraction was cancelled by applicant.');
                            } else {
                                // In-flight (Queued, Processing, Staged) -> schedule next poll sequentially
                                self.scheduleNextPoll(jobId);
                            }
                        } else {
                            self.stopPolling();
                            self.state.activeJobId = null;
                            self.showError(resp.message || 'Extraction status check failed.');
                        }
                    } catch (e) {
                        self.handleNetworkRetry(jobId, 'Unable to parse server response.');
                    }
                } else if (xhr.status === 404) {
                    // Job evicted from cache or session expired: terminal
                    self.stopPolling();
                    self.state.activeJobId = null;
                    self.showError('Extraction job was not found or session expired. Your manually entered form values remain intact.');
                } else if (xhr.status === 403) {
                    // Terminal authorization loss: stop all polling, invalidate active job, clear explanation
                    self.stopPolling();
                    self.state.activeJobId = null;
                    self.showError('Your applicant session has expired or is unauthorized. A valid applicant session is required before retrying extraction or submitting your application. Your manually entered form values remain intact.');
                } else {
                    // Unexpected server error (500, 502, 503) -> apply bounded retry policy
                    self.handleNetworkRetry(jobId, 'Server returned status ' + xhr.status);
                }
            };

            xhr.onerror = function () {
                self.handleNetworkRetry(jobId, 'Network error during status poll.');
            };

            xhr.send();
        },

        fetchResult: function (jobId) {
            var self = this;
            if (this.state.activeJobId !== jobId) {
                return;
            }
            var url = this.config.handlerUrl + '?action=result&jobId=' + encodeURIComponent(jobId);

            var xhr = new XMLHttpRequest();
            xhr.open('GET', url, true);

            xhr.onload = function () {
                // MT-RES-02: Discard if job was cancelled or changed while request was in-flight
                if (self.state.activeJobId !== jobId) {
                    return;
                }

                if (xhr.status === 200) {
                    try {
                        var resp = JSON.parse(xhr.responseText);
                        if (resp.success && resp.suggestions) {
                            self.state.suggestionPackage = resp.suggestions;
                            self.showCompletion(resp.suggestions);
                        } else {
                            self.state.activeJobId = null;
                            self.showError('Extraction completed, but suggestions could not be loaded.');
                        }
                    } catch (e) {
                        self.state.activeJobId = null;
                        self.showError('Failed to parse extraction results.');
                    }
                } else if (xhr.status === 403) {
                    self.state.activeJobId = null;
                    self.showError('Your applicant session has expired or is unauthorized. A valid applicant session is required before retrying extraction or submitting your application. Your manually entered form values remain intact.');
                } else {
                    self.state.activeJobId = null;
                    self.showError('Unable to retrieve extraction results (Status ' + xhr.status + '). Your manually entered form values remain intact.');
                }
            };

            xhr.onerror = function () {
                if (self.state.activeJobId === jobId) {
                    self.state.activeJobId = null;
                    self.showError('Network error while retrieving extraction suggestions. Your manually entered form values remain intact.');
                }
            };

            xhr.send();
        },

        cancelActiveJob: function () {
            var self = this;
            var cancellingJobId = this.state.activeJobId;
            if (!cancellingJobId) {
                this.resetUploadState();
                return;
            }

            // Immediately mark polling inactive and detach activeJobId so in-flight responses are discarded
            this.stopPolling();
            this.state.activeJobId = null;

            var csrfToken = this.getCsrfToken();
            var formData = new FormData();
            formData.append('action', 'cancel');
            formData.append('jobId', cancellingJobId);
            formData.append('csrf_token', csrfToken);

            var xhr = new XMLHttpRequest();
            xhr.open('POST', this.config.handlerUrl, true);
            xhr.setRequestHeader('X-CSRF-Token', csrfToken);

            xhr.onload = function () {
                self.showError('Extraction cancelled by applicant.');
            };

            xhr.onerror = function () {
                self.resetUploadState();
            };

            xhr.send(formData);
        },

        showProgress: function (message, percent) {
            var dropzone = document.getElementById('aiDropzone');
            if (dropzone) dropzone.style.display = 'none';

            var errBox = document.getElementById('aiErrorBox');
            if (errBox) errBox.style.display = 'none';

            var compBox = document.getElementById('aiCompletionBox');
            if (compBox) compBox.style.display = 'none';

            var progContainer = document.getElementById('aiProgressContainer');
            if (progContainer) progContainer.style.display = 'block';

            var msgEl = document.getElementById('aiProgressMessage');
            if (msgEl) msgEl.innerText = message || 'Processing...';

            var pctEl = document.getElementById('aiProgressPercent');
            if (pctEl) pctEl.innerText = (percent || 0) + '%';

            var barFill = document.getElementById('aiProgressBarFill');
            if (barFill) barFill.style.width = (percent || 0) + '%';
        },

        updateProgressUI: function (resp) {
            var pct = resp.progress || 0;
            var msg = resp.message || 'Processing documents...';

            var msgEl = document.getElementById('aiProgressMessage');
            if (msgEl) msgEl.innerText = msg;

            var pctEl = document.getElementById('aiProgressPercent');
            if (pctEl) pctEl.innerText = pct + '%';

            var barFill = document.getElementById('aiProgressBarFill');
            if (barFill) barFill.style.width = pct + '%';

            var countSummary = document.getElementById('aiFileCountSummary');
            if (countSummary && resp.totalFiles > 0) {
                countSummary.innerText = 'Processed ' + (resp.processedFiles || 0) + ' of ' + resp.totalFiles + ' document(s)';
            }
        },

        showError: function (message) {
            this.stopPolling();

            var progContainer = document.getElementById('aiProgressContainer');
            if (progContainer) progContainer.style.display = 'none';

            var compBox = document.getElementById('aiCompletionBox');
            if (compBox) compBox.style.display = 'none';

            var errBox = document.getElementById('aiErrorBox');
            if (errBox) {
                errBox.style.display = 'block';
                var msgEl = document.getElementById('aiErrorMessage');
                if (msgEl) msgEl.innerText = message || 'An error occurred during extraction.';
            }
        },

        showCompletion: function (suggestions) {
            this.stopPolling();

            var progContainer = document.getElementById('aiProgressContainer');
            if (progContainer) progContainer.style.display = 'none';

            var errBox = document.getElementById('aiErrorBox');
            if (errBox) errBox.style.display = 'none';

            var compBox = document.getElementById('aiCompletionBox');
            if (compBox) {
                compBox.style.display = 'block';
                var msgEl = document.getElementById('aiCompletionMessage');
                if (msgEl) {
                    var docCount = suggestions && suggestions.AuditSummary ? (suggestions.AuditSummary.TotalDocumentsProcessed || suggestions.AuditSummary.TotalDocumentsIngested || 1) : 1;
                    msgEl.innerText = 'Document extraction complete! ' + docCount + ' document(s) extracted. Suggestions are ready for review below.';
                }
            }

            // Phase F.4: Render suggestions across all 20 PDS form controls
            // SAFEGUARD: Values are NEVER automatically applied into inputs or selects.
            // Every value requires explicit applicant [Apply], [Select], or [Apply All] action.
            this.renderSuggestions(suggestions);

            // Persist suggestions in browser tab session so that ASP.NET Web Forms postbacks
            // (e.g. ProvinceChanged cascading dropdown) do not destroy the review state
            try {
                var serialized = JSON.stringify(suggestions);
                sessionStorage.setItem(this.getStorageKey('suggestions'), serialized);
                sessionStorage.setItem('ummi_ai_suggestions', serialized);
                if (this.state.activeJobId) {
                    sessionStorage.setItem(this.getStorageKey('active_job'), this.state.activeJobId);
                    sessionStorage.setItem('ummi_ai_active_job', this.state.activeJobId);
                }
            } catch (e) {
                // Best effort
            }

            // Phase F.5: Render repeating document & sea-service review cards (session-only)
            this.ensureRepeatingReviewInitialized(suggestions);
            this.renderRepeatingRecords(suggestions);
            this.updateRepeatingStep3Summary();
        },

        resetUploadState: function () {
            this.stopPolling();
            this.state.activeJobId = null;
            this.state.isPollingActive = false;
            this.state.networkRetryCount = 0;

            this.clearScopedSessionStorage();

            var fileInput = document.getElementById('aiFileInput');
            if (fileInput) fileInput.value = '';

            var errBox = document.getElementById('aiErrorBox');
            if (errBox) errBox.style.display = 'none';

            var progContainer = document.getElementById('aiProgressContainer');
            if (progContainer) progContainer.style.display = 'none';

            var compBox = document.getElementById('aiCompletionBox');
            if (compBox) compBox.style.display = 'none';

            var dropzone = document.getElementById('aiDropzone');
            if (dropzone) dropzone.style.display = 'block';

            this.state.repeatingReview = { documents: {}, seaService: {} };
            this.state.fieldDecisions = {};
            this.state.showDiscardedRepeating = false;
            this.state.suggestionPackage = null;

            // Clear suggestion badges from form controls
            this.clearAllSuggestionSlots();

            // NOTE: Applicant manually-typed form values (txtFirstName, txtLastName, etc.)
            // are strictly left intact and NEVER cleared.
            this.voluntaryCleanup();
        },

        voluntaryCleanup: function () {
            this.clearScopedSessionStorage();
            try { sessionStorage.removeItem('ummi_ai_repeating_review'); } catch (e) {}
            this.state.fieldDecisions = {};

            var csrfToken = this.getCsrfToken();
            if (!csrfToken) return;

            var formData = new FormData();
            formData.append('action', 'cleanup');
            formData.append('csrf_token', csrfToken);

            try {
                if (navigator.sendBeacon) {
                    navigator.sendBeacon(this.config.handlerUrl, formData);
                } else {
                    var xhr = new XMLHttpRequest();
                    xhr.open('POST', this.config.handlerUrl, true);
                    xhr.setRequestHeader('X-CSRF-Token', csrfToken);
                    xhr.send(formData);
                }
            } catch (e) {
                // Best-effort cleanup: safe-fail
            }
        },

        withdrawConsent: function () {
            this.state.hasConsent = false;
            this.stopPolling();
            this.state.activeJobId = null;
            this.state.isPollingActive = false;
            this.state.networkRetryCount = 0;
            this.state.suggestionPackage = null;
            this.state.repeatingReview = { documents: {}, seaService: {} };
            this.state.fieldDecisions = {};
            this.state.showDiscardedRepeating = false;

            this.clearScopedSessionStorage();
            try { sessionStorage.removeItem('ummi_ai_repeating_review'); } catch (e) {}

            // Clear suggestion badges from all form controls immediately upon withdrawal
            // CRITICAL ARCHITECTURAL SAFEGUARD:
            // Manually entered applicant values (txtFirstName, txtLastName, DOB, etc.)
            // are strictly preserved and NEVER cleared when AI consent is withdrawn.
            this.clearAllSuggestionSlots();

            var consentChk = document.getElementById('chkAiConsent');
            if (consentChk) consentChk.checked = false;

            var dropzone = document.getElementById('aiDropzone');
            if (dropzone) {
                dropzone.classList.add('disabled');
                dropzone.setAttribute('aria-disabled', 'true');
                dropzone.style.display = 'block';
            }

            var btnWithdraw = document.getElementById('btnAiWithdrawConsent');
            if (btnWithdraw) btnWithdraw.style.display = 'none';

            var progContainer = document.getElementById('aiProgressContainer');
            if (progContainer) progContainer.style.display = 'none';

            var errBox = document.getElementById('aiErrorBox');
            if (errBox) errBox.style.display = 'none';

            var compBox = document.getElementById('aiCompletionBox');
            if (compBox) compBox.style.display = 'none';

            var fileInput = document.getElementById('aiFileInput');
            if (fileInput) fileInput.value = '';

            // CRITICAL ARCHITECTURAL SAFEGUARD:
            // Manually entered applicant values (txtFirstName, txtLastName, DOB, etc.)
            // are strictly preserved and NEVER cleared when AI consent is withdrawn.

            var csrfToken = this.getCsrfToken();
            if (csrfToken) {
                var formData = new FormData();
                formData.append('action', 'withdraw_consent');
                formData.append('csrf_token', csrfToken);

                try {
                    if (navigator.sendBeacon) {
                        navigator.sendBeacon(this.config.handlerUrl, formData);
                    } else {
                        var xhr = new XMLHttpRequest();
                        xhr.open('POST', this.config.handlerUrl, true);
                        xhr.setRequestHeader('X-CSRF-Token', csrfToken);
                        xhr.send(formData);
                    }
                } catch (e) {
                    // Safe-fail
                }
            }
        },

        // ── Phase F.4/F.6: Suggestion Review of PDS Fields ──

        ValidationStatus: {
            Missing: 0,
            ExtractedValid: 1,
            UnresolvedReference: 2,
            Conflicting: 3,
            Ambiguous: 4,
            FormatWarning: 5,
            ReviewRequired: 6
        },

        isStatus: function (status, expected) {
            if (status === null || status === undefined) return false;
            if (typeof expected === 'number') {
                return status === expected || status === String(expected);
            }
            if (typeof expected === 'string') {
                if (String(status).toLowerCase() === expected.toLowerCase()) return true;
                var code = this.ValidationStatus[expected];
                return code !== undefined && (status === code || status === String(code));
            }
            return false;
        },

        coreFields: {
            // Step 1: Personal Info
            LastName:         { isDropdown: false, isDate: false, step: 1, label: 'Last Name' },
            FirstName:        { isDropdown: false, isDate: false, step: 1, label: 'First Name' },
            MiddleName:       { isDropdown: false, isDate: false, step: 1, label: 'Middle Name' },
            Suffix:           { isDropdown: true,  isDate: false, step: 1, label: 'Suffix' },
            DateOfBirth:      { isDropdown: false, isDate: true,  step: 1, label: 'Date of Birth' },
            PlaceOfBirth:     { isDropdown: false, isDate: false, step: 1, label: 'Place of Birth' },
            Gender:           { isDropdown: true,  isDate: false, step: 1, label: 'Gender' },
            CivilStatus:      { isDropdown: true,  isDate: false, step: 1, label: 'Civil Status' },
            Religion:         { isDropdown: true,  isDate: false, step: 1, label: 'Religion', companionOtherKey: 'ReligionOther' },
            Nationality:      { isDropdown: true,  isDate: false, step: 1, label: 'Nationality', companionOtherKey: 'NationalityOther' },
            Height:           { isDropdown: false, isDate: false, step: 1, label: 'Height' },
            Weight:           { isDropdown: false, isDate: false, step: 1, label: 'Weight' },
            AppliedRank:      { isDropdown: true,  isDate: false, step: 1, label: 'Applied Rank' },

            // Step 2: Contact & Education
            ContactNumber:    { isDropdown: false, isDate: false, step: 2, label: 'Contact Number' },
            EmailAddress:     { isDropdown: false, isDate: false, step: 2, label: 'Email Address' },
            Address:          { isDropdown: false, isDate: false, step: 2, label: 'Address' },
            Province:         { isDropdown: true,  isDate: false, step: 2, label: 'Province' },
            City:             { isDropdown: true,  isDate: false, step: 2, label: 'City / Municipality' },
            SchoolName:       { isDropdown: true,  isDate: false, step: 2, label: 'School / University', companionOtherKey: 'SchoolOther' },
            Course:           { isDropdown: true,  isDate: false, step: 2, label: 'Course', companionOtherKey: 'CourseOther' }
        },

        escapeHtml: function (str) {
            if (str === null || str === undefined) return '';
            return String(str)
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;');
        },

        formatSource: function (src) {
            if (!src) return '';
            var cat = src.CategoryKey || src.DocumentCategory || 'Document';
            cat = cat.charAt(0).toUpperCase() + cat.slice(1);
            var p = src.PageNumber ? ('p.' + src.PageNumber) : 'p.1';
            return cat + ' (' + p + ')';
        },

        formatDateForInput: function (val) {
            if (!val) return '';
            if (typeof val === 'string') {
                var match = /\/Date\((\d+)\)\//.exec(val);
                if (match) {
                    var d = new Date(parseInt(match[1], 10));
                    return !isNaN(d.getTime()) ? this.toISOStringDate(d) : '';
                }
                var parsed = new Date(val);
                if (!isNaN(parsed.getTime())) {
                    return this.toISOStringDate(parsed);
                }
                return ''; // Safe fallback for invalid dates
            }
            if (val instanceof Date) {
                return !isNaN(val.getTime()) ? this.toISOStringDate(val) : '';
            }
            return '';
        },

        toISOStringDate: function (d) {
            var year = d.getFullYear();
            var month = ('0' + (d.getMonth() + 1)).slice(-2);
            var day = ('0' + d.getDate()).slice(-2);
            return year + '-' + month + '-' + day;
        },

        getControl: function (fieldKey) {
            if (window.AiFieldIds && window.AiFieldIds[fieldKey]) {
                var el = document.getElementById(window.AiFieldIds[fieldKey]);
                if (el) return el;
            }
            return document.querySelector('[id$="' + fieldKey + '"]');
        },

        getCompanionControl: function (companionKey) {
            if (!companionKey) return null;
            if (window.AiFieldIds && window.AiFieldIds[companionKey]) {
                var el = document.getElementById(window.AiFieldIds[companionKey]);
                if (el) return el;
            }
            return document.querySelector('[id$="' + companionKey + '"]');
        },

        getSlot: function (fieldKey) {
            return document.getElementById('aiSuggestion_' + fieldKey);
        },

        getControlValue: function (ctrl, isDropdown) {
            if (!ctrl) return '';
            if (isDropdown) {
                if (ctrl.selectedIndex >= 0) {
                    var opt = ctrl.options[ctrl.selectedIndex];
                    if (!opt) return '';
                    var val = (opt.value != null ? String(opt.value).trim() : '');
                    var txt = (opt.text != null ? String(opt.text).trim() : '');
                    if (val === '' || val === '0' || /^select\b/i.test(txt)) {
                        return '';
                    }
                    return txt;
                }
                var v = ctrl.value != null ? String(ctrl.value).trim() : '';
                return (/^select\b/i.test(v)) ? '' : v;
            }
            return ctrl.value != null ? String(ctrl.value).trim() : '';
        },

        renderSuggestions: function (suggestions) {
            this.clearAllSuggestionSlots();
            if (!suggestions || !suggestions.PersonalDetails) return;

            var pd = suggestions.PersonalDetails;
            var step1ActionableCount = 0;
            var step1ConflictCount = 0;

            for (var fieldKey in this.coreFields) {
                if (!this.coreFields.hasOwnProperty(fieldKey)) continue;

                var fieldDef = this.coreFields[fieldKey];
                var sug = pd[fieldKey];
                if (!sug) continue;

                var slot = this.getSlot(fieldKey);
                if (!slot) continue;

                this.renderFieldSuggestion(slot, fieldKey, fieldDef, sug);

                // Track Step 1 batch eligibility (strictly exclude Step 2 dependent controls Province and City)
                if (fieldDef.step === 1 && fieldKey !== 'Province' && fieldKey !== 'City') {
                    var status = sug.Status;
                    var hasConflict = (this.isStatus(status, 'Conflicting') || (sug.ConflictingAlternatives && sug.ConflictingAlternatives.length > 0));
                    var isAmbiguous = this.isStatus(status, 'Ambiguous');
                    var isFormatWarning = this.isStatus(status, 'FormatWarning') || (!sug.NormalizedValue && sug.StatusMessage);
                    var isMissing = (this.isStatus(status, 'Missing') || (!sug.NormalizedValue && !sug.ExtractedRawValue));

                    if (hasConflict || isAmbiguous || isFormatWarning) {
                        step1ConflictCount++;
                    } else if (!isMissing) {
                        var ctrl = this.getControl(fieldKey);
                        var currVal = this.getControlValue(ctrl, fieldDef.isDropdown);
                        var rawProposed = sug.NormalizedValue != null ? sug.NormalizedValue : (sug.ExtractedRawValue || '');
                        var proposedVal = fieldDef.isDate ? this.formatDateForInput(rawProposed) : String(rawProposed);
                        if (!currVal || currVal.toLowerCase() !== proposedVal.toLowerCase()) {
                            step1ActionableCount++;
                        }
                    }
                }
            }

            // Update Step 1 Batch container UI
            var batchContainer = document.getElementById('aiStep1BatchContainer');
            var batchNote = document.getElementById('aiStep1BatchNote');
            if (batchContainer) {
                if (step1ActionableCount > 0) {
                    batchContainer.style.display = 'inline-flex';
                    batchContainer.style.alignItems = 'center';
                    if (batchNote) {
                        batchNote.innerText = step1ConflictCount > 0
                            ? '(' + step1ActionableCount + ' ready, ' + step1ConflictCount + ' conflict/ambiguity requiring manual review)'
                            : '(' + step1ActionableCount + ' suggestions ready)';
                    }
                } else {
                    batchContainer.style.display = 'none';
                }
            }
        },

        renderFieldSuggestion: function (slot, fieldKey, fieldDef, sug) {
            var status = sug.Status;
            var hasConflict = (this.isStatus(status, 'Conflicting') || (sug.ConflictingAlternatives && sug.ConflictingAlternatives.length > 0));
            var isAmbiguous = this.isStatus(status, 'Ambiguous');
            var isFormatWarning = this.isStatus(status, 'FormatWarning') || (!sug.NormalizedValue && !!sug.StatusMessage);
            var isMissing = this.isStatus(status, 'Missing');

            if (isMissing && !sug.ExtractedRawValue && (!sug.CandidateSuggestions || sug.CandidateSuggestions.length === 0)) {
                slot.innerHTML = '';
                return;
            }

            // 1. Conflicting alternatives (FR-CM-66)
            if (hasConflict) {
                this.renderConflictCard(slot, fieldKey, sug);
                return;
            }

            // 2. Ambiguous structure (FR-CM-64)
            if (isAmbiguous) {
                this.renderAmbiguousWarning(slot, fieldKey, sug);
                return;
            }

            // 3. Format or measurement boundary warning (FR-CM-60/62: Height 50-250cm, Weight 20-300kg, CivilStatus)
            if (isFormatWarning) {
                this.renderWarningCard(slot, fieldKey, fieldDef, sug);
                return;
            }

            // 4. Fuzzy reference lookups (FR-CM-63)
            if (fieldDef.isDropdown && sug.CandidateSuggestions && sug.CandidateSuggestions.length > 0 && !sug.ResolvedForeignKeyId) {
                this.renderCandidateCard(slot, fieldKey, sug, fieldDef.companionOtherKey);
                return;
            }

            // 5. Standard valid or unreferenced suggestion
            this.renderStandardSuggestion(slot, fieldKey, fieldDef, sug);
        },

        renderStandardSuggestion: function (slot, fieldKey, fieldDef, sug) {
            var rawProposed = sug.NormalizedValue != null ? sug.NormalizedValue : sug.ExtractedRawValue;
            var proposedStr = fieldDef.isDate ? this.formatDateForInput(rawProposed) : String(rawProposed != null ? rawProposed : '');
            if (!proposedStr) {
                slot.innerHTML = '';
                return;
            }

            var ctrl = this.getControl(fieldKey);
            var currVal = this.getControlValue(ctrl, fieldDef.isDropdown);
            var isSame = false;
            if (currVal) {
                if (currVal.toLowerCase() === proposedStr.toLowerCase()) {
                    isSame = true;
                } else if (fieldDef.isDropdown && currVal.length > 2) {
                    var cLower = currVal.toLowerCase();
                    var pLower = proposedStr.toLowerCase();
                    if (pLower.indexOf(cLower) === 0 || cLower.indexOf(pLower) === 0) {
                        isSame = true;
                    }
                }
            }

            var dec = this.state.fieldDecisions ? this.state.fieldDecisions[fieldKey] : null;
            var isExplicitlyApplied = (dec && dec.action === 'applied' && (isSame || !currVal));
            var isExplicitlyRejected = (dec && dec.action === 'rejected');
            var src = (sug.Sources && sug.Sources.length > 0) ? sug.Sources[0] : null;
            var srcText = src ? ('<span class="ai-sug-src">' + this.escapeHtml(this.formatSource(src)) + '</span>') : '';
            var fkey = sug.ResolvedForeignKeyId != null ? sug.ResolvedForeignKeyId : '';

            if (isExplicitlyRejected) {
                slot.innerHTML =
                    '<div class="ai-suggestion-pill ai-sug-rejected">' +
                        '<div class="ai-sug-left">' +
                            '<i class="fa fa-times text-danger me-1"></i>' +
                            '<span class="ai-sug-label text-muted">Rejected:</span> ' +
                            '<span class="ai-sug-val text-muted text-decoration-line-through">' + this.escapeHtml(proposedStr) + '</span>' +
                        '</div>' +
                        (srcText ? '<div class="ai-sug-right">' + srcText + '</div>' : '') +
                    '</div>';
            } else if (isSame || isExplicitlyApplied) {
                var labelText = isExplicitlyApplied ? 'Applied:' : 'Matches document:';
                var displayVal = (isExplicitlyApplied && dec && dec.value) ? dec.value : proposedStr;
                slot.innerHTML =
                    '<div class="ai-suggestion-pill ai-sug-matched">' +
                        '<div class="ai-sug-left">' +
                            '<i class="fa fa-check text-success me-1"></i>' +
                            '<span class="ai-sug-label">' + labelText + '</span> ' +
                            '<span class="ai-sug-val">' + this.escapeHtml(displayVal) + '</span>' +
                        '</div>' +
                        (srcText ? '<div class="ai-sug-right">' + srcText + '</div>' : '') +
                    '</div>';
            } else if (currVal) {
                slot.innerHTML =
                    '<div class="ai-suggestion-pill ai-sug-different">' +
                        '<div class="ai-sug-left">' +
                            '<span class="ai-curr-val">Current: ' + this.escapeHtml(currVal) + '</span>' +
                            '<span><span class="ai-sug-label">Suggested:</span> <strong class="ai-sug-val">' + this.escapeHtml(proposedStr) + '</strong></span>' +
                        '</div>' +
                        '<div class="ai-sug-right">' +
                            srcText +
                            '<button type="button" class="btn-reject-suggestion" data-field="' + this.escapeHtml(fieldKey) + '" title="Dismiss suggestion">' +
                                'Reject' +
                            '</button>' +
                            '<button type="button" class="btn-apply-suggestion btn-replace-suggestion" data-field="' + this.escapeHtml(fieldKey) + '" data-val="' + this.escapeHtml(proposedStr) + '" data-fkey="' + this.escapeHtml(fkey) + '" title="Replace current value">' +
                                'Replace' +
                            '</button>' +
                        '</div>' +
                    '</div>';
            } else {
                slot.innerHTML =
                    '<div class="ai-suggestion-pill">' +
                        '<div class="ai-sug-left">' +
                            '<span class="ai-sug-label">Suggested:</span> ' +
                            '<strong class="ai-sug-val">' + this.escapeHtml(proposedStr) + '</strong>' +
                        '</div>' +
                        '<div class="ai-sug-right">' +
                            srcText +
                            '<button type="button" class="btn-reject-suggestion" data-field="' + this.escapeHtml(fieldKey) + '" title="Dismiss suggestion">' +
                                'Reject' +
                            '</button>' +
                            '<button type="button" class="btn-apply-suggestion" data-field="' + this.escapeHtml(fieldKey) + '" data-val="' + this.escapeHtml(proposedStr) + '" data-fkey="' + this.escapeHtml(fkey) + '" title="Apply suggested value">' +
                                'Apply' +
                            '</button>' +
                        '</div>' +
                    '</div>';
            }
        },

        renderConflictCard: function (slot, fieldKey, sug) {
            var dec = this.state.fieldDecisions ? this.state.fieldDecisions[fieldKey] : null;
            if (dec && dec.action === 'keep_current') {
                slot.innerHTML = '<div class="ai-suggestion-pill"><i class="fa fa-circle-check text-muted"></i> <span class="ai-sug-label text-muted">Current value retained</span></div>';
                return;
            }

            var primaryVal = sug.NormalizedValue != null ? String(sug.NormalizedValue) : (sug.ExtractedRawValue || '');
            var primarySrc = (sug.Sources && sug.Sources.length > 0) ? sug.Sources[0] : null;

            var html =
                '<div class="ai-conflict-card">' +
                    '<div class="ai-conflict-header">' +
                        '<i class="fa fa-triangle-exclamation text-warning me-1"></i>' +
                        '<span>Conflicting document values found:</span>' +
                    '</div>' +
                    '<div class="ai-conflict-options">';

            // Option 1: Primary extracted
            html +=
                '<label class="ai-conflict-option">' +
                    '<input type="radio" name="conflict_' + this.escapeHtml(fieldKey) + '" value="' + this.escapeHtml(primaryVal) + '" checked="checked">' +
                    '<span class="ai-conflict-text">' + this.escapeHtml(primaryVal) + '</span>' +
                    (primarySrc ? ('<span class="badge-ai-src"><i class="fa fa-file-lines me-1"></i>' + this.escapeHtml(this.formatSource(primarySrc)) + '</span>') : '') +
                '</label>';

            // Options 2+: Conflicting alternatives
            if (sug.ConflictingAlternatives && sug.ConflictingAlternatives.length > 0) {
                for (var i = 0; i < sug.ConflictingAlternatives.length; i++) {
                    var alt = sug.ConflictingAlternatives[i];
                    var altVal = alt.Value != null ? String(alt.Value) : (alt.RawText || '');
                    html +=
                        '<label class="ai-conflict-option">' +
                            '<input type="radio" name="conflict_' + this.escapeHtml(fieldKey) + '" value="' + this.escapeHtml(altVal) + '">' +
                            '<span class="ai-conflict-text">' + this.escapeHtml(altVal) + '</span>' +
                            (alt.Source ? ('<span class="badge-ai-src"><i class="fa fa-file-lines me-1"></i>' + this.escapeHtml(this.formatSource(alt.Source)) + '</span>') : '') +
                        '</label>';
                }
            }

            // Option: Keep current
            html +=
                '<label class="ai-conflict-option">' +
                    '<input type="radio" name="conflict_' + this.escapeHtml(fieldKey) + '" value="__KEEP_CURRENT__">' +
                    '<span class="ai-conflict-text text-muted" style="font-weight:normal;">Keep current value / decide manually</span>' +
                '</label>';

            html +=
                    '</div>' +
                    '<div class="ai-conflict-footer">' +
                        '<button type="button" class="btn btn-sm btn-primary btn-apply-conflict" data-field="' + this.escapeHtml(fieldKey) + '" style="font-size:11px;padding:2px 8px;">' +
                            '<i class="fa fa-check me-1"></i>Apply Selected' +
                        '</button>' +
                    '</div>' +
                '</div>';

            slot.innerHTML = html;
        },

        renderCandidateCard: function (slot, fieldKey, sug, companionOtherKey) {
            var rawVal = sug.ExtractedRawValue || String(sug.NormalizedValue || '');
            var html =
                '<div class="ai-candidate-card">' +
                    '<div class="ai-candidate-header">' +
                        '<i class="fa fa-magnifying-glass me-1 text-primary"></i>' +
                        '<span>Reference suggestions for "<em>' + this.escapeHtml(rawVal) + '</em>":</span>' +
                    '</div>' +
                    '<div class="ai-candidate-list">';

            for (var i = 0; i < sug.CandidateSuggestions.length; i++) {
                var cand = sug.CandidateSuggestions[i];
                var score = Math.round(cand.SimilarityScore * 100);
                var candText = cand.DisplayText || cand.MatchedCodeOrName;
                html +=
                    '<div class="ai-candidate-pill">' +
                        '<span class="ai-candidate-text">' + this.escapeHtml(candText) + '</span>' +
                        '<span class="ai-candidate-score">' + score + '% match</span>' +
                        '<button type="button" class="btn-select-candidate" data-field="' + this.escapeHtml(fieldKey) + '" data-id="' + this.escapeHtml(cand.Id) + '" data-text="' + this.escapeHtml(candText) + '">' +
                            '<i class="fa fa-check me-1"></i>Select' +
                        '</button>' +
                    '</div>';
            }

            html += '</div>';

            if (companionOtherKey) {
                html +=
                    '<div class="mt-2">' +
                        '<button type="button" class="btn-specify-other" data-field="' + this.escapeHtml(fieldKey) + '" data-raw="' + this.escapeHtml(rawVal) + '">' +
                            '<i class="fa fa-pen me-1"></i>Not in list? Specify as "Others": <strong>' + this.escapeHtml(rawVal) + '</strong>' +
                        '</button>' +
                    '</div>';
            }

            html += '</div>';
            slot.innerHTML = html;
        },

        renderAmbiguousWarning: function (slot, fieldKey, sug) {
            var rawText = sug.ExtractedRawValue || String(sug.NormalizedValue || '');
            var proposedVal = sug.NormalizedValue != null ? String(sug.NormalizedValue) : '';
            var src = (sug.Sources && sug.Sources.length > 0) ? sug.Sources[0] : null;

            var html =
                '<div class="ai-ambiguous-warning">' +
                    '<div class="ai-ambiguous-title">' +
                        '<i class="fa fa-triangle-exclamation text-warning me-1"></i>' +
                        '<span>Ambiguous Name Structure Detected</span>' +
                    '</div>' +
                    '<div>' +
                        'Extracted text: <code class="ai-raw-name">"' + this.escapeHtml(rawText) + '"</code>' +
                    '</div>' +
                    '<div class="ai-ambiguous-note">' +
                        (sug.StatusMessage ? this.escapeHtml(sug.StatusMessage) : 'Multiple interpretations of First/Middle/Last names are possible. Please verify or manually enter name parts.') +
                    '</div>' +
                    '<div class="ai-ambiguous-actions">' +
                        (src ? ('<span class="badge-ai-src"><i class="fa fa-file-lines me-1"></i>' + this.escapeHtml(this.formatSource(src)) + '</span>') : '');

            if (proposedVal) {
                html +=
                    '<button type="button" class="btn-apply-suggestion" data-field="' + this.escapeHtml(fieldKey) + '" data-val="' + this.escapeHtml(proposedVal) + '" style="font-size:10.5px;">' +
                        '<i class="fa fa-check me-1"></i>Apply Proposed: "' + this.escapeHtml(proposedVal) + '"' +
                    '</button>';
            }

            html +=
                    '</div>' +
                '</div>';

            slot.innerHTML = html;
        },

        renderWarningCard: function (slot, fieldKey, fieldDef, sug) {
            var rawVal = sug.ExtractedRawValue || String(sug.NormalizedValue || '');
            var src = (sug.Sources && sug.Sources.length > 0) ? sug.Sources[0] : null;
            var srcBadge = src ? ('<span class="badge-ai-src"><i class="fa fa-file-lines me-1"></i>' + this.escapeHtml(this.formatSource(src)) + '</span>') : '';
            var warnMsg = sug.StatusMessage || 'Format or measurement range warning detected.';

            var html =
                '<div class="ai-warning-card">' +
                    '<div class="ai-warning-header">' +
                        '<i class="fa fa-triangle-exclamation text-warning me-1"></i>' +
                        '<span>' + this.escapeHtml(warnMsg) + '</span>' +
                    '</div>' +
                    '<div class="ai-warning-body">' +
                        '<span>Extracted: <strong>' + this.escapeHtml(rawVal) + '</strong></span>' +
                        srcBadge +
                    '</div>' +
                    '<div class="ai-warning-note text-muted" style="font-size:11px;margin-top:2px;">' +
                        'Please verify or enter manually.' +
                    '</div>' +
                '</div>';
            slot.innerHTML = html;
        },

    rejectSuggestion: function (fieldKey) {
        this.state.fieldDecisions = this.state.fieldDecisions || {};
        this.state.fieldDecisions[fieldKey] = {
            action: 'rejected',
            timestamp: new Date().toISOString()
        };
        this.saveState();
        this.evaluateField(fieldKey);
        this.updateGlobalProgress();
    },

    applySuggestion: function (fieldKey, value, foreignKeyId, companionOtherValue) {
            var fieldDef = this.coreFields[fieldKey];
            if (!fieldDef) return;

            var ctrl = this.getControl(fieldKey);
            if (!ctrl) return;

            if (fieldDef.isDropdown) {
                var selected = false;
                // 1. Try matching foreignKeyId if provided
                if (foreignKeyId && foreignKeyId !== 'other') {
                    for (var i = 0; i < ctrl.options.length; i++) {
                        if (ctrl.options[i].value == foreignKeyId) {
                            ctrl.selectedIndex = i;
                            selected = true;
                            break;
                        }
                    }
                }

                // 2. Try text match
                if (!selected && value && value !== 'other') {
                    var valLower = String(value).trim().toLowerCase();
                    for (var j = 0; j < ctrl.options.length; j++) {
                        if (ctrl.options[j].text.trim().toLowerCase() === valLower) {
                            ctrl.selectedIndex = j;
                            selected = true;
                            break;
                        }
                    }
                }

                // 3. Try value match
                if (!selected && value) {
                    for (var k = 0; k < ctrl.options.length; k++) {
                        if (ctrl.options[k].value.trim().toLowerCase() === String(value).trim().toLowerCase()) {
                            ctrl.selectedIndex = k;
                            selected = true;
                            break;
                        }
                    }
                }

                // 3.5. Partial / starts-with match (handles suffixes like " City", " Municipality", " Province")
                // Only applied when exact matches fail, avoiding false positives on short common words.
                if (!selected && value && value !== 'other') {
                    var valLowerP = String(value).trim().toLowerCase();
                    var bestIdx = -1;
                    var bestLen = 0;
                    for (var p = 0; p < ctrl.options.length; p++) {
                        var optLower = ctrl.options[p].text.trim().toLowerCase();
                        if (optLower === '' || ctrl.options[p].value === '') continue;
                        // Option text is a prefix of the extracted value (e.g. "mandaue" in "mandaue city")
                        if (optLower.length > 2 && valLowerP.indexOf(optLower) === 0 && optLower.length > bestLen) {
                            bestIdx = p;
                            bestLen = optLower.length;
                        }
                    }
                    if (bestIdx >= 0) {
                        ctrl.selectedIndex = bestIdx;
                        selected = true;
                    }
                }

                // 4. Handle "Others (Please specify)" pattern
                if ((!selected || value === 'other' || foreignKeyId === 'other') && fieldDef.companionOtherKey) {
                    var otherOptIndex = -1;
                    for (var m = 0; m < ctrl.options.length; m++) {
                        var optText = ctrl.options[m].text.toLowerCase();
                        if (ctrl.options[m].value === 'other' || optText.indexOf('others (please specify)') !== -1 || optText === 'other') {
                            otherOptIndex = m;
                            break;
                        }
                    }

                    if (otherOptIndex >= 0) {
                        ctrl.selectedIndex = otherOptIndex;
                        selected = true;

                        var otherInput = this.getCompanionControl(fieldDef.companionOtherKey);
                        if (otherInput) {
                            otherInput.value = companionOtherValue || (value !== 'other' ? value : '');
                        }
                    }
                }

                // Call OtherField.toggle if available
                if (window.OtherField && typeof window.OtherField.toggle === 'function') {
                    window.OtherField.toggle(ctrl);
                }

                // If Province was selected, trigger ASP.NET AutoPostBack to populate City dropdown
                if (fieldKey === 'Province') {
                    this.isPostBackInProgress = true;
                    // Persist decision in storage BEFORE triggering postback navigation
                    var appliedProvDisplay = value === 'other' && companionOtherValue ? companionOtherValue : value;
                    this.recordFieldDecision(fieldKey, 'applied', appliedProvDisplay);

                    if (typeof window.__doPostBack === 'function') {
                        window.__doPostBack(ctrl.name || ctrl.id, '');
                    } else if (ctrl.onchange && typeof ctrl.onchange === 'function') {
                        ctrl.onchange();
                    } else {
                        ctrl.dispatchEvent(new Event('change', { bubbles: true }));
                    }
                    return;
                } else {
                    // Trigger change event on select
                    ctrl.dispatchEvent(new Event('change', { bubbles: true }));
                }

            } else if (fieldDef.isDate) {
                var formattedDate = this.formatDateForInput(value);
                ctrl.value = formattedDate;
                ctrl.dispatchEvent(new Event('change', { bubbles: true }));

                // Recalculate age if global calculateAge function exists
                if (typeof window.calculateAge === 'function') {
                    window.calculateAge();
                }

            } else {
                ctrl.value = value != null ? value : '';
                ctrl.dispatchEvent(new Event('input', { bubbles: true }));
                ctrl.dispatchEvent(new Event('change', { bubbles: true }));
            }

            // Record applicant decision
            var appliedDisplay = value === 'other' && companionOtherValue ? companionOtherValue : value;
            this.recordFieldDecision(fieldKey, 'applied', appliedDisplay);

            // Update slot to show Applied state
            var slot = this.getSlot(fieldKey);
            if (slot) {
                slot.innerHTML =
                    '<div class="ai-suggestion-pill ai-sug-matched">' +
                        '<i class="fa fa-check text-success"></i>' +
                        '<span class="ai-sug-label">Applied:</span>' +
                        '<strong class="ai-sug-val">' + this.escapeHtml(appliedDisplay) + '</strong>' +
                    '</div>';
            }

            // Sync review step
            if (typeof window.updateReview === 'function') {
                window.updateReview();
            }
        },

        restoreCitySelectionAfterPostback: function () {
            var cityCtrl = this.getControl('City');
            if (!cityCtrl || !cityCtrl.options) return;

            var cityDec = this.state.fieldDecisions ? this.state.fieldDecisions['City'] : null;
            if (cityDec && cityDec.action === 'applied' && cityDec.value) {
                var matchedIdx = this.findDropdownOptionIndex(cityCtrl, cityDec.value);
                if (matchedIdx > 0) {
                    // Valid for the newly selected province: safely restore selection
                    cityCtrl.selectedIndex = matchedIdx;
                    cityCtrl.dispatchEvent(new Event('change', { bubbles: true }));
                    var slot = this.getSlot('City');
                    if (slot) {
                        var optText = cityCtrl.options[matchedIdx].text.trim();
                        slot.innerHTML =
                            '<div class="ai-suggestion-pill ai-sug-matched">' +
                                '<i class="fa fa-check text-success"></i>' +
                                '<span class="ai-sug-label">Applied:</span>' +
                                '<strong class="ai-sug-val">' + this.escapeHtml(optText) + '</strong>' +
                            '</div>';
                    }
                } else {
                    // Not valid for the new province: reset selection and invalidate decision
                    // so AI suggestion remains available for explicit applicant review
                    cityCtrl.selectedIndex = 0;
                    delete this.state.fieldDecisions['City'];
                    this.persistFieldDecisions();
                    cityCtrl.dispatchEvent(new Event('change', { bubbles: true }));

                    var cityDef = this.coreFields['City'];
                    var citySug = this.state.suggestionPackage && this.state.suggestionPackage.PersonalDetails
                        ? this.state.suggestionPackage.PersonalDetails['City'] : null;
                    var citySlot = this.getSlot('City');
                    if (cityDef && citySug && citySlot) {
                        this.renderFieldSuggestion(citySlot, 'City', cityDef, citySug);
                    }
                }
            }
        },

        findDropdownOptionIndex: function (ctrl, value) {
            if (!ctrl || !ctrl.options || !value) return -1;
            var valLower = String(value).trim().toLowerCase();

            // 1. Exact text match
            for (var i = 0; i < ctrl.options.length; i++) {
                if (ctrl.options[i].value === '' || ctrl.options[i].value === '0') continue;
                if (ctrl.options[i].text.trim().toLowerCase() === valLower) {
                    return i;
                }
            }

            // 2. Exact value match
            for (var j = 0; j < ctrl.options.length; j++) {
                if (ctrl.options[j].value === '' || ctrl.options[j].value === '0') continue;
                if (ctrl.options[j].value.trim().toLowerCase() === valLower) {
                    return j;
                }
            }

            // 3. Prefix/partial match (handles "Mandaue" matching "Mandaue City" or vice versa)
            var bestIdx = -1;
            var bestLen = 0;
            for (var p = 0; p < ctrl.options.length; p++) {
                var optLower = ctrl.options[p].text.trim().toLowerCase();
                if (optLower === '' || ctrl.options[p].value === '' || ctrl.options[p].value === '0') continue;
                if (optLower.length > 2) {
                    if (valLower.indexOf(optLower) === 0 && optLower.length > bestLen) {
                        bestIdx = p;
                        bestLen = optLower.length;
                    } else if (optLower.indexOf(valLower) === 0 && valLower.length > bestLen) {
                        bestIdx = p;
                        bestLen = valLower.length;
                    }
                }
            }
            return bestIdx;
        },

        applyAllStep1: function () {
            if (!this.state.suggestionPackage || !this.state.suggestionPackage.PersonalDetails) return;

            var pd = this.state.suggestionPackage.PersonalDetails;
            var eligibleItems = [];
            var skippedCount = 0;

            for (var fieldKey in this.coreFields) {
                if (!this.coreFields.hasOwnProperty(fieldKey)) continue;

                var fieldDef = this.coreFields[fieldKey];
                // Step 2 controls (including dependent Province and City) are strictly excluded from batch apply
                if (fieldDef.step !== 1 || fieldKey === 'Province' || fieldKey === 'City') continue;

                var sug = pd[fieldKey];
                if (!sug) continue;

                var status = sug.Status;
                var hasConflict = (this.isStatus(status, 'Conflicting') || (sug.ConflictingAlternatives && sug.ConflictingAlternatives.length > 0));
                var isAmbiguous = this.isStatus(status, 'Ambiguous');
                var isFormatWarning = this.isStatus(status, 'FormatWarning') || (!sug.NormalizedValue && sug.StatusMessage);
                var isMissing = (this.isStatus(status, 'Missing') || (!sug.NormalizedValue && !sug.ExtractedRawValue));

                if (hasConflict || isAmbiguous) {
                    skippedCount++;
                    continue;
                }
                if (isFormatWarning) {
                    skippedCount++;
                    continue;
                }

                if (isMissing) continue;

                var dec = this.state.fieldDecisions ? this.state.fieldDecisions[fieldKey] : null;
                if (dec && (dec.action === 'rejected' || dec.action === 'applied' || dec.action === 'keep_current')) {
                    continue;
                }

                // For dropdowns with fuzzy candidates without exact resolved FK, require explicit applicant review
                if (fieldDef.isDropdown && sug.CandidateSuggestions && sug.CandidateSuggestions.length > 0 && !sug.ResolvedForeignKeyId) {
                    skippedCount++;
                    continue;
                }

                var valToApply = sug.NormalizedValue != null ? sug.NormalizedValue : sug.ExtractedRawValue;
                var fkey = sug.ResolvedForeignKeyId != null ? sug.ResolvedForeignKeyId : null;
                var ctrl = this.getControl(fieldKey);
                var currVal = this.getControlValue(ctrl, fieldDef.isDropdown);
                var proposedFormatted = fieldDef.isDate ? this.formatDateForInput(valToApply) : String(valToApply);

                eligibleItems.push({
                    fieldKey: fieldKey,
                    fieldDef: fieldDef,
                    valToApply: valToApply,
                    fkey: fkey,
                    currVal: currVal,
                    proposedFormatted: proposedFormatted,
                    isDifferent: (currVal && currVal.toLowerCase() !== proposedFormatted.toLowerCase())
                });
            }

            if (eligibleItems.length === 0) return;

            // Check if any eligible field has a manually entered value that would be overwritten
            var overwriteList = [];
            for (var i = 0; i < eligibleItems.length; i++) {
                if (eligibleItems[i].isDifferent) {
                    overwriteList.push('• ' + eligibleItems[i].fieldDef.label + ' (Current: "' + eligibleItems[i].currVal + '" -> Suggested: "' + eligibleItems[i].proposedFormatted + '")');
                }
            }

            var allowOverwrite = true;
            if (overwriteList.length > 0) {
                var confirmMsg = "The following fields already contain manually entered values:\n\n" +
                    overwriteList.join("\n") +
                    "\n\nDo you want to replace these values with the document suggestions?\n\n" +
                    "• Click OK to replace all listed fields.\n" +
                    "• Click Cancel to apply suggestions ONLY to blank fields.";
                allowOverwrite = window.confirm(confirmMsg);
            }

            var appliedCount = 0;
            for (var j = 0; j < eligibleItems.length; j++) {
                var item = eligibleItems[j];
                // If applicant declined overwrite, skip fields that have existing different values
                if (!allowOverwrite && item.isDifferent) {
                    continue;
                }
                this.applySuggestion(item.fieldKey, item.valToApply, item.fkey);
                appliedCount++;
            }

            var batchNote = document.getElementById('aiStep1BatchNote');
            var btnApplyAll = document.getElementById('btnAiApplyAllStep1');
            if (batchNote) {
                var msg = 'Applied ' + appliedCount + ' Step 1 suggestion(s).';
                if (skippedCount > 0) {
                    msg += ' ' + skippedCount + ' field(s) require manual review.';
                }
                batchNote.innerText = msg;
            }
            if (btnApplyAll) {
                btnApplyAll.disabled = true;
                btnApplyAll.classList.add('opacity-50');
            }
        },

        loadSyntheticSuggestions: function (pkg) {
            this.state.hasConsent = true;
            this.state.suggestionPackage = pkg;
            var consentChk = document.getElementById('chkAiConsent');
            if (consentChk) consentChk.checked = true;
            this.updateConsentState();
            this.showCompletion(pkg);
        },

        clearAllSuggestionSlots: function () {
            var slots = document.querySelectorAll('.ai-suggestion-slot');
            for (var i = 0; i < slots.length; i++) {
                slots[i].innerHTML = '';
            }

            var batchContainer = document.getElementById('aiStep1BatchContainer');
            if (batchContainer) batchContainer.style.display = 'none';

            var batchNote = document.getElementById('aiStep1BatchNote');
            if (batchNote) batchNote.innerText = '';

            var btnApplyAll = document.getElementById('btnAiApplyAllStep1');
            if (btnApplyAll) {
                btnApplyAll.disabled = false;
                btnApplyAll.classList.remove('opacity-50');
            }

            this.clearRepeatingReviewUi();
        },

        // ── Phase F.5: Repeating Document & Sea Service Review (session-only) ──

        persistRepeatingReview: function () {
            try {
                var serialized = JSON.stringify(this.state.repeatingReview);
                sessionStorage.setItem(this.getStorageKey('repeating_review'), serialized);
                sessionStorage.setItem('ummi_ai_repeating_review', serialized);
            } catch (e) { /* best effort */ }
        },

        ensureRepeatingReviewInitialized: function (suggestions) {
            if (!this.state.repeatingReview) {
                this.state.repeatingReview = { documents: {}, seaService: {} };
            }
            if (!this.state.repeatingReview.documents) this.state.repeatingReview.documents = {};
            if (!this.state.repeatingReview.seaService) this.state.repeatingReview.seaService = {};

            var docs = (suggestions && suggestions.Documents) ? suggestions.Documents : [];
            var seas = (suggestions && suggestions.SeaServiceRecords) ? suggestions.SeaServiceRecords : [];

            for (var i = 0; i < docs.length; i++) {
                var dk = String(i);
                if (!this.state.repeatingReview.documents[dk]) {
                    this.state.repeatingReview.documents[dk] = this.createDefaultRepeatingDecision();
                }
            }
            for (var j = 0; j < seas.length; j++) {
                var sk = String(j);
                if (!this.state.repeatingReview.seaService[sk]) {
                    this.state.repeatingReview.seaService[sk] = this.createDefaultRepeatingDecision();
                }
            }
            this.persistRepeatingReview();
        },

        createDefaultRepeatingDecision: function () {
            return {
                decision: 'pending',
                editing: false,
                confirmedConflict: false,
                textOnly: false,
                selectedDocTypeId: null,
                selectedVesselId: null,
                selectedRankId: null,
                edited: null
            };
        },

        getRepeatingDecision: function (kind, index) {
            var map = (kind === 'sea') ? this.state.repeatingReview.seaService : this.state.repeatingReview.documents;
            var key = String(index);
            if (!map[key]) map[key] = this.createDefaultRepeatingDecision();
            return map[key];
        },

        clearRepeatingReviewUi: function () {
            var panel = document.getElementById('aiRepeatingReviewPanel');
            if (panel) panel.style.display = 'none';

            var docList = document.getElementById('aiDocumentReviewList');
            if (docList) docList.innerHTML = '';
            var seaList = document.getElementById('aiSeaServiceReviewList');
            if (seaList) seaList.innerHTML = '';

            var step3 = document.getElementById('aiRepeatingStep3Summary');
            if (step3) step3.style.display = 'none';
            var step3List = document.getElementById('aiRepeatingStep3List');
            if (step3List) step3List.innerHTML = '';

            var badge = document.getElementById('aiRepeatingCountBadge');
            if (badge) badge.innerText = '';

            var btnShow = document.getElementById('btnAiShowDiscarded');
            if (btnShow) {
                btnShow.style.display = 'none';
                btnShow.innerHTML = '<i class="fa fa-eye me-1"></i>Show discarded';
            }
        },

        toggleRepeatingPanelBody: function () {
            var body = document.getElementById('aiRepeatingBody');
            var chevron = document.getElementById('aiRepeatingChevron');
            var header = document.getElementById('aiRepeatingHeader');
            if (!body) return;
            var hidden = body.style.display === 'none';
            body.style.display = hidden ? '' : 'none';
            if (chevron) {
                chevron.className = hidden ? 'fa fa-chevron-up' : 'fa fa-chevron-down';
            }
            if (header) header.setAttribute('aria-expanded', hidden ? 'true' : 'false');
        },

        formatDisplayDate: function (val) {
            var iso = this.formatDateForInput(val);
            return iso || '';
        },

        buildSourceBadgesHtml: function (sources) {
            if (!sources || !sources.length) return '';
            var html = '<div class="ai-record-sources">';
            for (var i = 0; i < sources.length; i++) {
                html += '<span class="badge-ai-src"><i class="fa fa-file-lines me-1"></i>' +
                    this.escapeHtml(this.formatSource(sources[i])) + '</span>';
            }
            html += '</div>';
            return html;
        },

        renderRepeatingRecords: function (suggestions) {
            var panel = document.getElementById('aiRepeatingReviewPanel');
            if (!panel) return;

            var docs = (suggestions && suggestions.Documents) ? suggestions.Documents : [];
            var seas = (suggestions && suggestions.SeaServiceRecords) ? suggestions.SeaServiceRecords : [];
            var total = docs.length + seas.length;

            if (total === 0) {
                panel.style.display = 'none';
                this.updateRepeatingStep3Summary();
                return;
            }

            // Auto-expand when records exist
            panel.style.display = '';
            var body = document.getElementById('aiRepeatingBody');
            if (body) body.style.display = '';
            var chevron = document.getElementById('aiRepeatingChevron');
            if (chevron) chevron.className = 'fa fa-chevron-up';
            var header = document.getElementById('aiRepeatingHeader');
            if (header) header.setAttribute('aria-expanded', 'true');

            var kept = 0, pending = 0, discarded = 0, needsReview = 0;
            var docList = document.getElementById('aiDocumentReviewList');
            var seaList = document.getElementById('aiSeaServiceReviewList');
            var docEmpty = document.getElementById('aiDocumentReviewEmpty');
            var seaEmpty = document.getElementById('aiSeaServiceReviewEmpty');
            if (docList) docList.innerHTML = '';
            if (seaList) seaList.innerHTML = '';

            var visibleDiscarded = 0;

            for (var i = 0; i < docs.length; i++) {
                var dDec = this.getRepeatingDecision('doc', i);
                if (dDec.decision === 'accepted') kept++;
                else if (dDec.decision === 'discarded') { discarded++; visibleDiscarded++; }
                else pending++;
                if (this.documentNeedsReviewGate(docs[i]) && dDec.decision === 'pending') needsReview++;

                if (dDec.decision === 'discarded' && !this.state.showDiscardedRepeating) continue;
                if (docList) docList.insertAdjacentHTML('beforeend', this.renderDocumentCard(docs[i], i, dDec));
            }

            for (var j = 0; j < seas.length; j++) {
                var sDec = this.getRepeatingDecision('sea', j);
                if (sDec.decision === 'accepted') kept++;
                else if (sDec.decision === 'discarded') { discarded++; visibleDiscarded++; }
                else pending++;
                if (this.seaServiceNeedsReviewGate(seas[j]) && sDec.decision === 'pending') needsReview++;

                if (sDec.decision === 'discarded' && !this.state.showDiscardedRepeating) continue;
                if (seaList) seaList.insertAdjacentHTML('beforeend', this.renderSeaServiceCard(seas[j], j, sDec));
            }

            if (docEmpty) docEmpty.style.display = docs.length === 0 ? '' : 'none';
            if (seaEmpty) seaEmpty.style.display = seas.length === 0 ? '' : 'none';

            var badge = document.getElementById('aiRepeatingCountBadge');
            if (badge) {
                badge.innerText = total + ' item(s)' +
                    (pending ? ' · ' + pending + ' pending' : '') +
                    (needsReview ? ' · ' + needsReview + ' need review' : '') +
                    (kept ? ' · ' + kept + ' kept' : '');
            }

            var btnShow = document.getElementById('btnAiShowDiscarded');
            if (btnShow) {
                btnShow.style.display = discarded > 0 ? '' : 'none';
            }

            this.updateRepeatingStep3Summary();
        },

        documentNeedsReviewGate: function (doc) {
            if (!doc) return false;
            if (doc.ConflictingDates || doc.IsNearDuplicate) return true;
            if (doc.Status === 6) return true; // ReviewRequired
            return false;
        },

        seaServiceNeedsReviewGate: function (ss) {
            if (!ss) return false;
            if (ss.IsNearDuplicate || ss.Status === 6) return true;
            return false;
        },

        documentNeedsReferenceChoice: function (doc, decision) {
            if (!doc) return false;
            if (decision && decision.selectedDocTypeId) return false;
            if (decision && decision.textOnly) return false;
            // Unresolved reference (2) or fuzzy candidates without resolved FK
            if (doc.Status === 2) return true;
            if ((!doc.DocumentTypeId) && doc.CandidateSuggestions && doc.CandidateSuggestions.length > 0) return true;
            return false;
        },

        seaNeedsReferenceChoice: function (ss, decision) {
            if (!ss) return false;
            var vesselOk = !!(ss.VesselId || (decision && (decision.selectedVesselId || decision.textOnly)));
            var rankOk = !!(ss.RankId || (decision && (decision.selectedRankId || decision.textOnly)));
            // If already resolved both, no choice needed
            if (ss.VesselId && ss.RankId) return false;
            if (decision && decision.textOnly) return false;
            if (decision && decision.selectedVesselId && decision.selectedRankId) return false;
            // Need choice when unresolved with candidates, or status UnresolvedReference
            if (ss.Status === 2) return true;
            var hasVesselCands = ss.CandidateVessels && ss.CandidateVessels.length > 0 && !ss.VesselId && !(decision && decision.selectedVesselId);
            var hasRankCands = ss.CandidateRanks && ss.CandidateRanks.length > 0 && !ss.RankId && !(decision && decision.selectedRankId);
            return hasVesselCands || hasRankCands || !vesselOk || !rankOk;
        },

        mergeDocumentView: function (doc, decision) {
            var view = {
                DocumentTypeName: doc.DocumentTypeName || '',
                DocumentNumber: doc.DocumentNumber || '',
                DateIssued: doc.DateIssued,
                DateExpiry: doc.DateExpiry,
                Grade: doc.Grade || '',
                HolderName: doc.HolderName || '',
                DocumentTypeId: doc.DocumentTypeId
            };
            if (decision && decision.edited) {
                if (decision.edited.DocumentTypeName != null) view.DocumentTypeName = decision.edited.DocumentTypeName;
                if (decision.edited.DocumentNumber != null) view.DocumentNumber = decision.edited.DocumentNumber;
                if (decision.edited.DateIssued != null) view.DateIssued = decision.edited.DateIssued;
                if (decision.edited.DateExpiry != null) view.DateExpiry = decision.edited.DateExpiry;
                if (decision.edited.Grade != null) view.Grade = decision.edited.Grade;
                if (decision.edited.HolderName != null) view.HolderName = decision.edited.HolderName;
            }
            if (decision && decision.selectedDocTypeId) view.DocumentTypeId = decision.selectedDocTypeId;
            if (decision && decision.textOnly) view.DocumentTypeId = null;
            return view;
        },

        mergeSeaServiceView: function (ss, decision) {
            var view = {
                VesselName: ss.VesselName || '',
                RankName: ss.RankName || '',
                DateFrom: ss.DateFrom,
                DateTo: ss.DateTo,
                EmployerAgency: ss.EmployerAgency || '',
                Remarks: ss.Remarks || '',
                Port: ss.Port || '',
                VesselId: ss.VesselId,
                RankId: ss.RankId
            };
            if (decision && decision.edited) {
                if (decision.edited.VesselName != null) view.VesselName = decision.edited.VesselName;
                if (decision.edited.RankName != null) view.RankName = decision.edited.RankName;
                if (decision.edited.DateFrom != null) view.DateFrom = decision.edited.DateFrom;
                if (decision.edited.DateTo != null) view.DateTo = decision.edited.DateTo;
                if (decision.edited.EmployerAgency != null) view.EmployerAgency = decision.edited.EmployerAgency;
                if (decision.edited.Remarks != null) view.Remarks = decision.edited.Remarks;
            }
            if (decision && decision.selectedVesselId) view.VesselId = decision.selectedVesselId;
            if (decision && decision.selectedRankId) view.RankId = decision.selectedRankId;
            if (decision && decision.textOnly) {
                view.VesselId = null;
                view.RankId = null;
            }
            return view;
        },

        renderDocumentCard: function (doc, index, decision) {
            var view = this.mergeDocumentView(doc, decision);
            var statusClass = 'ai-record-card';
            var badgeClass = 'status-pending';
            var badgeText = 'Pending';
            if (decision.decision === 'accepted') {
                statusClass += ' ai-record-accepted';
                badgeClass = 'status-kept';
                badgeText = 'Kept for now';
            } else if (decision.decision === 'discarded') {
                statusClass += ' ai-record-discarded';
                badgeClass = 'status-discarded';
                badgeText = 'Discarded';
            } else if (this.documentNeedsReviewGate(doc) || this.documentNeedsReferenceChoice(doc, decision)) {
                statusClass += ' ai-record-needs-review';
                badgeClass = 'status-review';
                badgeText = 'Needs review';
            }

            var title = view.DocumentTypeName || 'Document';
            var html = '<div class="' + statusClass + '" data-kind="doc" data-index="' + index + '">';
            html += '<div class="ai-record-header">';
            html += '<div class="ai-record-title">' + this.escapeHtml(title) + '</div>';
            html += '<span class="ai-record-status-badge ' + badgeClass + '">' + this.escapeHtml(badgeText) + '</span>';
            html += '</div>';

            if (decision.editing) {
                html += this.renderDocumentEditFields(view, index);
            } else {
                html += '<div class="ai-record-fields">';
                html += this.renderReadField('Number', view.DocumentNumber);
                html += this.renderReadField('Issued', this.formatDisplayDate(view.DateIssued));
                html += this.renderReadField('Expiry', this.formatDisplayDate(view.DateExpiry));
                if (view.Grade) html += this.renderReadField('Grade', view.Grade);
                if (view.HolderName) html += this.renderReadField('Holder', view.HolderName);
                html += '</div>';
            }

            html += this.buildSourceBadgesHtml(doc.Sources);

            if (doc.StatusMessage) {
                html += '<div class="ai-record-warning"><i class="fa fa-triangle-exclamation me-1"></i>' +
                    this.escapeHtml(doc.StatusMessage) + '</div>';
            }
            if (doc.ConflictingDates) {
                html += '<div class="ai-record-warning">Conflicting issue/expiry dates were found across documents. Confirm before keeping.</div>';
            }

            if (decision.decision === 'pending' && !decision.editing) {
                if (this.documentNeedsReviewGate(doc)) {
                    html += '<div class="ai-record-gate"><label>' +
                        '<input type="checkbox" class="ai-gate-conflict" data-kind="doc" data-index="' + index + '"' +
                        (decision.confirmedConflict ? ' checked' : '') + '>' +
                        '<span>I reviewed this duplicate/conflict and wish to keep this entry for now (session only).</span>' +
                        '</label></div>';
                }
                if (this.documentNeedsReferenceChoice(doc, decision)) {
                    html += this.renderDocTypeCandidates(doc, index, decision);
                }
            }

            html += '<div class="ai-record-actions">' + this.renderRepeatingActions('doc', index, decision) + '</div>';
            html += '</div>';
            return html;
        },

        renderSeaServiceCard: function (ss, index, decision) {
            var view = this.mergeSeaServiceView(ss, decision);
            var statusClass = 'ai-record-card';
            var badgeClass = 'status-pending';
            var badgeText = 'Pending';
            if (decision.decision === 'accepted') {
                statusClass += ' ai-record-accepted';
                badgeClass = 'status-kept';
                badgeText = 'Kept for now';
            } else if (decision.decision === 'discarded') {
                statusClass += ' ai-record-discarded';
                badgeClass = 'status-discarded';
                badgeText = 'Discarded';
            } else if (this.seaServiceNeedsReviewGate(ss) || this.seaNeedsReferenceChoice(ss, decision)) {
                statusClass += ' ai-record-needs-review';
                badgeClass = 'status-review';
                badgeText = 'Needs review';
            }

            var title = (view.VesselName || 'Vessel') + ' — ' + (view.RankName || 'Rank');
            var html = '<div class="' + statusClass + '" data-kind="sea" data-index="' + index + '">';
            html += '<div class="ai-record-header">';
            html += '<div class="ai-record-title">' + this.escapeHtml(title) + '</div>';
            html += '<span class="ai-record-status-badge ' + badgeClass + '">' + this.escapeHtml(badgeText) + '</span>';
            html += '</div>';

            if (decision.editing) {
                html += this.renderSeaServiceEditFields(view, index);
            } else {
                html += '<div class="ai-record-fields">';
                html += this.renderReadField('Vessel', view.VesselName);
                html += this.renderReadField('Rank', view.RankName);
                html += this.renderReadField('From', this.formatDisplayDate(view.DateFrom));
                html += this.renderReadField('To', this.formatDisplayDate(view.DateTo));
                if (view.EmployerAgency) html += this.renderReadField('Agency', view.EmployerAgency);
                if (view.Port) html += this.renderReadField('Port', view.Port + ' (session only)');
                if (view.Remarks) html += this.renderReadField('Remarks', view.Remarks);
                html += '</div>';
            }

            html += this.buildSourceBadgesHtml(ss.Sources);

            if (ss.NearDuplicateNote) {
                html += '<div class="ai-record-warning"><i class="fa fa-clone me-1"></i>' +
                    this.escapeHtml(ss.NearDuplicateNote) + '</div>';
            }
            if (ss.StatusMessage) {
                html += '<div class="ai-record-warning">' + this.escapeHtml(ss.StatusMessage) + '</div>';
            }

            if (decision.decision === 'pending' && !decision.editing) {
                if (this.seaServiceNeedsReviewGate(ss)) {
                    html += '<div class="ai-record-gate"><label>' +
                        '<input type="checkbox" class="ai-gate-conflict" data-kind="sea" data-index="' + index + '"' +
                        (decision.confirmedConflict ? ' checked' : '') + '>' +
                        '<span>I reviewed this overlapping/near-duplicate voyage and wish to keep it for now (session only).</span>' +
                        '</label></div>';
                }
                if (this.seaNeedsReferenceChoice(ss, decision)) {
                    html += this.renderSeaReferenceCandidates(ss, index, decision);
                }
            }

            html += '<div class="ai-record-actions">' + this.renderRepeatingActions('sea', index, decision) + '</div>';
            html += '</div>';
            return html;
        },

        renderReadField: function (label, value) {
            if (value === null || value === undefined || value === '') {
                return '<div class="ai-record-field"><label>' + this.escapeHtml(label) + '</label><span>—</span></div>';
            }
            return '<div class="ai-record-field"><label>' + this.escapeHtml(label) + '</label><span>' +
                this.escapeHtml(String(value)) + '</span></div>';
        },

        renderDocumentEditFields: function (view, index) {
            return '<div class="ai-record-fields">' +
                '<div class="ai-record-field"><label>Type</label><input type="text" data-edit="DocumentTypeName" data-kind="doc" data-index="' + index + '" value="' + this.escapeHtml(view.DocumentTypeName) + '"></div>' +
                '<div class="ai-record-field"><label>Number</label><input type="text" data-edit="DocumentNumber" data-kind="doc" data-index="' + index + '" value="' + this.escapeHtml(view.DocumentNumber) + '"></div>' +
                '<div class="ai-record-field"><label>Issued</label><input type="date" data-edit="DateIssued" data-kind="doc" data-index="' + index + '" value="' + this.escapeHtml(this.formatDisplayDate(view.DateIssued)) + '"></div>' +
                '<div class="ai-record-field"><label>Expiry</label><input type="date" data-edit="DateExpiry" data-kind="doc" data-index="' + index + '" value="' + this.escapeHtml(this.formatDisplayDate(view.DateExpiry)) + '"></div>' +
                '<div class="ai-record-field"><label>Grade</label><input type="text" data-edit="Grade" data-kind="doc" data-index="' + index + '" value="' + this.escapeHtml(view.Grade) + '"></div>' +
                '<div class="ai-record-field"><label>Holder</label><input type="text" data-edit="HolderName" data-kind="doc" data-index="' + index + '" value="' + this.escapeHtml(view.HolderName) + '"></div>' +
                '</div>';
        },

        renderSeaServiceEditFields: function (view, index) {
            return '<div class="ai-record-fields">' +
                '<div class="ai-record-field"><label>Vessel</label><input type="text" data-edit="VesselName" data-kind="sea" data-index="' + index + '" value="' + this.escapeHtml(view.VesselName) + '"></div>' +
                '<div class="ai-record-field"><label>Rank</label><input type="text" data-edit="RankName" data-kind="sea" data-index="' + index + '" value="' + this.escapeHtml(view.RankName) + '"></div>' +
                '<div class="ai-record-field"><label>From</label><input type="date" data-edit="DateFrom" data-kind="sea" data-index="' + index + '" value="' + this.escapeHtml(this.formatDisplayDate(view.DateFrom)) + '"></div>' +
                '<div class="ai-record-field"><label>To</label><input type="date" data-edit="DateTo" data-kind="sea" data-index="' + index + '" value="' + this.escapeHtml(this.formatDisplayDate(view.DateTo)) + '"></div>' +
                '<div class="ai-record-field"><label>Agency</label><input type="text" data-edit="EmployerAgency" data-kind="sea" data-index="' + index + '" value="' + this.escapeHtml(view.EmployerAgency) + '"></div>' +
                '<div class="ai-record-field"><label>Remarks</label><input type="text" data-edit="Remarks" data-kind="sea" data-index="' + index + '" value="' + this.escapeHtml(view.Remarks) + '"></div>' +
                '</div>';
        },

        renderDocTypeCandidates: function (doc, index, decision) {
            var html = '<div class="ai-record-candidates"><div class="ai-record-candidates-title">' +
                'Select a verified document type, or keep the original text without a database match:</div>';
            var cands = doc.CandidateSuggestions || [];
            for (var i = 0; i < cands.length; i++) {
                var c = cands[i];
                var id = c.Id != null ? String(c.Id) : '';
                var text = c.DisplayText || c.MatchedCodeOrName || '';
                var score = (c.SimilarityScore != null) ? Math.round(c.SimilarityScore * 100) + '% match' : '';
                var checked = (decision.selectedDocTypeId != null && String(decision.selectedDocTypeId) === id) ? ' checked' : '';
                html += '<label class="ai-record-candidate-option">' +
                    '<input type="radio" name="doc_type_' + index + '" class="ai-ref-choice" data-kind="doc" data-index="' + index + '" data-ref="docType" value="' + this.escapeHtml(id) + '"' + checked + '>' +
                    '<span>' + this.escapeHtml(text) + (score ? ' <span class="ai-candidate-score">' + this.escapeHtml(score) + '</span>' : '') + '</span></label>';
            }
            var textChecked = decision.textOnly ? ' checked' : '';
            html += '<label class="ai-record-candidate-option">' +
                '<input type="radio" name="doc_type_' + index + '" class="ai-ref-choice" data-kind="doc" data-index="' + index + '" data-ref="docType" value="__TEXT_ONLY__"' + textChecked + '>' +
                '<span>Keep original text (no database match): &ldquo;' + this.escapeHtml(doc.DocumentTypeName || '') + '&rdquo;</span></label>';
            html += '</div>';
            return html;
        },

        renderSeaReferenceCandidates: function (ss, index, decision) {
            var html = '<div class="ai-record-candidates">';

            if (!ss.VesselId && !(decision.selectedVesselId) && !decision.textOnly) {
                html += '<div class="ai-record-candidates-title">Vessel match — select a verified vessel or keep text only:</div>';
                var vc = ss.CandidateVessels || [];
                for (var i = 0; i < vc.length; i++) {
                    var c = vc[i];
                    var id = c.Id != null ? String(c.Id) : '';
                    var text = c.DisplayText || c.MatchedCodeOrName || '';
                    var score = (c.SimilarityScore != null) ? Math.round(c.SimilarityScore * 100) + '% match' : '';
                    var checked = (decision.selectedVesselId != null && String(decision.selectedVesselId) === id) ? ' checked' : '';
                    html += '<label class="ai-record-candidate-option">' +
                        '<input type="radio" name="sea_vessel_' + index + '" class="ai-ref-choice" data-kind="sea" data-index="' + index + '" data-ref="vessel" value="' + this.escapeHtml(id) + '"' + checked + '>' +
                        '<span>' + this.escapeHtml(text) + (score ? ' <span class="ai-candidate-score">' + this.escapeHtml(score) + '</span>' : '') + '</span></label>';
                }
                html += '<label class="ai-record-candidate-option">' +
                    '<input type="radio" name="sea_vessel_' + index + '" class="ai-ref-choice" data-kind="sea" data-index="' + index + '" data-ref="vessel" value="__TEXT_ONLY__">' +
                    '<span>Keep vessel text (no database match): &ldquo;' + this.escapeHtml(ss.VesselName || '') + '&rdquo;</span></label>';
            }

            if (!ss.RankId && !(decision.selectedRankId) && !decision.textOnly) {
                html += '<div class="ai-record-candidates-title" style="margin-top:6px;">Rank match — select a verified rank or keep text only:</div>';
                var rc = ss.CandidateRanks || [];
                for (var j = 0; j < rc.length; j++) {
                    var r = rc[j];
                    var rid = r.Id != null ? String(r.Id) : '';
                    var rtext = r.DisplayText || r.MatchedCodeOrName || '';
                    var rscore = (r.SimilarityScore != null) ? Math.round(r.SimilarityScore * 100) + '% match' : '';
                    var rchecked = (decision.selectedRankId != null && String(decision.selectedRankId) === rid) ? ' checked' : '';
                    html += '<label class="ai-record-candidate-option">' +
                        '<input type="radio" name="sea_rank_' + index + '" class="ai-ref-choice" data-kind="sea" data-index="' + index + '" data-ref="rank" value="' + this.escapeHtml(rid) + '"' + rchecked + '>' +
                        '<span>' + this.escapeHtml(rtext) + (rscore ? ' <span class="ai-candidate-score">' + this.escapeHtml(rscore) + '</span>' : '') + '</span></label>';
                }
                html += '<label class="ai-record-candidate-option">' +
                    '<input type="radio" name="sea_rank_' + index + '" class="ai-ref-choice" data-kind="sea" data-index="' + index + '" data-ref="rank" value="__TEXT_ONLY__">' +
                    '<span>Keep rank text (no database match): &ldquo;' + this.escapeHtml(ss.RankName || '') + '&rdquo;</span></label>';
            }

            // Global text-only when neither resolved and no candidates chosen yet
            if ((!ss.VesselId || !ss.RankId) && !decision.textOnly) {
                html += '<label class="ai-record-candidate-option" style="margin-top:4px;">' +
                    '<input type="radio" name="sea_textonly_' + index + '" class="ai-ref-choice" data-kind="sea" data-index="' + index + '" data-ref="allText" value="__TEXT_ONLY__">' +
                    '<span>Keep all as original text (no vessel/rank database match)</span></label>';
            }

            html += '</div>';
            return html;
        },

        renderRepeatingActions: function (kind, index, decision) {
            if (decision.editing) {
                return '<button type="button" class="btn-ai-save-edit" data-kind="' + kind + '" data-index="' + index + '"><i class="fa fa-floppy-disk me-1"></i>Save edits</button>' +
                    '<button type="button" class="btn-ai-cancel-edit" data-kind="' + kind + '" data-index="' + index + '">Cancel</button>';
            }
            if (decision.decision === 'discarded') {
                return '<button type="button" class="btn-ai-restore" data-kind="' + kind + '" data-index="' + index + '"><i class="fa fa-rotate-left me-1"></i>Restore</button>';
            }
            if (decision.decision === 'accepted') {
                return '<button type="button" class="btn-ai-edit" data-kind="' + kind + '" data-index="' + index + '"><i class="fa fa-pen me-1"></i>Edit</button>' +
                    '<button type="button" class="btn-ai-discard" data-kind="' + kind + '" data-index="' + index + '"><i class="fa fa-xmark me-1"></i>Discard</button>';
            }
            return '<button type="button" class="btn-ai-keep" data-kind="' + kind + '" data-index="' + index + '"><i class="fa fa-bookmark me-1"></i>Keep for now</button>' +
                '<button type="button" class="btn-ai-edit" data-kind="' + kind + '" data-index="' + index + '"><i class="fa fa-pen me-1"></i>Edit</button>' +
                '<button type="button" class="btn-ai-discard" data-kind="' + kind + '" data-index="' + index + '"><i class="fa fa-xmark me-1"></i>Discard</button>';
        },

        syncGateAndRefFromDom: function (kind, index) {
            var decision = this.getRepeatingDecision(kind, index);
            var card = document.querySelector('.ai-record-card[data-kind="' + kind + '"][data-index="' + index + '"]');
            if (!card) return decision;

            var gate = card.querySelector('.ai-gate-conflict');
            if (gate) decision.confirmedConflict = !!gate.checked;

            if (kind === 'doc') {
                var docRadio = card.querySelector('input[name="doc_type_' + index + '"]:checked');
                if (docRadio) {
                    if (docRadio.value === '__TEXT_ONLY__') {
                        decision.textOnly = true;
                        decision.selectedDocTypeId = null;
                    } else {
                        decision.textOnly = false;
                        decision.selectedDocTypeId = docRadio.value ? parseInt(docRadio.value, 10) : null;
                    }
                }
            } else {
                var vesselRadio = card.querySelector('input[name="sea_vessel_' + index + '"]:checked');
                if (vesselRadio) {
                    if (vesselRadio.value === '__TEXT_ONLY__') {
                        decision.selectedVesselId = null;
                        // partial text-only for vessel
                        decision._vesselTextOnly = true;
                    } else {
                        decision.selectedVesselId = vesselRadio.value ? parseInt(vesselRadio.value, 10) : null;
                        decision._vesselTextOnly = false;
                    }
                }
                var rankRadio = card.querySelector('input[name="sea_rank_' + index + '"]:checked');
                if (rankRadio) {
                    if (rankRadio.value === '__TEXT_ONLY__') {
                        decision.selectedRankId = null;
                        decision._rankTextOnly = true;
                    } else {
                        decision.selectedRankId = rankRadio.value ? parseInt(rankRadio.value, 10) : null;
                        decision._rankTextOnly = false;
                    }
                }
                var allText = card.querySelector('input[name="sea_textonly_' + index + '"]:checked');
                if (allText && allText.value === '__TEXT_ONLY__') {
                    decision.textOnly = true;
                    decision.selectedVesselId = null;
                    decision.selectedRankId = null;
                } else if (decision._vesselTextOnly && decision._rankTextOnly) {
                    decision.textOnly = true;
                } else if (decision._vesselTextOnly || decision._rankTextOnly) {
                    // Allow mixed: one FK selected, one text-only — treat as conscious choice
                    decision.textOnly = false;
                } else if (decision.selectedVesselId || decision.selectedRankId) {
                    // Applicant selected verified candidate(s) after a prior text-only choice
                    decision.textOnly = false;
                }
            }
            return decision;
        },

        keepRepeatingRecord: function (kind, index) {
            if (isNaN(index)) return;
            var pkg = this.state.suggestionPackage;
            if (!pkg) return;

            var decision = this.syncGateAndRefFromDom(kind, index);
            var record = (kind === 'sea')
                ? (pkg.SeaServiceRecords && pkg.SeaServiceRecords[index])
                : (pkg.Documents && pkg.Documents[index]);
            if (!record) return;

            if (kind === 'doc') {
                if (this.documentNeedsReviewGate(record) && !decision.confirmedConflict) {
                    alert('Please confirm that you reviewed the duplicate/conflict before keeping this document for now.');
                    return;
                }
                if (this.documentNeedsReferenceChoice(record, decision)) {
                    alert('Please select a verified document type or choose to keep the original text without a database match.');
                    return;
                }
            } else {
                if (this.seaServiceNeedsReviewGate(record) && !decision.confirmedConflict) {
                    alert('Please confirm that you reviewed the overlapping/near-duplicate voyage before keeping it for now.');
                    return;
                }
                // Re-check after sync — if still needs reference and not text-only / selections incomplete
                if (this.seaNeedsReferenceChoice(record, decision)) {
                    // Allow if vessel/rank each either resolved originally, selected, or text-only flagged
                    var vesselResolved = !!(record.VesselId || decision.selectedVesselId || decision._vesselTextOnly || decision.textOnly);
                    var rankResolved = !!(record.RankId || decision.selectedRankId || decision._rankTextOnly || decision.textOnly);
                    if (!vesselResolved || !rankResolved) {
                        alert('Please select verified vessel/rank matches or choose to keep the original text without a database match.');
                        return;
                    }
                }
            }

            decision.decision = 'accepted';
            decision.editing = false;
            this.persistRepeatingReview();
            this.renderRepeatingRecords(pkg);
        },

        discardRepeatingRecord: function (kind, index) {
            if (isNaN(index)) return;
            var decision = this.getRepeatingDecision(kind, index);
            decision.decision = 'discarded';
            decision.editing = false;
            this.persistRepeatingReview();
            this.renderRepeatingRecords(this.state.suggestionPackage);
        },

        restoreRepeatingRecord: function (kind, index) {
            if (isNaN(index)) return;
            var decision = this.getRepeatingDecision(kind, index);
            decision.decision = 'pending';
            decision.editing = false;
            decision.textOnly = false;
            decision.confirmedConflict = false;
            decision.selectedDocTypeId = null;
            decision.selectedVesselId = null;
            decision.selectedRankId = null;
            decision._vesselTextOnly = false;
            decision._rankTextOnly = false;
            this.persistRepeatingReview();
            this.renderRepeatingRecords(this.state.suggestionPackage);
        },

        toggleEditRepeatingRecord: function (kind, index, enable) {
            if (isNaN(index)) return;
            var decision = this.getRepeatingDecision(kind, index);
            decision.editing = !!enable;
            // Editing resets accepted back to pending so applicant must re-confirm Keep for now
            if (enable && decision.decision === 'accepted') {
                decision.decision = 'pending';
            }
            this.persistRepeatingReview();
            this.renderRepeatingRecords(this.state.suggestionPackage);
        },

        saveEditRepeatingRecord: function (kind, index) {
            if (isNaN(index)) return;
            var decision = this.getRepeatingDecision(kind, index);
            var card = document.querySelector('.ai-record-card[data-kind="' + kind + '"][data-index="' + index + '"]');
            if (!card) return;

            var edited = decision.edited || {};
            var inputs = card.querySelectorAll('input[data-edit]');
            for (var i = 0; i < inputs.length; i++) {
                var field = inputs[i].getAttribute('data-edit');
                edited[field] = inputs[i].value;
            }
            decision.edited = edited;
            decision.editing = false;
            decision.decision = 'pending';
            this.persistRepeatingReview();
            this.renderRepeatingRecords(this.state.suggestionPackage);
        },

        updateRepeatingStep3Summary: function () {
            var summary = document.getElementById('aiRepeatingStep3Summary');
            var list = document.getElementById('aiRepeatingStep3List');
            if (!summary || !list) return;

            var pkg = this.state.suggestionPackage;
            var docs = (pkg && pkg.Documents) ? pkg.Documents : [];
            var seas = (pkg && pkg.SeaServiceRecords) ? pkg.SeaServiceRecords : [];

            if (docs.length + seas.length === 0) {
                summary.style.display = 'none';
                list.innerHTML = '';
                return;
            }

            summary.style.display = '';
            var html = '';
            var keptDocs = 0, keptSeas = 0, pending = 0, discarded = 0;

            for (var i = 0; i < docs.length; i++) {
                var d = this.getRepeatingDecision('doc', i);
                var view = this.mergeDocumentView(docs[i], d);
                if (d.decision === 'accepted') {
                    keptDocs++;
                    html += '<div class="ai-repeating-step3-item"><strong>Document (kept for now):</strong> ' +
                        this.escapeHtml(view.DocumentTypeName || 'Document') +
                        (view.DocumentNumber ? ' · #' + this.escapeHtml(view.DocumentNumber) : '') +
                        '</div>';
                } else if (d.decision === 'discarded') {
                    discarded++;
                } else {
                    pending++;
                }
            }
            for (var j = 0; j < seas.length; j++) {
                var s = this.getRepeatingDecision('sea', j);
                var sv = this.mergeSeaServiceView(seas[j], s);
                if (s.decision === 'accepted') {
                    keptSeas++;
                    html += '<div class="ai-repeating-step3-item"><strong>Sea service (kept for now):</strong> ' +
                        this.escapeHtml(sv.VesselName || 'Vessel') + ' / ' + this.escapeHtml(sv.RankName || 'Rank') +
                        (this.formatDisplayDate(sv.DateFrom) ? ' · ' + this.escapeHtml(this.formatDisplayDate(sv.DateFrom)) : '') +
                        (this.formatDisplayDate(sv.DateTo) ? ' → ' + this.escapeHtml(this.formatDisplayDate(sv.DateTo)) : '') +
                        (sv.Port ? ' · Port: ' + this.escapeHtml(sv.Port) + ' (session only)' : '') +
                        '</div>';
                } else if (s.decision === 'discarded') {
                    discarded++;
                } else {
                    pending++;
                }
            }

            if (!html) {
                html = '<div class="ai-repeating-step3-muted">No document or sea service items marked &ldquo;Keep for now.&rdquo; ' +
                    pending + ' pending, ' + discarded + ' discarded. None of these will be submitted with your application.</div>';
            } else {
                html += '<div class="ai-repeating-step3-muted mt-1">Session review only — not attached, not submitted, not saved. ' +
                    (pending ? pending + ' still pending. ' : '') +
                    (discarded ? discarded + ' discarded. ' : '') +
                    '</div>';
            }
            list.innerHTML = html;
        },

        /**
         * Phase G.1: Serializes accepted repeating decisions + edited values into the
         * hfAiRepeatingDecisions hidden field for server-side Phase G persistence.
         * Only accepted records are included; pending and discarded are excluded.
         * The active job ID is synced to hfAiJobId for authoritative package retrieval.
         */
        syncRepeatingDecisionsToForm: function () {
            try {
                var hfDecisions = document.getElementById('hfAiRepeatingDecisions');
                var hfJobId = document.getElementById('hfAiJobId');

                if (hfJobId && this.state.activeJobId) {
                    hfJobId.value = this.state.activeJobId;
                }

                if (!hfDecisions) return;
                if (!this.state.suggestionPackage) {
                    hfDecisions.value = '';
                    return;
                }

                var pkg = this.state.suggestionPackage;
                var docs = pkg.Documents || [];
                var seas = pkg.SeaServiceRecords || [];

                var acceptedDocs = [];
                var acceptedSeas = [];

                for (var i = 0; i < docs.length; i++) {
                    var d = this.getRepeatingDecision('doc', i);
                    if (d.decision !== 'accepted') continue;
                    var view = this.mergeDocumentView(docs[i], d);
                    // Find the StagedFileId of a source document for this record
                    var srcFileId = '';
                    if (docs[i].Sources && docs[i].Sources.length > 0) {
                        srcFileId = docs[i].Sources[0].StagedFileId || '';
                    }
                    acceptedDocs.push({
                        Index: i,
                        DocumentTypeId: view.DocumentTypeId || null,
                        DocumentTypeName: view.DocumentTypeName || '',
                        DocumentNumber: view.DocumentNumber || '',
                        DateIssued: view.DateIssued || null,
                        DateExpiry: view.DateExpiry || null,
                        Grade: view.Grade || '',
                        HolderName: view.HolderName || '',
                        TextOnly: !!(d.textOnly),
                        StagedFileId: srcFileId
                    });
                }

                for (var j = 0; j < seas.length; j++) {
                    var s = this.getRepeatingDecision('sea', j);
                    if (s.decision !== 'accepted') continue;
                    var sv = this.mergeSeaServiceView(seas[j], s);
                    acceptedSeas.push({
                        Index: j,
                        VesselId: sv.VesselId || null,
                        VesselName: sv.VesselName || '',
                        RankId: sv.RankId || null,
                        RankName: sv.RankName || '',
                        DateFrom: sv.DateFrom || null,
                        DateTo: sv.DateTo || null,
                        Remarks: sv.Remarks || '',
                        TextOnly: !!(s.textOnly)
                    });
                }

                var payload = {
                    JobId: this.state.activeJobId || '',
                    AcceptedDocuments: acceptedDocs,
                    AcceptedSeaService: acceptedSeas
                };

                hfDecisions.value = JSON.stringify(payload);
            } catch (e) {
                // Safe fail — form submission must not be blocked by this
                if (window.console && console.error) {
                    console.error('Phase G: syncRepeatingDecisionsToForm error:', e);
                }
            }
        }
    };

    window.ApplicantAiAssist = ApplicantAiAssist;

    // Support ASP.NET AJAX ScriptManager partial postbacks if present
    if (typeof window.Sys !== 'undefined' && window.Sys.WebForms && window.Sys.WebForms.PageRequestManager) {
        window.Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            if (window.ApplicantAiAssist) {
                window.ApplicantAiAssist.restorePostbackState();
            }
        });
    }

    // Auto-init on DOMContentLoaded
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function () {
            ApplicantAiAssist.init();
        });
    } else {
        ApplicantAiAssist.init();
    }

})(window, document);
