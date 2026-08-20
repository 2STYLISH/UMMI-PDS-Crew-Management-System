Option Strict Off
Option Explicit On

Partial Public Class ApplicantPool
    Protected WithEvents lblNotify As Global.System.Web.UI.WebControls.Label
    Protected WithEvents txtLastName As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents txtFirstName As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents drpdwnRankType As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents drpdwnRank As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents txtDateFrom As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents txtDateTo As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnSearch As Global.System.Web.UI.WebControls.Button
    Protected WithEvents btnReset As Global.System.Web.UI.WebControls.Button
    Protected WithEvents btnGenerateLink As Global.System.Web.UI.WebControls.Button
    Protected WithEvents btnManageLinks As Global.System.Web.UI.WebControls.Button
    Protected WithEvents lblCount As Global.System.Web.UI.WebControls.Label
    Protected WithEvents lblAvgAge As Global.System.Web.UI.WebControls.Label
    Protected WithEvents panelGenerateLink As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents btnCloseGenPanel As Global.System.Web.UI.WebControls.Button
    Protected WithEvents txtLinkFullname As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents txtLinkEmail As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents drpdwnLinkRank As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents txtLinkValidity As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnCreateLink As Global.System.Web.UI.WebControls.Button
    Protected WithEvents panelLinkResult As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents lblGeneratedExpiry As Global.System.Web.UI.WebControls.Label
    Protected WithEvents panelManageLinks As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents btnCloseManagePanel As Global.System.Web.UI.WebControls.Button
    Protected WithEvents gvLinks As Global.System.Web.UI.WebControls.GridView
    Protected WithEvents lblLinkStatus As Global.System.Web.UI.WebControls.Label
    Protected WithEvents btnExpireLink As Global.System.Web.UI.WebControls.LinkButton
    Protected WithEvents gvApplicants As Global.System.Web.UI.WebControls.GridView
    Protected WithEvents imgAvatar As Global.System.Web.UI.WebControls.Image
    Protected WithEvents lnkProfile As Global.System.Web.UI.WebControls.HyperLink
    Protected WithEvents lblVesselExp As Global.System.Web.UI.WebControls.Label
    Protected WithEvents btnHire As Global.System.Web.UI.WebControls.LinkButton
    Protected WithEvents divSummary As Global.System.Web.UI.HtmlControls.HtmlGenericControl
    Protected WithEvents txtGeneratedLink As Global.System.Web.UI.HtmlControls.HtmlInputText
    Protected WithEvents drpdwnVesselExpType As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents btnAddApplicant As Global.System.Web.UI.WebControls.Button
    Protected WithEvents btnSendLinkEmail As Global.System.Web.UI.WebControls.Button
    Protected WithEvents drpdwnLinkStatusFilter As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents btnBulkExpire As Global.System.Web.UI.WebControls.Button
End Class