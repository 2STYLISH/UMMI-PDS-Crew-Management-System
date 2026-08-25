Imports MySql.Data.MySqlClient
Imports System.Data

Public Class Certificates
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(s As Object, e As EventArgs) Handles Me.Load
        RequireLogin()
        RequireRole(ROLE_MANNING_STAFF, ROLE_DOCUMENTATION_OFFICER, ROLE_SUPER_ADMIN, ROLE_ADMIN)
        If Not IsPostBack Then
            CType(Master, masterPage).lblPageTitle.Text = "Certificates"
            If Request.QueryString("ID") <> "" Then
                Dim pid As String = Decrypt(HttpUtility.UrlDecode(Request.QueryString("ID")))
                ViewState("PreFilterPID") = pid
            End If
            SearchCerts(Nothing, Nothing)
        End If
    End Sub

    Protected Sub SearchCerts(s As Object, e As EventArgs)
        Dim certFilter As String = drpdwnCertType.SelectedValue  ' APAT, PDOS, or PETE
        Dim sql As String =
            "SELECT pi.lastname, pi.firstname, r.rank_code, d.documentName, " &
            "pd.document_num, pd.date_issued, pd.date_expiry, d.month_expiry_warning " &
            "FROM tbl_personnel_documents pd " &
            "JOIN tbl_personnel_info pi ON pi.id=pd.personnel_id " &
            "JOIN tbl_documents d ON d.id=pd.document_id " &
            "LEFT JOIN tbl_rank r ON r.id=pi.position " &
            "WHERE d.documentName LIKE CONCAT('%', @cert, '%') " &
            "AND (@nm = '' OR pi.lastname LIKE CONCAT('%', @nm, '%')) " &
            "ORDER BY pi.lastname, d.sequence"
        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text,
            New MySqlParameter("@cert", certFilter),
            New MySqlParameter("@nm",   txtName.Text.Trim()))
        ViewState("CertData") = dt
        gvCerts.DataSource = dt
        gvCerts.PageIndex = 0
        gvCerts.DataBind()
    End Sub

    Protected Sub gvCerts_RowDataBound(s As Object, e As System.Web.UI.WebControls.GridViewRowEventArgs)
        If e.Row.RowType <> System.Web.UI.WebControls.DataControlRowType.DataRow Then Return
        Dim expiryText As String = e.Row.Cells(5).Text
        Dim expiryDate As Date
        If Date.TryParse(expiryText, expiryDate) Then
            If Date.Now >= expiryDate Then
                e.Row.Cells(5).BackColor = Drawing.Color.DarkRed
                e.Row.Cells(5).ForeColor = Drawing.Color.White
            ElseIf Date.Now.AddMonths(3) >= expiryDate Then
                e.Row.Cells(5).BackColor = Drawing.ColorTranslator.FromHtml("#F59E0B")
                e.Row.Cells(5).ForeColor = Drawing.Color.White
            End If
        End If
    End Sub

    Protected Sub gvCerts_PageIndexChanging(s As Object, e As System.Web.UI.WebControls.GridViewPageEventArgs)
        gvCerts.PageIndex = e.NewPageIndex
        Dim dt As DataTable = TryCast(ViewState("CertData"), DataTable)
        gvCerts.DataSource = dt
        gvCerts.DataBind()
    End Sub

    Protected Sub ExportCerts(s As Object, e As EventArgs)
        Dim dt As DataTable = TryCast(ViewState("CertData"), DataTable)
        If dt Is Nothing Then
            SearchCerts(Nothing, Nothing)
            dt = TryCast(ViewState("CertData"), DataTable)
        End If
        Dim title As String = "UMMI Certificates — " & drpdwnCertType.SelectedValue
        ExportToExcel(dt, "Certs_" & drpdwnCertType.SelectedValue & "_" & DateTime.Now.ToString("yyyyMMdd"), title, Response)
    End Sub

End Class
