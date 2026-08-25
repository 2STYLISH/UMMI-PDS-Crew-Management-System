Option Strict Off
Option Explicit On

Partial Public Class SelfEncode
    Protected WithEvents lblNotify As Global.System.Web.UI.WebControls.Label
    Protected WithEvents hfCurrentStep As Global.System.Web.UI.WebControls.HiddenField
    Protected WithEvents txtLastName As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents txtFirstName As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents txtMiddleName As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents drpdwnSuffix As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents txtDOB As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents txtPOB As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents drpdwnGender As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents drpdwnCivilStatus As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents drpdwnReligion As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents txtReligionOther As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents drpdwnNationality As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents txtNationalityOther As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents txtHeight As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents txtWeight As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents drpdwnRank As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents txtContact As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents txtEmail As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents txtAddress As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents drpdwnProvince As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents drpdwnCity As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents drpdwnSchool As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents txtSchoolOther As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents drpdwnCourse As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents txtCourseOther As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents lblReviewName As Global.System.Web.UI.WebControls.Label
    Protected WithEvents lblReviewDOB As Global.System.Web.UI.WebControls.Label
    Protected WithEvents lblReviewContact As Global.System.Web.UI.WebControls.Label
    Protected WithEvents lblReviewRank As Global.System.Web.UI.WebControls.Label
    Protected WithEvents btnSubmit As Global.System.Web.UI.WebControls.Button
End Class