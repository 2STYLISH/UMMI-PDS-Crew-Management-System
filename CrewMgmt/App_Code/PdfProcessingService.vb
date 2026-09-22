Imports System
Imports System.Collections.Generic
Imports System.IO
Imports UglyToad.PdfPig
Imports UglyToad.PdfPig.DocumentLayoutAnalysis.TextExtractor
Imports UglyToad.PdfPig.Rendering.Skia

''' <summary>
''' PHASE D — PDF Ingestion, Text Usability Routing, and Rendering Service (FR-CM-58)
''' Evaluates PDF documents for native text usability and renders scanned pages to PNG.
''' 
''' ARCHITECTURAL CONSTRAINTS:
''' - Never modifies, renames, or deletes the original staged PDF document.
''' - Enforces maximum page count before any text extraction or rendering begins.
''' - Applies the two-condition usability heuristic (character count + text density)
'''   to prevent image-dominant or mixed-content pages from misrouting to the text path.
''' - Renders scanned pages to temporary PNGs in the designated scratch directory.
''' - All numeric thresholds are configurable via Web.config and marked as provisional defaults.
''' </summary>
Public Class PdfProcessingService

    Public Class PdfPageAnalysisResult
        Public Property PageNumber As Integer = 0
        Public Property LetterCount As Integer = 0
        Public Property PageAreaPoints As Double = 0.0
        Public Property TextDensity As Double = 0.0
        Public Property IsTextUsable As Boolean = False
        Public Property ExtractedText As String = String.Empty
    End Class

    Public Class PdfAnalysisResult
        Public Property IsSuccess As Boolean = False
        Public Property PageCount As Integer = 0
        Public Property ErrorMessage As String = String.Empty
        Public Property Pages As New List(Of PdfPageAnalysisResult)()
    End Class

    ''' <summary>
    ''' Inspects the given PDF, enforces the page count limit, and evaluates each page's
    ''' embedded text against the two-condition usability heuristic (FR-CM-58).
    ''' </summary>
    Public Shared Function AnalyzePdf(pdfPath As String) As PdfAnalysisResult
        Dim result As New PdfAnalysisResult()

        If Not File.Exists(pdfPath) Then
            result.ErrorMessage = "The specified PDF file was not found on disk."
            Return result
        End If

        ' 1. Load provisional configuration values
        Dim maxPages As Integer = GetConfigInt("ApplicantUpload_MaxPdfPages", 10)
        Dim minChars As Integer = GetConfigInt("ApplicantExtraction_MinPdfTextChars", 50)
        Dim minDensity As Double = GetConfigDouble("ApplicantExtraction_MinPdfTextDensity", 0.001)

        Try
            Using doc As PdfDocument = PdfDocument.Open(pdfPath)
                result.PageCount = doc.NumberOfPages

                ' 2. Enforce page count limit
                If maxPages > 0 AndAlso doc.NumberOfPages > maxPages Then
                    result.ErrorMessage = String.Format(
                        "PDF document exceeds the maximum allowable page count of {0} pages (found {1} pages).",
                        maxPages, doc.NumberOfPages)
                    Return result
                End If

                ' 3. Evaluate each page
                For pageNum As Integer = 1 To doc.NumberOfPages
                    Dim pdfPage As UglyToad.PdfPig.Content.Page = doc.GetPage(pageNum)
                    Dim pageRes As New PdfPageAnalysisResult()
                    pageRes.PageNumber = pageNum

                    Dim letterCount As Integer = 0
                    If pdfPage.Letters IsNot Nothing Then
                        letterCount = pdfPage.Letters.Count
                    End If
                    pageRes.LetterCount = letterCount

                    Dim width As Double = pdfPage.Width
                    Dim height As Double = pdfPage.Height
                    Dim area As Double = width * height
                    pageRes.PageAreaPoints = area

                    Dim density As Double = 0.0
                    If area > 0 Then
                        density = CDbl(letterCount) / area
                    End If
                    pageRes.TextDensity = density

                    ' Two-condition usability heuristic:
                    ' Condition A: Raw letter count >= threshold
                    ' Condition B: Text density ratio >= threshold
                    Dim isUsable As Boolean = (letterCount >= minChars) AndAlso (density >= minDensity)
                    pageRes.IsTextUsable = isUsable

                    If isUsable Then
                        Try
                            pageRes.ExtractedText = ContentOrderTextExtractor.GetText(pdfPage)
                        Catch ex As Exception
                            ' If layout-order extraction fails, mark as unusable to trigger visual OCR fallback
                            pageRes.IsTextUsable = False
                            pageRes.ExtractedText = String.Empty
                        End Try
                    End If

                    result.Pages.Add(pageRes)
                Next

                result.IsSuccess = True
            End Using

        Catch ex As Exception
            result.IsSuccess = False
            result.ErrorMessage = "Failed to parse PDF document: " & ex.Message
        End Try

        Return result
    End Function

    ''' <summary>
    ''' Renders a single PDF page to a temporary PNG file on disk for visual OCR processing.
    ''' The caller is strictly responsible for deleting the generated file in a Finally block.
    ''' </summary>
    Public Shared Function RenderPageToPng(pdfPath As String, pageNumber As Integer, outputDirectory As String) As String
        If Not Directory.Exists(outputDirectory) Then
            Directory.CreateDirectory(outputDirectory)
        End If

        Dim renderDpi As Single = CSng(GetConfigDouble("ApplicantExtraction_RenderDpi", 150.0))
        If renderDpi < 72.0F Then renderDpi = 150.0F
        Dim scale As Single = renderDpi / 72.0F

        Dim uniqueId As String = Guid.NewGuid().ToString("N")
        Dim targetFilename As String = String.Format("page_{0}_{1}.png", pageNumber, uniqueId)
        Dim targetPath As String = Path.Combine(outputDirectory, targetFilename)

        Using doc As PdfDocument = PdfDocument.Open(pdfPath)
            If pageNumber < 1 OrElse pageNumber > doc.NumberOfPages Then
                Throw New ArgumentOutOfRangeException("pageNumber", "Requested page number is out of range.")
            End If

            ' Initialize Skia rendering extension
            PdfPigExtensions.AddSkiaPageFactory(doc)

            ' Render page to PNG stream at specified scale
            Using ms As MemoryStream = PdfPigExtensions.GetPageAsPng(doc, pageNumber, scale, 100)
                File.WriteAllBytes(targetPath, ms.ToArray())
            End Using
        End Using

        Return targetPath
    End Function

    ' ── Configuration Helpers ──────────────────────────────────────────────────
    Private Shared Function GetConfigInt(key As String, defaultValue As Integer) As Integer
        Dim valStr As String = System.Web.Configuration.WebConfigurationManager.AppSettings(key)
        If String.IsNullOrWhiteSpace(valStr) Then
            valStr = System.Configuration.ConfigurationManager.AppSettings(key)
        End If
        Dim result As Integer = defaultValue
        If Not String.IsNullOrEmpty(valStr) AndAlso Integer.TryParse(valStr.Trim(), result) Then
            Return result
        End If
        Return defaultValue
    End Function

    Private Shared Function GetConfigDouble(key As String, defaultValue As Double) As Double
        Dim valStr As String = System.Web.Configuration.WebConfigurationManager.AppSettings(key)
        If String.IsNullOrWhiteSpace(valStr) Then
            valStr = System.Configuration.ConfigurationManager.AppSettings(key)
        End If
        Dim result As Double = defaultValue
        If Not String.IsNullOrEmpty(valStr) AndAlso Double.TryParse(valStr.Trim(), System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, result) Then
            Return result
        End If
        Return defaultValue
    End Function

End Class
