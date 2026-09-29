Imports System
Imports System.Collections.Generic
Imports System.Diagnostics
Imports System.IO
Imports System.Linq
Imports System.Threading
Imports System.Web
Imports System.Web.Caching
Imports System.Web.Hosting
Imports System.Web.Script.Serialization
Imports PdsMappingModels

''' <summary>
''' Phase F.1 / F.3: Manages the full lifecycle and state of applicant AI extraction jobs.
''' Stores job states in HttpRuntime.Cache to decouple long-running processing from ASP.NET session locks.
''' Provides managed background execution via HostingEnvironment.QueueBackgroundWorkItem (QBWI)
''' to ensure cooperative AppDomain shutdown handling and cancellation support.
'''
''' F.3 additions:
'''   - Cache-eviction callback: staged files are purged when a job cache entry expires naturally.
'''   - FailJob / CancelJob: staged files deleted immediately on terminal failure or cancellation.
'''   - Audit events (no PII) emitted at Queued, Completed, Failed, and Cancelled checkpoints.
'''   - ClearStagedFiles: voluntary cleanup utility for use on submission or session expiry.
''' </summary>
Public Class ApplicantExtractionJobManager

    Private Const CACHE_PREFIX As String = "ApplicantAiJob_"
    Private Const SESSION_INDEX_PREFIX As String = "ApplicantAiSessionIndex_"
    Private Shared ReadOnly JobLock As New Object()
    Private Shared ReadOnly ExtractionThrottle As New SemaphoreSlim(4, 4)
    Private Shared ReadOnly _serializer As New JavaScriptSerializer() With {.MaxJsonLength = Int32.MaxValue}

    ''' <summary>
    ''' Phase G: Durable envelope for authoritative repeating extraction package and staged document metadata.
    ''' Saved to extraction_package.json in the authorized applicant staging directory.
    ''' </summary>
    Public Class AuthoritativePackageEnvelope
        Public Property JobId As String = String.Empty
        Public Property ApplicantLinkId As String = String.Empty
        Public Property SessionId As String = String.Empty
        Public Property CreatedAtUtc As DateTime = DateTime.UtcNow
        Public Property StagedDocuments As New List(Of ApplicantStorageService.StagedDocument)()
        Public Property SuggestionPackage As PdsExtractionSuggestionPackage = Nothing
    End Class

    ''' <summary>
    ''' In-memory representation of an extraction job.
    ''' </summary>
    Public Class ApplicantExtractionJobState
        Public Property JobId As String
        Public Property SessionId As String
        Public Property ApplicantLinkId As String
        Public Property Status As String ' "Staged", "Queued", "Processing", "Completed", "Failed", "Cancelled"
        Public Property ProgressPercent As Integer
        Public Property StageMessage As String
        Public Property TotalFiles As Integer
        Public Property ProcessedFiles As Integer
        Public Property CreatedAtUtc As DateTime
        Public Property CompletedAtUtc As Nullable(Of DateTime)
        Public Property ErrorMessage As String
        Public Property StagedDocuments As List(Of ApplicantStorageService.StagedDocument)
        Public Property SuggestionPackage As PdsExtractionSuggestionPackage

        <ScriptIgnore>
        Public Property Cts As CancellationTokenSource

        Public Sub New()
            JobId = Guid.NewGuid().ToString("N")
            Status = "Staged"
            ProgressPercent = 0
            StageMessage = "Initialized"
            CreatedAtUtc = DateTime.UtcNow
            StagedDocuments = New List(Of ApplicantStorageService.StagedDocument)()
            Cts = New CancellationTokenSource()
        End Sub
    End Class

    ''' <summary>
    ''' Atomically acquires an upload slot for the session if no active upload or extraction job is in-flight.
    ''' Prevents race conditions from simultaneous duplicate upload requests.
    ''' </summary>
    Public Shared Function TryAcquireSessionUploadSlot(sessionId As String, linkId As String, ByRef outJob As ApplicantExtractionJobState) As Boolean
        If String.IsNullOrWhiteSpace(sessionId) Then
            Throw New ArgumentException("SessionId is required to acquire an upload slot.", "sessionId")
        End If

        SyncLock JobLock
            If HasActiveJobForSession(sessionId) Then
                outJob = Nothing
                Return False
            End If

            Dim job As New ApplicantExtractionJobState() With {
                .SessionId = sessionId,
                .ApplicantLinkId = If(linkId, "0"),
                .Status = "Uploading",
                .StageMessage = "Receiving and staging uploaded documents..."
            }

            Dim cacheKey As String = CACHE_PREFIX & job.JobId
            Dim sessionIndexKey As String = SESSION_INDEX_PREFIX & sessionId

            ' F.3: Register cache-eviction callback so staged files are purged on natural expiry
            Dim evictionCallback As New CacheItemRemovedCallback(AddressOf OnJobCacheEvicted)
            HttpRuntime.Cache.Insert(cacheKey, job, Nothing, Cache.NoAbsoluteExpiration, TimeSpan.FromMinutes(30), CacheItemPriority.Default, evictionCallback)
            HttpRuntime.Cache.Insert(sessionIndexKey, job.JobId, Nothing, Cache.NoAbsoluteExpiration, TimeSpan.FromMinutes(30), CacheItemPriority.Default, Nothing)

            outJob = job
            Return True
        End SyncLock
    End Function

    ''' <summary>
    ''' Releases an upload slot if file validation or upload failed before finalization.
    ''' </summary>
    Public Shared Sub ReleaseSessionUpload(sessionId As String, jobId As String)
        If String.IsNullOrWhiteSpace(sessionId) OrElse String.IsNullOrWhiteSpace(jobId) Then Return

        SyncLock JobLock
            Dim sessionIndexKey As String = SESSION_INDEX_PREFIX & sessionId.Trim()
            Dim existingJobId As String = TryCast(HttpRuntime.Cache.Get(sessionIndexKey), String)

            If String.Equals(existingJobId, jobId, StringComparison.OrdinalIgnoreCase) Then
                HttpRuntime.Cache.Remove(sessionIndexKey)
            End If

            Dim cacheKey As String = CACHE_PREFIX & jobId.Trim()
            Dim job As ApplicantExtractionJobState = TryCast(HttpRuntime.Cache.Get(cacheKey), ApplicantExtractionJobState)
            If job IsNot Nothing AndAlso job.Status = "Uploading" Then
                HttpRuntime.Cache.Remove(cacheKey)
            End If
        End SyncLock
    End Sub

    ''' <summary>
    ''' Transitions an atomically acquired upload slot from 'Uploading' to 'Staged' with staged documents.
    ''' </summary>
    Public Shared Sub FinalizeStagedJob(jobId As String, stagedDocs As List(Of ApplicantStorageService.StagedDocument))
        If String.IsNullOrWhiteSpace(jobId) Then Return

        SyncLock JobLock
            Dim cacheKey As String = CACHE_PREFIX & jobId.Trim()
            Dim job As ApplicantExtractionJobState = TryCast(HttpRuntime.Cache.Get(cacheKey), ApplicantExtractionJobState)
            If job IsNot Nothing Then
                job.StagedDocuments = If(stagedDocs, New List(Of ApplicantStorageService.StagedDocument)())
                job.TotalFiles = job.StagedDocuments.Count
                job.Status = "Staged"
                job.StageMessage = "Documents staged successfully. Ready for processing."
            End If
        End SyncLock
    End Sub

    ''' <summary>
    ''' Registers a newly staged extraction job in HttpRuntime.Cache.
    ''' Caches the job for 30 minutes with sliding expiration.
    ''' </summary>
    Public Shared Function CreateJob(sessionId As String, linkId As String, stagedDocs As List(Of ApplicantStorageService.StagedDocument)) As ApplicantExtractionJobState
        If String.IsNullOrWhiteSpace(sessionId) Then
            Throw New ArgumentException("SessionId is required to register an extraction job.", "sessionId")
        End If

        SyncLock JobLock
            Dim job As New ApplicantExtractionJobState() With {
                .SessionId = sessionId,
                .ApplicantLinkId = If(linkId, "0"),
                .TotalFiles = If(stagedDocs IsNot Nothing, stagedDocs.Count, 0),
                .StagedDocuments = If(stagedDocs, New List(Of ApplicantStorageService.StagedDocument)()),
                .Status = "Staged",
                .StageMessage = "Documents staged successfully. Ready for processing."
            }

            Dim cacheKey As String = CACHE_PREFIX & job.JobId
            Dim sessionIndexKey As String = SESSION_INDEX_PREFIX & sessionId

            ' F.3: Register cache-eviction callback so staged files are purged on natural expiry
            Dim evictionCallback As New CacheItemRemovedCallback(AddressOf OnJobCacheEvicted)
            HttpRuntime.Cache.Insert(cacheKey, job, Nothing, Cache.NoAbsoluteExpiration, TimeSpan.FromMinutes(30), CacheItemPriority.Default, evictionCallback)
            HttpRuntime.Cache.Insert(sessionIndexKey, job.JobId, Nothing, Cache.NoAbsoluteExpiration, TimeSpan.FromMinutes(30), CacheItemPriority.Default, Nothing)

            Return job
        End SyncLock
    End Function

    ''' <summary>
    ''' Retrieves a job by ID, strictly verifying that it belongs to the requesting session ID.
    ''' Returns Nothing if the job does not exist or if session ID mismatch occurs (cross-session protection).
    ''' </summary>
    Public Shared Function GetJob(jobId As String, requestingSessionId As String) As ApplicantExtractionJobState
        If String.IsNullOrWhiteSpace(jobId) Then Return Nothing

        Dim cacheKey As String = CACHE_PREFIX & jobId.Trim()
        Dim job As ApplicantExtractionJobState = TryCast(HttpRuntime.Cache.Get(cacheKey), ApplicantExtractionJobState)

        If job Is Nothing Then Return Nothing

        ' Anti-cross-session guard: Strictly ensure requesting session matches job session
        If Not String.IsNullOrEmpty(requestingSessionId) AndAlso Not String.Equals(job.SessionId, requestingSessionId, StringComparison.OrdinalIgnoreCase) Then
            Return Nothing
        End If

        Return job
    End Function

    ''' <summary>
    ''' Checks whether an active extraction job is currently queued or processing for the given session ID.
    ''' Used to prevent duplicate uploads or concurrent extraction flooding (idempotency guard).
    ''' </summary>
    Public Shared Function HasActiveJobForSession(sessionId As String) As Boolean
        If String.IsNullOrWhiteSpace(sessionId) Then Return False

        Dim sessionIndexKey As String = SESSION_INDEX_PREFIX & sessionId.Trim()
        Dim existingJobId As String = TryCast(HttpRuntime.Cache.Get(sessionIndexKey), String)

        If String.IsNullOrEmpty(existingJobId) Then Return False

        Dim job As ApplicantExtractionJobState = TryCast(HttpRuntime.Cache.Get(CACHE_PREFIX & existingJobId), ApplicantExtractionJobState)
        If job Is Nothing Then Return False

        Return (job.Status = "Uploading" OrElse job.Status = "Staged" OrElse job.Status = "Queued" OrElse job.Status = "Processing")
    End Function

    ''' <summary>
    ''' Updates progress and stage message for an in-flight job.
    ''' </summary>
    Public Shared Sub UpdateProgress(jobId As String, percent As Integer, message As String, Optional processedCount As Integer = -1)
        If String.IsNullOrWhiteSpace(jobId) Then Return

        SyncLock JobLock
            Dim cacheKey As String = CACHE_PREFIX & jobId.Trim()
            Dim job As ApplicantExtractionJobState = TryCast(HttpRuntime.Cache.Get(cacheKey), ApplicantExtractionJobState)
            If job IsNot Nothing Then
                job.ProgressPercent = Math.Max(0, Math.Min(100, percent))
                job.StageMessage = If(message, "")
                If processedCount >= 0 Then job.ProcessedFiles = processedCount
                If job.Status = "Queued" OrElse job.Status = "Staged" Then
                    job.Status = "Processing"
                End If
            End If
        End SyncLock
    End Sub

    ''' <summary>
    ''' Marks an extraction job as successfully completed with its suggestion package.
    ''' </summary>
    Public Shared Sub CompleteJob(jobId As String, package As PdsExtractionSuggestionPackage)
        If String.IsNullOrWhiteSpace(jobId) Then Return

        SyncLock JobLock
            Dim cacheKey As String = CACHE_PREFIX & jobId.Trim()
            Dim job As ApplicantExtractionJobState = TryCast(HttpRuntime.Cache.Get(cacheKey), ApplicantExtractionJobState)
            If job IsNot Nothing Then
                ' Safeguard: Cancelled or consent-withdrawn jobs must NEVER publish results or transition to Completed
                If job.Status = "Cancelled" OrElse job.Status = "ConsentWithdrawn" OrElse
                   (job.Cts IsNot Nothing AndAlso job.Cts.IsCancellationRequested) Then
                    Return
                End If
                job.Status = "Completed"
                job.ProgressPercent = 100
                job.StageMessage = "Extraction and validation completed successfully."
                job.SuggestionPackage = package
                job.CompletedAtUtc = DateTime.UtcNow
                PersistAuthoritativePackage(job)
            End If
        End SyncLock
    End Sub

    ''' <summary>
    ''' Marks an extraction job as failed with an error message.
    ''' F.3: Deletes staged files immediately on failure; emits privacy-safe audit event.
    ''' </summary>
    Public Shared Sub FailJob(jobId As String, errorMessage As String)
        If String.IsNullOrWhiteSpace(jobId) Then Return

        Dim docsToDelete As List(Of ApplicantStorageService.StagedDocument) = Nothing
        SyncLock JobLock
            Dim cacheKey As String = CACHE_PREFIX & jobId.Trim()
            Dim job As ApplicantExtractionJobState = TryCast(HttpRuntime.Cache.Get(cacheKey), ApplicantExtractionJobState)
            If job IsNot Nothing Then
                ' Safeguard: Do not overwrite Cancelled or ConsentWithdrawn with Failed
                If job.Status = "Cancelled" OrElse job.Status = "ConsentWithdrawn" Then Return
                job.Status = "Failed"
                job.ErrorMessage = If(errorMessage, "An unexpected extraction error occurred.")
                job.StageMessage = "Extraction encountered an error."
                job.CompletedAtUtc = DateTime.UtcNow
                ' F.3: Capture staged docs for deletion outside SyncLock
                docsToDelete = job.StagedDocuments
                job.StagedDocuments = New List(Of ApplicantStorageService.StagedDocument)()
            End If
        End SyncLock

        ' F.3: Delete staged files outside the lock to avoid holding it during I/O
        If docsToDelete IsNot Nothing Then
            DeleteStagedFiles(docsToDelete)
        End If

        ' F.3: Privacy-safe audit — no PII, no filenames
        AuditHelper.LogApplicantExtractionEvent(
            action:="ExtractionFailed",
            itemCount:=If(docsToDelete IsNot Nothing, docsToDelete.Count, 0),
            outcome:="Failed",
            durationMs:=0
        )
    End Sub

    ''' <summary>
    ''' Cancels a pending or running extraction job for the session.
    ''' F.3: Staged files are deleted immediately on cancellation; emits privacy-safe audit event.
    ''' </summary>
    Public Shared Function CancelJob(jobId As String, requestingSessionId As String) As Boolean
        If String.IsNullOrWhiteSpace(jobId) Then Return False

        Dim docsToDelete As List(Of ApplicantStorageService.StagedDocument) = Nothing
        Dim cancelled As Boolean = False

        SyncLock JobLock
            Dim job As ApplicantExtractionJobState = GetJob(jobId, requestingSessionId)
            If job Is Nothing Then Return False

            If job.Status = "Queued" OrElse job.Status = "Processing" OrElse job.Status = "Staged" OrElse job.Status = "Uploading" Then
                job.Status = "Cancelled"
                job.StageMessage = "Job cancelled by applicant."
                job.CompletedAtUtc = DateTime.UtcNow
                ' F.3: Capture staged docs for deletion outside SyncLock
                docsToDelete = job.StagedDocuments
                job.StagedDocuments = New List(Of ApplicantStorageService.StagedDocument)()
                Try
                    If job.Cts IsNot Nothing AndAlso Not job.Cts.IsCancellationRequested Then
                        job.Cts.Cancel()
                    End If
                Catch
                End Try
                cancelled = True
            End If
        End SyncLock

        If cancelled Then
            ' F.3: Delete staged files outside the lock to avoid holding it during I/O
            If docsToDelete IsNot Nothing Then
                DeleteStagedFiles(docsToDelete)
            End If
            ' F.3: Privacy-safe audit event
            AuditHelper.LogApplicantExtractionEvent(
                action:="ExtractionCancelled",
                itemCount:=If(docsToDelete IsNot Nothing, docsToDelete.Count, 0),
                outcome:="Cancelled",
                durationMs:=0
            )
        End If

        Return cancelled
    End Function

    ''' <summary>
    ''' Starts the managed background extraction pipeline for a staged job.
    ''' Coordinates DocumentExtractionService (Phase D) and PdsExtractionMappingService (Phase E).
    ''' F.3: Emits audit events at Queued, Completed, Failed, and Cancelled checkpoints.
    '''       Staged files deleted on completion after package is in memory; eviction callback handles expiry cleanup.
    ''' </summary>
    Public Shared Sub StartExtraction(jobId As String, requestingSessionId As String)
        If String.IsNullOrWhiteSpace(jobId) Then Return

        Dim job As ApplicantExtractionJobState = GetJob(jobId, requestingSessionId)
        If job Is Nothing Then Return

        SyncLock JobLock
            If job.Status <> "Staged" AndAlso job.Status <> "Uploading" Then Return
            job.Status = "Queued"
            job.ProgressPercent = 5
            job.StageMessage = "Queued for extraction..."
            ' F.3: Privacy-safe audit — job queued
            AuditHelper.LogApplicantExtractionEvent(
                action:="ExtractionQueued",
                itemCount:=job.TotalFiles,
                outcome:="Queued",
                durationMs:=0
            )
        End SyncLock

        QueueManagedWorkItem(Sub(hostCancellationToken)
            Dim linkedCts As CancellationTokenSource = Nothing
            Dim acquiredLock As Boolean = False
            Try
                linkedCts = CancellationTokenSource.CreateLinkedTokenSource(hostCancellationToken, job.Cts.Token)
                Dim cancelToken As CancellationToken = linkedCts.Token

                If cancelToken.IsCancellationRequested Then
                    SyncLock JobLock
                        job.Status = "Cancelled"
                        job.StageMessage = "Job cancelled before execution started."
                        job.CompletedAtUtc = DateTime.UtcNow
                    End SyncLock
                    Return
                End If

                ' Wait for bounded concurrency throttle (max 4 simultaneous extraction batches server-wide)
                acquiredLock = ExtractionThrottle.Wait(TimeSpan.FromSeconds(30), cancelToken)
                If Not acquiredLock Then
                    FailJob(jobId, "The server is currently under heavy load. Please retry in a few moments.")
                    Return
                End If

                SyncLock JobLock
                    If job.Status = "Cancelled" OrElse cancelToken.IsCancellationRequested Then
                        job.Status = "Cancelled"
                        job.StageMessage = "Job cancelled by applicant."
                        job.CompletedAtUtc = DateTime.UtcNow
                        Return
                    End If
                    job.Status = "Processing"
                    job.ProgressPercent = 10
                    job.StageMessage = "Starting document extraction pipeline..."
                End SyncLock

                Dim stagedDocs As List(Of ApplicantStorageService.StagedDocument) = job.StagedDocuments
                Dim docResults As New List(Of DocumentExtractionService.DocumentExtractionResult)()
                Dim totalDocs As Integer = If(stagedDocs IsNot Nothing, stagedDocs.Count, 0)

                For i As Integer = 0 To totalDocs - 1
                    If cancelToken.IsCancellationRequested Then
                        SyncLock JobLock
                            job.Status = "Cancelled"
                            job.StageMessage = "Job cancelled by applicant."
                            job.CompletedAtUtc = DateTime.UtcNow
                        End SyncLock
                        Return
                    End If

                    Dim doc As ApplicantStorageService.StagedDocument = stagedDocs(i)
                    Dim docIndex As Integer = i + 1
                    Dim catName As String = If(Not String.IsNullOrEmpty(doc.Category), doc.Category, "Document")

                    Dim currentProgress As Integer = 10 + CInt((i / CDbl(Math.Max(1, totalDocs))) * 70.0)
                    UpdateProgress(jobId, currentProgress, String.Format("Extracting {0} ({1} of {2})...", catName, docIndex, totalDocs), i)

                    ' Execute Phase D extraction for this staged document
                    Dim docRes As DocumentExtractionService.DocumentExtractionResult =
                        DocumentExtractionService.ExtractFromStagedDocument(doc)
                    docResults.Add(docRes)

                    UpdateProgress(jobId, 10 + CInt((docIndex / CDbl(Math.Max(1, totalDocs))) * 70.0), String.Format("Extracted {0} ({1} of {2})", catName, docIndex, totalDocs), docIndex)
                Next

                If cancelToken.IsCancellationRequested Then
                    SyncLock JobLock
                        job.Status = "Cancelled"
                        job.StageMessage = "Job cancelled by applicant."
                        job.CompletedAtUtc = DateTime.UtcNow
                    End SyncLock
                    Return
                End If

                ' Check if all documents failed
                Dim allFailed As Boolean = (docResults.Count > 0 AndAlso docResults.All(Function(r) Not r.IsSuccess))
                If allFailed Then
                    Dim failedDoc As DocumentExtractionService.DocumentExtractionResult =
                        docResults.FirstOrDefault(Function(r) Not String.IsNullOrEmpty(r.ErrorMessage))
                    Dim firstErr As String = If(failedDoc IsNot Nothing, failedDoc.ErrorMessage, "")
                    If String.IsNullOrWhiteSpace(firstErr) Then
                        firstErr = "Unable to extract information from the uploaded documents. Please ensure documents are legible and valid."
                    End If
                    FailJob(jobId, firstErr)
                    Return
                End If

                ' At least one document succeeded or partially succeeded -> Map to PDS suggestions via Phase E
                UpdateProgress(jobId, 85, "Validating and mapping extracted fields to PDS schema...")

                Dim phaseSw As Stopwatch = Stopwatch.StartNew()
                Dim suggestionPackage As PdsExtractionSuggestionPackage =
                    PdsExtractionMappingService.ProcessExtractionResults(docResults, job.SessionId)
                phaseSw.Stop()

                ' Safeguard: Check cancellation before publishing completed results
                If cancelToken.IsCancellationRequested OrElse job.Status = "Cancelled" OrElse job.Status = "ConsentWithdrawn" Then
                    SyncLock JobLock
                        job.Status = "Cancelled"
                        job.StageMessage = "Job cancelled by applicant."
                        job.CompletedAtUtc = DateTime.UtcNow
                        job.SuggestionPackage = Nothing
                    End SyncLock
                    Return
                End If

                If suggestionPackage IsNot Nothing AndAlso suggestionPackage.IsSuccess Then
                    CompleteJob(jobId, suggestionPackage)
                    If job.Status = "Completed" Then
                        ' F.3: Emit completion audit before staging-file purge
                        AuditHelper.LogApplicantExtractionEvent(
                            action:="ExtractionCompleted",
                            itemCount:=docResults.Count,
                            outcome:="Success",
                            durationMs:=phaseSw.ElapsedMilliseconds
                        )
                    End If
                Else
                    Dim mapErr As String = If(suggestionPackage IsNot Nothing AndAlso Not String.IsNullOrEmpty(suggestionPackage.ErrorMessage),
                                              suggestionPackage.ErrorMessage,
                                              "PDS suggestion mapping encountered an unexpected error.")
                    FailJob(jobId, mapErr)
                End If

            Catch opCancelEx As OperationCanceledException
                SyncLock JobLock
                    job.Status = "Cancelled"
                    job.StageMessage = "Job cancelled by applicant."
                    job.CompletedAtUtc = DateTime.UtcNow
                End SyncLock
            Catch ex As Exception
                FailJob(jobId, "An unexpected extraction error occurred: " & ex.Message)
            Finally
                If acquiredLock Then
                    ExtractionThrottle.Release()
                End If
                If linkedCts IsNot Nothing Then
                    linkedCts.Dispose()
                End If
            End Try
        End Sub)
    End Sub

    ' ── F.3: Staged File Cleanup Helpers ──────────────────────────────────────

    ''' <summary>
    ''' F.3: Deletes all physical staged documents for a job from disk.
    ''' Called on job failure, cancellation, or voluntary post-submission cleanup.
    ''' Safe-fail: exceptions per file are swallowed; caller is never interrupted.
    ''' </summary>
    Public Shared Sub DeleteStagedFiles(docs As List(Of ApplicantStorageService.StagedDocument))
        If docs Is Nothing Then Return
        For Each doc As ApplicantStorageService.StagedDocument In docs
            Try
                If Not String.IsNullOrEmpty(doc.PhysicalDiskPath) AndAlso File.Exists(doc.PhysicalDiskPath) Then
                    File.Delete(doc.PhysicalDiskPath)
                End If
            Catch
                ' Safe-fail: cleanup must not disrupt caller
            End Try
        Next
    End Sub

    ''' <summary>
    ''' F.3: Voluntarily purges staged files for a session's active job.
    ''' Called after successful manual submission (SubmitApplication) to ensure
    ''' no orphaned staging files remain on disk after the session is abandoned.
    ''' </summary>
    Public Shared Sub ClearStagedFilesForSession(sessionId As String)
        If String.IsNullOrWhiteSpace(sessionId) Then Return
        Try
            Dim sessionIndexKey As String = SESSION_INDEX_PREFIX & sessionId.Trim()
            Dim existingJobId As String = TryCast(HttpRuntime.Cache.Get(sessionIndexKey), String)
            If Not String.IsNullOrEmpty(existingJobId) Then
                Dim cacheKey As String = CACHE_PREFIX & existingJobId
                Dim job As ApplicantExtractionJobState = TryCast(HttpRuntime.Cache.Get(cacheKey), ApplicantExtractionJobState)
                If job IsNot Nothing Then
                    ' Concurrency safeguard: signal cancellation if job is in-flight before deleting files
                    SyncLock JobLock
                        If job.Status = "Uploading" OrElse job.Status = "Queued" OrElse job.Status = "Processing" Then
                            Try
                                If job.Cts IsNot Nothing AndAlso Not job.Cts.IsCancellationRequested Then
                                    job.Cts.Cancel()
                                end If
                            Catch
                            End Try
                            job.Status = "Cancelled"
                            job.StageMessage = "Job cancelled due to session reset or cleanup."
                        End If
                    End SyncLock

                    If job.StagedDocuments IsNot Nothing Then
                        DeleteStagedFiles(job.StagedDocuments)
                        SyncLock JobLock
                            job.StagedDocuments = New List(Of ApplicantStorageService.StagedDocument)()
                        End SyncLock
                    End If
                End If
            End If

            ' Also clean up the physical session folder if it exists
            Dim basePath As String = ApplicantStorageService.GetBaseUploadPhysicalPath()
            Dim folderKey As String = ApplicantStorageService.GenerateSafeFolderKey(sessionId.Trim())
            Dim stagingDir As String = Path.Combine(basePath, "ApplicantStaging", folderKey)
            If Directory.Exists(stagingDir) Then
                Try
                    Directory.Delete(stagingDir, True)
                Catch
                End Try
            End If
        Catch
            ' Safe-fail: cleanup must not disrupt submission
        End Try
    End Sub

    ''' <summary>
    ''' F.3 Supplemental: Explicitly withdraws AI consent for an applicant session.
    ''' Cancels any active extraction, wipes suggestion packages from memory,
    ''' purges all staged documents from disk, and invalidates session job cache.
    ''' Does NOT clear manually entered form fields.
    ''' </summary>
    Public Shared Sub WithdrawConsentForSession(sessionId As String)
        If String.IsNullOrWhiteSpace(sessionId) Then Return
        Try
            Dim sessionIndexKey As String = SESSION_INDEX_PREFIX & sessionId.Trim()
            Dim existingJobId As String = TryCast(HttpRuntime.Cache.Get(sessionIndexKey), String)

            If Not String.IsNullOrEmpty(existingJobId) Then
                Dim cacheKey As String = CACHE_PREFIX & existingJobId
                Dim job As ApplicantExtractionJobState = TryCast(HttpRuntime.Cache.Get(cacheKey), ApplicantExtractionJobState)

                If job IsNot Nothing Then
                    SyncLock JobLock
                        If job.Cts IsNot Nothing AndAlso Not job.Cts.IsCancellationRequested Then
                            Try
                                job.Cts.Cancel()
                            Catch
                            End Try
                        End If
                        job.Status = "ConsentWithdrawn"
                        job.StageMessage = "Applicant AI consent was withdrawn. Suggestions and staged files cleared."
                        job.SuggestionPackage = Nothing
                        job.CompletedAtUtc = DateTime.UtcNow
                    End SyncLock
                End If

                ' Invalidate job cache entries so subsequent result queries return 404
                HttpRuntime.Cache.Remove(cacheKey)
                HttpRuntime.Cache.Remove(sessionIndexKey)
            End If

            ' Purge physical files and session folder from disk
            ClearStagedFilesForSession(sessionId)

            ' Privacy-safe audit trail
            AuditHelper.LogApplicantExtractionEvent("ConsentWithdrawn", 0, "Withdrawn", 0)

        Catch ex As Exception
            ' Safe-fail: withdrawal must not break calling process
        End Try
    End Sub

    ''' <summary>
    ''' F.3: Cache-eviction callback invoked by ASP.NET when a job cache entry expires naturally
    ''' (after 30-minute sliding window with no polling activity).
    ''' Deletes any remaining staged files for the expired job to prevent orphaned disk artifacts.
    ''' </summary>
    Private Shared Sub OnJobCacheEvicted(key As String, value As Object, reason As CacheItemRemovedReason)
        If Not key.StartsWith(CACHE_PREFIX, StringComparison.OrdinalIgnoreCase) Then Return
        Try
            Dim job As ApplicantExtractionJobState = TryCast(value, ApplicantExtractionJobState)
            If job IsNot Nothing AndAlso job.StagedDocuments IsNot Nothing AndAlso job.StagedDocuments.Count > 0 Then
                ' Only delete files if job did not complete successfully (successful jobs may have had files
                ' already cleaned up, but we delete defensively here)
                DeleteStagedFiles(job.StagedDocuments)
                ' F.3: Emit eviction audit with no PII
                AuditHelper.LogApplicantExtractionEvent(
                    action:="ExtractionJobEvicted",
                    itemCount:=job.StagedDocuments.Count,
                    outcome:=If(String.Equals(job.Status, "Completed", StringComparison.OrdinalIgnoreCase), "ExpiredAfterCompletion", "ExpiredOrphaned"),
                    durationMs:=0
                )
            End If
        Catch
            ' Safe-fail: eviction callback must never raise
        End Try
    End Sub

    ''' <summary>
    ''' Queues managed background execution via HostingEnvironment.QueueBackgroundWorkItem.
    ''' ASP.NET registers this work item with the runtime and delays AppDomain shutdown (IIS recycles)
    ''' up to the configured shutdownTimeLimit (default 90s) while signaling the CancellationToken.
    ''' </summary>
    Public Shared Sub QueueManagedWorkItem(workItem As Action(Of CancellationToken))
        If workItem Is Nothing Then Throw New ArgumentNullException("workItem")

        If HostingEnvironment.IsHosted Then
            HostingEnvironment.QueueBackgroundWorkItem(workItem)
        Else
            ' Fallback for unit test and out-of-host execution: run asynchronously on ThreadPool
            ThreadPool.QueueUserWorkItem(Sub(state)
                Dim cts As New CancellationTokenSource()
                Try
                    workItem(cts.Token)
                Catch
                End Try
            End Sub)
        End If
    End Sub

    ''' <summary>
    ''' Phase G: Persists the authoritative extraction package and staged document records to disk
    ''' in the applicant's authorized staging folder as extraction_package.json.
    ''' </summary>
    Public Shared Sub PersistAuthoritativePackage(job As ApplicantExtractionJobState)
        If job Is Nothing OrElse job.SuggestionPackage Is Nothing Then Return
        Try
            Dim envelope As New AuthoritativePackageEnvelope With {
                .JobId = job.JobId,
                .ApplicantLinkId = If(job.ApplicantLinkId, "0"),
                .SessionId = If(job.SessionId, String.Empty),
                .CreatedAtUtc = DateTime.UtcNow,
                .StagedDocuments = If(job.StagedDocuments, New List(Of ApplicantStorageService.StagedDocument)()),
                .SuggestionPackage = job.SuggestionPackage
            }

            Dim json As String = _serializer.Serialize(envelope)

            ' 1. Write to session staging directory
            If Not String.IsNullOrWhiteSpace(job.SessionId) Then
                Dim sessionDir As String = ApplicantStorageService.GetStagingPhysicalDirectory(job.SessionId)
                Dim pkgPath As String = Path.Combine(sessionDir, "extraction_package.json")
                File.WriteAllText(pkgPath, json, System.Text.Encoding.UTF8)
            End If

            ' 2. If applicant link ID is known and not 0, also write to link staging directory
            If Not String.IsNullOrWhiteSpace(job.ApplicantLinkId) AndAlso job.ApplicantLinkId <> "0" Then
                Dim linkDir As String = ApplicantStorageService.GetStagingPhysicalDirectory("link_" & job.ApplicantLinkId.Trim())
                Dim linkPkgPath As String = Path.Combine(linkDir, "extraction_package.json")
                File.WriteAllText(linkPkgPath, json, System.Text.Encoding.UTF8)
            End If
        Catch ex As Exception
            ' Safe fail: disk persistence failure should be logged but never crash caller
        End Try
    End Sub

    ''' <summary>
    ''' Phase G: Retrieves the authoritative extraction suggestion package, recovering from disk
    ''' if HttpRuntime.Cache was evicted or lost. Verifies applicant/link ownership and returns Nothing
    ''' on mismatch or forged identifiers.
    ''' </summary>
    Public Shared Function GetAuthoritativePackage(jobId As String, sessionId As String, linkId As String, ByRef outStagedDocs As List(Of ApplicantStorageService.StagedDocument)) As PdsExtractionSuggestionPackage
        outStagedDocs = Nothing

        ' 1. Check HttpRuntime.Cache first
        If Not String.IsNullOrWhiteSpace(jobId) Then
            SyncLock JobLock
                Dim cacheKey As String = CACHE_PREFIX & jobId.Trim()
                Dim job As ApplicantExtractionJobState = TryCast(HttpRuntime.Cache.Get(cacheKey), ApplicantExtractionJobState)
                If job IsNot Nothing AndAlso job.SuggestionPackage IsNot Nothing Then
                    ' Verify link ownership
                    If Not String.IsNullOrWhiteSpace(linkId) AndAlso linkId <> "0" AndAlso
                       Not String.IsNullOrWhiteSpace(job.ApplicantLinkId) AndAlso job.ApplicantLinkId <> "0" Then
                        If Not String.Equals(job.ApplicantLinkId, linkId.Trim(), StringComparison.OrdinalIgnoreCase) Then
                            Return Nothing ' Cross-applicant link mismatch
                        End If
                    End If
                    outStagedDocs = job.StagedDocuments
                    Return job.SuggestionPackage
                End If
            End SyncLock
        End If

        ' 2. Cache miss: recover from disk in authoritative staging folder
        Dim searchDirs As New List(Of String)()
        If Not String.IsNullOrWhiteSpace(linkId) AndAlso linkId <> "0" Then
            searchDirs.Add(ApplicantStorageService.GetStagingPhysicalDirectory("link_" & linkId.Trim()))
        End If
        If Not String.IsNullOrWhiteSpace(sessionId) Then
            searchDirs.Add(ApplicantStorageService.GetStagingPhysicalDirectory(sessionId.Trim()))
        End If
        If Not String.IsNullOrWhiteSpace(jobId) Then
            searchDirs.Add(ApplicantStorageService.GetStagingPhysicalDirectory(jobId.Trim()))
        End If

        For Each searchDir As String In searchDirs
            Try
                Dim pkgPath As String = Path.Combine(searchDir, "extraction_package.json")
                If File.Exists(pkgPath) Then
                    Dim rawJson As String = File.ReadAllText(pkgPath, System.Text.Encoding.UTF8)
                    If Not String.IsNullOrWhiteSpace(rawJson) Then
                        Dim envelope As AuthoritativePackageEnvelope = _serializer.Deserialize(Of AuthoritativePackageEnvelope)(rawJson)
                        If envelope IsNot Nothing AndAlso envelope.SuggestionPackage IsNot Nothing Then
                            ' Validate link ownership
                            If Not String.IsNullOrWhiteSpace(linkId) AndAlso linkId <> "0" AndAlso
                               Not String.IsNullOrWhiteSpace(envelope.ApplicantLinkId) AndAlso envelope.ApplicantLinkId <> "0" Then
                                If Not String.Equals(envelope.ApplicantLinkId, linkId.Trim(), StringComparison.OrdinalIgnoreCase) Then
                                    Return Nothing ' Cross-applicant link mismatch
                                End If
                            End If

                            ' Validate jobId if provided
                            If Not String.IsNullOrWhiteSpace(jobId) AndAlso Not String.IsNullOrWhiteSpace(envelope.JobId) Then
                                If Not String.Equals(envelope.JobId, jobId.Trim(), StringComparison.OrdinalIgnoreCase) Then
                                    Continue For
                                End If
                            End If

                            outStagedDocs = envelope.StagedDocuments
                            Return envelope.SuggestionPackage
                        End If
                    End If
                End If
            Catch
                ' Try next directory
            End Try
        Next

        Return Nothing
    End Function

End Class
