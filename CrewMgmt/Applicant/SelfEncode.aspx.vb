Imports MySql.Data.MySqlClient

Public Class SelfEncode
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' Session re-hydration after app restart / session timeout when FormsAuthentication cookie is present
        If (Session("UserType") Is Nothing OrElse Session("ApplicantLinkID") Is Nothing) AndAlso
           User IsNot Nothing AndAlso User.Identity IsNot Nothing AndAlso User.Identity.IsAuthenticated Then
            If User.Identity.Name.StartsWith("LNK-", StringComparison.OrdinalIgnoreCase) Then
                Dim authLinkId As String = User.Identity.Name.Substring(4)
                Dim lidInt As Integer
                Dim isValid As Boolean = False
                Dim applicantName As String = Nothing
                If Integer.TryParse(authLinkId, lidInt) AndAlso lidInt > 0 Then
                    Try
                        Using cn As New MySqlConnection(DbHelper.ConnStr)
                            cn.Open()
                            Using cmd As New MySqlCommand("SELECT fullname FROM tbl_applicant_generated_link WHERE id=@lid AND status='Active' AND (validity IS NULL OR validity >= NOW()) LIMIT 1", cn)
                                cmd.Parameters.AddWithValue("@lid", authLinkId)
                                Dim objName As Object = cmd.ExecuteScalar()
                                If objName IsNot Nothing AndAlso Not Convert.IsDBNull(objName) Then
                                    applicantName = objName.ToString()
                                    isValid = True
                                End If
                            End Using
                        End Using
                    Catch
                        isValid = False
                    End Try
                End If

                If isValid Then
                    Session("UserID") = User.Identity.Name
                    Session("ApplicantLinkID") = authLinkId
                    Session("UserType") = "APPLICANT"
                    Session("UserViewCrewContactDetails") = "0"
                    Session("UserFullname") = applicantName
                    ' Also rehydrate first/last name from link_token if available
                    Try
                        Using cnTok As New MySqlConnection(DbHelper.ConnStr)
                            cnTok.Open()
                            Using cmdTok As New MySqlCommand("SELECT link_token FROM tbl_applicant_generated_link WHERE id=@lid", cnTok)
                                cmdTok.Parameters.AddWithValue("@lid", authLinkId)
                                Dim tokObj As Object = cmdTok.ExecuteScalar()
                                If tokObj IsNot Nothing AndAlso Not Convert.IsDBNull(tokObj) Then
                                    Dim tokStr As String = tokObj.ToString()
                                    Dim qIdx As Integer = tokStr.IndexOf("?e=")
                                    If qIdx >= 0 Then
                                        Dim encE As String = tokStr.Substring(qIdx + 3)
                                        Dim decE As String = Decrypt(HttpUtility.UrlDecode(encE))
                                        If Not String.IsNullOrEmpty(decE) Then
                                            Dim p2 As System.Collections.Specialized.NameValueCollection = System.Web.HttpUtility.ParseQueryString(decE)
                                            Session("ApplicantFirstName") = p2("fn")
                                            Session("ApplicantLastName") = p2("ln")
                                        End If
                                    End If
                                End If
                            End Using
                        End Using
                    Catch
                    End Try
                    If Session("ApplicantCsrfToken") Is Nothing Then
                        Session("ApplicantCsrfToken") = Guid.NewGuid().ToString("N")
                    End If
                Else
                    FormsAuthentication.SignOut()
                    Session.Clear()
                    Session.Abandon()
                    Response.Redirect("~/Applicant/AccessDenied.aspx", True)
                    Return
                End If
            End If
        End If

        ' UC-CM-15: mode=add allows internal staff (Manning Staff, Doc Officer, Super Admin, Admin) to add applicants manually
        Dim isAddMode As Boolean = (Request.QueryString("mode") = "add")
        If isAddMode Then
            If Not HasInternalStaffAccess() Then
                Response.Redirect("~/login.aspx", True)
                Return
            End If
        Else
            ' UC-CM-24: Normal self-encode access — allow APPLICANT and internal staff (Manning/Admin)
            If Not HasApplicantAccess() AndAlso Not HasInternalStaffAccess() Then
                Response.Redirect("~/Applicant/AccessDenied.aspx", True)
                Return
            End If
        End If

        If Not IsPostBack Then
            CType(Master, masterPage).lblPageTitle.Text = If(isAddMode, "Add Applicant", "My Application")
            LoadDropdowns()
            ' Pre-fill name, email, and position from link (or leave blank for add mode)
            If Not isAddMode Then
                If Session("ApplicantLastName") IsNot Nothing AndAlso Not String.IsNullOrEmpty(Session("ApplicantLastName").ToString()) Then
                    txtLastName.Text = Session("ApplicantLastName").ToString()
                Else
                    txtLastName.Text = If(Session("UserFullname") IsNot Nothing, Session("UserFullname").ToString(), "")
                End If

                If Session("ApplicantFirstName") IsNot Nothing AndAlso Not String.IsNullOrEmpty(Session("ApplicantFirstName").ToString()) Then
                    txtFirstName.Text = Session("ApplicantFirstName").ToString()
                End If

                If Session("ApplicantLinkID") IsNot Nothing Then
                    Try
                        Using cnLink As New MySqlConnection(DbHelper.ConnStr)
                            cnLink.Open()
                            Using cmdLink As New MySqlCommand("SELECT email, position_applied FROM tbl_applicant_generated_link WHERE id=@lid", cnLink)
                                cmdLink.Parameters.AddWithValue("@lid", Session("ApplicantLinkID").ToString())
                                Using drL As MySqlDataReader = cmdLink.ExecuteReader()
                                    If drL.Read() Then
                                        If String.IsNullOrEmpty(txtEmail.Text) AndAlso Not Convert.IsDBNull(drL("email")) Then
                                            txtEmail.Text = drL("email").ToString()
                                        End If
                                        If drpdwnRank.SelectedIndex <= 0 AndAlso Not Convert.IsDBNull(drL("position_applied")) Then
                                            Dim posCode As String = drL("position_applied").ToString().Trim()
                                            Dim itemByText As System.Web.UI.WebControls.ListItem = drpdwnRank.Items.FindByText(posCode)
                                            If itemByText IsNot Nothing Then
                                                drpdwnRank.SelectedValue = itemByText.Value
                                            End If
                                        End If
                                    End If
                                End Using
                            End Using
                        End Using
                    Catch
                    End Try
                End If
            End If
        End If

        ' Phase F.1: Anti-CSRF token initialization for secure applicant actions
        If Session("ApplicantCsrfToken") Is Nothing Then
            Session("ApplicantCsrfToken") = Guid.NewGuid().ToString("N")
        End If
        hfApplicantCsrfToken.Value = CStr(Session("ApplicantCsrfToken"))
    End Sub

    Private Sub LoadDropdowns()
        ' Religions
        PopulateDropdownWithOther(drpdwnReligion, "SELECT id, religion FROM tbl_religion ORDER BY religion", "religion", "id", "Select...")

        ' Nationalities
        PopulateDropdownWithOther(drpdwnNationality, "SELECT id, nationality FROM tbl_nationality ORDER BY nationality", "nationality", "id", "Select...")

        ' Ranks
        Dim dtRnk As System.Data.DataTable = DbHelper.FillDataTable("SELECT id,rank_code FROM tbl_rank ORDER BY rank_type,sequence", System.Data.CommandType.Text)
        drpdwnRank.Items.Clear()
        drpdwnRank.Items.Add(New System.Web.UI.WebControls.ListItem("Select position...", ""))
        For Each row As System.Data.DataRow In dtRnk.Rows
            drpdwnRank.Items.Add(New System.Web.UI.WebControls.ListItem(row("rank_code").ToString(), row("id").ToString()))
        Next

        ' Provinces / Cities
        LoadProvinces()
        LoadCities(0)

        ' Schools
        PopulateDropdownWithOther(drpdwnSchool, "SELECT id, school_name FROM tbl_school ORDER BY school_name", "school_name", "id", "Select school...")

        ' Courses
        PopulateDropdownWithOther(drpdwnCourse, "SELECT id, course FROM tbl_course ORDER BY course", "course", "id", "Select course...")
    End Sub

    ' ── PopulateDropdownWithOther ───────────────────────────────────────────
    ' Loads DB items (excluding any "Other" variants) then appends exactly one
    ' "Others (Please specify)" item at the bottom with value="other".
    Private Sub PopulateDropdownWithOther(ddl As System.Web.UI.WebControls.DropDownList, query As String, textField As String, idField As String, placeholder As String)
        Dim dt As System.Data.DataTable = DbHelper.FillDataTable(query, System.Data.CommandType.Text)
        ddl.Items.Clear()
        ddl.Items.Add(New System.Web.UI.WebControls.ListItem(placeholder, ""))
        For Each row As System.Data.DataRow In dt.Rows
            Dim textVal As String = row(textField).ToString().Trim()
            Dim idVal As String = row(idField).ToString()
            If Not IsOtherVariation(textVal) Then
                ddl.Items.Add(New System.Web.UI.WebControls.ListItem(textVal, idVal))
            End If
        Next
        ddl.Items.Add(New System.Web.UI.WebControls.ListItem("Others (Please specify)", "other"))
    End Sub

    Private Function IsOtherVariation(text As String) As Boolean
        Dim t As String = text.Trim().ToLower()
        Return t = "other" OrElse t = "others" OrElse t.StartsWith("others (")
    End Function

    Private Sub LoadProvinces()
        drpdwnProvince.Items.Clear()
        drpdwnProvince.Items.Add(New System.Web.UI.WebControls.ListItem("Select province...", ""))
        Dim dt As System.Data.DataTable = DbHelper.FillDataTable("SELECT id,provinces FROM tbl_provinces ORDER BY provinces", System.Data.CommandType.Text)
        For Each row As System.Data.DataRow In dt.Rows
            drpdwnProvince.Items.Add(New System.Web.UI.WebControls.ListItem(row("provinces").ToString(), row("id").ToString()))
        Next
    End Sub

    Private Sub LoadCities(provinceID As Integer)
        drpdwnCity.Items.Clear()
        drpdwnCity.Items.Add(New System.Web.UI.WebControls.ListItem("Select city...", ""))
        Dim sql As String = "SELECT id,cities FROM tbl_cities "
        If provinceID > 0 Then sql &= "WHERE province=@pid "
        sql &= "ORDER BY cities"
        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                If provinceID > 0 Then cmd.Parameters.AddWithValue("@pid", provinceID)
                Using dr As MySqlDataReader = cmd.ExecuteReader()
                    Do While dr.Read()
                        drpdwnCity.Items.Add(New System.Web.UI.WebControls.ListItem(dr("cities").ToString(), dr("id").ToString()))
                    Loop
                End Using
            End Using
        End Using
    End Sub

    Protected Sub ProvinceChanged(sender As Object, e As EventArgs)
        Dim pid As Integer = 0
        Integer.TryParse(drpdwnProvince.SelectedValue, pid)
        LoadCities(pid)
        hfCurrentStep.Value = "2"
    End Sub

    Private Function ValidateApplicantAge(dobText As String, ByRef outDob As DateTime, ByRef errorMessage As String) As Boolean
        If String.IsNullOrWhiteSpace(dobText) Then
            errorMessage = "Date of Birth is required."
            Return False
        End If

        Dim parsedDob As DateTime
        Dim dateFormats As String() = {"yyyy-MM-dd", "MM/dd/yyyy", "dd/MM/yyyy", "M/d/yyyy", "d/M/yyyy", "yyyy/MM/dd"}
        If Not DateTime.TryParseExact(dobText.Trim(), dateFormats, System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, parsedDob) Then
            If Not DateTime.TryParse(dobText.Trim(), parsedDob) Then
                errorMessage = "Please enter a valid calendar Date of Birth."
                Return False
            End If
        End If

        Dim today As DateTime = DateTime.Today
        If parsedDob.Date > today Then
            errorMessage = "Date of Birth cannot be in the future."
            Return False
        End If

        ' Exact date-based age calculation (cannot assume current year - birth year >= 18)
        Dim age As Integer = today.Year - parsedDob.Year
        If parsedDob.Date > today.AddYears(-age) Then
            age -= 1
        End If

        If age < 18 Then
            errorMessage = "Applicant must be at least 18 years old to apply."
            Return False
        End If

        outDob = parsedDob
        Return True
    End Function

    ' UC-CM-24: Submit self-encoded application
    Protected Sub SubmitApplication(sender As Object, e As EventArgs)

        ' ── Server-side Age & Date of Birth Validation (Exact boundary calculation) ──
        Dim applicantDob As DateTime
        Dim dobError As String = ""
        If Not ValidateApplicantAge(txtDOB.Text, applicantDob, dobError) Then
            lblNotify.Text = "<div class='alert alert-danger'><i class='fa fa-circle-exclamation me-2'></i>" & Server.HtmlEncode(dobError) & "</div>"
            Return
        End If

        ' ── Server-side Required Field Validation (Issue 2: All applicant fields) ──
        Dim missingFields As New List(Of String)()

        If String.IsNullOrWhiteSpace(txtLastName.Text) Then missingFields.Add("Last Name")
        If String.IsNullOrWhiteSpace(txtFirstName.Text) Then missingFields.Add("First Name")
        If String.IsNullOrWhiteSpace(txtPOB.Text) Then missingFields.Add("Place of Birth")
        If String.IsNullOrWhiteSpace(drpdwnGender.SelectedValue) Then missingFields.Add("Gender")
        If String.IsNullOrWhiteSpace(drpdwnCivilStatus.SelectedValue) Then missingFields.Add("Civil Status")

        If String.IsNullOrWhiteSpace(drpdwnReligion.SelectedValue) Then
            missingFields.Add("Religion")
        ElseIf drpdwnReligion.SelectedValue = "other" AndAlso String.IsNullOrWhiteSpace(txtReligionOther.Text) Then
            missingFields.Add("Religion (Please specify)")
        End If

        If String.IsNullOrWhiteSpace(drpdwnNationality.SelectedValue) Then
            missingFields.Add("Nationality")
        ElseIf drpdwnNationality.SelectedValue = "other" AndAlso String.IsNullOrWhiteSpace(txtNationalityOther.Text) Then
            missingFields.Add("Nationality (Please specify)")
        End If

        Dim heightVal As Decimal = 0
        If String.IsNullOrWhiteSpace(txtHeight.Text) OrElse Not Decimal.TryParse(txtHeight.Text.Trim(), heightVal) OrElse heightVal <= 0 Then
            missingFields.Add("Height (valid positive number in cm)")
        End If

        Dim weightVal As Decimal = 0
        If String.IsNullOrWhiteSpace(txtWeight.Text) OrElse Not Decimal.TryParse(txtWeight.Text.Trim(), weightVal) OrElse weightVal <= 0 Then
            missingFields.Add("Weight (valid positive number in kg)")
        End If

        If String.IsNullOrWhiteSpace(drpdwnBloodType.SelectedValue) Then missingFields.Add("Blood Type")
        If String.IsNullOrWhiteSpace(drpdwnRank.SelectedValue) OrElse drpdwnRank.SelectedIndex <= 0 Then missingFields.Add("Applied Rank")

        If String.IsNullOrWhiteSpace(txtContact.Text) Then missingFields.Add("Contact Number")

        If String.IsNullOrWhiteSpace(txtEmail.Text) Then
            missingFields.Add("Email Address")
        Else
            Try
                Dim m As New System.Net.Mail.MailAddress(txtEmail.Text.Trim())
            Catch
                missingFields.Add("Valid Email Address")
            End Try
        End If

        If String.IsNullOrWhiteSpace(txtAddress.Text) Then missingFields.Add("Address")
        If String.IsNullOrWhiteSpace(drpdwnProvince.SelectedValue) OrElse drpdwnProvince.SelectedValue = "0" OrElse drpdwnProvince.SelectedIndex <= 0 Then
            missingFields.Add("Province")
        End If
        If String.IsNullOrWhiteSpace(drpdwnCity.SelectedValue) OrElse drpdwnCity.SelectedValue = "0" OrElse drpdwnCity.SelectedIndex <= 0 Then
            missingFields.Add("City / Municipality")
        End If

        If String.IsNullOrWhiteSpace(drpdwnSchool.SelectedValue) Then
            missingFields.Add("School / University")
        ElseIf drpdwnSchool.SelectedValue = "other" AndAlso String.IsNullOrWhiteSpace(txtSchoolOther.Text) Then
            missingFields.Add("School / University (Please specify)")
        End If

        If String.IsNullOrWhiteSpace(drpdwnCourse.SelectedValue) Then
            missingFields.Add("Course")
        ElseIf drpdwnCourse.SelectedValue = "other" AndAlso String.IsNullOrWhiteSpace(txtCourseOther.Text) Then
            missingFields.Add("Course (Please specify)")
        End If

        If missingFields.Count > 0 Then
            lblNotify.Text = "<div class='alert alert-danger'><i class='fa fa-circle-exclamation me-2'></i>Please complete all required fields: " &
                Server.HtmlEncode(String.Join(", ", missingFields)) & ".</div>"
            Return
        End If

        ' ── Validate applicant link state (G-08) ──────────────────────────────
        If Session("ApplicantLinkID") IsNot Nothing Then
            Dim checkLinkId As String = Session("ApplicantLinkID").ToString()
            Dim linkStatusObj As Object = DbHelper.ExecuteScalar(
                "SELECT status FROM tbl_applicant_generated_link WHERE id=@lid AND (validity IS NULL OR validity >= NOW()) LIMIT 1",
                New MySqlParameter("@lid", checkLinkId))
            If linkStatusObj Is Nothing OrElse Not String.Equals(linkStatusObj.ToString(), "Active", StringComparison.OrdinalIgnoreCase) Then
                lblNotify.Text = "<div class='alert alert-danger'><i class='fa fa-circle-exclamation me-2'></i>This applicant link has expired, been used, or revoked.</div>"
                Return
            End If
        End If

        Dim sql As String = "INSERT INTO tbl_personnel_info " &
            "(firstname, middlename, lastname, suffix, position, religion, nationality, " &
            " school_name, course, date_of_birth, place_of_birth, gender, civil_status, " &
            " height, weight, blood_type, email_address, applicant_contact_num, address, province, city, " &
            " crew_status, crew_availability, date_added) " &
            "VALUES (@fn,@mn,@ln,@sfx,@pos,@rel,@nat,@sch,@crs,@dob,@pob,@gen,@civ," &
            "  @ht,@wt,@bt,@em,@ct,@addr,@prov,@city,5,1,NOW()); SELECT LAST_INSERT_ID();"

        Dim newPersonnelId As Integer = 0
        Dim copiedPermanentFiles As New List(Of String)()
        Dim submissionSuccess As Boolean = False

        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using tran As MySqlTransaction = cn.BeginTransaction()
                Try
                    ' ── Concurrency & Double-Submission Guard (TC-CM-172 / FR-CM-75) ──
                    If Session("ApplicantLinkID") IsNot Nothing Then
                        Dim linkID As String = Session("ApplicantLinkID").ToString()
                        Dim sqlCheckLock As String = "SELECT status, validity FROM tbl_applicant_generated_link WHERE id=@lid FOR UPDATE"
                        Using cmdCheckLock As New MySqlCommand(sqlCheckLock, cn, tran)
                            cmdCheckLock.Parameters.AddWithValue("@lid", linkID)
                            Using drLock As MySqlDataReader = cmdCheckLock.ExecuteReader()
                                If Not drLock.Read() Then
                                    Throw New ApplicationException("Applicant link not found.")
                                End If
                                Dim curStatus As String = drLock("status").ToString()
                                Dim curValidity As Object = drLock("validity")
                                drLock.Close()

                                If Not String.Equals(curStatus, "Active", StringComparison.OrdinalIgnoreCase) Then
                                    Throw New ApplicationException("This applicant link has already been used or is no longer active.")
                                End If
                                If curValidity IsNot Nothing AndAlso Not Convert.IsDBNull(curValidity) Then
                                    If Convert.ToDateTime(curValidity) < DateTime.Now Then
                                        Throw New ApplicationException("This applicant link has expired.")
                                    End If
                                End If
                            End Using
                        End Using
                    End If

                    Using cmd As New MySqlCommand(sql, cn, tran)
                        cmd.Parameters.AddWithValue("@fn",   txtFirstName.Text.Trim())
                        cmd.Parameters.AddWithValue("@mn",   If(String.IsNullOrWhiteSpace(txtMiddleName.Text), DBNull.Value, CObj(txtMiddleName.Text.Trim())))
                        cmd.Parameters.AddWithValue("@ln",   txtLastName.Text.Trim())
                        cmd.Parameters.AddWithValue("@sfx",  drpdwnSuffix.SelectedValue)
                        cmd.Parameters.AddWithValue("@pos",  If(drpdwnRank.SelectedValue = "", DBNull.Value, CObj(drpdwnRank.SelectedValue)))
                        cmd.Parameters.AddWithValue("@rel",  SafeResolveLookupId(drpdwnReligion.SelectedValue,    "tbl_religion",    "religion"))
                        cmd.Parameters.AddWithValue("@nat",  SafeResolveLookupId(drpdwnNationality.SelectedValue, "tbl_nationality", "nationality"))
                        cmd.Parameters.AddWithValue("@sch",  SafeResolveLookupId(drpdwnSchool.SelectedValue,      "tbl_school",      "school_name"))
                        cmd.Parameters.AddWithValue("@crs",  SafeResolveLookupId(drpdwnCourse.SelectedValue,      "tbl_course",      "course"))
                        cmd.Parameters.AddWithValue("@dob",  applicantDob.Date)
                        cmd.Parameters.AddWithValue("@pob",  txtPOB.Text.Trim())
                        cmd.Parameters.AddWithValue("@gen",  drpdwnGender.SelectedValue)
                        cmd.Parameters.AddWithValue("@civ",  drpdwnCivilStatus.SelectedValue)
                        cmd.Parameters.AddWithValue("@ht",   heightVal)
                        cmd.Parameters.AddWithValue("@wt",   weightVal)
                        cmd.Parameters.AddWithValue("@bt",   drpdwnBloodType.SelectedValue)
                        cmd.Parameters.AddWithValue("@em",   txtEmail.Text.Trim())
                        cmd.Parameters.AddWithValue("@ct",   txtContact.Text.Trim())
                        cmd.Parameters.AddWithValue("@addr", txtAddress.Text.Trim())
                        cmd.Parameters.AddWithValue("@prov", If(drpdwnProvince.SelectedValue = "", DBNull.Value, CObj(drpdwnProvince.SelectedValue)))
                        cmd.Parameters.AddWithValue("@city", If(drpdwnCity.SelectedValue = "",    DBNull.Value, CObj(drpdwnCity.SelectedValue)))

                        Dim newID As Object = cmd.ExecuteScalar()
                        If newID IsNot Nothing AndAlso Not Convert.IsDBNull(newID) Then
                            Integer.TryParse(newID.ToString(), newPersonnelId)
                        End If
                    End Using

                    If newPersonnelId <= 0 Then
                        Throw New ApplicationException("Failed to generate personnel record.")
                    End If

                    ' Update link record with personnel_id INSIDE the transaction with Active status guard
                    If Session("ApplicantLinkID") IsNot Nothing Then
                        Dim linkID As String = Session("ApplicantLinkID").ToString()
                        Dim sqlLink As String = "UPDATE tbl_applicant_generated_link SET status='Used', personnel_id=@pid, last_date_access=NOW() WHERE id=@lid AND status='Active'"
                        Using cmdLink As New MySqlCommand(sqlLink, cn, tran)
                            cmdLink.Parameters.AddWithValue("@pid", newPersonnelId)
                            cmdLink.Parameters.AddWithValue("@lid", linkID)
                            Dim rowsAffected As Integer = cmdLink.ExecuteNonQuery()
                            If rowsAffected = 0 Then
                                Throw New ApplicationException("Failed to update applicant link. Link may have already been consumed.")
                            End If
                        End Using
                    End If

                    ' ── Phase G.2/G.3: Persist accepted AI repeating records inside transaction ──
                    PersistAiRepeatingRecords(newPersonnelId, cn, tran, copiedPermanentFiles)

                    ' Commit entire transaction atomically
                    tran.Commit()
                    submissionSuccess = True

                    ' Audit activity log
                    Try
                        GetAdmin("Self-Encoded Application", newPersonnelId.ToString(), "SelfEncode",
                            txtLastName.Text.Trim() & ", " & txtFirstName.Text.Trim())
                    Catch
                    End Try

                Catch ex As Exception
                    ' Atomic Rollback
                    Try
                        tran.Rollback()
                    Catch
                    End Try

                    ' File operation compensation: remove only files created during this failed submit
                    For Each permPath As String In copiedPermanentFiles
                        Try
                            If System.IO.File.Exists(permPath) Then
                                System.IO.File.Delete(permPath)
                            End If
                        Catch
                        End Try
                    Next

                    lblNotify.Text = "<div class='alert alert-danger'><i class='fa fa-circle-exclamation me-2'></i>" &
                        "An error occurred while submitting your application: " & Server.HtmlEncode(ex.Message) & "</div>"
                    Return
                End Try
            End Using
        End Using

        ' Display success only after verified commit
        lblNotify.Text = "<div class='alert alert-success'><i class='fa fa-circle-check me-2'></i>" &
            "Your application has been submitted successfully! The Manning Office will review your information. " &
            "Thank you, " & Server.HtmlEncode(txtFirstName.Text.Trim()) & "!</div>"

        ' Phase G.4: Trigger async staging cleanup ONLY after successful commit
        Dim sessionIdToClean As String = Session.SessionID
        Dim linkIdToClean As String = If(Session("ApplicantLinkID"), "").ToString()
        System.Web.Hosting.HostingEnvironment.QueueBackgroundWorkItem(Sub(ct)
            Try
                If Not String.IsNullOrWhiteSpace(sessionIdToClean) Then
                    Dim dir As String = ApplicantStorageService.GetStagingPhysicalDirectory(sessionIdToClean)
                    ApplicantStorageService.DeleteTemporaryArtifacts(dir)
                End If
                If Not String.IsNullOrWhiteSpace(linkIdToClean) AndAlso linkIdToClean <> "0" Then
                    Dim linkDir As String = ApplicantStorageService.GetStagingPhysicalDirectory("link_" & linkIdToClean)
                    ApplicantStorageService.DeleteTemporaryArtifacts(linkDir)
                End If
            Catch
            End Try
        End Sub)

        ' Clear session after successful submit
        Session.Clear()
        Session.Abandon()
    End Sub

    ' ── Phase G.2/G.3: PersistAiRepeatingRecords ──────────────────────────────
    ''' <summary>
    ''' Phase G: Reads hfAiRepeatingDecisions (client-serialized accepted decisions),
    ''' retrieves the authoritative server-side extraction package (GetAuthoritativePackage),
    ''' validates each accepted record against the authoritative index inside the caller transaction:
    '''   - Accepted sea service records into tbl_personnel_sea_service
    '''   - Accepted document records into tbl_personnel_documents (with file promotion from staging)
    '''
    ''' SECURITY & INTEGRITY:
    '''   - Single MySqlTransaction: rolls back if any step fails
    '''   - In-memory compensation list tracks newly-created permanent files for deletion on rollback
    '''   - Index-based record matching prevents injection of fabricated records
    '''   - UMMI vs External vessel rule: UMMI sets vessel_id, vessel_name=NULL; External sets vessel_id=NULL, vessel_name=name
    '''   - Document type FK validated against tbl_documents
    '''   - Staged files validated against authoritative package staged docs
    ''' </summary>
    Private Sub PersistAiRepeatingRecords(personnelId As Integer, cn As MySqlConnection, tran As MySqlTransaction, copiedPermanentFiles As List(Of String))
        Dim rawDecisions As String = hfAiRepeatingDecisions.Value
        If String.IsNullOrWhiteSpace(rawDecisions) Then Return

        Dim jobId As String = hfAiJobId.Value
        Dim sessionId As String = Session.SessionID
        Dim linkId As String = If(Session("ApplicantLinkID"), "").ToString()

        ' Retrieve authoritative package from cache or disk
        Dim outStagedDocs As List(Of ApplicantStorageService.StagedDocument) = Nothing
        Dim pkg As PdsMappingModels.PdsExtractionSuggestionPackage =
            ApplicantExtractionJobManager.GetAuthoritativePackage(jobId, sessionId, linkId, outStagedDocs)

        If pkg Is Nothing Then Return ' No AI extraction completed or cross-applicant mismatch — skip safely

        ' Parse client decision payload
        Dim serializer As New System.Web.Script.Serialization.JavaScriptSerializer() With {.MaxJsonLength = 512000}
        Dim payload As Dictionary(Of String, Object) = Nothing
        Try
            payload = TryCast(serializer.DeserializeObject(rawDecisions), Dictionary(Of String, Object))
        Catch
            Return
        End Try
        If payload Is Nothing Then Return

        ' ── G.2: Sea Service Records ───────────────────────────────────────────
        Dim authSeas As List(Of PdsMappingModels.PdsSeaServiceSuggestion) = pkg.SeaServiceRecords
        If authSeas IsNot Nothing AndAlso authSeas.Count > 0 Then
            Dim seaItems As Object() = Nothing
            If payload.ContainsKey("AcceptedSeaService") Then
                seaItems = TryCast(payload("AcceptedSeaService"), Object())
            End If
            If seaItems IsNot Nothing Then
                For Each itemObj As Object In seaItems
                    Dim item As Dictionary(Of String, Object) = TryCast(itemObj, Dictionary(Of String, Object))
                    If item Is Nothing Then Continue For

                    ' Validate index against authoritative package (G-06)
                    Dim idx As Integer = -1
                    If Not item.ContainsKey("Index") OrElse Not Integer.TryParse(item("Index").ToString(), idx) Then
                        Throw New ApplicationException("Forged or missing sea service suggestion index.")
                    End If
                    If idx < 0 OrElse idx >= authSeas.Count Then
                        Throw New ApplicationException("Sea service suggestion index out of bounds.")
                    End If

                    Dim auth As PdsMappingModels.PdsSeaServiceSuggestion = authSeas(idx)

                    ' Resolve vessel (UMMI vs External vessel rule — Section 7)
                    Dim vesselId As Object = DBNull.Value
                    Dim vesselName As Object = DBNull.Value

                    Dim candidateVesselId As Integer = 0
                    Dim hasCandidateVesselId As Boolean = False
                    If item.ContainsKey("VesselId") AndAlso item("VesselId") IsNot Nothing AndAlso
                       Integer.TryParse(item("VesselId").ToString(), candidateVesselId) AndAlso candidateVesselId > 0 Then
                        hasCandidateVesselId = True
                    ElseIf auth.VesselId.HasValue AndAlso auth.VesselId.Value > 0 Then
                        candidateVesselId = auth.VesselId.Value
                        hasCandidateVesselId = True
                    End If

                    If hasCandidateVesselId Then
                        ' Validate that the vessel ID actually exists in tbl_vessels
                        Using vCmd As New MySqlCommand("SELECT COUNT(*) FROM tbl_vessels WHERE id = @vid", cn, tran)
                            vCmd.Parameters.AddWithValue("@vid", candidateVesselId)
                            Dim vExists As Object = vCmd.ExecuteScalar()
                            If vExists IsNot Nothing AndAlso Convert.ToInt32(vExists) > 0 Then
                                ' UMMI vessel: valid vessel_id, vessel_name MUST be NULL
                                vesselId = candidateVesselId
                                vesselName = DBNull.Value
                            Else
                                ' Forged/invalid vessel_id: treated as external vessel
                                vesselId = DBNull.Value
                                Dim cVslName As String = GetStrField(item, "VesselName")
                                Dim vNameStr As String = If(Not String.IsNullOrWhiteSpace(cVslName), cVslName.Trim(), If(auth.VesselName, "").Trim())
                                If vNameStr.Length > 200 Then vNameStr = vNameStr.Substring(0, 200)
                                vesselName = If(String.IsNullOrWhiteSpace(vNameStr), DBNull.Value, CObj(vNameStr))
                            End If
                        End Using
                    Else
                        ' External vessel: vessel_id MUST be NULL, vessel_name contains external vessel name
                        vesselId = DBNull.Value
                        Dim cVslName As String = GetStrField(item, "VesselName")
                        Dim vNameStr As String = If(Not String.IsNullOrWhiteSpace(cVslName), cVslName.Trim(), If(auth.VesselName, "").Trim())
                        If vNameStr.Length > 200 Then vNameStr = vNameStr.Substring(0, 200)
                        vesselName = If(String.IsNullOrWhiteSpace(vNameStr), DBNull.Value, CObj(vNameStr))
                    End If

                    ' Resolve rank_id: validate against tbl_rank
                    Dim rankId As Object = DBNull.Value
                    Dim candidateRankId As Integer = 0
                    Dim hasCandidateRankId As Boolean = False
                    If item.ContainsKey("RankId") AndAlso item("RankId") IsNot Nothing AndAlso
                       Integer.TryParse(item("RankId").ToString(), candidateRankId) AndAlso candidateRankId > 0 Then
                        hasCandidateRankId = True
                    ElseIf auth.RankId.HasValue AndAlso auth.RankId.Value > 0 Then
                        candidateRankId = auth.RankId.Value
                        hasCandidateRankId = True
                    End If

                    If hasCandidateRankId Then
                        Using rCmd As New MySqlCommand("SELECT COUNT(*) FROM tbl_rank WHERE id = @rid", cn, tran)
                            rCmd.Parameters.AddWithValue("@rid", candidateRankId)
                            Dim rExists As Object = rCmd.ExecuteScalar()
                            If rExists IsNot Nothing AndAlso Convert.ToInt32(rExists) > 0 Then
                                rankId = candidateRankId
                            End If
                        End Using
                    End If

                    ' Date validation (G-09: invalid date range rejected)
                    Dim dateFrom As Nullable(Of DateTime) = Nothing
                    Dim parsedDf As DateTime
                    Dim clientDateFrom As String = GetStrField(item, "DateFrom")
                    If Not String.IsNullOrWhiteSpace(clientDateFrom) AndAlso DateTime.TryParse(clientDateFrom, parsedDf) Then
                        dateFrom = parsedDf
                    ElseIf auth.DateFrom.HasValue Then
                        dateFrom = auth.DateFrom.Value
                    End If

                    If Not dateFrom.HasValue Then
                        Throw New ApplicationException("Invalid sea service date range: Date From is required.")
                    End If

                    Dim dateTo As Object = DBNull.Value
                    Dim parsedDt As DateTime
                    Dim clientDateTo As String = GetStrField(item, "DateTo")
                    If Not String.IsNullOrWhiteSpace(clientDateTo) AndAlso DateTime.TryParse(clientDateTo, parsedDt) Then
                        If parsedDt < dateFrom.Value Then
                            Throw New ApplicationException("Invalid sea service date range: Date To cannot be earlier than Date From.")
                        End If
                        dateTo = parsedDt
                    ElseIf auth.DateTo.HasValue Then
                        If auth.DateTo.Value < dateFrom.Value Then
                            Throw New ApplicationException("Invalid sea service date range: Date To cannot be earlier than Date From.")
                        End If
                        dateTo = auth.DateTo.Value
                    End If

                    Dim remarks As String = GetStrField(item, "Remarks")
                    If String.IsNullOrWhiteSpace(remarks) Then remarks = If(auth.Remarks, "")
                    If remarks.Length > 500 Then remarks = remarks.Substring(0, 500)

                    Dim port As String = GetStrField(item, "Port")
                    If String.IsNullOrWhiteSpace(port) Then port = If(auth.Port, "")
                    If port.Length > 200 Then port = port.Substring(0, 200)

                    Dim sqlSea As String =
                        "INSERT INTO tbl_personnel_sea_service " &
                        "(personnel_id, vessel_id, vessel_name, rank_id, port, date_from, date_to, remarks) " &
                        "VALUES (@pid, @vid, @vn, @rid, @pt, @df, @dt, @rem)"
                    Using cmd As New MySqlCommand(sqlSea, cn, tran)
                        cmd.Parameters.AddWithValue("@pid", personnelId)
                        cmd.Parameters.AddWithValue("@vid", vesselId)
                        cmd.Parameters.AddWithValue("@vn",  vesselName)
                        cmd.Parameters.AddWithValue("@rid", rankId)
                        cmd.Parameters.AddWithValue("@pt",  If(String.IsNullOrWhiteSpace(port), DBNull.Value, CObj(port)))
                        cmd.Parameters.AddWithValue("@df",  dateFrom.Value)
                        cmd.Parameters.AddWithValue("@dt",  dateTo)
                        cmd.Parameters.AddWithValue("@rem", If(String.IsNullOrWhiteSpace(remarks), DBNull.Value, CObj(remarks)))
                        cmd.ExecuteNonQuery()
                    End Using
                Next
            End If
        End If

        ' ── G.3: Document Records (with file move from staging) ────────────────
        Dim basePath As String = ApplicantStorageService.GetBaseUploadPhysicalPath()
        Dim permDocDir As String = System.IO.Path.Combine(basePath, "documents", personnelId.ToString())
        If Not System.IO.Directory.Exists(permDocDir) Then
            System.IO.Directory.CreateDirectory(permDocDir)
        End If

        Dim authDocs As List(Of PdsMappingModels.PdsDocumentSuggestion) = pkg.Documents
        If authDocs IsNot Nothing AndAlso authDocs.Count > 0 Then
            Dim docItems As Object() = Nothing
            If payload.ContainsKey("AcceptedDocuments") Then
                docItems = TryCast(payload("AcceptedDocuments"), Object())
            End If
            If docItems IsNot Nothing Then
                For Each itemObj As Object In docItems
                    Dim item As Dictionary(Of String, Object) = TryCast(itemObj, Dictionary(Of String, Object))
                    If item Is Nothing Then Continue For

                    ' Validate index against authoritative package (G-06)
                    Dim idx As Integer = -1
                    If Not item.ContainsKey("Index") OrElse Not Integer.TryParse(item("Index").ToString(), idx) Then
                        Throw New ApplicationException("Forged or missing document suggestion index.")
                    End If
                    If idx < 0 OrElse idx >= authDocs.Count Then
                        Throw New ApplicationException("Document suggestion index out of bounds.")
                    End If

                    Dim auth As PdsMappingModels.PdsDocumentSuggestion = authDocs(idx)

                    ' Resolve document_id (FK to tbl_documents)
                    Dim docTypeId As Object = DBNull.Value
                    Dim candidateDocTypeId As Integer = 0
                    If item.ContainsKey("DocumentTypeId") AndAlso item("DocumentTypeId") IsNot Nothing AndAlso
                       Integer.TryParse(item("DocumentTypeId").ToString(), candidateDocTypeId) AndAlso candidateDocTypeId > 0 Then
                        Using dCmd As New MySqlCommand("SELECT COUNT(*) FROM tbl_documents WHERE id = @did", cn, tran)
                            dCmd.Parameters.AddWithValue("@did", candidateDocTypeId)
                            Dim dExists As Object = dCmd.ExecuteScalar()
                            If dExists IsNot Nothing AndAlso Convert.ToInt32(dExists) > 0 Then
                                docTypeId = candidateDocTypeId
                            End If
                        End Using
                    ElseIf auth.DocumentTypeId.HasValue AndAlso auth.DocumentTypeId.Value > 0 Then
                        Using dCmd As New MySqlCommand("SELECT COUNT(*) FROM tbl_documents WHERE id = @did", cn, tran)
                            dCmd.Parameters.AddWithValue("@did", auth.DocumentTypeId.Value)
                            Dim dExists As Object = dCmd.ExecuteScalar()
                            If dExists IsNot Nothing AndAlso Convert.ToInt32(dExists) > 0 Then
                                docTypeId = auth.DocumentTypeId.Value
                            End If
                        End Using
                    End If

                    ' If no verified document type ID matches tbl_documents, skip document record
                    If docTypeId Is DBNull.Value Then Continue For

                    Dim docNum As String = GetStrField(item, "DocumentNumber")
                    If String.IsNullOrWhiteSpace(docNum) Then docNum = If(auth.DocumentNumber, "")
                    If docNum.Length > 200 Then docNum = docNum.Substring(0, 200)

                    Dim dateIssued As Object = DBNull.Value
                    Dim dateExpiry As Object = DBNull.Value
                    Dim diDate As DateTime
                    Dim deDate As DateTime
                    Dim clientDateIssued As String = GetStrField(item, "DateIssued")
                    If Not String.IsNullOrWhiteSpace(clientDateIssued) AndAlso DateTime.TryParse(clientDateIssued, diDate) Then
                        dateIssued = diDate
                    ElseIf auth.DateIssued.HasValue Then
                        dateIssued = auth.DateIssued.Value
                    End If

                    Dim clientDateExpiry As String = GetStrField(item, "DateExpiry")
                    If Not String.IsNullOrWhiteSpace(clientDateExpiry) AndAlso DateTime.TryParse(clientDateExpiry, deDate) Then
                        dateExpiry = deDate
                    ElseIf auth.DateExpiry.HasValue Then
                        dateExpiry = auth.DateExpiry.Value
                    End If

                    Dim grade As String = GetStrField(item, "Grade")
                    If String.IsNullOrWhiteSpace(grade) Then grade = If(auth.Grade, "")
                    If grade.Length > 50 Then grade = grade.Substring(0, 50)

                    ' G.3: Promote staged file to permanent storage
                    Dim imgId As Object = DBNull.Value
                    Dim clientStagedFileId As String = GetStrField(item, "StagedFileId")
                    If Not String.IsNullOrWhiteSpace(clientStagedFileId) AndAlso outStagedDocs IsNot Nothing Then
                        ' Validate StagedFileId belongs to this applicant's authoritative staged docs (G-12)
                        Dim matchedDoc As ApplicantStorageService.StagedDocument = Nothing
                        For Each sd As ApplicantStorageService.StagedDocument In outStagedDocs
                            If String.Equals(sd.StagedFileId, clientStagedFileId.Trim(), StringComparison.OrdinalIgnoreCase) Then
                                matchedDoc = sd
                                Exit For
                            End If
                        Next

                        If matchedDoc IsNot Nothing AndAlso System.IO.File.Exists(matchedDoc.PhysicalDiskPath) Then
                            Dim permFileName As String = String.Format("{0}_{1}_{2}{3}",
                                personnelId,
                                docTypeId.ToString(),
                                Guid.NewGuid().ToString("N"),
                                matchedDoc.Extension)
                            Dim permPath As String = System.IO.Path.Combine(permDocDir, permFileName)
                            System.IO.File.Copy(matchedDoc.PhysicalDiskPath, permPath, False)
                            copiedPermanentFiles.Add(permPath)

                            ' UMMI viewer convention (ProfileViewer resolves ~/Uploads/documents/ & imgId)
                            imgId = personnelId.ToString() & "/" & permFileName
                        End If
                    End If

                    Dim sqlDoc As String =
                        "INSERT INTO tbl_personnel_documents " &
                        "(personnel_id, document_id, document_num, date_issued, date_expiry, grade, img_id, required_documents) " &
                        "VALUES (@pid, @did, @dn, @di, @de, @gr, @img, '0')"
                    Using cmd As New MySqlCommand(sqlDoc, cn, tran)
                        cmd.Parameters.AddWithValue("@pid", personnelId)
                        cmd.Parameters.AddWithValue("@did", docTypeId)
                        cmd.Parameters.AddWithValue("@dn",  If(String.IsNullOrWhiteSpace(docNum), DBNull.Value, CObj(docNum)))
                        cmd.Parameters.AddWithValue("@di",  dateIssued)
                        cmd.Parameters.AddWithValue("@de",  dateExpiry)
                        cmd.Parameters.AddWithValue("@gr",  If(String.IsNullOrWhiteSpace(grade), DBNull.Value, CObj(grade)))
                        cmd.Parameters.AddWithValue("@img", imgId)
                        cmd.ExecuteNonQuery()
                    End Using
                Next
            End If
        End If
    End Sub

    ''' <summary>
    ''' Safe helper to extract a string value from a deserialized JSON dictionary.
    ''' Returns empty string on missing or null key.
    ''' </summary>
    Private Function GetStrField(item As Dictionary(Of String, Object), key As String) As String
        If item Is Nothing OrElse Not item.ContainsKey(key) OrElse item(key) Is Nothing Then Return ""
        Return item(key).ToString().Trim()
    End Function

    ' ── SafeResolveLookupId ─────────────────────────────────────────────────
    ' Resolves the FK value to store:
    '   - Standard selection  → returns the selected FK ID directly.
    '   - "other" (Others selected) → looks up the existing "Others (Please specify)"
    '     record ID from the DB. NEVER inserts a new row — the user-typed text
    '     in the companion TextBox is for display only and is discarded.
    '   - Nothing selected    → returns DBNull.
    Private Function SafeResolveLookupId(selectedValue As String, tableName As String, colName As String) As Object
        If selectedValue = "other" Then
            ' Return the existing FK ID for "Others (Please specify)" — no INSERT.
            Dim dt As System.Data.DataTable = DbHelper.FillDataTable(
                String.Format("SELECT id FROM {0} WHERE LOWER(TRIM({1})) LIKE 'others%' LIMIT 1", tableName, colName),
                System.Data.CommandType.Text)
            If dt.Rows.Count > 0 Then
                Return dt.Rows(0)("id")
            End If
            Return DBNull.Value
        End If
        Return If(String.IsNullOrEmpty(selectedValue), DBNull.Value, CObj(selectedValue))
    End Function

End Class
