Imports MySql.Data.MySqlClient
Imports System.Data

Public Class ProfileViewer
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        RequireLogin()
        RequireRole(ROLE_MANNING_STAFF, ROLE_DOCUMENTATION_OFFICER, ROLE_SUPER_ADMIN, ROLE_ADMIN, ROLE_PRINCIPAL, ROLE_VESSEL_OWNER)

        If Not IsPostBack Then
            ' WBS 1.2.1 — URL Parameter Decryption
            Dim encID As String = HttpUtility.UrlDecode(Request.QueryString("ID"))
            Dim encType As String = HttpUtility.UrlDecode(Request.QueryString("Type"))
            Dim encVerifier As String = HttpUtility.UrlDecode(Request.QueryString("Verifier"))

            ViewState("PersonnelID") = Decrypt(encID)
            ViewState("Type")        = Decrypt(encType)
            ViewState("Verifier")    = Decrypt(encVerifier)

            Dim pid As String = If(ViewState("PersonnelID") IsNot Nothing, ViewState("PersonnelID").ToString(), "")
            If String.IsNullOrEmpty(pid) Then
                Response.Redirect("~/Crew/QueryCrew.aspx", True)
                Return
            End If

            GetPersonnelAct("Viewed Profile", CurrentUserID().ToString(), "ProfileViewer", pid)

            ' WBS 1.2.21/1.2.22 — Verifier mode
            SetupVerifier()

            ' Role-based section visibility
            ApplyRoleVisibility()

            ' Load all sections
            LoadCrewInfo(pid)
            LoadDocuments(pid, "Personal",  gvDocPersonal)
            LoadDocuments(pid, "License",   gvDocLicense)
            LoadDocuments(pid, "Medical",   gvDocMedical)
            LoadDocuments(pid, "Training",  gvDocTraining)
            LoadDocuments(pid, "Outsource", gvDocOutsource)
            LoadDocuments(pid, "UMMI",      gvDocUMMI)
            LoadSeaService(pid)
            LoadComments(pid)
            LoadFamily(pid)
        End If
    End Sub

    Private Sub ApplyRoleVisibility()
        Dim canSeeContact As Boolean = CanViewContactDetails()
        divContactInfo.Visible = canSeeContact
        divStatutory.Visible   = canSeeContact
        divFamilyInfo.Visible  = canSeeContact
        divComments.Visible    = canSeeContact
        liComments.Visible     = canSeeContact
        ' UC-CM-07: Personal notes only for contact-visible users
        divPersonalNotes.Visible = canSeeContact
    End Sub

    Private Sub SetupVerifier()
        Dim verifier As String = If(ViewState("Verifier") IsNot Nothing, ViewState("Verifier").ToString(), "")
        If verifier = "benefits" OrElse verifier = "tin" Then
            divBtnVerify.Visible  = True
            divVerifyBanner.Visible = True
            lblVerifyType.Text = If(verifier = "benefits", "Statutory Benefits Verification Mode", "TIN Verification Mode")
        End If
    End Sub

    ' ── WBS 1.2.2 + UC-CM-07 Personal Information ──────────────────────
    Private Sub LoadCrewInfo(pid As String)
        Dim sql As String = "SELECT pi.*, r.rank_code, rel.religion, n.nationality, " &
                            "TIMESTAMPDIFF(YEAR,pi.date_of_birth,CURDATE()) AS age_, " &
                            "ds.meaning AS status_text, " &
                            "pr.provinces AS prov_name, ct.cities AS city_name " &
                            "FROM tbl_personnel_info pi " &
                            "LEFT JOIN tbl_rank               r  ON r.id  = pi.position " &
                            "LEFT JOIN tbl_religion            rel ON rel.id = pi.religion " &
                            "LEFT JOIN tbl_nationality         n   ON n.id  = pi.nationality " &
                            "LEFT JOIN tbl_dropdown_selection  ds  ON ds.type='crew_status' AND ds.sequence=pi.crew_status " &
                            "LEFT JOIN tbl_provinces           pr  ON pr.id = pi.province " &
                            "LEFT JOIN tbl_cities              ct  ON ct.id = pi.city " &
                            "WHERE pi.id=@id LIMIT 1"
        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                cmd.Parameters.AddWithValue("@id", pid)
                Using dr As MySqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        Dim fn As String = dr("lastname").ToString() & ", " & dr("firstname").ToString() & " " & dr("middlename").ToString()
                        lblFullName.Text = Server.HtmlEncode(fn)
                        lblRank.Text     = If(IsDBNull(dr("rank_code")), "", dr("rank_code").ToString())
                        lblEmpStatus.Text = If(IsDBNull(dr("emp_status")), "", dr("emp_status").ToString())
                        lblCrewStatusText.Text = If(IsDBNull(dr("status_text")), "", dr("status_text").ToString())

                        ' WBS 1.2.4 Age
                        lblAge.Text = If(IsDBNull(dr("age_")), "N/A", dr("age_").ToString())

                        ' WBS 1.2.3 BMI
                        If Not IsDBNull(dr("height")) AndAlso Not IsDBNull(dr("weight")) Then
                            Dim h As Double = CDbl(dr("height")) / 100 ' cm to m
                            Dim w As Double = CDbl(dr("weight"))
                            If h > 0 Then
                                Dim bmi As Double = Math.Round(w / (h * h), 1)
                                lblBMI.Text = bmi.ToString("F1")
                                Dim cls As String = GetBMIClass(bmi)
                                lblBMIClass.Text = cls
                                Select Case cls
                                    Case "Underweight" : lblBMIClass.CssClass = "bmi-badge bmi-underweight"
                                    Case "Normal"      : lblBMIClass.CssClass = "bmi-badge bmi-normal"
                                    Case "Overweight"  : lblBMIClass.CssClass = "bmi-badge bmi-overweight"
                                    Case Else          : lblBMIClass.CssClass = "bmi-badge bmi-obese"
                                End Select
                            End If
                        End If

                        lblDOB.Text  = If(IsDBNull(dr("date_of_birth")), "", CDate(dr("date_of_birth")).ToString("MMMM dd, yyyy"))
                        lblPOB.Text  = If(IsDBNull(dr("place_of_birth")), "", dr("place_of_birth").ToString())
                        lblGender.Text      = If(IsDBNull(dr("gender")), "", dr("gender").ToString())
                        lblCivilStatus.Text = If(IsDBNull(dr("civil_status")), "", dr("civil_status").ToString())
                        lblReligion.Text    = If(IsDBNull(dr("religion")), "", dr("religion").ToString())
                        lblNationality.Text = If(IsDBNull(dr("nationality")), "", dr("nationality").ToString())
                        lblHeight.Text      = If(IsDBNull(dr("height")), "", dr("height").ToString())
                        lblWeight.Text      = If(IsDBNull(dr("weight")), "", dr("weight").ToString())
                        lblDateHired.Text   = If(IsDBNull(dr("date_hired")), "", CDate(dr("date_hired")).ToString("MMMM dd, yyyy"))
                        lblAddress.Text     = If(IsDBNull(dr("address")), "", dr("address").ToString())
                        lblContact.Text     = If(IsDBNull(dr("applicant_contact_num")), "", dr("applicant_contact_num").ToString())
                        lblEmail.Text       = If(IsDBNull(dr("email_address")), "", dr("email_address").ToString())

                        ' UC-CM-07: Blood Type
                        lblBloodType.Text = If(IsDBNull(dr("blood_type")), "—", dr("blood_type").ToString())

                        ' UC-CM-07: HMO Information
                        lblHMONumber.Text     = If(IsDBNull(dr("hmo_number")), "—", dr("hmo_number").ToString())
                        lblHMOExpiry.Text     = If(IsDBNull(dr("hmo_expiry")), "—", Convert.ToDateTime(dr("hmo_expiry")).ToString("MMMM dd, yyyy"))
                        lblNumDependents.Text = If(IsDBNull(dr("num_dependents")), "0", dr("num_dependents").ToString())

                        ' UC-CM-07: Uniform Sizes
                        lblUniformCoverall.Text = If(IsDBNull(dr("uniform_coverall")), "—", dr("uniform_coverall").ToString())
                        lblUniformShoes.Text    = If(IsDBNull(dr("uniform_shoes")), "—", dr("uniform_shoes").ToString())
                        lblUniformPolo.Text     = If(IsDBNull(dr("uniform_polo")), "—", dr("uniform_polo").ToString())
                        lblUniformPants.Text    = If(IsDBNull(dr("uniform_pants")), "—", dr("uniform_pants").ToString())

                        ' UC-CM-07: Personal Notes (visible to users with contact access)
                        If Not IsDBNull(dr("personal_notes")) AndAlso dr("personal_notes").ToString() <> "" Then
                            lblPersonalNotes.Text = Server.HtmlEncode(dr("personal_notes").ToString())
                        End If

                        ' WBS 1.2.5 Statutory
                        lblSSS.Text       = If(IsDBNull(dr("sss")), "—", dr("sss").ToString())
                        lblTIN.Text       = If(IsDBNull(dr("tin")), "—", dr("tin").ToString())
                        lblPhilHealth.Text = If(IsDBNull(dr("philhealth")), "—", dr("philhealth").ToString())
                        lblPagIBIG.Text   = If(IsDBNull(dr("pagibig")), "—", dr("pagibig").ToString())
                        lblVerifiedBenefits.Text = If(dr.GetInt32("verified_benefits") = 1,
                            "<span style='color:#10b981'><i class='fa fa-circle-check'></i> Benefits Verified</span>", "")
                        lblVerifiedTIN.Text = If(dr.GetInt32("verified_tin") = 1,
                            "<span style='color:#10b981'><i class='fa fa-circle-check'></i> TIN Verified</span>", "")

                        ' UC-CM-07: Gender-appropriate photo placeholder
                        Dim gender As String = If(IsDBNull(dr("gender")), "", dr("gender").ToString())
                        If Not IsDBNull(dr("picture_id")) AndAlso dr("picture_id").ToString() <> "" Then
                            imgProfilePic.ImageUrl = "~/Uploads/picture/" & dr("picture_id").ToString()
                        Else
                            imgProfilePic.ImageUrl = If(gender = "Female", "~/images/silhouette_female.png", "~/images/silhouette_user.png")
                        End If

                        CType(Master, masterPage).lblPageTitle.Text = fn
                    End If
                End Using
            End Using
        End Using

        ' WBS 1.2.19 Total years
        LoadTotalService(pid)
    End Sub

    ' WBS 1.2.3 BMI classification
    Private Function GetBMIClass(bmi As Double) As String
        If bmi < 18.5 Then Return "Underweight"
        If bmi < 25   Then Return "Normal"
        If bmi < 30   Then Return "Overweight"
        Return "Obese"
    End Function

    ' WBS 1.2.9-1.2.14 Document tabs
    Private Sub LoadDocuments(pid As String, docType As String, gv As System.Web.UI.WebControls.GridView)
        Dim sql As String = "SELECT d.documentName, pd.document_num, pd.date_issued, pd.date_expiry, " &
                            "pd.grade, d.month_expiry_warning, pd.img_id, pd.id AS pd_id " &
                            "FROM tbl_personnel_documents pd " &
                            "JOIN tbl_documents d ON d.id=pd.document_id " &
                            "WHERE pd.personnel_id=@pid AND d.docType=@dt " &
                            "ORDER BY d.sequence"
        Dim dt As DataTable = New DataTable()
        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                cmd.Parameters.AddWithValue("@pid", pid)
                cmd.Parameters.AddWithValue("@dt", docType)
                Using da As New MySqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        ' Add columns expected by the GridView
        Dim boundCols As New List(Of System.Web.UI.WebControls.BoundField)
        For Each col As String In {"documentName", "document_num", "date_issued", "date_expiry", "grade"}
            Dim bf As New System.Web.UI.WebControls.BoundField()
            bf.DataField = col
            bf.HeaderText = col.Replace("_", " ").Replace("document", "Doc").Replace("date ", "")
            gv.Columns.Add(bf)
        Next

        ' UC-CM-08: Add "View Scan" template column
        Dim scanCol As New System.Web.UI.WebControls.TemplateField()
        scanCol.HeaderText = "Scan"
        scanCol.ItemStyle.Width = System.Web.UI.WebControls.Unit.Pixel(60)
        gv.Columns.Add(scanCol)

        gv.DataSource = dt
        gv.DataBind()
    End Sub

    ' WBS 1.2.15 — Document expiry color-coding + UC-CM-08 scan viewer
    Protected Sub DocRowDataBound(sender As Object, e As System.Web.UI.WebControls.GridViewRowEventArgs)
        If e.Row.RowType <> System.Web.UI.WebControls.DataControlRowType.DataRow Then Return

        ' Expiry warning color
        Dim expiryText As String = e.Row.Cells(3).Text ' date_expiry column
        If expiryText = "&nbsp;" OrElse expiryText = "" Then
            ' no expiry
        Else
            Dim expiryDate As Date
            If Date.TryParse(expiryText, expiryDate) Then
                Dim warningMonths As Integer = 3
                If e.Row.Cells.Count > 5 Then
                    Integer.TryParse(e.Row.Cells(5).Text.Replace("&nbsp;", "0"), warningMonths)
                End If
                If warningMonths = 0 Then warningMonths = 3
                If Date.Now.AddMonths(warningMonths) >= expiryDate Then
                    e.Row.Cells(3).BackColor = Drawing.Color.DarkRed
                    e.Row.Cells(3).ForeColor = Drawing.Color.White
                End If
            End If
        End If

        ' UC-CM-08: View Scan link (last column)
        Dim dr As DataRowView = CType(e.Row.DataItem, DataRowView)
        Dim imgId As String = If(Not IsDBNull(dr("img_id")), dr("img_id").ToString(), "")
        Dim lastCellIdx As Integer = e.Row.Cells.Count - 1
        If imgId <> "" Then
            Dim imgUrl As String = ResolveUrl("~/Uploads/documents/" & imgId)
            e.Row.Cells(lastCellIdx).Text = "<a href='javascript:void(0)' onclick=""showImagePopup('" &
                imgUrl.Replace("'", "\'") & "')"" class='gv-link' title='View Scan'>" &
                "<i class='fa fa-image'></i></a>"
        End If
    End Sub

    ' WBS 1.2.17/1.2.18 Sea Service + Period Calculation + UC-CM-09 Port column
    Private Sub LoadSeaService(pid As String)
        Dim sql As String = "SELECT pss.*, v.vesselName AS vessel_name, r.rank_code " &
                            "FROM tbl_personnel_sea_service pss " &
                            "LEFT JOIN tbl_vessels v ON v.id=pss.vessel_id " &
                            "LEFT JOIN tbl_rank r ON r.id=pss.rank_id " &
                            "WHERE pss.personnel_id=@pid ORDER BY pss.date_from DESC"
        Dim dt As DataTable = DbHelper.FillDataTable(sql, System.Data.CommandType.Text,
            New MySqlParameter("@pid", pid))
        gvSeaService.DataSource = dt
        gvSeaService.DataBind()
    End Sub

    Protected Sub SeaServiceRowDataBound(sender As Object, e As System.Web.UI.WebControls.GridViewRowEventArgs)
        If e.Row.RowType <> System.Web.UI.WebControls.DataControlRowType.DataRow Then Return
        ' Port is column 2, Sign-On is column 3, Sign-Off is column 4
        Dim fromText As String = e.Row.Cells(3).Text
        Dim toText   As String = e.Row.Cells(4).Text
        Dim d1, d2 As Date
        If Date.TryParse(fromText, d1) AndAlso Date.TryParse(toText, d2) Then
            Dim lbl As System.Web.UI.WebControls.Label =
                CType(e.Row.FindControl("lblPeriod"), System.Web.UI.WebControls.Label)
            If lbl IsNot Nothing Then lbl.Text = GetDatePeriod(d1, d2)
        End If
    End Sub

    ' WBS 1.2.18 getDatePeriod
    Public Function GetDatePeriod(d1 As Date, d2 As Date) As String
        If d2 < d1 Then
            Dim tmp As Date = d1 : d1 = d2 : d2 = tmp
        End If
        Dim months As Integer = (d2.Year - d1.Year) * 12 + d2.Month - d1.Month
        Dim years As Integer = months \ 12
        Dim remMonths As Integer = months Mod 12
        Dim result As String = ""
        If years > 0 Then result = years.ToString() & " yr(s) "
        If remMonths > 0 Then result &= remMonths.ToString() & " mo(s)"
        Return result.Trim()
    End Function

    ' WBS 1.2.19 Total Years in Service
    Private Sub LoadTotalService(pid As String)
        Dim sql As String = "SELECT TRUNCATE(SUM(DATEDIFF(IFNULL(date_to,CURDATE()),date_from))/365,0) AS tot " &
                            "FROM tbl_personnel_sea_service WHERE personnel_id=@pid " &
                            "UNION ALL " &
                            "SELECT TRUNCATE(SUM(DATEDIFF(IFNULL(date_to,CURDATE()),date_from))/365,0) AS tot " &
                            "FROM tbl_contracts WHERE personnel_id=@pid"
        Dim total As Double = 0
        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                cmd.Parameters.AddWithValue("@pid", pid)
                Using dr As MySqlDataReader = cmd.ExecuteReader()
                    Do While dr.Read()
                        If Not IsDBNull(dr("tot")) Then total += CDbl(dr("tot"))
                    Loop
                End Using
            End Using
        End Using
        lblTotalService.Text   = Math.Truncate(total).ToString() & " yr(s)"
        lblTotalYrsService.Text = "Total: " & Math.Truncate(total).ToString() & " yr(s) at sea"
    End Sub

    ' WBS 1.2.20 + UC-CM-10 Comments/Assessments
    Private Sub LoadComments(pid As String)
        Dim sql As String = "SELECT date_sent, comments, added_by_name, img_id FROM tbl_personnel_comment " &
                            "WHERE personnel_id=@pid ORDER BY date_sent DESC"
        Dim dt As DataTable = DbHelper.FillDataTable(sql, System.Data.CommandType.Text,
            New MySqlParameter("@pid", pid))
        gvComments.DataSource = dt
        gvComments.DataBind()
    End Sub

    ' UC-CM-10: Assessment attachment indicator
    Protected Sub CommentRowDataBound(sender As Object, e As System.Web.UI.WebControls.GridViewRowEventArgs)
        If e.Row.RowType <> System.Web.UI.WebControls.DataControlRowType.DataRow Then Return
        Dim drv As DataRowView = CType(e.Row.DataItem, DataRowView)
        Dim lnk As System.Web.UI.WebControls.HyperLink = CType(e.Row.FindControl("lnkAttachment"), System.Web.UI.WebControls.HyperLink)
        If lnk IsNot Nothing AndAlso Not IsDBNull(drv("img_id")) AndAlso drv("img_id").ToString() <> "" Then
            lnk.Visible = True
            lnk.NavigateUrl = ResolveUrl("~/Uploads/documents/" & drv("img_id").ToString())
        End If
    End Sub

    ' WBS 1.2.7/1.2.8 Family + HMO
    Private Sub LoadFamily(pid As String)
        Dim sql As String = "SELECT pfi.*, rel.relationship AS relationship_name, " &
                            "(SELECT COUNT(*) FROM tbl_hmo_beneficiary h WHERE h.family_id=pfi.id) AS hmo_count " &
                            "FROM tbl_personnel_family_info pfi " &
                            "LEFT JOIN tbl_relationship rel ON rel.id=pfi.relationship " &
                            "WHERE pfi.personnel_id=@pid ORDER BY rel.sequence"
        Dim dt As DataTable = DbHelper.FillDataTable(sql, System.Data.CommandType.Text,
            New MySqlParameter("@pid", pid))
        gvFamily.DataSource = dt
        gvFamily.DataBind()
    End Sub

    ' WBS 1.2.21/1.2.22 Verify
    Protected Sub VerifyData(sender As Object, e As EventArgs)
        Dim verifier As String = If(ViewState("Verifier") IsNot Nothing, ViewState("Verifier").ToString(), "")
        Dim col As String = If(verifier = "benefits", "verified_benefits", "verified_tin")
        Dim pid As String = If(ViewState("PersonnelID") IsNot Nothing, ViewState("PersonnelID").ToString(), "")
        If String.IsNullOrEmpty(pid) Then Return

        Dim sql As String = "UPDATE tbl_personnel_info SET " & col & "=1 WHERE id=@id"
        DbHelper.ExecuteNonQuery(sql, New MySqlParameter("@id", pid))
        GetAdmin("Verified " & verifier, CurrentUserID().ToString(), "ProfileViewer", "PersonnelID=" & pid)
        lblNotify.Text = "<div class='alert alert-success'><i class='fa fa-circle-check'></i>Successfully verified!</div>"
    End Sub

    Protected Sub PrintCrewDetails(sender As Object, e As EventArgs)
        Dim pid As String = If(ViewState("PersonnelID") IsNot Nothing, ViewState("PersonnelID").ToString(), "")
        Dim printDetail As String = If(CanViewContactDetails(), "1", "0")
        Dim encPid As String = HttpUtility.UrlEncode(Encrypt(pid))
        Response.Redirect("~/Crew/Print.aspx?printType=Personnel&PrintDetails=" &
            Encrypt(printDetail) & "&PersonnelID=" & encPid, True)
    End Sub

End Class
