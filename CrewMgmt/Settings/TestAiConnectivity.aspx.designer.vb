Option Strict Off
Option Explicit On

Partial Public Class TestAiConnectivity
    Protected WithEvents btnRunTest As Global.System.Web.UI.WebControls.Button
    Protected WithEvents panelResults As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents panelMetrics As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents panelError As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents lblStatusBanner As Global.System.Web.UI.WebControls.Label
    Protected WithEvents lblHttpStatus As Global.System.Web.UI.WebControls.Label
    Protected WithEvents lblModelReported As Global.System.Web.UI.WebControls.Label
    Protected WithEvents lblLatency As Global.System.Web.UI.WebControls.Label
    Protected WithEvents lblPromptTokens As Global.System.Web.UI.WebControls.Label
    Protected WithEvents lblCompletionTokens As Global.System.Web.UI.WebControls.Label
    Protected WithEvents lblTotalTokens As Global.System.Web.UI.WebControls.Label
    Protected WithEvents litRawContent As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents lblErrorDetail As Global.System.Web.UI.WebControls.Label
End Class
