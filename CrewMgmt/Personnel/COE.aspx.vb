Imports MySql.Data.MySqlClient
Imports System.Data

Public Class COE
    Inherits System.Web.UI.Page
    Protected Sub Page_Load(s As Object, e As EventArgs) Handles Me.Load
        RequireLogin()
        RequireRole("MANNING_STAFF", "SUPER_ADMIN")
        If Not IsPostBack Then
            CType(Master, masterPage).lblPageTitle.Text = "COE Generation"
            If Request.QueryString("ID") <> "" Then
                Dim pid As String = Decrypt(HttpUtility.UrlDecode(Request.QueryString("ID")))
                LoadCOE(pid)
            End If
        End If
    End Sub
    Protected Sub SearchCrew(s As Object, e As EventArgs)
        Dim sql As String = "SELECT id, lastname, firstname, r.rank_code FROM tbl_personnel_info pi " &
            "LEFT JOIN tbl_rank r ON r.id=pi.position " &
            "WHERE pi.lastname LIKE CONCAT(''%'',@ln,''%'') ORDER BY pi.lastname LIMIT 20"
        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text, New MySqlParameter("@ln", txtSearch.Text.Trim()))
        gvCrew.DataSource = dt
        gvCrew.DataBind()
    End Sub
    Protected Sub gvCrew_RowCommand(s As Object, e As System.Web.UI.WebControls.GridViewCommandEventArgs)
        If e.CommandName = "SelectCrew" Then LoadCOE(e.CommandArgument.ToString())
    End Sub
    Private Sub LoadCOE(pid As String)
        Dim sql As String = "SELECT pi.lastname, pi.firstname, r.rank_code, pi.date_hired," &
            "(SELECT MAX(date_to) FROM tbl_contracts WHERE personnel_id=pi.id) AS last_contract " &
            "FROM tbl_personnel_info pi LEFT JOIN tbl_rank r ON r.id=pi.position WHERE pi.id=@id"
        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                cmd.Parameters.AddWithValue("@id", pid)
                Using dr As MySqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        lblCOEName.Text = dr("lastname").ToString() & ", " & dr("firstname").ToString()
                        lblCOERank.Text = If(IsDBNull(dr("rank_code")), "", dr("rank_code").ToString())
                        lblCOEFrom.Text = If(IsDBNull(dr("date_hired")), "N/A", CDate(dr("date_hired")).ToString("MMMM dd, yyyy"))
                        lblCOETo.Text   = If(IsDBNull(dr("last_contract")), "Present", CDate(dr("last_contract")).ToString("MMMM dd, yyyy"))
                        panelCOE.Visible = True
                        GetPortalAct("Generated COE", CurrentUserID().ToString(), "COE", "Personnel COE", pid)
                    End If
                End Using
            End Using
        End Using
    End Sub
    Protected Sub ExportCOE(s As Object, e As EventArgs)
        lblNotify.Text = "<div class='alert alert-info'>COE export — use browser Print function to save as PDF.</div>"
    End Sub
End Class
