Imports MySql.Data.MySqlClient

Public Class SelfEncode
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
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
            ' Pre-fill name from link (or leave blank for add mode)
            If Not isAddMode Then
                txtLastName.Text = If(Session("UserFullname") IsNot Nothing, Session("UserFullname").ToString(), "")
            End If
        End If
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

    ' UC-CM-24: Submit self-encoded application
    Protected Sub SubmitApplication(sender As Object, e As EventArgs)

        ' ── Server-side required field validation ──────────────────────────────
        If String.IsNullOrEmpty(txtLastName.Text.Trim()) OrElse
           String.IsNullOrEmpty(txtFirstName.Text.Trim()) OrElse
           Not IsDate(txtDOB.Text) OrElse
           String.IsNullOrEmpty(txtContact.Text.Trim()) Then
            lblNotify.Text = "<div class='alert alert-danger'><i class='fa fa-circle-exclamation me-2'></i>Please fill in all required fields (marked with *).</div>"
            Return
        End If

        ' ── Server-side guard for "Others (Please specify)" fields ────────────
        ' The user must type something in the specify box, but the text is NOT saved;
        ' only the "Others (Please specify)" FK ID is stored.
        If drpdwnReligion.SelectedValue = "other" AndAlso String.IsNullOrEmpty(txtReligionOther.Text.Trim()) Then
            lblNotify.Text = "<div class='alert alert-danger'><i class='fa fa-circle-exclamation me-2'></i>Please specify your Religion when &quot;Others (Please specify)&quot; is selected.</div>"
            Return
        End If
        If drpdwnNationality.SelectedValue = "other" AndAlso String.IsNullOrEmpty(txtNationalityOther.Text.Trim()) Then
            lblNotify.Text = "<div class='alert alert-danger'><i class='fa fa-circle-exclamation me-2'></i>Please specify your Nationality when &quot;Others (Please specify)&quot; is selected.</div>"
            Return
        End If
        If drpdwnSchool.SelectedValue = "other" AndAlso String.IsNullOrEmpty(txtSchoolOther.Text.Trim()) Then
            lblNotify.Text = "<div class='alert alert-danger'><i class='fa fa-circle-exclamation me-2'></i>Please specify your School / University when &quot;Others (Please specify)&quot; is selected.</div>"
            Return
        End If
        If drpdwnCourse.SelectedValue = "other" AndAlso String.IsNullOrEmpty(txtCourseOther.Text.Trim()) Then
            lblNotify.Text = "<div class='alert alert-danger'><i class='fa fa-circle-exclamation me-2'></i>Please specify your Course when &quot;Others (Please specify)&quot; is selected.</div>"
            Return
        End If

        Dim sql As String = "INSERT INTO tbl_personnel_info " &
            "(firstname, middlename, lastname, suffix, position, religion, nationality, " &
            " school_name, course, date_of_birth, place_of_birth, gender, civil_status, " &
            " height, weight, email_address, applicant_contact_num, address, province, city, " &
            " crew_status, crew_availability, date_added) " &
            "VALUES (@fn,@mn,@ln,@sfx,@pos,@rel,@nat,@sch,@crs,@dob,@pob,@gen,@civ," &
            "  @ht,@wt,@em,@ct,@addr,@prov,@city,5,1,NOW()); SELECT LAST_INSERT_ID();"

        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)

                cmd.Parameters.AddWithValue("@fn",   txtFirstName.Text.Trim())
                cmd.Parameters.AddWithValue("@mn",   txtMiddleName.Text.Trim())
                cmd.Parameters.AddWithValue("@ln",   txtLastName.Text.Trim())
                cmd.Parameters.AddWithValue("@sfx",  drpdwnSuffix.SelectedValue)
                cmd.Parameters.AddWithValue("@pos",  If(drpdwnRank.SelectedValue = "", DBNull.Value, CObj(drpdwnRank.SelectedValue)))
                cmd.Parameters.AddWithValue("@rel",  SafeResolveLookupId(drpdwnReligion.SelectedValue,    "tbl_religion",    "religion"))
                cmd.Parameters.AddWithValue("@nat",  SafeResolveLookupId(drpdwnNationality.SelectedValue, "tbl_nationality", "nationality"))
                cmd.Parameters.AddWithValue("@sch",  SafeResolveLookupId(drpdwnSchool.SelectedValue,      "tbl_school",      "school_name"))
                cmd.Parameters.AddWithValue("@crs",  SafeResolveLookupId(drpdwnCourse.SelectedValue,      "tbl_course",      "course"))
                cmd.Parameters.AddWithValue("@dob",  CDate(txtDOB.Text))
                cmd.Parameters.AddWithValue("@pob",  txtPOB.Text.Trim())
                cmd.Parameters.AddWithValue("@gen",  drpdwnGender.SelectedValue)
                cmd.Parameters.AddWithValue("@civ",  drpdwnCivilStatus.SelectedValue)
                cmd.Parameters.AddWithValue("@ht",   If(String.IsNullOrEmpty(txtHeight.Text), DBNull.Value, CObj(txtHeight.Text)))
                cmd.Parameters.AddWithValue("@wt",   If(String.IsNullOrEmpty(txtWeight.Text), DBNull.Value, CObj(txtWeight.Text)))
                cmd.Parameters.AddWithValue("@em",   txtEmail.Text.Trim())
                cmd.Parameters.AddWithValue("@ct",   txtContact.Text.Trim())
                cmd.Parameters.AddWithValue("@addr", txtAddress.Text.Trim())
                cmd.Parameters.AddWithValue("@prov", If(drpdwnProvince.SelectedValue = "", DBNull.Value, CObj(drpdwnProvince.SelectedValue)))
                cmd.Parameters.AddWithValue("@city", If(drpdwnCity.SelectedValue = "",    DBNull.Value, CObj(drpdwnCity.SelectedValue)))

                Dim newID As Object = cmd.ExecuteScalar()

                ' Update link record with personnel_id
                If Session("ApplicantLinkID") IsNot Nothing Then
                    Dim linkID As String = Session("ApplicantLinkID").ToString()
                    DbHelper.ExecuteNonQuery("UPDATE tbl_applicant_generated_link SET status='Used', personnel_id=@pid WHERE id=@lid",
                        New MySqlParameter("@pid", newID),
                        New MySqlParameter("@lid", linkID))
                End If

                GetAdmin("Self-Encoded Application", If(newID IsNot Nothing, newID.ToString(), ""), "SelfEncode",
                    txtLastName.Text.Trim() & ", " & txtFirstName.Text.Trim())

                lblNotify.Text = "<div class='alert alert-success'><i class='fa fa-circle-check me-2'></i>" &
                    "Your application has been submitted successfully! The Manning Office will review your information. " &
                    "Thank you, " & Server.HtmlEncode(txtFirstName.Text.Trim()) & "!</div>"

                ' Clear session after successful submit
                Session.Clear()
                Session.Abandon()
            End Using
        End Using
    End Sub

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
