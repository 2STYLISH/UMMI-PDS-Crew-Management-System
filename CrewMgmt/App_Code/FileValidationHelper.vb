Imports System.IO
Imports System.Web.Configuration

''' <summary>
''' PHASE C — Applicant Document File Validation Helper
''' Implements validation for applicant supporting document uploads (FR-CM-56, FR-CM-57).
'''
''' RESPONSIBILITIES:
'''   - Allowed format whitelist: .pdf, .jpg, .jpeg, .png
'''   - Content-signature verification (magic bytes) to ensure file content matches declared type
'''   - Enforces configurable upload limits (file size, session size, file count)
'''   - Provides sanitized file names (prevents path traversal / illegal characters)
'''   - Generates user-friendly, privacy-safe error messages for rejected files
'''
''' DESIGN CONSTRAINTS & LIMITATIONS:
'''   - Magic-byte verification is a content-signature check; it does not guarantee
'''     complete structural integrity or absence of polyglot exploits without a full decoder.
'''   - PDF page-count enforcement is deferred to Phase D when PDF parsing is introduced.
'''   - All limits are configurable via Web.config and marked [PROPOSED / TBD - Subject to UMMI Approval].
''' </summary>
Public Class FileValidationHelper

    ' ── Whitelist of allowed extensions (lowercase) ───────────────────────────
    Private Shared ReadOnly AllowedExtensions As New HashSet(Of String)(StringComparer.OrdinalIgnoreCase) From {
        ".pdf", ".jpg", ".jpeg", ".png"
    }

    ' ── Magic byte signatures ─────────────────────────────────────────────────
    ' PDF: %PDF- (0x25, 0x50, 0x44, 0x46)
    Private Shared ReadOnly PdfSignature As Byte() = {&H25, &H50, &H44, &H46}
    ' JPEG: 0xFF, 0xD8, 0xFF
    Private Shared ReadOnly JpegSignature As Byte() = {&HFF, &HD8, &HFF}
    ' PNG: 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A
    Private Shared ReadOnly PngSignature As Byte() = {&H89, &H50, &H4E, &H47, &HD, &HA, &H1A, &HA}

    ' ── Validation Result Container ───────────────────────────────────────────
    Public Class ValidationResult
        Public Property IsValid As Boolean = False
        Public Property ErrorMessage As String = String.Empty
        Public Property DetectedExtension As String = String.Empty
        Public Property DetectedContentType As String = String.Empty
        Public Property SanitizedFileName As String = String.Empty
        Public Property FileSizeBytes As Long = 0
    End Class

    ' ── Configurable Limit Resolvers [PROPOSED / TBD - Subject to UMMI Approval] ──
    Public Shared Function GetMaxFileSizeBytes() As Long
        Dim val As String = WebConfigurationManager.AppSettings("ApplicantUpload_MaxFileSizeBytes")
        Dim limit As Long = 5242880L ' Default: 5 MB [PROPOSED / TBD]
        If Not String.IsNullOrEmpty(val) Then Long.TryParse(val, limit)
        Return limit
    End Function

    Public Shared Function GetMaxSessionSizeBytes() As Long
        Dim val As String = WebConfigurationManager.AppSettings("ApplicantUpload_MaxSessionSizeBytes")
        Dim limit As Long = 26214400L ' Default: 25 MB [PROPOSED / TBD]
        If Not String.IsNullOrEmpty(val) Then Long.TryParse(val, limit)
        Return limit
    End Function

    Public Shared Function GetMaxFileCount() As Integer
        Dim val As String = WebConfigurationManager.AppSettings("ApplicantUpload_MaxFileCount")
        Dim limit As Integer = 10 ' Default: 10 files [PROPOSED / TBD]
        If Not String.IsNullOrEmpty(val) Then Integer.TryParse(val, limit)
        Return limit
    End Function

    Public Shared Function GetRetentionDays() As Integer
        Dim val As String = WebConfigurationManager.AppSettings("ApplicantUpload_RetentionDays")
        Dim limit As Integer = 7 ' Default: 7 days [PROPOSED / TBD]
        If Not String.IsNullOrEmpty(val) Then Integer.TryParse(val, limit)
        Return limit
    End Function

    Public Shared Function GetMaxPdfPages() As Integer
        Dim val As String = WebConfigurationManager.AppSettings("ApplicantUpload_MaxPdfPages")
        Dim limit As Integer = 10 ' Default: 10 pages [PROPOSED / TBD - Enforced in Phase D]
        If Not String.IsNullOrEmpty(val) Then Integer.TryParse(val, limit)
        Return limit
    End Function

    ' ── SanitizeFileName ──────────────────────────────────────────────────────
    ''' <summary>
    ''' Strips directory navigation characters (e.g. .., /, \) and illegal filesystem characters.
    ''' Preserves only the safe base filename and valid extension.
    ''' </summary>
    Public Shared Function SanitizeFileName(rawFileName As String) As String
        If String.IsNullOrWhiteSpace(rawFileName) Then Return "document"
        Dim cleanName As String = Path.GetFileName(rawFileName).Trim()
        Dim invalidChars As Char() = Path.GetInvalidFileNameChars()
        For Each c As Char In invalidChars
            cleanName = cleanName.Replace(c, "_"c)
        Next
        If cleanName.Length > 150 Then
            Dim ext As String = Path.GetExtension(cleanName)
            cleanName = cleanName.Substring(0, 140) & ext
        End If
        Return cleanName
    End Function

    ' ── ValidateFile ──────────────────────────────────────────────────────────
    ''' <summary>
    ''' Performs FR-CM-56 and FR-CM-57 validation on an uploaded file.
    ''' Verifies:
    '''   1. Filename presence and extension against allowed whitelist (.pdf, .jpg, .jpeg, .png)
    '''   2. Non-empty file size (greater than 0 bytes)
    '''   3. Per-file maximum size limit
    '''   4. Binary magic-byte content-signature verification
    ''' </summary>
    Public Shared Function ValidateFile(fileBytes As Byte(), rawFileName As String) As ValidationResult
        Dim result As New ValidationResult()

        If fileBytes Is Nothing OrElse fileBytes.Length = 0 Then
            result.ErrorMessage = "The uploaded file is empty (0 bytes) and cannot be processed."
            Return result
        End If

        result.FileSizeBytes = fileBytes.Length
        result.SanitizedFileName = SanitizeFileName(rawFileName)

        ' 1. Check extension whitelist
        Dim ext As String = Path.GetExtension(result.SanitizedFileName).ToLowerInvariant()
        If String.IsNullOrEmpty(ext) OrElse Not AllowedExtensions.Contains(ext) Then
            result.ErrorMessage = String.Format(
                "Unsupported file format '{0}'. Permitted formats are: PDF, JPG, JPEG, and PNG.",
                If(String.IsNullOrEmpty(ext), "(none)", ext))
            Return result
        End If
        result.DetectedExtension = ext

        ' 2. Check per-file size limit
        Dim maxBytes As Long = GetMaxFileSizeBytes()
        If fileBytes.Length > maxBytes Then
            Dim maxMB As Double = Math.Round(maxBytes / 1048576.0, 1)
            Dim actualMB As Double = Math.Round(fileBytes.Length / 1048576.0, 1)
            result.ErrorMessage = String.Format(
                "File size ({0} MB) exceeds the maximum permitted limit of {1} MB.",
                actualMB, maxMB)
            Return result
        End If

        ' 3. Verify magic bytes / content signature
        Dim signatureMatches As Boolean = False
        Select Case ext
            Case ".pdf"
                signatureMatches = CheckSignature(fileBytes, PdfSignature)
                If signatureMatches Then
                    result.DetectedContentType = "application/pdf"
                Else
                    result.ErrorMessage = "File content does not match a valid PDF document signature."
                End If

            Case ".jpg", ".jpeg"
                signatureMatches = CheckSignature(fileBytes, JpegSignature)
                If signatureMatches Then
                    result.DetectedContentType = "image/jpeg"
                Else
                    result.ErrorMessage = "File content does not match a valid JPEG image signature."
                End If

            Case ".png"
                signatureMatches = CheckSignature(fileBytes, PngSignature)
                If signatureMatches Then
                    result.DetectedContentType = "image/png"
                Else
                    result.ErrorMessage = "File content does not match a valid PNG image signature."
                End If
        End Select

        If Not signatureMatches Then
            Return result
        End If

        result.IsValid = True
        Return result
    End Function

    ' ── ValidateSessionLimits ─────────────────────────────────────────────────
    ''' <summary>
    ''' Validates aggregate limits across all files uploaded in a self-encoding session.
    ''' Checks maximum file count and total combined upload size.
    ''' </summary>
    Public Shared Function ValidateSessionLimits(currentFileCount As Integer, currentTotalBytes As Long, newFileBytes As Long) As ValidationResult
        Dim result As New ValidationResult()

        Dim maxCount As Integer = GetMaxFileCount()
        If currentFileCount + 1 > maxCount Then
            result.ErrorMessage = String.Format(
                "Maximum file count reached. You may upload up to {0} supporting documents per application.",
                maxCount)
            Return result
        End If

        Dim maxSessionBytes As Long = GetMaxSessionSizeBytes()
        If (currentTotalBytes + newFileBytes) > maxSessionBytes Then
            Dim maxMB As Double = Math.Round(maxSessionBytes / 1048576.0, 1)
            result.ErrorMessage = String.Format(
                "Total upload size exceeds the maximum session limit of {0} MB.",
                maxMB)
            Return result
        End If

        result.IsValid = True
        Return result
    End Function

    ' ── CheckSignature Helper ─────────────────────────────────────────────────
    Private Shared Function CheckSignature(data As Byte(), signature As Byte()) As Boolean
        If data.Length < signature.Length Then Return False
        For i As Integer = 0 To signature.Length - 1
            If data(i) <> signature(i) Then Return False
        Next
        Return True
    End Function

End Class
