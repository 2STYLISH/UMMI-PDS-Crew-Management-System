Option Strict Off
Option Explicit On

Partial Public Class QueryCrew
    Protected WithEvents UpdatePanel1 As Global.System.Web.UI.UpdatePanel
    Protected WithEvents lblNotify As Global.System.Web.UI.WebControls.Label
    Protected WithEvents txtLastName As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents txtFirstName As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents drpdwnCrewStatus As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents drpdwnCrewAvailability As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents drpdwnRankType As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents drpdwnRank As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents drpdwnProvince As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents drpdwnCity As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents drpdwnVesselTypeExperience As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents drpdwnVessel As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents txtDate As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents chkCadetship As Global.System.Web.UI.WebControls.CheckBox
    Protected WithEvents chkJOCAP As Global.System.Web.UI.WebControls.CheckBox
    Protected WithEvents chkHigherLic As Global.System.Web.UI.WebControls.CheckBox
    Protected WithEvents btnSearch As Global.System.Web.UI.WebControls.Button
    Protected WithEvents btnReset As Global.System.Web.UI.WebControls.Button
    Protected WithEvents btnPrintResult As Global.System.Web.UI.WebControls.Button
    Protected WithEvents btnExportExcel As Global.System.Web.UI.WebControls.Button
    Protected WithEvents lblCrewCount As Global.System.Web.UI.WebControls.Label
    Protected WithEvents lblAverageAge As Global.System.Web.UI.WebControls.Label
    Protected WithEvents lblSearchSummary As Global.System.Web.UI.WebControls.Label
    Protected WithEvents GridViewQueryCrew As Global.System.Web.UI.WebControls.GridView
    Protected WithEvents lnkProfile As Global.System.Web.UI.WebControls.HyperLink
    Protected WithEvents divCrewStatus As Global.System.Web.UI.HtmlControls.HtmlGenericControl
    Protected WithEvents divAvailability As Global.System.Web.UI.HtmlControls.HtmlGenericControl
    Protected WithEvents divSummary As Global.System.Web.UI.HtmlControls.HtmlGenericControl
End Class