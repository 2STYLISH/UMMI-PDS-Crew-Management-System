Imports System.Web.SessionState
Public Class GlobalApplication
    Inherits System.Web.HttpApplication
    Sub Application_Start(ByVal sender As Object, ByVal e As EventArgs)
    End Sub
    Sub Session_Start(ByVal sender As Object, ByVal e As EventArgs)
    End Sub
    Sub Application_Error(ByVal sender As Object, ByVal e As EventArgs)
        Dim ex As Exception = Server.GetLastError()
    End Sub
    Sub Session_End(ByVal sender As Object, ByVal e As EventArgs)
    End Sub
End Class
