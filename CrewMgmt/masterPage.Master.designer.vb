Option Strict Off
Option Explicit On

Partial Public Class masterPage
    Protected WithEvents ScriptManager1 As Global.System.Web.UI.ScriptManager
    Protected WithEvents lblMasterNotify As Global.System.Web.UI.WebControls.Label
    Protected WithEvents lnkHome As Global.System.Web.UI.WebControls.HyperLink
    Protected WithEvents divNavCrew As Global.System.Web.UI.HtmlControls.HtmlGenericControl
    Protected WithEvents divNavPersonnel As Global.System.Web.UI.HtmlControls.HtmlGenericControl
    Protected WithEvents divNavAdmin As Global.System.Web.UI.HtmlControls.HtmlGenericControl
    Protected WithEvents divNavApplicant As Global.System.Web.UI.HtmlControls.HtmlGenericControl
    Protected WithEvents lnkSelfEncode As Global.System.Web.UI.WebControls.HyperLink
    Protected WithEvents lblTopbarDate As Global.System.Web.UI.WebControls.Label
    Public    WithEvents lblSidebarRole As Global.System.Web.UI.WebControls.Label
    Protected WithEvents lblUserInitial As Global.System.Web.UI.WebControls.Label
    Public    WithEvents lblTopbarUser As Global.System.Web.UI.WebControls.Label
    Public    WithEvents lblSidebarUser As Global.System.Web.UI.WebControls.Label
    Protected WithEvents btnLogout As Global.System.Web.UI.WebControls.LinkButton
    Public    WithEvents lblPageTitle As Global.System.Web.UI.WebControls.Label
End Class