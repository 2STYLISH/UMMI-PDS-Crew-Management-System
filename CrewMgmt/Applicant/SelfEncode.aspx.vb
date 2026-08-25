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
        Dim dtRel As System.Data.DataTable = DbHelper.FillDataTable("SELECT id,religion FROM tbl_religion ORDER BY religion", System.Data.CommandType.Text)
        drpdwnReligion.Items.Clear()
        drpdwnReligion.Items.Add(New System.Web.UI.WebControls.ListItem("Select...", ""))
        For Each row As System.Data.DataRow In dtRel.Rows
            drpdwnReligion.Items.Add(New System.Web.UI.WebControls.ListItem(row("religion").ToString(), row("id").ToString()))
        Next

        ' Nationalities
        Dim dtNat As System.Data.DataTable = DbHelper.FillDataTable("SELECT id,nationality FROM tbl_nationality ORDER BY nationality", System.Data.CommandType.Text)
        drpdwnNationality.Items.Clear()
        drpdwnNationality.Items.Add(New System.Web.UI.WebControls.ListItem("Select...", ""))
        For Each row As System.Data.DataRow In dtNat.Rows
            drpdwnNationality.Items.Add(New System.Web.UI.WebControls.ListItem(row("nationality").ToString(), row("id").ToString()))
        Next

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

        ' Schools / Courses
        Dim dtSch As System.Data.DataTable = DbHelper.FillDataTable("SELECT id,school_name FROM tbl_school ORDER BY school_name", System.Data.CommandType.Text)
        drpdwnSchool.Items.Clear()
        drpdwnSchool.Items.Add(New System.Web.UI.WebControls.ListItem("Select school...", ""))
        For Each row As System.Data.DataRow In dtSch.Rows
            drpdwnSchool.Items.Add(New System.Web.UI.WebControls.ListItem(row("school_name").ToString(), row("id").ToString()))
        Next

        Dim dtCrs As System.Data.DataTable = DbHelper.FillDataTable("SELECT id,course FROM tbl_course ORDER BY course", System.Data.CommandType.Text)
        drpdwnCourse.Items.Clear()
        drpdwnCourse.Items.Add(New System.Web.UI.WebControls.ListItem("Select course...", ""))
        For Each row As System.Data.DataRow In dtCrs.Rows
            drpdwnCourse.Items.Add(New System.Web.UI.WebControls.ListItem(row("course").ToString(), row("id").ToString()))
        Next
    End Sub

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
    End Sub

    ' UC-CM-24: Submit self-encoded application
    Protected Sub SubmitApplication(sender As Object, e As EventArgs)
        ' Validate required fields
        If String.IsNullOrEmpty(txtLastName.Text.Trim()) OrElse
           String.IsNullOrEmpty(txtFirstName.Text.Trim()) OrElse
           Not IsDate(txtDOB.Text) OrElse
           String.IsNullOrEmpty(txtContact.Text.Trim()) Then
            lblNotify.Text = "<div class='alert alert-danger'><i class='fa fa-circle-exclamation me-2'></i>Please fill in all required fields (marked with *).</div>"
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
                cmd.Parameters.AddWithValue("@rel",  If(drpdwnReligion.SelectedValue = "", DBNull.Value, CObj(drpdwnReligion.SelectedValue)))
                cmd.Parameters.AddWithValue("@nat",  If(drpdwnNationality.SelectedValue = "", DBNull.Value, CObj(drpdwnNationality.SelectedValue)))
                cmd.Parameters.AddWithValue("@sch",  If(drpdwnSchool.SelectedValue = "", DBNull.Value, CObj(drpdwnSchool.SelectedValue)))
                cmd.Parameters.AddWithValue("@crs",  If(drpdwnCourse.SelectedValue = "", DBNull.Value, CObj(drpdwnCourse.SelectedValue)))
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
                cmd.Parameters.AddWithValue("@city", If(drpdwnCity.SelectedValue = "", DBNull.Value, CObj(drpdwnCity.SelectedValue)))

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

                ' Clear form
                Session.Clear()
                Session.Abandon()
            End Using
        End Using
    End Sub

End Class
