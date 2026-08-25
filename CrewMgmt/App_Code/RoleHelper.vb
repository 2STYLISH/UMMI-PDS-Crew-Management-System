Imports System.Web

''' <summary>
''' Role and permission helper for the Crew Management Module.
''' Supports seven distinct roles:
''' 1. MANNING_STAFF
''' 2. SUPER_ADMIN
''' 3. PRINCIPAL
''' 4. APPLICANT
''' 5. DOCUMENTATION_OFFICER (access equivalent to MANNING_STAFF)
''' 6. ADMIN (access equivalent to SUPER_ADMIN)
''' 7. VESSEL_OWNER (access equivalent to PRINCIPAL)
''' </summary>
Module RoleHelper

    ' ════════════════════════════════════════════════════════════════════════
    ' ROLE STRING CONSTANTS (tbl_user_type.user_type values)
    ' ════════════════════════════════════════════════════════════════════════
    Public Const ROLE_MANNING_STAFF         As String = "MANNING_STAFF"
    Public Const ROLE_SUPER_ADMIN           As String = "SUPER_ADMIN"
    Public Const ROLE_PRINCIPAL             As String = "PRINCIPAL"
    Public Const ROLE_APPLICANT             As String = "APPLICANT"
    Public Const ROLE_DOCUMENTATION_OFFICER As String = "DOCUMENTATION_OFFICER"
    Public Const ROLE_ADMIN                 As String = "ADMIN"
    Public Const ROLE_VESSEL_OWNER          As String = "VESSEL_OWNER"

    ' Legacy aliases preserved for backward compatibility
    Public Const ROLE_MANNING               As String = "MANNING_STAFF"
    Public Const ROLE_SUPERADMIN            As String = "SUPER_ADMIN"

    ' ════════════════════════════════════════════════════════════════════════
    ' ROLE NUMERIC IDS (tbl_user_type.id values)
    ' ════════════════════════════════════════════════════════════════════════
    Public Const ROLE_ID_MANNING_STAFF         As Integer = 1
    Public Const ROLE_ID_SUPER_ADMIN           As Integer = 2
    Public Const ROLE_ID_PRINCIPAL             As Integer = 3
    Public Const ROLE_ID_APPLICANT             As Integer = 4
    Public Const ROLE_ID_DOCUMENTATION_OFFICER As Integer = 5
    Public Const ROLE_ID_ADMIN                 As Integer = 6
    Public Const ROLE_ID_VESSEL_OWNER          As Integer = 7

    ''' <summary>Return the current user's actual role code from session.</summary>
    Public Function CurrentRole() As String
        Dim ctx As HttpContext = HttpContext.Current
        If ctx Is Nothing OrElse ctx.Session("UserType") Is Nothing Then Return String.Empty
        Return ctx.Session("UserType").ToString()
    End Function

    ' ════════════════════════════════════════════════════════════════════════
    ' EXACT-ROLE IDENTITY HELPERS (Strict check for specific identity)
    ' ════════════════════════════════════════════════════════════════════════

    ''' <summary>True only if current user is exactly Manning Staff.</summary>
    Public Function IsManningStaff() As Boolean
        Return CurrentRole() = ROLE_MANNING_STAFF
    End Function

    ''' <summary>True only if current user is exactly Documentation Officer.</summary>
    Public Function IsDocumentationOfficer() As Boolean
        Return CurrentRole() = ROLE_DOCUMENTATION_OFFICER
    End Function

    ''' <summary>True only if current user is exactly Super-Admin.</summary>
    Public Function IsSuperAdmin() As Boolean
        Return CurrentRole() = ROLE_SUPER_ADMIN
    End Function

    ''' <summary>True only if current user is exactly Admin.</summary>
    Public Function IsAdmin() As Boolean
        Return CurrentRole() = ROLE_ADMIN
    End Function

    ''' <summary>True only if current user is exactly Principal.</summary>
    Public Function IsPrincipal() As Boolean
        Return CurrentRole() = ROLE_PRINCIPAL
    End Function

    ''' <summary>True only if current user is exactly Vessel Owner.</summary>
    Public Function IsVesselOwner() As Boolean
        Return CurrentRole() = ROLE_VESSEL_OWNER
    End Function

    ''' <summary>True only if current user is exactly Applicant.</summary>
    Public Function IsApplicant() As Boolean
        Return CurrentRole() = ROLE_APPLICANT
    End Function

    ''' <summary>Exact identity helper for Manning Staff.</summary>
    Public Function IsManning() As Boolean
        Return IsManningStaff()
    End Function

    ' ════════════════════════════════════════════════════════════════════════
    ' ACCESS-GROUP HELPERS (For authorization, navigation, and feature access)
    ' ════════════════════════════════════════════════════════════════════════

    ''' <summary>
    ''' True if the user belongs to the Manning Staff access group:
    ''' MANNING_STAFF or DOCUMENTATION_OFFICER.
    ''' </summary>
    Public Function HasManningAccess() As Boolean
        Dim r As String = CurrentRole()
        Return r = ROLE_MANNING_STAFF OrElse r = ROLE_DOCUMENTATION_OFFICER
    End Function

    ''' <summary>
    ''' True if the user belongs to the Administrative access group:
    ''' SUPER_ADMIN or ADMIN.
    ''' </summary>
    Public Function HasAdministrativeAccess() As Boolean
        Dim r As String = CurrentRole()
        Return r = ROLE_SUPER_ADMIN OrElse r = ROLE_ADMIN
    End Function

    ''' <summary>
    ''' True if the user belongs to the Internal Staff access group:
    ''' MANNING_STAFF, DOCUMENTATION_OFFICER, SUPER_ADMIN, ADMIN.
    ''' </summary>
    Public Function HasInternalStaffAccess() As Boolean
        Return HasManningAccess() OrElse HasAdministrativeAccess()
    End Function

    ''' <summary>
    ''' True if the user belongs to the Principal access group:
    ''' PRINCIPAL or VESSEL_OWNER.
    ''' </summary>
    Public Function HasPrincipalAccess() As Boolean
        Dim r As String = CurrentRole()
        Return r = ROLE_PRINCIPAL OrElse r = ROLE_VESSEL_OWNER
    End Function

    ''' <summary>
    ''' True if the user belongs to the Applicant access group:
    ''' APPLICANT.
    ''' </summary>
    Public Function HasApplicantAccess() As Boolean
        Return CurrentRole() = ROLE_APPLICANT
    End Function

    ' ════════════════════════════════════════════════════════════════════════
    ' INDIVIDUAL USER PERMISSIONS & FEATURE FLAGS
    ' ════════════════════════════════════════════════════════════════════════

    ''' <summary>
    ''' True if the current user can see restricted crew contact/family/assessment info.
    ''' Controlled by per-user flag Session("UserViewCrewContactDetails") = "1".
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
    ''' UC-CM-06: True if user can navigate to Crew Change List from crew search results.
    ''' Administrative access (SUPER_ADMIN, ADMIN) grants CCL access by default,
    ''' or user must have explicit ccl_permission flag set.
    ''' </summary>
    Public Function HasCCLPermission() As Boolean
        If HasAdministrativeAccess() Then Return True
        Dim ctx As HttpContext = HttpContext.Current
        If ctx Is Nothing OrElse ctx.Session("UserCCLPermission") Is Nothing Then Return False
        Return CStr(ctx.Session("UserCCLPermission")) = "1"
    End Function

    ''' <summary>
    ''' UC-CM-25/26: True if user can access the Releasing Checklist.
    ''' Available to internal staff (MANNING_STAFF, DOCUMENTATION_OFFICER, SUPER_ADMIN, ADMIN).
    ''' </summary>
    Public Function CanViewReleasingChecklist() As Boolean
        Return HasInternalStaffAccess()
    End Function

    ''' <summary>
    ''' UC-CM-09 FR-CM-20: True if user has PDS role for extra sea service columns.
    ''' Available to Administrative access group (SUPER_ADMIN, ADMIN).
    ''' </summary>
    Public Function IsPDSRole() As Boolean
        Return HasAdministrativeAccess()
    End Function

    ''' <summary>Returns human-readable display name for any role code.</summary>
    Public Function GetRoleDisplayName(roleCode As String) As String
        Select Case roleCode
            Case ROLE_SUPER_ADMIN
                Return "Super Admin"
            Case ROLE_ADMIN
                Return "Admin"
            Case ROLE_MANNING_STAFF
                Return "Manning Staff"
            Case ROLE_DOCUMENTATION_OFFICER
                Return "Documentation Officer"
            Case ROLE_PRINCIPAL
                Return "Principal"
            Case ROLE_VESSEL_OWNER
                Return "Vessel Owner"
            Case ROLE_APPLICANT
                Return "Applicant"
            Case Else
                Return roleCode
        End Select
    End Function

    ' ════════════════════════════════════════════════════════════════════════
    ' PAGE SECURITY & AUTHORIZATION
    ' ════════════════════════════════════════════════════════════════════════

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
