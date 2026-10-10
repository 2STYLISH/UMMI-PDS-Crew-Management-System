Imports MySql.Data.MySqlClient

Partial Class Settings_UserAccounts
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        RequireLogin()
        RequireRole(ROLE_SUPER_ADMIN)
        If Not IsPostBack Then
            CType(Master, masterPage).lblPageTitle.Text = "User Accounts"
        End If
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        pnlEdit.Visible = False
        lblMessage.Text = ""
        Dim query As String = txtSearch.Text.Trim()
        
        Dim sql As String = "SELECT id, username, fullname, type FROM tbl_users WHERE username LIKE @q OR fullname LIKE @q ORDER BY fullname"
        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text, New MySqlParameter("@q", "%" & query & "%"))
        gvUsers.DataSource = dt
        gvUsers.DataBind()
    End Sub

    Protected Sub gvUsers_SelectedIndexChanged(sender As Object, e As EventArgs)
        lblMessage.Text = ""
        Dim userId As Integer = Convert.ToInt32(gvUsers.SelectedDataKey.Value)
        LoadUserAccess(userId)
    End Sub

    Private Sub LoadUserAccess(userId As Integer)
        Dim sql As String = "SELECT id, username, fullname, type, allow_crew_search, allow_applicant_pool FROM tbl_users WHERE id = @id"
        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                cmd.Parameters.AddWithValue("@id", userId)
                Using dr As MySqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        hfEditUserId.Value = dr("id").ToString()
                        lblEditUser.Text = Server.HtmlEncode(dr("fullname").ToString() & " (" & dr("username").ToString() & ")")
                        Dim role As String = dr("type").ToString()
                        lblEditRole.Text = GetRoleDisplayName(role)

                        If role = ROLE_SUPER_ADMIN Then
                            pnlSettings.Visible = False
                            pnlSuperAdmin.Visible = True
                        Else
                            pnlSettings.Visible = True
                            pnlSuperAdmin.Visible = False
                            chkAllowCrewSearch.Checked = (Convert.ToInt32(dr("allow_crew_search")) = 1)
                            chkAllowApplicantPool.Checked = (Convert.ToInt32(dr("allow_applicant_pool")) = 1)
                        End If
                        
                        pnlEdit.Visible = True
                        pnlSearch.Visible = False
                    End If
                End Using
            End Using
        End Using
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        Dim userId As Integer = Convert.ToInt32(hfEditUserId.Value)
        Dim allowCS As Integer = If(chkAllowCrewSearch.Checked, 1, 0)
        Dim allowAP As Integer = If(chkAllowApplicantPool.Checked, 1, 0)

        Dim sql As String = "UPDATE tbl_users SET allow_crew_search=@cs, allow_applicant_pool=@ap WHERE id=@id AND type != @sa"
        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                cmd.Parameters.AddWithValue("@cs", allowCS)
                cmd.Parameters.AddWithValue("@ap", allowAP)
                cmd.Parameters.AddWithValue("@id", userId)
                cmd.Parameters.AddWithValue("@sa", ROLE_SUPER_ADMIN)
                cmd.ExecuteNonQuery()
            End Using
        End Using

        GetAdmin("Updated user access", CurrentUserID().ToString(), "UserAccounts", "Target UserID: " & userId)
        lblMessage.Text = "Access settings updated successfully. Changes will apply on the user's next login."
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        pnlEdit.Visible = False
        pnlSearch.Visible = True
    End Sub

End Class
