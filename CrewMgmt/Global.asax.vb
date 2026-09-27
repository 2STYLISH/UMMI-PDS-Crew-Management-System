Imports System.Web.SessionState
Imports System.Web.Caching

''' <summary>
''' F.3: Global application events.
''' Application_Start: initialises the once-per-24h abandoned staging cleanup gate.
''' Session_End: voluntarily purges staged files for the ending session so no
'''              orphaned disk artifacts are left behind after normal session expiry.
''' </summary>
Public Class GlobalApplication
    Inherits System.Web.HttpApplication

    ''' F.3: Cache key used as a rate-limit gate to prevent CleanupAbandonedStagingSessions
    ''' from executing more than once per 24 hours across all concurrent requests.
    Private Const CLEANUP_GATE_KEY As String = "ApplicantStagingCleanup_LastRun"

    Sub Application_Start(ByVal sender As Object, ByVal e As EventArgs)
        ' F.3: Prime the 24-hour cleanup gate on first application start.
        ' The gate is set with a 24-hour absolute expiry; when it expires ASP.NET
        ' will automatically allow the next request to trigger a cleanup cycle.
        If HttpRuntime.Cache(CLEANUP_GATE_KEY) Is Nothing Then
            HttpRuntime.Cache.Insert(CLEANUP_GATE_KEY, DateTime.UtcNow,
                Nothing, DateTime.UtcNow.AddHours(24),
                Cache.NoSlidingExpiration,
                CacheItemPriority.Default, Nothing)
            ' Run an initial cleanup pass on startup (safe-fail)
            Try
                ApplicantStorageService.CleanupAbandonedStagingSessions()
            Catch
            End Try
        End If
    End Sub

    Sub Session_Start(ByVal sender As Object, ByVal e As EventArgs)
    End Sub

    Sub Application_Error(ByVal sender As Object, ByVal e As EventArgs)
        Dim ex As Exception = Server.GetLastError()
    End Sub

    ''' <summary>
    ''' F.3: Voluntary cleanup on session end.
    ''' Deletes any remaining staged documents tied to the ending session's active job.
    ''' NOTE: Session_End only fires when sessionState mode="InProc". If SqlServer or
    ''' StateServer mode is used in production, staged file cleanup must be handled via
    ''' the 24-hour scheduled CleanupAbandonedStagingSessions sweep instead.
    ''' </summary>
    Sub Session_End(ByVal sender As Object, ByVal e As EventArgs)
        Try
            Dim sessionId As String = Session.SessionID
            If Not String.IsNullOrWhiteSpace(sessionId) Then
                ApplicantExtractionJobManager.ClearStagedFilesForSession(sessionId)
            End If
        Catch
            ' Safe-fail: session end cleanup must never disrupt ASP.NET session infrastructure
        End Try
    End Sub

    ''' <summary>
    ''' F.3: Rate-limited lazy trigger for abandoned staging cleanup.
    ''' Call this from any request handler that should participate in the maintenance sweep.
    ''' Executes at most once per 24 hours regardless of how many concurrent requests arrive.
    ''' </summary>
    Public Shared Sub TryRunScheduledStagingCleanup()
        Try
            If HttpRuntime.Cache(CLEANUP_GATE_KEY) Is Nothing Then
                ' Gate expired — time for a new cleanup cycle
                HttpRuntime.Cache.Insert(CLEANUP_GATE_KEY, DateTime.UtcNow,
                    Nothing, DateTime.UtcNow.AddHours(24),
                    Cache.NoSlidingExpiration,
                    CacheItemPriority.Default, Nothing)
                ' Run cleanup asynchronously so current request is not blocked
                System.Web.Hosting.HostingEnvironment.QueueBackgroundWorkItem(
                    Sub(ct)
                        Try
                            ApplicantStorageService.CleanupAbandonedStagingSessions()
                        Catch
                        End Try
                    End Sub)
            End If
        Catch
            ' Safe-fail: maintenance must never break handler execution
        End Try
    End Sub

End Class
