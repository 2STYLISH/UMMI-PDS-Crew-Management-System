<%@ Page Language="VB" MasterPageFile="~/masterPage.Master" CodeBehind="TestAiConnectivity.aspx.vb"
    Inherits="TestAiConnectivity" Title="AI Connectivity Test" %>
<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="fade-in">

    <%-- ── Page Header ── --%>
    <div class="card mb-3">
        <div class="card-header-ummi">
            <i class="fa fa-flask me-2"></i>DeepInfra / Qwen3-VL Connectivity Test
            <span class="badge ms-2" style="background:#e0f2fe;color:#0369a1;font-size:11px;font-weight:600;">
                Phase B — Development Only
            </span>
        </div>
        <div class="card-body-ummi">
            <div class="alert alert-info" style="font-size:13px;">
                <i class="fa fa-circle-info me-2"></i>
                <strong>Purpose:</strong> This page verifies that the CrewMgmt backend can successfully
                communicate with DeepInfra and <code>Qwen/Qwen3-VL-30B-A3B-Instruct</code>
                using a synthetic, non-sensitive test document image.
                No applicant data is processed. No database records are created or modified.
            </div>
            <div class="alert alert-warning" style="font-size:13px;">
                <i class="fa fa-lock me-2"></i>
                <strong>Security:</strong> This page is restricted to Super Admin and Admin accounts.
                The API key is retrieved securely from the server environment variable
                <code>DEEPINFRA_API_KEY</code> and is never displayed, logged, or sent to the browser.
            </div>

            <%-- ── Test Image Preview ── --%>
            <div class="mb-3">
                <p style="font-size:13px;font-weight:600;color:#1a2744;margin-bottom:6px;">
                    <i class="fa fa-image me-1"></i>Synthetic Test Document (tests/fixtures/sample_test_doc.jpg)
                </p>
                <img src="<%=SampleImageBase64Src%>"
                     alt="Synthetic test document — not a real document"
                     style="max-width:520px;border:2px solid #e2e8f0;border-radius:8px;display:block;" />
                <p style="font-size:11px;color:#94a3b8;margin-top:4px;">
                    This is a synthetic document containing no real personal information.
                    It is used solely to confirm that Qwen3-VL can read text from an image.
                </p>
            </div>

            <%-- ── Run Test Button ── --%>
            <asp:Button ID="btnRunTest" runat="server"
                Text="Run Connectivity Test"
                CssClass="btn-ummi-primary"
                OnClick="RunConnectivityTest"
                OnClientClick="showLoading();" />
        </div>
    </div>

    <%-- ── Results Panel (hidden until test runs) ── --%>
    <asp:Panel ID="panelResults" runat="server" Visible="false">
        <div class="card mb-3">
            <div class="card-header-ummi">
                <i class="fa fa-chart-bar me-2"></i>Test Results
            </div>
            <div class="card-body-ummi">

                <%-- Overall Status --%>
                <asp:Label ID="lblStatusBanner" runat="server" Text="" />

                <%-- Diagnostic Metrics Table --%>
                <asp:Panel ID="panelMetrics" runat="server" Visible="false">
                    <table class="table table-sm mt-3" style="font-size:13px;max-width:600px;">
                        <tbody>
                            <tr>
                                <td class="fw-bold text-muted" style="width:200px;">HTTP Status</td>
                                <td><asp:Label ID="lblHttpStatus" runat="server" Text="—" /></td>
                            </tr>
                            <tr>
                                <td class="fw-bold text-muted">Model Reported by API</td>
                                <td><asp:Label ID="lblModelReported" runat="server" Text="—" /></td>
                            </tr>
                            <tr>
                                <td class="fw-bold text-muted">Response Latency</td>
                                <td><asp:Label ID="lblLatency" runat="server" Text="—" /></td>
                            </tr>
                            <tr>
                                <td class="fw-bold text-muted">Prompt Tokens</td>
                                <td><asp:Label ID="lblPromptTokens" runat="server" Text="—" /></td>
                            </tr>
                            <tr>
                                <td class="fw-bold text-muted">Completion Tokens</td>
                                <td><asp:Label ID="lblCompletionTokens" runat="server" Text="—" /></td>
                            </tr>
                            <tr>
                                <td class="fw-bold text-muted">Total Tokens</td>
                                <td><asp:Label ID="lblTotalTokens" runat="server" Text="—" /></td>
                            </tr>
                        </tbody>
                    </table>

                    <%-- AI Raw Output (safe for Phase B because test doc has no real PII) --%>
                    <div class="mt-3">
                        <p style="font-size:13px;font-weight:600;color:#1a2744;margin-bottom:4px;">
                            <i class="fa fa-robot me-1"></i>
                            Raw AI Response <small class="text-muted fw-normal">
                                (Phase B test only — production responses may contain PII and must not be displayed)
                            </small>
                        </p>
                        <pre id="preRawOutput" style="background:#f8fafc;border:1px solid #e2e8f0;
                             border-radius:6px;padding:14px;font-size:12px;white-space:pre-wrap;
                             word-break:break-word;max-height:400px;overflow-y:auto;"><asp:Literal ID="litRawContent" runat="server" /></pre>
                    </div>
                </asp:Panel>

                <%-- Error Detail (shown on failure) --%>
                <asp:Panel ID="panelError" runat="server" Visible="false">
                    <div class="alert alert-danger mt-3" style="font-size:13px;">
                        <i class="fa fa-circle-exclamation me-2"></i>
                        <strong>Error Detail:</strong><br />
                        <asp:Label ID="lblErrorDetail" runat="server" Text="" />
                    </div>
                </asp:Panel>

            </div>
        </div>
    </asp:Panel>

</div>
</asp:Content>
