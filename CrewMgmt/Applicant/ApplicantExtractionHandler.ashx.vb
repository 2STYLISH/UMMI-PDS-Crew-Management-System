Imports System
Imports System.Collections.Generic
Imports System.IO
Imports System.Web
Imports System.Web.SessionState
Imports System.Web.Script.Serialization
Imports MySql.Data.MySqlClient
Imports PdsMappingModels

''' <summary>
''' Phase F.1: Async HTTP handler for applicant document extraction.
''' Implements IReadOnlySessionState to avoid holding exclusive ASP.NET session locks,
''' ensuring concurrent polling and uninterrupted applicant form interactions.
''' Enforces link authorization, anti-CSRF, server-enforced consent, and provisional limits.
''' </summary>
Public Class ApplicantExtractionHandler
    Implements IHttpHandler, IReadOnlySessionState

    Private Shared ReadOnly _serializer As New JavaScriptSerializer()

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        ' Standard JSON and security headers
        context.Response.ContentType = "application/json"
        context.Response.AddHeader("X-Content-Type-Options", "nosniff")
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)
        context.Response.Cache.SetNoStore()

        Dim action As String = context.Request.QueryString("action")
        If String.IsNullOrEmpty(action) Then
            action = context.Request.Form("action")
        End If
        If String.IsNullOrEmpty(action) Then
            If context.Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase) Then
                action = "upload"
            Else
                action = "status"
            End If
        End If

        Try
            Select Case action.ToLowerInvariant()
                Case "csrf"
                    HandleGetCsrfToken(context)

                Case "upload"
                    HandleUpload(context)

                Case "status"
                    HandleStatus(context)

                Case "cancel"
                    HandleCancel(context)

                Case "result"
                    HandleResult(context)

                Case "cleanup"
                    ' F.3: Voluntary post-submission staged-file cleanup
                    HandleCleanup(context)

                Case "withdraw_consent"
                    ' F.3 Supplemental: Explicit applicant AI-consent withdrawal
                    HandleWithdrawConsent(context)

                Case Else
                    WriteJsonResponse(context, 400, False, "Unknown action requested: " & action)
            End Select

        Catch ex As Exception
            ' Safe error response: do not leak raw server exception details or paths to client
            WriteJsonResponse(context, 500, False, "A server error occurred while processing the request.")
        End Try
    End Sub

    ''' <summary>
    ''' Returns the active anti-CSRF token for the applicant session.
    ''' </summary>
    Private Sub HandleGetCsrfToken(context As HttpContext)
        Dim linkId As String = Nothing
        Dim authErr As String = Nothing
        If Not ValidateApplicantSession(context, linkId, authErr) Then
            WriteJsonResponse(context, 401, False, authErr)
            Return
        End If

        Dim csrfToken As String = If(context.Session("ApplicantCsrfToken") IsNot Nothing,
                                     context.Session("ApplicantCsrfToken").ToString(), "")
        If String.IsNullOrEmpty(csrfToken) Then
            csrfToken = Guid.NewGuid().ToString("N")
            context.Session("ApplicantCsrfToken") = csrfToken
        End If

        Dim result As Object = New With {
            .success = True,
            .csrfToken = csrfToken
        }
        context.Response.StatusCode = 200
        context.Response.Write(_serializer.Serialize(result))
    End Sub

    ''' <summary>
    ''' Handles file upload, validations, staging, and job creation.
    ''' In Phase F.1, live extraction calling DeepInfra is not yet activated.
    ''' </summary>
    Private Sub HandleUpload(context As HttpContext)
        If Not context.Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase) Then
            WriteJsonResponse(context, 405, False, "Upload requires HTTP POST.")
            Return
        End If

        ' 1. Session & Link Authorization
        Dim linkId As String = Nothing
        Dim authErr As String = Nothing
        If Not ValidateApplicantSession(context, linkId, authErr) Then
            WriteJsonResponse(context, 403, False, authErr)
            Return
        End If

        ' 2. Anti-CSRF Protection
        If Not ValidateCsrfToken(context) Then
            WriteJsonResponse(context, 403, False, "Invalid or missing anti-CSRF token.")
            Return
        End If

        ' 3. Server-Enforced Consent Gate (RA 10173 Compliance)
        If Not ValidateApplicantConsent(context) Then
            WriteJsonResponse(context, 400, False, "Explicit applicant consent is required before processing documents (RA 10173).")
            Return
        End If

        ' 4. Atomic Concurrency Guard (Prevent duplicate in-flight jobs or simultaneous uploads for the same session)
        Dim sessionId As String = context.Session.SessionID
        Dim uploadJob As ApplicantExtractionJobManager.ApplicantExtractionJobState = Nothing
        If Not ApplicantExtractionJobManager.TryAcquireSessionUploadSlot(sessionId, linkId, uploadJob) Then
            WriteJsonResponse(context, 409, False, "An extraction job is already in progress for this session.")
            Return
        End If

        Dim stagedDocs As New List(Of ApplicantStorageService.StagedDocument)()
        Try
            ' 5. Validate File Count
            Dim files As HttpFileCollection = context.Request.Files
            If files Is Nothing OrElse files.Count = 0 Then
                ApplicantExtractionJobManager.ReleaseSessionUpload(sessionId, uploadJob.JobId)
                WriteJsonResponse(context, 400, False, "No files uploaded.")
                Return
            End If

            Dim maxFiles As Integer = FileValidationHelper.GetMaxFileCount()
            If files.Count > maxFiles Then
                ApplicantExtractionJobManager.ReleaseSessionUpload(sessionId, uploadJob.JobId)
                WriteJsonResponse(context, 400, False, String.Format("Exceeded maximum allowed files per session ({0}).", maxFiles))
                Return
            End If

            ' 6. Validate Session Total Upload Size
            Dim maxSessionBytes As Long = FileValidationHelper.GetMaxSessionSizeBytes()
            Dim totalBytes As Long = 0
            For i As Integer = 0 To files.Count - 1
                Dim file As HttpPostedFile = files(i)
                If file IsNot Nothing Then
                    totalBytes += file.ContentLength
                End If
            Next

            If totalBytes > maxSessionBytes Then
                ApplicantExtractionJobManager.ReleaseSessionUpload(sessionId, uploadJob.JobId)
                WriteJsonResponse(context, 400, False, String.Format("Total upload size ({0:N1} MB) exceeds maximum allowed session limit ({1:N1} MB).",
                                                                     totalBytes / (1024.0 * 1024.0), maxSessionBytes / (1024.0 * 1024.0)))
                Return
            End If

            ' 7. Validate and Stage Each File
            Dim maxFileBytes As Long = FileValidationHelper.GetMaxFileSizeBytes()

            For i As Integer = 0 To files.Count - 1
                Dim file As HttpPostedFile = files(i)
                If file Is Nothing OrElse file.ContentLength = 0 Then Continue For

                If file.ContentLength > maxFileBytes Then
                    CleanupStagedDocs(stagedDocs)
                    ApplicantExtractionJobManager.ReleaseSessionUpload(sessionId, uploadJob.JobId)
                    WriteJsonResponse(context, 400, False, String.Format("File '{0}' exceeds the maximum allowed size of 5 MB.", Path.GetFileName(file.FileName)))
                    Return
                End If

                ' Read bytes
                Dim fileBytes(file.ContentLength - 1) As Byte
                file.InputStream.Seek(0, SeekOrigin.Begin)
                file.InputStream.Read(fileBytes, 0, file.ContentLength)

                ' Category hint if supplied by form
                Dim catKey As String = "category_" & i
                Dim category As String = context.Request.Form(catKey)
                If String.IsNullOrWhiteSpace(category) Then category = "Other"

                ' Stage document using existing Phase C service
                Dim stageRes As ApplicantStorageService.StageResult =
                    ApplicantStorageService.StageDocument(fileBytes, file.FileName, category, sessionId)

                If Not stageRes.IsSuccess Then
                    CleanupStagedDocs(stagedDocs)
                    ApplicantExtractionJobManager.ReleaseSessionUpload(sessionId, uploadJob.JobId)
                    WriteJsonResponse(context, 400, False, "File validation failed: " & stageRes.ErrorMessage)
                    Return
                End If

                stagedDocs.Add(stageRes.StagedDoc)
            Next

            If stagedDocs.Count = 0 Then
                ApplicantExtractionJobManager.ReleaseSessionUpload(sessionId, uploadJob.JobId)
                WriteJsonResponse(context, 400, False, "No valid files could be processed.")
                Return
            End If

            ' 8. Finalize Job in HttpRuntime.Cache
            ApplicantExtractionJobManager.FinalizeStagedJob(uploadJob.JobId, stagedDocs)

            ' 9. Phase F.2: Start managed background extraction pipeline
            ApplicantExtractionJobManager.StartExtraction(uploadJob.JobId, sessionId)

            ' F.3: Rate-limited lazy trigger for abandoned staging cleanup (at most once per 24h)
            GlobalApplication.TryRunScheduledStagingCleanup()

            Dim responseObj As Object = New With {
                .success = True,
                .jobId = uploadJob.JobId,
                .status = "Queued",
                .fileCount = stagedDocs.Count,
                .message = "Documents staged successfully. Extraction pipeline queued."
            }

            context.Response.StatusCode = 200
            context.Response.Write(_serializer.Serialize(responseObj))

        Catch ex As Exception
            CleanupStagedDocs(stagedDocs)
            ApplicantExtractionJobManager.ReleaseSessionUpload(sessionId, uploadJob.JobId)
            WriteJsonResponse(context, 500, False, "A server error occurred while processing the upload.")
        End Try
    End Sub

    ''' <summary>
    ''' Handles job status polling without holding an exclusive session lock.
    ''' </summary>
    Private Sub HandleStatus(context As HttpContext)
        Dim linkId As String = Nothing
        Dim authErr As String = Nothing
        If Not ValidateApplicantSession(context, linkId, authErr) Then
            WriteJsonResponse(context, 403, False, authErr)
            Return
        End If

        Dim jobId As String = context.Request.QueryString("jobId")
        If String.IsNullOrWhiteSpace(jobId) Then
            jobId = context.Request.Form("jobId")
        End If

        If String.IsNullOrWhiteSpace(jobId) Then
            WriteJsonResponse(context, 400, False, "Job ID is required.")
            Return
        End If

        ' Retrieve job verifying requesting session ID matches (Anti-Cross-Session)
        Dim job As ApplicantExtractionJobManager.ApplicantExtractionJobState =
            ApplicantExtractionJobManager.GetJob(jobId, context.Session.SessionID)

        If job Is Nothing OrElse (Not String.IsNullOrEmpty(job.ApplicantLinkId) AndAlso Not String.Equals(job.ApplicantLinkId, linkId, StringComparison.OrdinalIgnoreCase)) Then
            WriteJsonResponse(context, 404, False, "Job not found or access denied.")
            Return
        End If

        Dim result As Object = New With {
            .success = True,
            .jobId = job.JobId,
            .status = job.Status,
            .progress = job.ProgressPercent,
            .message = job.StageMessage,
            .totalFiles = job.TotalFiles,
            .processedFiles = job.ProcessedFiles,
            .hasSuggestions = (job.SuggestionPackage IsNot Nothing),
            .error = job.ErrorMessage
        }

        context.Response.StatusCode = 200
        context.Response.Write(_serializer.Serialize(result))
    End Sub

    ''' <summary>
    ''' Handles cancelling a queued or active extraction job.
    ''' </summary>
    Private Sub HandleCancel(context As HttpContext)
        If Not context.Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase) Then
            WriteJsonResponse(context, 405, False, "Cancel requires HTTP POST.")
            Return
        End If

        Dim linkId As String = Nothing
        Dim authErr As String = Nothing
        If Not ValidateApplicantSession(context, linkId, authErr) Then
            WriteJsonResponse(context, 403, False, authErr)
            Return
        End If

        If Not ValidateCsrfToken(context) Then
            WriteJsonResponse(context, 403, False, "Invalid anti-CSRF token.")
            Return
        End If

        Dim jobId As String = context.Request.Form("jobId")
        If String.IsNullOrWhiteSpace(jobId) Then
            jobId = context.Request.QueryString("jobId")
        End If

        Dim jobCheck As ApplicantExtractionJobManager.ApplicantExtractionJobState =
            ApplicantExtractionJobManager.GetJob(jobId, context.Session.SessionID)

        If jobCheck Is Nothing OrElse (Not String.IsNullOrEmpty(jobCheck.ApplicantLinkId) AndAlso Not String.Equals(jobCheck.ApplicantLinkId, linkId, StringComparison.OrdinalIgnoreCase)) Then
            WriteJsonResponse(context, 404, False, "Job not found or access denied.")
            Return
        End If

        Dim cancelled As Boolean = ApplicantExtractionJobManager.CancelJob(jobId, context.Session.SessionID)
        If cancelled Then
            WriteJsonResponse(context, 200, True, "Job cancelled successfully.")
        Else
            WriteJsonResponse(context, 400, False, "Unable to cancel job (either not found, not active, or access denied).")
        End If
    End Sub

    ''' <summary>
    ''' Handles retrieving extraction results and PDS suggestions.
    ''' Enforces session, link, and cross-session isolation.
    ''' </summary>
    Private Sub HandleResult(context As HttpContext)
        Dim linkId As String = Nothing
        Dim authErr As String = Nothing
        If Not ValidateApplicantSession(context, linkId, authErr) Then
            WriteJsonResponse(context, 403, False, authErr)
            Return
        End If

        Dim jobId As String = context.Request.QueryString("jobId")
        If String.IsNullOrWhiteSpace(jobId) Then
            jobId = context.Request.Form("jobId")
        End If

        If String.IsNullOrWhiteSpace(jobId) Then
            WriteJsonResponse(context, 400, False, "Job ID is required.")
            Return
        End If

        ' Retrieve job verifying requesting session ID matches (Anti-Cross-Session)
        Dim job As ApplicantExtractionJobManager.ApplicantExtractionJobState =
            ApplicantExtractionJobManager.GetJob(jobId, context.Session.SessionID)

        If job Is Nothing OrElse (Not String.IsNullOrEmpty(job.ApplicantLinkId) AndAlso Not String.Equals(job.ApplicantLinkId, linkId, StringComparison.OrdinalIgnoreCase)) Then
            WriteJsonResponse(context, 404, False, "Job not found or access denied.")
            Return
        End If

        If Not String.Equals(job.Status, "Completed", StringComparison.OrdinalIgnoreCase) Then
            WriteJsonResponse(context, 400, False, "Job extraction is not completed yet.")
            Return
        End If

        ' Phase F.5: Scrub original filenames and disk paths before client serialization.
        ' CategoryKey + PageNumber source attribution is preserved for applicant review badges.
        ScrubSuggestionPackageForClient(job.SuggestionPackage)

        Dim responseObj As Object = New With {
            .success = True,
            .jobId = job.JobId,
            .status = job.Status,
            .suggestions = job.SuggestionPackage
        }

        context.Response.StatusCode = 200
        context.Response.Write(_serializer.Serialize(responseObj))
    End Sub

    ''' <summary>
    ''' Phase F.5 privacy harden: removes OriginalFileName and any path-like values from
    ''' SourceAttribution objects before JSON is returned to the browser.
    ''' Does not alter CategoryKey, PageNumber, or extracted suggestion values.
    ''' </summary>
    Friend Shared Sub ScrubSuggestionPackageForClient(pkg As PdsExtractionSuggestionPackage)
        If pkg Is Nothing Then Return

        If pkg.PersonalDetails IsNot Nothing Then
            ScrubFieldSources(pkg.PersonalDetails.LastName)
            ScrubFieldSources(pkg.PersonalDetails.FirstName)
            ScrubFieldSources(pkg.PersonalDetails.MiddleName)
            ScrubFieldSources(pkg.PersonalDetails.Suffix)
            ScrubFieldSources(pkg.PersonalDetails.DateOfBirth)
            ScrubFieldSources(pkg.PersonalDetails.PlaceOfBirth)
            ScrubFieldSources(pkg.PersonalDetails.Gender)
            ScrubFieldSources(pkg.PersonalDetails.CivilStatus)
            ScrubFieldSources(pkg.PersonalDetails.Religion)
            ScrubFieldSources(pkg.PersonalDetails.Nationality)
            ScrubFieldSources(pkg.PersonalDetails.Height)
            ScrubFieldSources(pkg.PersonalDetails.Weight)
            ScrubFieldSources(pkg.PersonalDetails.AppliedRank)
            ScrubFieldSources(pkg.PersonalDetails.ContactNumber)
            ScrubFieldSources(pkg.PersonalDetails.EmailAddress)
            ScrubFieldSources(pkg.PersonalDetails.Address)
            ScrubFieldSources(pkg.PersonalDetails.Province)
            ScrubFieldSources(pkg.PersonalDetails.City)
            ScrubFieldSources(pkg.PersonalDetails.SchoolName)
            ScrubFieldSources(pkg.PersonalDetails.Course)
        End If

        If pkg.Documents IsNot Nothing Then
            For Each doc As PdsDocumentSuggestion In pkg.Documents
                If doc Is Nothing Then Continue For
                ScrubSourceList(doc.Sources)
            Next
        End If

        If pkg.SeaServiceRecords IsNot Nothing Then
            For Each ss As PdsSeaServiceSuggestion In pkg.SeaServiceRecords
                If ss Is Nothing Then Continue For
                ScrubSourceList(ss.Sources)
            Next
        End If
    End Sub

    Private Shared Sub ScrubFieldSources(Of T)(field As PdsFieldSuggestion(Of T))
        If field Is Nothing Then Return
        ScrubSourceList(field.Sources)
        If field.ConflictingAlternatives IsNot Nothing Then
            For Each alt As ConflictingAlternative(Of T) In field.ConflictingAlternatives
                If alt IsNot Nothing AndAlso alt.Source IsNot Nothing Then
                    ScrubSingleSource(alt.Source)
                End If
            Next
        End If
    End Sub

    Private Shared Sub ScrubSourceList(sources As List(Of SourceAttribution))
        If sources Is Nothing Then Return
        For Each src As SourceAttribution In sources
            ScrubSingleSource(src)
        Next
    End Sub

    Private Shared Sub ScrubSingleSource(src As SourceAttribution)
        If src Is Nothing Then Return
        ' Remove original client filenames; CategoryKey + PageNumber remain for source badges.
        src.OriginalFileName = String.Empty
    End Sub

    ''' <summary>
    ''' F.3: Handles voluntary post-submission cleanup of staged files.
    ''' Called by the applicant client after SubmitApplication completes successfully,
    ''' or when the applicant explicitly cancels the upload process.
    ''' Requires valid session, active link, and valid CSRF token.
    ''' </summary>
    Private Sub HandleCleanup(context As HttpContext)
        If Not context.Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase) Then
            WriteJsonResponse(context, 405, False, "Cleanup requires HTTP POST.")
            Return
        End If

        Dim linkId As String = Nothing
        Dim authErr As String = Nothing
        If Not ValidateApplicantSession(context, linkId, authErr) Then
            WriteJsonResponse(context, 403, False, authErr)
            Return
        End If

        If Not ValidateCsrfToken(context) Then
            WriteJsonResponse(context, 403, False, "Invalid anti-CSRF token.")
            Return
        End If

        ' Safe-fail: purge staged files for the current session
        Dim sessionId As String = context.Session.SessionID
        ApplicantExtractionJobManager.ClearStagedFilesForSession(sessionId)

        WriteJsonResponse(context, 200, True, "Staged documents cleared successfully.")
    End Sub

    ''' <summary>
    ''' F.3 Supplemental: Explicitly withdraws applicant AI consent.
    ''' Halts active processing, wipes suggestion packages from memory,
    ''' purges local staged files, and invalidates session extraction job cache.
    ''' Does NOT clear manually entered form fields.
    ''' </summary>
    Private Sub HandleWithdrawConsent(context As HttpContext)
        If Not context.Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase) Then
            WriteJsonResponse(context, 405, False, "Withdrawal requires HTTP POST.")
            Return
        End If

        Dim linkId As String = Nothing
        Dim authErr As String = Nothing
        If Not ValidateApplicantSession(context, linkId, authErr) Then
            WriteJsonResponse(context, 403, False, authErr)
            Return
        End If

        If Not ValidateCsrfToken(context) Then
            WriteJsonResponse(context, 403, False, "Invalid anti-CSRF token.")
            Return
        End If

        Dim sessionId As String = context.Session.SessionID
        ApplicantExtractionJobManager.WithdrawConsentForSession(sessionId)

        WriteJsonResponse(context, 200, True, "AI extraction consent withdrawn and staged documents removed.")
    End Sub

    ' ── Security & Authorization Helpers ─────────────────────────────────────

    ''' <summary>
    ''' Validates that the current request has an authenticated applicant session with an active link,
    ''' or has internal staff administrative access.
    ''' </summary>
    Private Function ValidateApplicantSession(context As HttpContext, ByRef linkId As String, ByRef errResponse As String) As Boolean
        If context.Session Is Nothing Then
            errResponse = "No active session found. Please re-open your applicant link."
            Return False
        End If

        Dim userType As String = If(context.Session("UserType") IsNot Nothing, context.Session("UserType").ToString(), "")
        linkId = If(context.Session("ApplicantLinkID") IsNot Nothing, context.Session("ApplicantLinkID").ToString(), "")

        ' Fallback 1: Extract from Session("UserID") if format is LNK-<id>
        If String.IsNullOrWhiteSpace(linkId) Then
            Dim uid As String = If(context.Session("UserID") IsNot Nothing, context.Session("UserID").ToString(), "")
            If uid.StartsWith("LNK-", StringComparison.OrdinalIgnoreCase) Then
                Dim candidateId As String = uid.Substring(4)
                Dim testInt As Integer
                If Integer.TryParse(candidateId, testInt) AndAlso testInt > 0 Then
                    linkId = candidateId
                    context.Session("ApplicantLinkID") = linkId
                    If String.IsNullOrEmpty(userType) Then
                        userType = "APPLICANT"
                        context.Session("UserType") = "APPLICANT"
                    End If
                End If
            End If
        End If

        ' Fallback 2: Extract from FormsAuthentication ticket (context.User.Identity.Name)
        If String.IsNullOrWhiteSpace(linkId) Then
            If context.User IsNot Nothing AndAlso context.User.Identity IsNot Nothing AndAlso
               context.User.Identity.IsAuthenticated AndAlso
               context.User.Identity.Name.StartsWith("LNK-", StringComparison.OrdinalIgnoreCase) Then
                Dim candidateId As String = context.User.Identity.Name.Substring(4)
                Dim testInt As Integer
                If Integer.TryParse(candidateId, testInt) AndAlso testInt > 0 Then
                    linkId = candidateId
                    context.Session("ApplicantLinkID") = linkId
                    If String.IsNullOrEmpty(userType) Then
                        userType = "APPLICANT"
                        context.Session("UserType") = "APPLICANT"
                    End If
                    If context.Session("UserID") Is Nothing Then
                        context.Session("UserID") = context.User.Identity.Name
                    End If
                End If
            End If
        End If

        If String.Equals(userType, "APPLICANT", StringComparison.OrdinalIgnoreCase) Then
            ' Fallback 3: Strict ownership check for credential logins (tbl_users.type = 'APPLICANT')
            ' Fail securely if ownership cannot be strictly proven by matching user's registered email
            If String.IsNullOrWhiteSpace(linkId) Then
                Dim userIdStr As String = If(context.Session("UserID") IsNot Nothing, context.Session("UserID").ToString(), "")
                Dim uid As Integer
                If Integer.TryParse(userIdStr, uid) AndAlso uid > 0 Then
                    Dim userEmail As String = Nothing
                    Using cn As New MySqlConnection(DbHelper.ConnStr)
                        cn.Open()
                        Using cmdUser As New MySqlCommand("SELECT email_address FROM tbl_users WHERE id=@uid AND type='APPLICANT' AND disable_user=0 LIMIT 1", cn)
                            cmdUser.Parameters.AddWithValue("@uid", uid)
                            Dim objEmail As Object = cmdUser.ExecuteScalar()
                            If objEmail IsNot Nothing AndAlso Not Convert.IsDBNull(objEmail) Then
                                userEmail = objEmail.ToString().Trim()
                            End If
                        End Using

                        ' Strict applicant-to-link ownership: Link email must strictly match user's registered email
                        If Not String.IsNullOrEmpty(userEmail) Then
                            Using cmdLink As New MySqlCommand(
                                "SELECT id FROM tbl_applicant_generated_link " &
                                "WHERE LOWER(TRIM(email)) = LOWER(TRIM(@em)) AND status='Active' AND " &
                                "(validity IS NULL OR validity >= NOW()) ORDER BY id DESC LIMIT 1", cn)
                                cmdLink.Parameters.AddWithValue("@em", userEmail)
                                Dim objLid As Object = cmdLink.ExecuteScalar()
                                If objLid IsNot Nothing AndAlso Not Convert.IsDBNull(objLid) Then
                                    linkId = objLid.ToString()
                                    context.Session("ApplicantLinkID") = linkId
                                End If
                            End Using
                        End If
                    End Using
                End If
            End If

            ' If still empty, FAIL SECURELY: do NOT guess, do NOT pick another applicant's link
            If String.IsNullOrWhiteSpace(linkId) Then
                errResponse = "No applicant link identifier associated with current session."
                Return False
            End If

            ' Validate format
            Dim lidInt As Integer
            If Not Integer.TryParse(linkId, lidInt) OrElse lidInt <= 0 Then
                errResponse = "Applicant link is invalid."
                Return False
            End If

            ' Query DB to verify link is active and not expired
            Dim sql As String = "SELECT id FROM tbl_applicant_generated_link " &
                                "WHERE id=@lid AND status='Active' AND " &
                                "(validity IS NULL OR validity >= NOW()) LIMIT 1"
            Using cn As New MySqlConnection(DbHelper.ConnStr)
                cn.Open()
                Using cmd As New MySqlCommand(sql, cn)
                    cmd.Parameters.AddWithValue("@lid", linkId)
                    Dim obj As Object = cmd.ExecuteScalar()
                    If obj Is Nothing Then
                        errResponse = "Applicant link is expired or no longer active."
                        Return False
                    End If
                End Using
            End Using

            ' Initialize Anti-CSRF token if missing after successful session rehydration
            If context.Session("ApplicantCsrfToken") Is Nothing OrElse
               String.IsNullOrEmpty(context.Session("ApplicantCsrfToken").ToString()) Then
                context.Session("ApplicantCsrfToken") = Guid.NewGuid().ToString("N")
            End If
            Return True

        ElseIf RoleHelper.HasInternalStaffAccess() Then
            linkId = "STAFF-" & If(context.Session("UserID") IsNot Nothing, context.Session("UserID").ToString(), "0")
            If context.Session("ApplicantCsrfToken") Is Nothing OrElse
               String.IsNullOrEmpty(context.Session("ApplicantCsrfToken").ToString()) Then
                context.Session("ApplicantCsrfToken") = Guid.NewGuid().ToString("N")
            End If
            Return True
        Else
            errResponse = "Unauthorized: Session is not authorized for applicant self-encoding."
            Return False
        End If
    End Function

    ''' <summary>
    ''' Verifies the anti-CSRF token passed in the X-CSRF-Token header or csrf_token parameter.
    ''' </summary>
    Private Function ValidateCsrfToken(context As HttpContext) As Boolean
        If context.Session Is Nothing Then Return False

        Dim sessionToken As String = If(context.Session("ApplicantCsrfToken") IsNot Nothing,
                                        context.Session("ApplicantCsrfToken").ToString(), "")
        If String.IsNullOrEmpty(sessionToken) Then Return False

        Dim reqToken As String = context.Request.Headers("X-CSRF-Token")
        If String.IsNullOrEmpty(reqToken) Then
            reqToken = context.Request.Form("csrf_token")
        End If

        Return String.Equals(sessionToken, reqToken, StringComparison.Ordinal)
    End Function

    ''' <summary>
    ''' Verifies that the applicant explicitly checked the consent checkbox (RA 10173).
    ''' </summary>
    Private Function ValidateApplicantConsent(context As HttpContext) As Boolean
        Dim consentVal As String = context.Request.Form("consent")
        If String.IsNullOrEmpty(consentVal) Then
            consentVal = context.Request.QueryString("consent")
        End If
        If String.IsNullOrEmpty(consentVal) Then
            consentVal = context.Request.Headers("X-Applicant-Consent")
        End If

        Return String.Equals(consentVal, "1", StringComparison.Ordinal) OrElse
               String.Equals(consentVal, "true", StringComparison.OrdinalIgnoreCase)
    End Function

    ''' <summary>
    ''' Deletes staged files if a batch fails partway through.
    ''' </summary>
    Private Sub CleanupStagedDocs(stagedDocs As List(Of ApplicantStorageService.StagedDocument))
        If stagedDocs Is Nothing Then Return
        For Each doc As ApplicantStorageService.StagedDocument In stagedDocs
            Try
                If File.Exists(doc.PhysicalDiskPath) Then
                    File.Delete(doc.PhysicalDiskPath)
                End If
            Catch
            End Try
        Next
    End Sub

    ''' <summary>
    ''' Writes a JSON response with status code.
    ''' </summary>
    Private Sub WriteJsonResponse(context As HttpContext, statusCode As Integer, success As Boolean, message As String)
        context.Response.StatusCode = statusCode
        Dim resp As Object = New With {
            .success = success,
            .message = message,
            .error = If(Not success, message, Nothing)
        }
        context.Response.Write(_serializer.Serialize(resp))
    End Sub

End Class
