Option Strict Off
Option Explicit On

Partial Public Class Settings_UserAccounts
    Protected WithEvents pnlSearch As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents txtSearch As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnSearch As Global.System.Web.UI.WebControls.Button
    Protected WithEvents gvUsers As Global.System.Web.UI.WebControls.GridView
    Protected WithEvents pnlEdit As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents lblEditUser As Global.System.Web.UI.WebControls.Label
    Protected WithEvents lblEditRole As Global.System.Web.UI.WebControls.Label
    Protected WithEvents hfEditUserId As Global.System.Web.UI.WebControls.HiddenField
    Protected WithEvents pnlSettings As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents chkAllowCrewSearch As Global.System.Web.UI.HtmlControls.HtmlInputCheckBox
    Protected WithEvents chkAllowApplicantPool As Global.System.Web.UI.HtmlControls.HtmlInputCheckBox
    Protected WithEvents btnSave As Global.System.Web.UI.WebControls.Button
    Protected WithEvents btnCancel As Global.System.Web.UI.WebControls.Button
    Protected WithEvents pnlSuperAdmin As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents lblMessage As Global.System.Web.UI.WebControls.Label
End Class
