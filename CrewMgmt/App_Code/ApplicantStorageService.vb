Imports System.IO
Imports System.Security.Cryptography
Imports System.Text
Imports System.Web
Imports System.Web.Configuration

''' <summary>
''' PHASE C — Applicant Document Storage & Lifecycle Service
''' Manages secure file staging, GUID filename scrambling, and lifecycle cleanup
''' (FR-CM-55, FR-CM-69, FR-CM-73).
'''
''' RESPONSIBILITIES:
'''   - Stages accepted original uploads into session-isolated folders on disk
'''   - Scrambles physical filenames to non-enumerable GUIDs on disk ({GUID}.{ext})
'''   - Preserves original sanitized display names and document categories in metadata
'''   - Immediate deletion of temporary processing scratch files (FR-CM-69)
'''   - Periodic cleanup of abandoned unsubmitted staging sessions (FR-CM-73)
'''   - Zero database modifications in this phase; database persistence is deferred to Phase G.
''' </summary>
Public Class ApplicantStorageService

    ' ── Staged Document Metadata Container ────────────────────────────────────
    <Serializable()>
    Public Class StagedDocument
        Public Property StagedFileId As String = String.Empty
        Public Property OriginalFileName As String = String.Empty
        Public Property Category As String = String.Empty
        Public Property Extension As String = String.Empty
        Public Property ContentType As String = String.Empty
        Public Property FileSizeBytes As Long = 0
        Public Property PhysicalDiskPath As String = String.Empty
        Public Property StagedAtUtc As DateTime = DateTime.UtcNow
    End Class

    ' ── Staging Operation Result ──────────────────────────────────────────────
    Public Class StageResult
        Public Property IsSuccess As Boolean = False
        Public Property ErrorMessage As String = String.Empty
        Public Property StagedDoc As StagedDocument = Nothing
    End Class

    Public Shared Property CustomBaseUploadPath As String = String.Empty

    ' ── ResolveBaseUploadPath ─────────────────────────────────────────────────
    ''' <summary>
    ''' Resolves the physical base directory for uploads from Web.config "UploadPath".
    ''' Falls back to "~/Uploads/" in ASP.NET, or project/temp directory in standalone test runners.
    ''' </summary>
    Public Shared Function GetBaseUploadPhysicalPath() As String
        If Not String.IsNullOrEmpty(CustomBaseUploadPath) Then
            Return CustomBaseUploadPath
        End If

        Dim uploadRel As String = WebConfigurationManager.AppSettings("UploadPath")
        If String.IsNullOrWhiteSpace(uploadRel) Then uploadRel = "~/Uploads/"

        Dim context As HttpContext = HttpContext.Current
        If context IsNot Nothing Then
            Return context.Server.MapPath(uploadRel)
        End If

        If System.Web.Hosting.HostingEnvironment.IsHosted Then
            Return System.Web.Hosting.HostingEnvironment.MapPath(uploadRel)
        End If

        ' Standalone/test runner fallback: inspect current directory / workspace
        Dim candidate As String = Path.Combine(Environment.CurrentDirectory, "CrewMgmt", "Uploads")
        If Directory.Exists(Path.Combine(Environment.CurrentDirectory, "CrewMgmt")) Then
            Return candidate
        End If

        candidate = Path.Combine(Environment.CurrentDirectory, "Uploads")
        If File.Exists(Path.Combine(Environment.CurrentDirectory, "Web.config")) Then
            Return candidate
        End If

        ' Final safe fallback for non-hosted testing
        Dim tempFallback As String = Path.Combine(Path.GetTempPath(), "UMMI_Uploads")
        If Not Directory.Exists(tempFallback) Then Directory.CreateDirectory(tempFallback)
        Return tempFallback
    End Function

    ' ── GenerateSafeFolderKey ─────────────────────────────────────────────────
    ''' <summary>
    ''' Computes a 16-character alphanumeric SHA-256 hash of the session or token ID.
    ''' Ensures:
    '''   1. No sensitive tokens or PII are exposed as directory names on the filesystem.
    '''   2. No directory traversal characters can be injected into path resolution.
    ''' </summary>
    Public Shared Function GenerateSafeFolderKey(tokenOrSessionId As String) As String
        If String.IsNullOrWhiteSpace(tokenOrSessionId) Then
            tokenOrSessionId = "anon_" & Guid.NewGuid().ToString("N")
        End If

        Using sha As SHA256 = SHA256.Create()
            Dim bytes As Byte() = sha.ComputeHash(Encoding.UTF8.GetBytes(tokenOrSessionId.Trim()))
            Dim sb As New StringBuilder()
            For i As Integer = 0 To 7 ' 8 bytes = 16 hex characters
                sb.Append(bytes(i).ToString("x2"))
            Next
            Return sb.ToString()
        End Using
    End Function

    ' ── GetStagingPhysicalDirectory ───────────────────────────────────────────
    Public Shared Function GetStagingPhysicalDirectory(tokenOrSessionId As String) As String
        Dim basePath As String = GetBaseUploadPhysicalPath()
        Dim folderKey As String = GenerateSafeFolderKey(tokenOrSessionId)
        Dim stagingDir As String = Path.Combine(basePath, "ApplicantStaging", folderKey)
        If Not Directory.Exists(stagingDir) Then
            Directory.CreateDirectory(stagingDir)
        End If
        Return stagingDir
    End Function

    ' ── StageDocument ─────────────────────────────────────────────────────────
    ''' <summary>
    ''' Validates and writes an applicant document to session staging on disk.
    ''' Scrambles the filename to a unique GUID while tracking original metadata.
    ''' </summary>
    Public Shared Function StageDocument(fileBytes As Byte(), rawFileName As String, category As String, tokenOrSessionId As String) As StageResult
        Dim result As New StageResult()

        ' 1. Validate file content and signature
        Dim valResult As FileValidationHelper.ValidationResult = FileValidationHelper.ValidateFile(fileBytes, rawFileName)
        If Not valResult.IsValid Then
            result.ErrorMessage = valResult.ErrorMessage
            Return result
        End If

        Try
            ' 2. Resolve staging directory
            Dim stagingDir As String = GetStagingPhysicalDirectory(tokenOrSessionId)

            ' 3. Generate non-enumerable GUID filename on disk
            Dim guidKey As String = Guid.NewGuid().ToString("N")
            Dim diskFileName As String = guidKey & valResult.DetectedExtension
            Dim physicalPath As String = Path.Combine(stagingDir, diskFileName)

            ' 4. Write bytes to disk
            File.WriteAllBytes(physicalPath, fileBytes)

            ' 5. Construct metadata container
            Dim doc As New StagedDocument() With {
                .StagedFileId = guidKey,
                .OriginalFileName = valResult.SanitizedFileName,
                .Category = If(String.IsNullOrWhiteSpace(category), "Other", category.Trim()),
                .Extension = valResult.DetectedExtension,
                .ContentType = valResult.DetectedContentType,
                .FileSizeBytes = valResult.FileSizeBytes,
                .PhysicalDiskPath = physicalPath,
                .StagedAtUtc = DateTime.UtcNow
            }

            result.StagedDoc = doc
            result.IsSuccess = True

        Catch ex As Exception
            result.ErrorMessage = "An error occurred while saving the uploaded document: " & ex.Message
        End Try

        Return result
    End Function

    ' ── DeleteTemporaryArtifacts (FR-CM-69) ───────────────────────────────────
    ''' <summary>
    ''' Immediately deletes temporary processing files or scratch directories (e.g.
    ''' converted PDF page images, intermediate AI caches) without deleting retained source files.
    ''' </summary>
    Public Shared Function DeleteTemporaryArtifacts(physicalPath As String) As Boolean
        Try
            If String.IsNullOrWhiteSpace(physicalPath) Then Return True
            If File.Exists(physicalPath) Then
                File.Delete(physicalPath)
                Return True
            ElseIf Directory.Exists(physicalPath) Then
                Directory.Delete(physicalPath, True)
                Return True
            End If
            Return True
        Catch ex As Exception
            ' Log or trace if needed; cleanup must never crash the caller
            Return False
        End Try
    End Function

    ' ── CleanupAbandonedStagingSessions (FR-CM-73) ────────────────────────────
    ''' <summary>
    ''' Scans ~/Uploads/ApplicantStaging/ and purges unsubmitted staging folders
    ''' whose last write timestamp is older than the configured retention threshold
    ''' (Default: 7 days [PROPOSED / TBD - Subject to UMMI Approval]).
    ''' </summary>
    Public Shared Function CleanupAbandonedStagingSessions(Optional retentionDaysOverride As Integer = 0) As Integer
        Dim purgedCount As Integer = 0
        Try
            Dim basePath As String = GetBaseUploadPhysicalPath()
            Dim rootStagingDir As String = Path.Combine(basePath, "ApplicantStaging")
            If Not Directory.Exists(rootStagingDir) Then Return 0

            Dim retentionDays As Integer = If(retentionDaysOverride > 0, retentionDaysOverride, FileValidationHelper.GetRetentionDays())
            Dim cutoffDate As DateTime = DateTime.UtcNow.AddDays(-retentionDays)

            Dim subDirs As String() = Directory.GetDirectories(rootStagingDir)
            For Each subDir As String In subDirs
                Try
                    Dim dirInfo As New DirectoryInfo(subDir)
                    If dirInfo.LastWriteTimeUtc < cutoffDate Then
                        Directory.Delete(subDir, True)
                        purgedCount += 1
                    End If
                Catch exDir As Exception
                    ' Continue cleaning remaining directories
                End Try
            Next
        Catch ex As Exception
            ' Safe fail — maintenance routine must not break calling process
        End Try
        Return purgedCount
    End Function

End Class
