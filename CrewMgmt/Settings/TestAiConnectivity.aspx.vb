''' <summary>
''' PHASE B — AI Connectivity Test Page (code-behind)
''' Restricted to SUPER_ADMIN and ADMIN roles.
''' No database writes. No real applicant data. No API key exposure.
''' </summary>
Public Class TestAiConnectivity
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        RequireLogin()
        RequireRole(ROLE_SUPER_ADMIN, ROLE_ADMIN)
        If Not IsPostBack Then
            CType(Master, masterPage).lblPageTitle.Text = "AI Connectivity Test"
        End If
    End Sub

    ''' <summary>
    ''' Resolves the physical path of the synthetic test fixture (tests/fixtures/sample_test_doc.jpg).
    ''' Checks repo-level tests/fixtures/ relative to application base directory or physical path.
    ''' </summary>
    Public Shared Function GetSampleImagePath() As String
        Dim baseDir As String = AppDomain.CurrentDomain.BaseDirectory
        Dim appPhys As String = If(System.Web.Hosting.HostingEnvironment.IsHosted,
                                  System.Web.Hosting.HostingEnvironment.ApplicationPhysicalPath,
                                  baseDir)

        Dim candidatePaths As String() = {
            System.IO.Path.Combine(appPhys, "..", "tests", "fixtures", "sample_test_doc.jpg"),
            System.IO.Path.Combine(baseDir, "..", "tests", "fixtures", "sample_test_doc.jpg"),
            System.IO.Path.Combine(baseDir, "..", "..", "tests", "fixtures", "sample_test_doc.jpg"),
            System.IO.Path.Combine(baseDir, "tests", "fixtures", "sample_test_doc.jpg")
        }

        For Each p As String In candidatePaths
            Try
                Dim fullPath As String = System.IO.Path.GetFullPath(p)
                If System.IO.File.Exists(fullPath) Then
                    Return fullPath
                End If
            Catch
            End Try
        Next

        Return Nothing
    End Function

    ''' <summary>
    ''' Returns base64 data URI of the synthetic test fixture for display on the page.
    ''' Since the fixture is located in tests/fixtures/ outside the web root, this avoids HTTP 404s.
    ''' </summary>
    Public ReadOnly Property SampleImageBase64Src As String
        Get
            Dim p As String = GetSampleImagePath()
            If Not String.IsNullOrEmpty(p) AndAlso System.IO.File.Exists(p) Then
                Try
                    Return "data:image/jpeg;base64," & Convert.ToBase64String(System.IO.File.ReadAllBytes(p))
                Catch
                    Return ""
                End Try
            End If
            Return ""
        End Get
    End Property

    ' ── RunConnectivityTest ─────────────────────────────────────────────────────
    ' Triggered by the "Run Connectivity Test" button.
    '
    ' Workflow (Phase B only):
    '   1. Load the synthetic test image from tests/fixtures/sample_test_doc.jpg
    '   2. Call DeepInfraService.TestConnectivity() with the image bytes
    '   3. Bind the returned DeepInfraResult to the result panel controls
    '
    ' Guarantees:
    '   - Does NOT modify any database table.
    '   - Does NOT log, display, or return the API key.
    '   - Does NOT process any real applicant document or PII.
    '   - DeepInfra access occurs entirely server-side.
    Protected Sub RunConnectivityTest(sender As Object, e As EventArgs)
        panelResults.Visible = True

        ' 1. Locate and read the synthetic test image from tests/fixtures/sample_test_doc.jpg.
        Dim sampleImagePath As String = GetSampleImagePath()
        If String.IsNullOrEmpty(sampleImagePath) OrElse Not System.IO.File.Exists(sampleImagePath) Then
            ShowError("Synthetic test image not found at tests/fixtures/sample_test_doc.jpg. " &
                      "Please ensure the fixture exists in the tests/fixtures folder.")
            Return
        End If

        Dim imageBytes As Byte()
        Try
            imageBytes = System.IO.File.ReadAllBytes(sampleImagePath)
        Catch ex As Exception
            ShowError("Could not read the test image file: " & ex.Message)
            Return
        End Try

        ' 2. Call the DeepInfra service (entirely server-side).
        Dim result As DeepInfraService.DeepInfraResult = DeepInfraService.TestConnectivity(imageBytes, "image/jpeg")

        ' 3. Bind results to UI controls.
        panelMetrics.Visible = True
        lblHttpStatus.Text = If(result.HttpStatusCode > 0, result.HttpStatusCode.ToString() & If(result.IsSuccess, " OK", ""), "N/A")
        lblModelReported.Text = If(Not String.IsNullOrEmpty(result.ModelReported), Server.HtmlEncode(result.ModelReported), "Not returned in response")
        lblLatency.Text = result.ExecutionTimeMs & " ms"
        lblPromptTokens.Text = If(result.PromptTokens > 0, result.PromptTokens.ToString(), "—")
        lblCompletionTokens.Text = If(result.CompletionTokens > 0, result.CompletionTokens.ToString(), "—")
        lblTotalTokens.Text = If(result.TotalTokens > 0, result.TotalTokens.ToString(), "—")

        If result.IsSuccess Then
            lblStatusBanner.Text =
                "<div class='alert alert-success' style='font-size:13px;'>" &
                "<i class='fa fa-circle-check me-2'></i>" &
                "<strong>Connectivity Test Passed.</strong> " &
                "DeepInfra API responded successfully and Qwen3-VL processed the test image." &
                "</div>"
            litRawContent.Text = Server.HtmlEncode(result.RawContent)
        Else
            lblStatusBanner.Text =
                "<div class='alert alert-danger' style='font-size:13px;'>" &
                "<i class='fa fa-circle-exclamation me-2'></i>" &
                "<strong>Connectivity Test Failed.</strong> " &
                "See the error detail below." &
                "</div>"
            If Not String.IsNullOrEmpty(result.RawContent) Then
                litRawContent.Text = Server.HtmlEncode(result.RawContent)
            End If
            ShowError(result.ErrorMessage)
        End If
    End Sub

    ' ── ShowError ───────────────────────────────────────────────────────────────
    ' Displays an error detail panel. The error message must never contain the API key.
    Private Sub ShowError(message As String)
        panelError.Visible = True
        lblErrorDetail.Text = Server.HtmlEncode(message)
    End Sub

End Class
