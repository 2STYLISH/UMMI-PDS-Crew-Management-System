Imports System.Web

''' <summary>
''' Role and permission helper for the Crew Management Module.
''' Four roles: MANNING_STAFF, SUPER_ADMIN, PRINCIPAL, APPLICANT
''' </summary>
Module RoleHelper

    Public Const ROLE_MANNING As String = "MANNING_STAFF"
    Public Const ROLE_ADMIN   As String = "SUPER_ADMIN"
    Public Const ROLE_PRINCIPAL As String = "PRINCIPAL"
    Public Const ROLE_APPLICANT As String = "APPLICANT"

    ''' <summary>Return the current user role from session.</summary>
    Public Function CurrentRole() As String
        Dim ctx As HttpContext = HttpContext.Current
        If ctx Is Nothing OrElse ctx.Session("UserType") Is Nothing Then Return String.Empty
        Return ctx.Session("UserType").ToString()
    End Function

    ''' <summary>True if the user has Manning Staff OR Super-Admin access.</summary>
    Public Function IsManning() As Boolean
        Dim r As String = CurrentRole()
        Return r = ROLE_MANNING OrElse r = ROLE_ADMIN
    End Function

    ''' <summary>True if Super-Admin.</summary>
    Public Function IsSuperAdmin() As Boolean
        Return CurrentRole() = ROLE_ADMIN
    End Function

    ''' <summary>True if Principal (restricted external user).</summary>
    Public Function IsPrincipal() As Boolean
        Return CurrentRole() = ROLE_PRINCIPAL
    End Function

    ''' <summary>True if Applicant (self-encode only).</summary>
    Public Function IsApplicant() As Boolean
        Return CurrentRole() = ROLE_APPLICANT
    End Function

    ''' <summary>
    ''' True if the current user can see restricted crew contact/family/assessment info.
    ''' PRINCIPAL and APPLICANT cannot see these.
    ''' </summary>
    Public Function CanViewContactDetails() As Boolean
        Dim ctx As HttpContext = HttpContext.Current
        If ctx Is Nothing Then Return False
        If ctx.Session("UserViewCrewContactDetails") IsNot Nothing Then
            Return CStr(ctx.Session("UserViewCrewContactDetails")) = "1"
        End If
        Return False
    End Function

    ''' <summary>
    ''' Redirect to login if there is no valid session.
    ''' Call at the top of every Page_Load.
    ''' </summary>
    Public Sub RequireLogin()
        Dim ctx As HttpContext = HttpContext.Current
        If ctx Is Nothing Then Return
        If ctx.Session("UserID") Is Nothing OrElse String.IsNullOrEmpty(ctx.Session("UserID").ToString()) Then
            ctx.Response.Redirect("~/login.aspx", True)
        End If
    End Sub

    ''' <summary>
    ''' Enforce that only allowed roles can access a page.
    ''' If the current role is not in the list, redirect to Home.
    ''' </summary>
    Public Sub RequireRole(ParamArray allowedRoles() As String)
        Dim ctx As HttpContext = HttpContext.Current
        If ctx Is Nothing Then Return
        Dim r As String = CurrentRole()
        For Each role As String In allowedRoles
            If r = role Then Return
        Next
        GetAdmin("Attempted to access restricted page", If(ctx.Session("UserID") IsNot Nothing, ctx.Session("UserID").ToString(), ""), "Security", ctx.Request.RawUrl)
        ctx.Response.Redirect("~/Home.aspx", True)
    End Sub

    ''' <summary>Return user ID as integer (0 if not set).</summary>
    Public Function CurrentUserID() As Integer
        Dim ctx As HttpContext = HttpContext.Current
        If ctx Is Nothing OrElse ctx.Session("UserID") Is Nothing Then Return 0
        Dim id As Integer
        Integer.TryParse(ctx.Session("UserID").ToString(), id)
        Return id
    End Function

    ''' <summary>Return display name of current user.</summary>
    Public Function CurrentUserFullname() As String
        Dim ctx As HttpContext = HttpContext.Current
        If ctx Is Nothing OrElse ctx.Session("UserFullname") Is Nothing Then Return String.Empty
        Return ctx.Session("UserFullname").ToString()
    End Function

End Module
