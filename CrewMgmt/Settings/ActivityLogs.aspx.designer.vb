Option Strict Off
Option Explicit On

Partial Public Class ActivityLogs
    Protected WithEvents drpdwnCategory As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents txtDateFrom As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents txtDateTo As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents txtUser As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnSearch As Global.System.Web.UI.WebControls.Button
    Protected WithEvents btnReset As Global.System.Web.UI.WebControls.Button
    Protected WithEvents btnExport As Global.System.Web.UI.WebControls.Button
    Protected WithEvents lblCount As Global.System.Web.UI.WebControls.Label
    Protected WithEvents gvLogs As Global.System.Web.UI.WebControls.GridView
End Class