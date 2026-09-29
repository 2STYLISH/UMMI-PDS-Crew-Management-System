Imports System
Imports System.Collections.Generic
Imports System.Diagnostics
Imports System.Drawing
Imports System.Drawing.Drawing2D
Imports System.Drawing.Imaging
Imports System.IO
Imports System.Linq

''' <summary>
''' PHASE D — Multimodal Ingestion & Vision-Language Extraction Service (FR-CM-58, FR-CM-59, FR-CM-60)
''' Orchestrates extraction across PDF (native text vs visual OCR) and direct image uploads.
''' 
''' ARCHITECTURAL CONSTRAINTS:
''' - Produces structured extraction results IN MEMORY ONLY.
''' - Zero database writes.
''' - Zero PDS field mapping (deferred to Phase E).
''' - Zero UI changes / zero SelfEncode.aspx modifications (deferred to Phase F).
''' - Original staged documents are read-only and strictly preserved.
''' - Guaranteed FR-CM-69 cleanup: Temporary rendered PNG files are deleted in a Finally
'''   block regardless of API timeout, HTTP error, JSON failure, or unhandled exception.
''' - Privacy-safe audit logging (no PII, filenames, or raw extraction text).
''' </summary>
Public Class DocumentExtractionService

    ''' <summary>
    ''' Extraction result for a single page or image.
    ''' RawJsonOutput contains the untrusted AI output to be validated by Phase E.
    ''' </summary>
    Public Class PageExtractionResult
        Public Property PageNumber As Integer = 1
        Public Property InputMode As String = String.Empty ' "text" or "image"
        Public Property IsSuccess As Boolean = False
        Public Property RawJsonOutput As String = String.Empty
        Public Property ErrorMessage As String = String.Empty
        Public Property ExecutionTimeMs As Long = 0
        Public Property PromptTokens As Integer = 0
        Public Property CompletionTokens As Integer = 0
    End Class

    ''' <summary>
    ''' Extraction result for the entire staged document.
    ''' </summary>
    Public Class DocumentExtractionResult
        Public Property StagedFileId As String = String.Empty
        Public Property OriginalFileName As String = String.Empty
        Public Property CategoryKey As String = String.Empty
        Public Property IsSuccess As Boolean = False
        Public Property ErrorMessage As String = String.Empty
        Public Property TotalPages As Integer = 0
        Public Property Pages As New List(Of PageExtractionResult)()
        Public Property AggregatedExecutionTimeMs As Long = 0
        Public Property TotalPromptTokens As Integer = 0
        Public Property TotalCompletionTokens As Integer = 0
    End Class

#If DEBUG Then
    ''' <summary>
    ''' Optional test hook for service-level failure injection during automated testing.
    ''' When set, invoked immediately after temporary PNG rendering and before API dispatch.
    ''' </summary>
    Public Shared Property FailureInjectionHook As Action(Of String) = Nothing
#End If

    ''' <summary>
    ''' Orchestrates document field extraction for a staged applicant document.
    ''' Routes PDF pages via native-text or visual OCR based on usability heuristic (FR-CM-58).
    ''' Routes image uploads directly to visual OCR (FR-CM-59).
    ''' </summary>
    Public Shared Function ExtractFromStagedDocument(
        stagedDoc As ApplicantStorageService.StagedDocument,
        Optional categoryKeyOverride As String = Nothing
    ) As DocumentExtractionResult

        Dim docResult As New DocumentExtractionResult()
        Dim totalSw As Stopwatch = Stopwatch.StartNew()

        If stagedDoc Is Nothing Then
            docResult.ErrorMessage = "Staged document reference is null."
            Return docResult
        End If

        docResult.StagedFileId = stagedDoc.StagedFileId
        docResult.OriginalFileName = stagedDoc.OriginalFileName

        If Not File.Exists(stagedDoc.PhysicalDiskPath) Then
            docResult.ErrorMessage = "The physical staged document could not be found on disk."
            Return docResult
        End If

        ' Resolve category definition
        Dim resolvedCatKey As String = If(Not String.IsNullOrWhiteSpace(categoryKeyOverride),
                                          categoryKeyOverride.Trim(),
                                          stagedDoc.Category)
        Dim catDef As ExtractionPromptCatalog.ExtractionCategoryDefinition =
            ExtractionPromptCatalog.GetCategory(resolvedCatKey)
        docResult.CategoryKey = catDef.CategoryKey

        Dim ext As String = If(stagedDoc.Extension, String.Empty).ToLowerInvariant()

        Try
            If ext = ".pdf" Then
                ProcessPdfDocument(stagedDoc, catDef, docResult)
            ElseIf ext = ".jpg" OrElse ext = ".jpeg" OrElse ext = ".png" Then
                ProcessImageDocument(stagedDoc, catDef, docResult)
            Else
                docResult.ErrorMessage = "Unsupported document extension for AI extraction: " & ext
            End If

        Catch ex As Exception
            docResult.IsSuccess = False
            docResult.ErrorMessage = "Unexpected extraction error: " & ex.Message
        Finally
            totalSw.Stop()
            docResult.AggregatedExecutionTimeMs = totalSw.ElapsedMilliseconds

            ' Determine overall success: at least one page succeeded and no complete failure
            If docResult.Pages.Count > 0 Then
                docResult.TotalPages = docResult.Pages.Count
                docResult.TotalPromptTokens = docResult.Pages.Sum(Function(p) p.PromptTokens)
                docResult.TotalCompletionTokens = docResult.Pages.Sum(Function(p) p.CompletionTokens)
                docResult.IsSuccess = docResult.Pages.All(Function(p) p.IsSuccess)
                If Not docResult.IsSuccess AndAlso docResult.Pages.Any(Function(p) p.IsSuccess) Then
                    ' Partial success
                    docResult.ErrorMessage = "Some document pages could not be extracted."
                End If
            End If

            ' Privacy-safe audit log: NEVER log PII, filenames, or raw extracted text
            Dim outcome As String = If(docResult.IsSuccess, "Success", "Failed")
            AuditHelper.LogApplicantExtractionEvent(
                action:="DocumentExtract",
                itemCount:=docResult.Pages.Count,
                outcome:=outcome,
                durationMs:=docResult.AggregatedExecutionTimeMs,
                modeSummary:=docResult.CategoryKey & " (" & ext & ")"
            )
        End Try

        Return docResult
    End Function

    ' ── PDF Processing Pipeline ────────────────────────────────────────────────
    Private Shared Sub ProcessPdfDocument(
        stagedDoc As ApplicantStorageService.StagedDocument,
        catDef As ExtractionPromptCatalog.ExtractionCategoryDefinition,
        docResult As DocumentExtractionResult
    )
        ' 1. Analyze PDF (checks page limit and evaluates text usability per page)
        Dim analysis As PdfProcessingService.PdfAnalysisResult =
            PdfProcessingService.AnalyzePdf(stagedDoc.PhysicalDiskPath)

        If Not analysis.IsSuccess Then
            docResult.IsSuccess = False
            docResult.ErrorMessage = analysis.ErrorMessage
            Return
        End If

        Dim stagingDir As String = Path.GetDirectoryName(stagedDoc.PhysicalDiskPath)
        Dim tmpDir As String = Path.Combine(stagingDir, "_tmp")

        ' 2. Process each page according to routing decision
        For Each pageAnalysis As PdfProcessingService.PdfPageAnalysisResult In analysis.Pages
            Dim pageResult As New PageExtractionResult()
            pageResult.PageNumber = pageAnalysis.PageNumber

            If pageAnalysis.IsTextUsable Then
                ' ── Native Text Path (FR-CM-58) ──
                pageResult.InputMode = "text"
                Dim apiRes As DeepInfraService.DeepInfraResult =
                    DeepInfraService.ExtractDocumentFields(
                        systemPrompt:=catDef.SystemPrompt,
                        userPrompt:=catDef.UserPrompt,
                        inputMode:="text",
                        extractedText:=pageAnalysis.ExtractedText
                    )

                pageResult.IsSuccess = apiRes.IsSuccess
                pageResult.RawJsonOutput = apiRes.RawContent
                pageResult.ErrorMessage = apiRes.ErrorMessage
                pageResult.ExecutionTimeMs = apiRes.ExecutionTimeMs
                pageResult.PromptTokens = apiRes.PromptTokens
                pageResult.CompletionTokens = apiRes.CompletionTokens

            Else
                ' ── Visual OCR Path (FR-CM-59) ──
                pageResult.InputMode = "image"
                Dim tmpPngPath As String = Nothing

                Try
                    ' Render page to temporary PNG in {StagingDir}/_tmp/
                    tmpPngPath = PdfProcessingService.RenderPageToPng(
                        pdfPath:=stagedDoc.PhysicalDiskPath,
                        pageNumber:=pageAnalysis.PageNumber,
                        outputDirectory:=tmpDir
                    )

#If DEBUG Then
                    ' Service-level test hook: allows test suites to inject failures/timeouts after temporary file creation
                    If FailureInjectionHook IsNot Nothing Then
                        FailureInjectionHook.Invoke(tmpPngPath)
                    End If
#End If

                    Dim renderedBytes As Byte() = File.ReadAllBytes(tmpPngPath)

                    ' Send rendered page to Qwen3-VL
                    Dim apiRes As DeepInfraService.DeepInfraResult =
                        DeepInfraService.ExtractDocumentFields(
                            systemPrompt:=catDef.SystemPrompt,
                            userPrompt:=catDef.UserPrompt,
                            inputMode:="image",
                            imageBytes:=renderedBytes,
                            mimeType:="image/png"
                        )

                    pageResult.IsSuccess = apiRes.IsSuccess
                    pageResult.RawJsonOutput = apiRes.RawContent
                    pageResult.ErrorMessage = apiRes.ErrorMessage
                    pageResult.ExecutionTimeMs = apiRes.ExecutionTimeMs
                    pageResult.PromptTokens = apiRes.PromptTokens
                    pageResult.CompletionTokens = apiRes.CompletionTokens

                Catch ex As Exception
                    pageResult.IsSuccess = False
                    pageResult.ErrorMessage = "Visual page extraction failed: " & ex.Message
                Finally
                    ' FR-CM-69 GUARANTEE: Temporary PNG is deleted in this Finally block
                    ' regardless of success, API error, timeout, or unhandled exception.
                    If Not String.IsNullOrEmpty(tmpPngPath) Then
                        ApplicantStorageService.DeleteTemporaryArtifacts(tmpPngPath)
                    End If
                End Try
            End If

            docResult.Pages.Add(pageResult)
        Next
    End Sub

    ' ── Direct Image Processing Pipeline ───────────────────────────────────────
    Private Shared Sub ProcessImageDocument(
        stagedDoc As ApplicantStorageService.StagedDocument,
        catDef As ExtractionPromptCatalog.ExtractionCategoryDefinition,
        docResult As DocumentExtractionResult
    )
        Dim pageResult As New PageExtractionResult()
        pageResult.PageNumber = 1
        pageResult.InputMode = "image"

        ' Read original file (read-only; original is strictly preserved)
        Dim imageBytes As Byte() = File.ReadAllBytes(stagedDoc.PhysicalDiskPath)
        Dim mimeType As String = If(String.IsNullOrWhiteSpace(stagedDoc.ContentType), "image/jpeg", stagedDoc.ContentType)

        ' Optional in-memory downscaling if enabled in Web.config
        Dim maxSizeBytes As Long = GetConfigLong("ApplicantExtraction_MaxImageSizeBytes", 0L)
        If maxSizeBytes > 0 AndAlso imageBytes.Length > maxSizeBytes Then
            Dim downscaledBytes As Byte() = DownscaleImageInMemory(imageBytes, mimeType)
            If downscaledBytes IsNot Nothing AndAlso downscaledBytes.Length > 0 Then
                imageBytes = downscaledBytes
            End If
        End If

        ' Send to Qwen3-VL
        Dim apiRes As DeepInfraService.DeepInfraResult =
            DeepInfraService.ExtractDocumentFields(
                systemPrompt:=catDef.SystemPrompt,
                userPrompt:=catDef.UserPrompt,
                inputMode:="image",
                imageBytes:=imageBytes,
                mimeType:=mimeType
            )

        pageResult.IsSuccess = apiRes.IsSuccess
        pageResult.RawJsonOutput = apiRes.RawContent
        pageResult.ErrorMessage = apiRes.ErrorMessage
        pageResult.ExecutionTimeMs = apiRes.ExecutionTimeMs
        pageResult.PromptTokens = apiRes.PromptTokens
        pageResult.CompletionTokens = apiRes.CompletionTokens

        docResult.Pages.Add(pageResult)
    End Sub

    ' ── Optional In-Memory Image Downscaling ────────────────────────────────────
    Private Shared Function DownscaleImageInMemory(originalBytes As Byte(), mimeType As String) As Byte()
        Try
            Using inStream As New MemoryStream(originalBytes)
                Using originalBmp As New Bitmap(inStream)
                    ' Target max dimensions (provisional: 1920x1080)
                    Const maxDim As Integer = 1920
                    Dim origW As Integer = originalBmp.Width
                    Dim origH As Integer = originalBmp.Height

                    If origW <= maxDim AndAlso origH <= maxDim Then
                        Return originalBytes
                    End If

                    Dim ratio As Double = Math.Min(CDbl(maxDim) / origW, CDbl(maxDim) / origH)
                    Dim newW As Integer = CInt(origW * ratio)
                    Dim newH As Integer = CInt(origH * ratio)

                    Using scaledBmp As New Bitmap(newW, newH)
                        Using g As Graphics = Graphics.FromImage(scaledBmp)
                            g.InterpolationMode = InterpolationMode.HighQualityBicubic
                            g.SmoothingMode = SmoothingMode.HighQuality
                            g.PixelOffsetMode = PixelOffsetMode.HighQuality
                            g.DrawImage(originalBmp, 0, 0, newW, newH)
                        End Using

                        Using outStream As New MemoryStream()
                            Dim format As ImageFormat = If(mimeType.IndexOf("png", StringComparison.OrdinalIgnoreCase) >= 0,
                                                           ImageFormat.Png,
                                                           ImageFormat.Jpeg)
                            scaledBmp.Save(outStream, format)
                            Return outStream.ToArray()
                        End Using
                    End Using
                End Using
            End Using
        Catch ex As Exception
            ' If downscaling encounters any issue, fall back safely to original bytes
            Return originalBytes
        End Try
    End Function

    ' ── Configuration Helper ───────────────────────────────────────────────────
    Private Shared Function GetConfigLong(key As String, defaultValue As Long) As Long
        Dim valStr As String = System.Web.Configuration.WebConfigurationManager.AppSettings(key)
        If String.IsNullOrWhiteSpace(valStr) Then
            valStr = System.Configuration.ConfigurationManager.AppSettings(key)
        End If
        Dim result As Long = defaultValue
        If Not String.IsNullOrEmpty(valStr) AndAlso Long.TryParse(valStr.Trim(), result) Then
            Return result
        End If
        Return defaultValue
    End Function

End Class
