# UMMI AI Anti-CSRF Token Lifecycle & Localhost Port Isolation Guide

## 1. Anti-CSRF Token Architecture & Lifecycle

The UMMI AI-assisted applicant autofill module enforces anti-CSRF protection across all state-changing endpoints (`upload`, `cancel`, `cleanup`, `withdraw_consent`) in `ApplicantExtractionHandler.ashx`.

### Lifecycle Workflow
1. **Link Authentication (`login.aspx.vb`)**:
   - When an applicant accesses their secure link (`login.aspx?e=...`), the server validates that the link is active and not expired in MySQL.
   - If the applicant already has an active authorized session for that exact same link ID, the existing `Session("ApplicantCsrfToken")` is preserved.
   - If it is a new session, an empty token, or a link/identity switch, a fresh cryptographically strong GUID (`Guid.NewGuid().ToString("N")`) is generated.
2. **Page Rendering (`SelfEncode.aspx` / `SelfEncode.aspx.vb`)**:
   - `hfApplicantCsrfToken.Value` and `window.AiCsrfToken` are populated from `Session("ApplicantCsrfToken")`.
3. **Client AJAX Requests (`applicant-ai-assist.js`)**:
   - Requests transmit the token both in the `X-CSRF-Token` HTTP header and the `csrf_token` form-data parameter.
   - If the server returns HTTP 403 specifically citing anti-CSRF mismatch (e.g. following an AppDomain recycle or multi-tab re-entry), `applicant-ai-assist.js` automatically requests a fresh token from the authorized `ApplicantExtractionHandler.ashx?action=csrf` endpoint and transparently retries the upload at most once.
   - Non-CSRF 403 errors (expired links, revoked links, unauthorized users) are never retried.
4. **Server Rehydration (`ApplicantExtractionHandler.ashx.vb`)**:
   - When ASP.NET in-proc session state is lost but the `.ASPXAUTH` FormsAuthentication ticket is valid, `ValidateApplicantSession` recovers the session and automatically re-initializes `Session("ApplicantCsrfToken")`.
   - `action=csrf` verifies that the applicant link is currently active and authorized, generating a token if missing and never returning an empty string.

---

## 2. Localhost Cross-Port Cookie Collision (Ports 54776 vs 54778)

### Root Cause
Under RFC 6265 Section 8.5, web browsers (including Google Chrome) scope cookies by **hostname/domain** (`localhost`), **ignoring port numbers**:
- An `ASP.NET_SessionId` or `.ASPXAUTH` cookie issued by `http://localhost:54778` (e.g. integration worktree) is also transmitted to `http://localhost:54776` (original worktree).
- Because separate IIS Express instances possess isolated in-process memory tables and distinct runtime-generated MachineKeys, cookies issued by one port are rejected by the other port.

### Operational Isolation Best Practices (Development Environment)
Production cookie security settings should remain intact. For local development with multiple concurrent IIS Express instances:
1. **Use Distinct Hostnames via `hosts` file**:
   Map local aliases in `C:\Windows\System32\drivers\etc\hosts`:
   ```
   127.0.0.1  dev.ummi.local
   127.0.0.1  integration.ummi.local
   ```
   Cookies will then be strictly isolated by origin hostname.
2. **Use Separate Browser Profiles or Incognito**:
   - Use a dedicated Chrome profile or Incognito window for each port to avoid shared cookie jars.
3. **Clear Site Data when Switching Ports**:
   - In Chrome DevTools (`F12`) -> **Application** -> **Storage** -> Click **Clear site data** when switching between port 54776 and port 54778.
