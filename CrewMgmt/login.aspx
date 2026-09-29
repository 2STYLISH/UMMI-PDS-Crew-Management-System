<%@ Page Language="VB" CodeBehind="login.aspx.vb" Inherits="login" %>
    <!DOCTYPE html>
    <html lang="en">

    <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>UMMI Crew Management</title>
        <meta name="description" content="UMMI Personnel Data System — Crew Management Module login portal" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
            rel="stylesheet" />
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" />
        <link rel="stylesheet" href="css/site.css" />
        <style>
            * {
                box-sizing: border-box;
            }

            body {
                background: #F0F4F8;
                margin: 0;
            }

            .login-split {
                min-height: 100vh;
                display: flex;
            }

            /* Left panel */
            .login-panel-left {
                background: #1E3A5F;
                width: 420px;
                flex-shrink: 0;
                display: flex;
                flex-direction: column;
                justify-content: space-between;
                padding: 48px 44px;
                position: relative;
                overflow: hidden;
            }

            .login-panel-left::before {
                content: '';
                position: absolute;
                top: -80px;
                right: -80px;
                width: 320px;
                height: 320px;
                border-radius: 50%;
                background: rgba(37, 99, 235, 0.15);
            }

            .login-panel-left::after {
                content: '';
                position: absolute;
                bottom: -60px;
                left: -60px;
                width: 260px;
                height: 260px;
                border-radius: 50%;
                background: rgba(255, 255, 255, 0.04);
            }

            .lp-brand {
                position: relative;
                z-index: 1;
            }

            .lp-logo {
                width: 48px;
                height: 48px;
                background: #2563EB;
                border-radius: 10px;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 22px;
                color: #fff;
                margin-bottom: 20px;
            }

            .lp-brand-name {
                font-size: 22px;
                font-weight: 700;
                color: #fff;
                letter-spacing: -0.5px;
                line-height: 1.2;
            }

            .lp-brand-sub {
                font-size: 13px;
                color: rgba(255, 255, 255, 0.55);
                margin-top: 4px;
            }

            .lp-features {
                position: relative;
                z-index: 1;
                margin-top: 40px;
            }

            .lp-feature {
                display: flex;
                align-items: flex-start;
                gap: 12px;
                margin-bottom: 20px;
            }

            .lp-feature-icon {
                width: 32px;
                height: 32px;
                background: rgba(255, 255, 255, 0.08);
                border-radius: 7px;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 13px;
                color: rgba(255, 255, 255, 0.7);
                flex-shrink: 0;
                margin-top: 1px;
            }

            .lp-feature-text strong {
                display: block;
                font-size: 13px;
                font-weight: 600;
                color: rgba(255, 255, 255, 0.9);
            }

            .lp-feature-text span {
                font-size: 12px;
                color: rgba(255, 255, 255, 0.45);
            }

            .lp-footer {
                position: relative;
                z-index: 1;
                font-size: 11px;
                color: rgba(255, 255, 255, 0.3);
            }

            /* Right panel */
            .login-panel-right {
                flex: 1;
                display: flex;
                align-items: center;
                justify-content: center;
                padding: 40px 24px;
                background: #F0F4F8;
            }

            .login-form-box {
                width: 100%;
                max-width: 400px;
            }

            .login-form-header {
                margin-bottom: 28px;
            }

            .login-form-header h2 {
                font-size: 22px;
                font-weight: 700;
                color: #111827;
                letter-spacing: -0.4px;
                margin-bottom: 4px;
            }

            .login-form-header p {
                font-size: 13px;
                color: #64748B;
            }

            .login-form-card {
                background: #fff;
                border: 1px solid #E2E8F0;
                border-radius: 12px;
                box-shadow: 0 4px 16px rgba(0, 0, 0, 0.06);
                padding: 28px;
            }

            .login-form-group {
                margin-bottom: 16px;
            }

            .login-form-label {
                display: block;
                font-size: 12px;
                font-weight: 600;
                color: #64748B;
                text-transform: uppercase;
                letter-spacing: 0.4px;
                margin-bottom: 5px;
            }

            .login-input-wrap {
                position: relative;
            }

            .login-input-icon {
                position: absolute;
                left: 10px;
                top: 50%;
                transform: translateY(-50%);
                color: #94A3B8;
                font-size: 13px;
                pointer-events: none;
            }

            .login-input {
                width: 100%;
                height: 40px;
                padding: 0 36px;
                border: 1px solid #E2E8F0;
                border-radius: 7px;
                font-size: 13px;
                font-family: 'Inter', sans-serif;
                color: #111827;
                background: #fff;
                transition: border-color 0.15s, box-shadow 0.15s;
            }

            .login-input:focus {
                outline: none;
                border-color: #2563EB;
                box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
            }

            .login-toggle-pw {
                position: absolute;
                right: 10px;
                top: 50%;
                transform: translateY(-50%);
                background: none;
                border: none;
                color: #94A3B8;
                font-size: 13px;
                cursor: pointer;
                padding: 0 4px;
                transition: color 0.15s;
            }

            .login-toggle-pw:hover {
                color: #64748B;
            }

            .login-btn {
                width: 100%;
                height: 42px;
                background: #2563EB;
                color: #fff;
                border: none;
                border-radius: 7px;
                font-size: 14px;
                font-weight: 600;
                font-family: 'Inter', sans-serif;
                cursor: pointer;
                margin-top: 4px;
                transition: background 0.15s, box-shadow 0.15s;
                display: flex;
                align-items: center;
                justify-content: center;
                gap: 8px;
            }

            .login-btn:hover {
                background: #1d4ed8;
                box-shadow: 0 4px 12px rgba(37, 99, 235, 0.3);
            }

            .login-btn:active {
                background: #1e40af;
            }

            .login-notify {
                padding: 10px 12px;
                border-radius: 7px;
                font-size: 12px;
                font-weight: 500;
                margin-bottom: 14px;
                display: flex;
                align-items: center;
                gap: 8px;
            }

            .login-notify-error {
                background: #FEF2F2;
                color: #DC2626;
                border: 1px solid #FECACA;
            }

            @media (max-width: 768px) {
                .login-panel-left {
                    display: none;
                }

                .login-panel-right {
                    background: #F0F4F8;
                }
            }
        </style>
    </head>

    <body>
        <form id="frmLogin" runat="server" method="post">
            <div class="login-split">

                <!-- ── Left Branding Panel ── -->
                <div class="login-panel-left">
                    <div class="lp-brand">
                        <div class="lp-logo"><i class="fa fa-anchor"></i></div>
                        <div class="lp-brand-name">UMMI Crew<br />Management</div>
                        <div class="lp-brand-sub">Personnel Data System · Manning Information</div>
                    </div>

                    <div class="lp-features">
                        <div class="lp-feature">
                            <div class="lp-feature-icon"><i class="fa fa-users"></i></div>
                            <div class="lp-feature-text">
                                <strong>Crew Records</strong>
                                <span>Centralized personnel file management</span>
                            </div>
                        </div>
                        <div class="lp-feature">
                            <div class="lp-feature-icon"><i class="fa fa-file-contract"></i></div>
                            <div class="lp-feature-text">
                                <strong>Contract Tracing</strong>
                                <span>Full deployment history and tracking</span>
                            </div>
                        </div>
                        <div class="lp-feature">
                            <div class="lp-feature-icon"><i class="fa fa-award"></i></div>
                            <div class="lp-feature-text">
                                <strong>Certification Monitoring</strong>
                                <span>Track validity and compliance deadlines</span>
                            </div>
                        </div>
                        <div class="lp-feature">
                            <div class="lp-feature-icon"><i class="fa fa-shield-halved"></i></div>
                            <div class="lp-feature-text">
                                <strong>Role-Based Access</strong>
                                <span>Secure, audited administrative controls</span>
                            </div>
                        </div>
                    </div>

                    <div class="lp-footer">
                        &copy; <%= DateTime.Now.Year %> UMMI Manning &mdash; All rights reserved
                    </div>
                </div>

                <!-- ── Right Login Panel ── -->
                <div class="login-panel-right">
                    <div class="login-form-box">

                        <div class="login-form-header">
                            <h2>Welcome back</h2>
                            <p>Sign in to your account to continue</p>
                        </div>

                        <div class="login-form-card">
                            <!-- Error notification -->
                            <asp:Label ID="lblNotify" runat="server" CssClass="login-notify login-notify-error" Visible="false" />

                            <!-- Username -->
                            <div class="login-form-group">
                                <label class="login-form-label" for="txtUsername">Username</label>
                                <div class="login-input-wrap">
                                    <i class="fa fa-user login-input-icon"></i>
                                    <asp:TextBox ID="txtUsername" runat="server" CssClass="login-input"
                                        placeholder="Enter your username" autocomplete="username"
                                        ClientIDMode="Static" />
                                </div>
                            </div>

                            <!-- Password -->
                            <div class="login-form-group">
                                <label class="login-form-label" for="txtPassword">Password</label>
                                <div class="login-input-wrap">
                                    <i class="fa fa-lock login-input-icon"></i>
                                    <asp:TextBox ID="txtPassword" runat="server" TextMode="Password"
                                        CssClass="login-input" placeholder="Enter your password"
                                        autocomplete="current-password" ClientIDMode="Static" />
                                    <button type="button" class="login-toggle-pw"
                                        onclick="var p=document.getElementById('txtPassword');p.type=p.type==='password'?'text':'password';this.querySelector('i').className=p.type==='password'?'fa fa-eye':'fa fa-eye-slash'">
                                        <i class="fa fa-eye"></i>
                                    </button>
                                </div>
                            </div>

                            <!-- Submit -->
                            <asp:Button ID="btnLogin" runat="server" Text="Sign In" CssClass="login-btn"
                                OnClick="btnLogin_Click" />
                        </div>

                        <div style="text-align:center; margin-top:20px; font-size:11px; color:#94A3B8;">
                            UMMI Manning &copy; <%= DateTime.Now.Year %> &mdash; Crew Management System
                        </div>
                    </div>
                </div>

            </div>
        </form>
    </body>

    </html>