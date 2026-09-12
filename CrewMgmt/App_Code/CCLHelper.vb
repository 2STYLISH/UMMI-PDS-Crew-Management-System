Imports MySql.Data.MySqlClient
Imports System.Data
Imports System.Web

''' <summary>
''' CCL (Change Crew List) Business Logic Module.
''' Handles reliever management, schedule CRUD, EOC auto-generation,
''' validation, conflict detection, and CCL-specific audit logging.
''' </summary>
Module CCLHelper

    ' ════════════════════════════════════════════════════════
    ' STATUS CONSTANTS
    ' ════════════════════════════════════════════════════════

    ' Reliever statuses
    Public Const RELIEVER_PENDING   As String = "Pending Approval"
    Public Const RELIEVER_APPROVED  As String = "Approved"
    Public Const RELIEVER_REJECTED  As String = "Rejected"
    Public Const RELIEVER_CANCELLED As String = "Cancelled"

    ' Schedule statuses
    Public Const SCHED_TENTATIVE  As String = "Tentative"
    Public Const SCHED_NEXT       As String = "Next"
    Public Const SCHED_COMPLETED  As String = "Completed"
    Public Const SCHED_CANCELLED  As String = "Cancelled"

    ' EOC statuses
    Public Const EOC_GENERATED  As String = "Generated"
    Public Const EOC_CANCELLED  As String = "Cancelled"
    Public Const EOC_SUPERSEDED As String = "Superseded"

    ' crew_status numeric values (mirrors tbl_dropdown_selection.sequence)
    Public Const CREW_ACTIVE   As Integer = 1
    Public Const CREW_ONBOARD  As Integer = 3
    Public Const CREW_RELIEVER As Integer = 7

    ' ════════════════════════════════════════════════════════
    ' DATA TRANSFER OBJECT
    ' ════════════════════════════════════════════════════════

    Public Class CCLScheduleDTO
        Public Property ScheduleId       As Integer = 0    ' 0 = new insert
        Public Property RelieverRecordId As Integer
        Public Property VesselId         As Integer
        Public Property CrewId           As Integer        ' incoming (reliever) crew
        Public Property JoiningDate      As Date
        Public Property JoiningPort      As String = ""
        Public Property DepartureDate    As Date
        Public Property ShipOnsignDate   As Date
        Public Property ScheduleStatus   As String = SCHED_TENTATIVE
        Public Property CreatedBy        As Integer
    End Class

    Public Class ApplyResult
        Public Property SuccessCount As Integer = 0
        Public Property SkippedList  As New List(Of String)
        Public Property Errors       As New List(Of String)
        Public ReadOnly Property IsSuccess As Boolean
            Get
                Return Errors.Count = 0
            End Get
        End Property
    End Class

    ' ════════════════════════════════════════════════════════
    ' SECTION 1: LOAD CCL DATA
    ' ════════════════════════════════════════════════════════

    ''' <summary>
    ''' Master query for the CCL grid.
    ''' Returns all ON BOARD and LINE UP crew for the vessel, joined
    ''' with their latest active reliever, schedule, and EOC records.
    ''' </summary>
    Public Function LoadCCLData(vesselId As Integer) As DataTable
        Dim sql As String =
            "SELECT " &
            "  pi.id                                                            AS crew_id," &
            "  r.rank_code," &
            "  TRIM(CONCAT(pi.lastname, ', ', pi.firstname, ' ', IFNULL(pi.middlename,''))) AS crew_name," &
            "  pi.crew_status," &
            "  ds.meaning                                                       AS crew_status_text," &
            "  pi.assigned_vessel_id," &
            "  cclr.id                                                          AS reliever_record_id," &
            "  cclr.status                                                      AS reliever_status," &
            "  cclr.reliever_crew_id," &
            "  cclr.approval_remarks," &
            "  cclr.approved_at," &
            "  TRIM(CONCAT(rpi.lastname, ', ', rpi.firstname))                  AS reliever_name," &
            "  rr.rank_code                                                     AS reliever_rank," &
            "  ccls.id                                                          AS schedule_id," &
            "  ccls.joining_date," &
            "  ccls.joining_port," &
            "  ccls.departure_date," &
            "  ccls.ship_onsign_date," &
            "  ccls.schedule_status," &
            "  eoc.id                                                           AS eoc_id," &
            "  eoc.eoc_status," &
            "  eoc.sign_on_date," &
            "  eoc.sign_off_date " &
            "FROM tbl_personnel_info pi " &
            "LEFT JOIN tbl_rank r ON r.id = pi.position " &
            "LEFT JOIN tbl_dropdown_selection ds " &
            "       ON ds.type = 'crew_status' AND ds.sequence = pi.crew_status " &
            "LEFT JOIN tbl_ccl_relievers cclr " &
            "       ON cclr.outgoing_crew_id = pi.id " &
            "      AND cclr.vessel_id = @vid " &
            "      AND cclr.status NOT IN ('Rejected','Cancelled') " &
            "LEFT JOIN tbl_personnel_info rpi ON rpi.id = cclr.reliever_crew_id " &
            "LEFT JOIN tbl_rank rr ON rr.id = rpi.position " &
            "LEFT JOIN tbl_ccl_schedules ccls " &
            "       ON ccls.reliever_id = cclr.id " &
            "      AND ccls.schedule_status NOT IN ('Cancelled') " &
            "LEFT JOIN tbl_ccl_eoc eoc " &
            "       ON eoc.schedule_id = ccls.id " &
            "      AND eoc.outgoing_crew_id = pi.id " &
            "WHERE pi.crew_status IN (3, 6) " &
            "  AND pi.assigned_vessel_id = @vid " &
            "ORDER BY r.sequence, pi.lastname"

        Return DbHelper.FillDataTable(sql, CommandType.Text,
                                      New MySqlParameter("@vid", vesselId))
    End Function

    ''' <summary>
    ''' Load summary statistics for the CCL header cards.
    ''' Returns a single-row DataTable with named columns.
    ''' </summary>
    Public Function LoadCCLSummary(vesselId As Integer) As DataRow
        Dim sql As String =
            "SELECT " &
            "  SUM(CASE WHEN pi.crew_status = 3 THEN 1 ELSE 0 END)                                       AS cnt_onboard," &
            "  SUM(CASE WHEN cclr.status = 'Pending Approval' THEN 1 ELSE 0 END)                         AS cnt_pending," &
            "  SUM(CASE WHEN cclr.status = 'Approved' AND ccls.id IS NULL THEN 1 ELSE 0 END)             AS cnt_approved_no_sched," &
            "  SUM(CASE WHEN ccls.schedule_status = 'Tentative' THEN 1 ELSE 0 END)                       AS cnt_tentative," &
            "  SUM(CASE WHEN ccls.schedule_status = 'Next' THEN 1 ELSE 0 END)                            AS cnt_next " &
            "FROM tbl_personnel_info pi " &
            "LEFT JOIN tbl_ccl_relievers cclr " &
            "       ON cclr.outgoing_crew_id = pi.id AND cclr.vessel_id = @vid " &
            "      AND cclr.status NOT IN ('Rejected','Cancelled') " &
            "LEFT JOIN tbl_ccl_schedules ccls " &
            "       ON ccls.reliever_id = cclr.id AND ccls.schedule_status NOT IN ('Cancelled') " &
            "WHERE pi.crew_status IN (3,6) AND pi.assigned_vessel_id = @vid"

        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text,
                                                     New MySqlParameter("@vid", vesselId))
        If dt.Rows.Count > 0 Then Return dt.Rows(0)
        Return Nothing
    End Function

    ''' <summary>
    ''' Load available (ACTIVE, crew_availability=1) crew for the reliever picker.
    ''' Excludes crew already assigned to a vessel or already an active reliever.
    ''' </summary>
    Public Function LoadAvailableRelievers(vesselId As Integer,
                                           Optional searchTerm As String = "") As DataTable
        Dim likeTerm As String = "%" & searchTerm & "%"
        Dim sql As String =
            "SELECT pi.id, r.rank_code, " &
            "  TRIM(CONCAT(pi.lastname, ', ', pi.firstname, ' ', IFNULL(pi.middlename,''))) AS crew_name " &
            "FROM tbl_personnel_info pi " &
            "LEFT JOIN tbl_rank r ON r.id = pi.position " &
            "WHERE pi.crew_status = 1 " &
            "  AND pi.crew_availability = 1 " &
            "  AND (pi.assigned_vessel_id IS NULL OR pi.assigned_vessel_id = 0) " &
            "  AND pi.id NOT IN (" &
            "      SELECT reliever_crew_id FROM tbl_ccl_relievers " &
            "      WHERE status IN ('Pending Approval','Approved')" &
            "  ) " &
            "  AND (pi.lastname LIKE @s OR pi.firstname LIKE @s OR r.rank_code LIKE @s) " &
            "ORDER BY r.sequence, pi.lastname " &
            "LIMIT 50"

        Return DbHelper.FillDataTable(sql, CommandType.Text,
                                      New MySqlParameter("@s", likeTerm))
    End Function

    ' ════════════════════════════════════════════════════════
    ' SECTION 2: RELIEVER MANAGEMENT
    ' ════════════════════════════════════════════════════════

    ''' <summary>
    ''' Check whether an active (Pending/Approved) reliever record already
    ''' exists for this outgoing crew on this vessel. Used to prevent duplicates.
    ''' </summary>
    Public Function HasActiveReliever(vesselId As Integer, outgoingCrewId As Integer) As Boolean
        Dim sql As String =
            "SELECT COUNT(*) FROM tbl_ccl_relievers " &
            "WHERE vessel_id=@vid AND outgoing_crew_id=@oid " &
            "  AND status IN ('Pending Approval','Approved')"
        Dim cnt As Object = DbHelper.ExecuteScalar(sql,
                                New MySqlParameter("@vid", vesselId),
                                New MySqlParameter("@oid", outgoingCrewId))
        Return (cnt IsNot Nothing AndAlso CInt(cnt) > 0)
    End Function

    ''' <summary>
    ''' Check whether a crew member is already committed as a reliever
    ''' on any active CCL (prevents double-booking a reliever).
    ''' </summary>
    Public Function IsAlreadyReliever(relieverCrewId As Integer) As Boolean
        Dim sql As String =
            "SELECT COUNT(*) FROM tbl_ccl_relievers " &
            "WHERE reliever_crew_id = @rid AND status IN ('Pending Approval','Approved')"
        Dim cnt As Object = DbHelper.ExecuteScalar(sql,
                                New MySqlParameter("@rid", relieverCrewId))
        Return (cnt IsNot Nothing AndAlso CInt(cnt) > 0)
    End Function

    ''' <summary>
    ''' Create a new reliever record. Returns new ID or -1 on failure.
    ''' </summary>
    Public Function CreateReliever(vesselId As Integer,
                                   outgoingCrewId As Integer,
                                   relieverCrewId As Integer,
                                   createdBy As Integer,
                                   Optional remarks As String = "") As Integer
        ' Business rule: no duplicate active reliever
        If HasActiveReliever(vesselId, outgoingCrewId) Then Return -1
        If IsAlreadyReliever(relieverCrewId) Then Return -2
        If outgoingCrewId = relieverCrewId Then Return -3  ' cannot self-relieve

        Dim sql As String =
            "INSERT INTO tbl_ccl_relievers " &
            "(vessel_id, outgoing_crew_id, reliever_crew_id, status, remarks, created_by) " &
            "VALUES (@vid, @oid, @rid, 'Pending Approval', @rem, @uid)"

        Using cn As MySqlConnection = DbHelper.GetConnection()
            Using cmd As New MySqlCommand(sql, cn)
                cmd.Parameters.AddWithValue("@vid", vesselId)
                cmd.Parameters.AddWithValue("@oid", outgoingCrewId)
                cmd.Parameters.AddWithValue("@rid", relieverCrewId)
                cmd.Parameters.AddWithValue("@rem", If(String.IsNullOrEmpty(remarks), DBNull.Value, CObj(remarks)))
                cmd.Parameters.AddWithValue("@uid", createdBy)
                cmd.ExecuteNonQuery()
                Dim newId As Integer = CInt(cmd.LastInsertedId)
                LogCCLAudit("reliever", newId, "Created", Nothing, RELIEVER_PENDING, remarks, createdBy)
                Return newId
            End Using
        End Using
    End Function

    ''' <summary>
    ''' Approve a reliever. Updates status to Approved and sets
    ''' reliever crew_status to RELIEVER (7) to block further assignments.
    ''' </summary>
    Public Function ApproveReliever(relieverId As Integer,
                                    approverId As Integer,
                                    Optional remarks As String = "") As Boolean
        ' Get reliever crew ID for status update
        Dim relCrewIdObj As Object = DbHelper.ExecuteScalar(
            "SELECT reliever_crew_id FROM tbl_ccl_relievers WHERE id=@id AND status='Pending Approval'",
            New MySqlParameter("@id", relieverId))
        If relCrewIdObj Is Nothing OrElse IsDBNull(relCrewIdObj) Then Return False

        Dim relCrewId As Integer = CInt(relCrewIdObj)

        Using cn As MySqlConnection = DbHelper.GetConnection()
            Using tr As MySqlTransaction = cn.BeginTransaction()
                Try
                    ' Update reliever record
                    Dim sql1 As String =
                        "UPDATE tbl_ccl_relievers SET status='Approved', " &
                        "approved_by=@uid, approved_at=NOW(), approval_remarks=@rem " &
                        "WHERE id=@id AND status='Pending Approval'"
                    Using cmd As New MySqlCommand(sql1, cn, tr)
                        cmd.Parameters.AddWithValue("@uid", approverId)
                        cmd.Parameters.AddWithValue("@rem", If(String.IsNullOrEmpty(remarks), DBNull.Value, CObj(remarks)))
                        cmd.Parameters.AddWithValue("@id", relieverId)
                        If cmd.ExecuteNonQuery() = 0 Then
                            tr.Rollback()
                            Return False
                        End If
                    End Using

                    ' Set reliever crew_status to RELIEVER(7)
                    Dim sql2 As String =
                        "UPDATE tbl_personnel_info SET crew_status=7, crew_availability=0 " &
                        "WHERE id=@cid AND crew_status=1"
                    Using cmd As New MySqlCommand(sql2, cn, tr)
                        cmd.Parameters.AddWithValue("@cid", relCrewId)
                        cmd.ExecuteNonQuery()
                    End Using

                    tr.Commit()
                    LogCCLAudit("reliever", relieverId, "Approved", RELIEVER_PENDING, RELIEVER_APPROVED, remarks, approverId)
                    Return True
                Catch ex As Exception
                    tr.Rollback()
                    Return False
                End Try
            End Using
        End Using
    End Function

    ''' <summary>
    ''' Reject a reliever. Returns crew member to ACTIVE status.
    ''' </summary>
    Public Function RejectReliever(relieverId As Integer,
                                   approverId As Integer,
                                   Optional remarks As String = "") As Boolean
        Dim relCrewIdObj As Object = DbHelper.ExecuteScalar(
            "SELECT reliever_crew_id FROM tbl_ccl_relievers WHERE id=@id AND status='Pending Approval'",
            New MySqlParameter("@id", relieverId))
        If relCrewIdObj Is Nothing OrElse IsDBNull(relCrewIdObj) Then Return False
        Dim relCrewId As Integer = CInt(relCrewIdObj)

        Dim sql As String =
            "UPDATE tbl_ccl_relievers SET status='Rejected', " &
            "approved_by=@uid, approved_at=NOW(), approval_remarks=@rem " &
            "WHERE id=@id AND status='Pending Approval'"
        Dim rows As Integer = DbHelper.ExecuteNonQuery(sql,
                                  New MySqlParameter("@uid", approverId),
                                  New MySqlParameter("@rem", If(String.IsNullOrEmpty(remarks), DBNull.Value, CObj(remarks))),
                                  New MySqlParameter("@id", relieverId))
        If rows > 0 Then
            ' Restore crew to ACTIVE (only if still RELIEVER)
            DbHelper.ExecuteNonQuery(
                "UPDATE tbl_personnel_info SET crew_status=1, crew_availability=1 WHERE id=@cid AND crew_status=7",
                New MySqlParameter("@cid", relCrewId))
            LogCCLAudit("reliever", relieverId, "Rejected", RELIEVER_PENDING, RELIEVER_REJECTED, remarks, approverId)
            Return True
        End If
        Return False
    End Function

    ''' <summary>
    ''' Cancel an Approved reliever (Admin/Super Admin only).
    ''' Cascades to cancel any linked Tentative schedule, and also reverts EOC if any.
    ''' </summary>
    Public Function CancelReliever(relieverId As Integer,
                                   cancelledBy As Integer,
                                   Optional remarks As String = "") As Boolean
        Dim relRow As Object = DbHelper.ExecuteScalar(
            "SELECT reliever_crew_id FROM tbl_ccl_relievers WHERE id=@id AND status IN ('Pending Approval','Approved')",
            New MySqlParameter("@id", relieverId))
        If relRow Is Nothing OrElse IsDBNull(relRow) Then Return False
        Dim relCrewId As Integer = CInt(relRow)

        Using cn As MySqlConnection = DbHelper.GetConnection()
            Using tr As MySqlTransaction = cn.BeginTransaction()
                Try
                    ' Cancel any linked Tentative/Next schedules
                    Dim schedIds As New List(Of Integer)
                    Using cmd As New MySqlCommand(
                            "SELECT id FROM tbl_ccl_schedules WHERE reliever_id=@rid AND schedule_status NOT IN ('Cancelled','Completed')", cn, tr)
                        cmd.Parameters.AddWithValue("@rid", relieverId)
                        Using dr As MySqlDataReader = cmd.ExecuteReader()
                            Do While dr.Read()
                                schedIds.Add(dr.GetInt32(0))
                            Loop
                        End Using
                    End Using

                    For Each sid As Integer In schedIds
                        CancelScheduleInternal(sid, cancelledBy, "Reliever cancelled: " & remarks, cn, tr)
                    Next

                    ' Cancel the reliever
                    Using cmd As New MySqlCommand(
                            "UPDATE tbl_ccl_relievers SET status='Cancelled', approval_remarks=@rem WHERE id=@id", cn, tr)
                        cmd.Parameters.AddWithValue("@rem", remarks)
                        cmd.Parameters.AddWithValue("@id", relieverId)
                        cmd.ExecuteNonQuery()
                    End Using

                    ' Restore crew to ACTIVE if still at RELIEVER(7)
                    Using cmd As New MySqlCommand(
                            "UPDATE tbl_personnel_info SET crew_status=1, crew_availability=1 WHERE id=@cid AND crew_status=7", cn, tr)
                        cmd.Parameters.AddWithValue("@cid", relCrewId)
                        cmd.ExecuteNonQuery()
                    End Using

                    tr.Commit()
                    LogCCLAudit("reliever", relieverId, "Cancelled", RELIEVER_APPROVED, RELIEVER_CANCELLED, remarks, cancelledBy)
                    Return True
                Catch ex As Exception
                    tr.Rollback()
                    Return False
                End Try
            End Using
        End Using
    End Function

    ' ════════════════════════════════════════════════════════
    ' SECTION 3: CCL SCHEDULE MANAGEMENT
    ' ════════════════════════════════════════════════════════

    ''' <summary>
    ''' Validate a CCL schedule DTO. Returns a list of error messages (empty = valid).
    ''' </summary>
    Public Function ValidateCCLSchedule(dto As CCLScheduleDTO) As List(Of String)
        Dim errs As New List(Of String)

        If String.IsNullOrWhiteSpace(dto.JoiningPort) Then errs.Add("Joining Port is required.")
        If dto.JoiningDate = Date.MinValue Then errs.Add("Joining Date is required.")
        If dto.DepartureDate = Date.MinValue Then errs.Add("Departure Date is required.")
        If dto.ShipOnsignDate = Date.MinValue Then errs.Add("Ship On-Sign Date is required.")

        If dto.JoiningDate <> Date.MinValue Then
            If dto.JoiningDate < Date.Today Then errs.Add("Joining Date must be today or a future date.")
            If dto.DepartureDate <> Date.MinValue AndAlso dto.DepartureDate < dto.JoiningDate Then
                errs.Add("Departure Date must be on or after Joining Date.")
            End If
            If dto.ShipOnsignDate <> Date.MinValue AndAlso dto.ShipOnsignDate > dto.JoiningDate Then
                errs.Add("Ship On-Sign Date must be on or before Joining Date.")
            End If
        End If

        ' Check reliever status is Approved
        If dto.RelieverRecordId > 0 Then
            Dim status As Object = DbHelper.ExecuteScalar(
                "SELECT status FROM tbl_ccl_relievers WHERE id=@rid",
                New MySqlParameter("@rid", dto.RelieverRecordId))
            If status Is Nothing OrElse IsDBNull(status) Then
                errs.Add("Reliever record not found.")
            ElseIf status.ToString() <> RELIEVER_APPROVED Then
                errs.Add("A CCL schedule can only be created for an Approved reliever.")
            End If
        Else
            errs.Add("Reliever reference is missing.")
        End If

        ' Check for existing active schedule on same reliever
        If dto.ScheduleId = 0 AndAlso dto.RelieverRecordId > 0 Then
            Dim existCount As Object = DbHelper.ExecuteScalar(
                "SELECT COUNT(*) FROM tbl_ccl_schedules WHERE reliever_id=@rid AND schedule_status NOT IN ('Cancelled')",
                New MySqlParameter("@rid", dto.RelieverRecordId))
            If existCount IsNot Nothing AndAlso CInt(existCount) > 0 Then
                errs.Add("A schedule already exists for this reliever. Use Edit to modify it.")
            End If
        End If

        Return errs
    End Function

    ''' <summary>
    ''' Save (insert or update) a CCL schedule. Returns new/existing schedule ID, -1 on failure.
    ''' </summary>
    Public Function SaveCCLSchedule(dto As CCLScheduleDTO) As Integer
        Dim errs As List(Of String) = ValidateCCLSchedule(dto)
        If errs.Count > 0 Then Return -1

        If dto.ScheduleId = 0 Then
            ' INSERT
            Dim sql As String =
                "INSERT INTO tbl_ccl_schedules " &
                "(reliever_id, vessel_id, crew_id, joining_date, joining_port, " &
                " departure_date, ship_onsign_date, schedule_status, created_by) " &
                "VALUES (@rid, @vid, @cid, @jd, @jp, @dd, @sod, 'Tentative', @uid)"
            Using cn As MySqlConnection = DbHelper.GetConnection()
                Using cmd As New MySqlCommand(sql, cn)
                    cmd.Parameters.AddWithValue("@rid", dto.RelieverRecordId)
                    cmd.Parameters.AddWithValue("@vid", dto.VesselId)
                    cmd.Parameters.AddWithValue("@cid", dto.CrewId)
                    cmd.Parameters.AddWithValue("@jd", dto.JoiningDate.ToString("yyyy-MM-dd"))
                    cmd.Parameters.AddWithValue("@jp", dto.JoiningPort.Trim())
                    cmd.Parameters.AddWithValue("@dd", dto.DepartureDate.ToString("yyyy-MM-dd"))
                    cmd.Parameters.AddWithValue("@sod", dto.ShipOnsignDate.ToString("yyyy-MM-dd"))
                    cmd.Parameters.AddWithValue("@uid", dto.CreatedBy)
                    cmd.ExecuteNonQuery()
                    Dim newId As Integer = CInt(cmd.LastInsertedId)
                    LogCCLAudit("schedule", newId, "Created", Nothing, SCHED_TENTATIVE, Nothing, dto.CreatedBy)
                    Return newId
                End Using
            End Using
        Else
            ' UPDATE (only Tentative schedules can be edited by Manning Staff)
            Dim sql As String =
                "UPDATE tbl_ccl_schedules SET " &
                "joining_date=@jd, joining_port=@jp, departure_date=@dd, " &
                "ship_onsign_date=@sod, date_updated=NOW() " &
                "WHERE id=@id AND schedule_status='Tentative'"
            Dim rows As Integer = DbHelper.ExecuteNonQuery(sql,
                                      New MySqlParameter("@jd", dto.JoiningDate.ToString("yyyy-MM-dd")),
                                      New MySqlParameter("@jp", dto.JoiningPort.Trim()),
                                      New MySqlParameter("@dd", dto.DepartureDate.ToString("yyyy-MM-dd")),
                                      New MySqlParameter("@sod", dto.ShipOnsignDate.ToString("yyyy-MM-dd")),
                                      New MySqlParameter("@id", dto.ScheduleId))
            If rows > 0 Then
                LogCCLAudit("schedule", dto.ScheduleId, "Updated", SCHED_TENTATIVE, SCHED_TENTATIVE, Nothing, dto.CreatedBy)
                Return dto.ScheduleId
            End If
            Return -1
        End If
    End Function

    ''' <summary>
    ''' Finalize a Tentative schedule to Next status. Triggers automatic EOC generation.
    ''' Returns True on success.
    ''' </summary>
    Public Function FinalizeSchedule(scheduleId As Integer,
                                     finalizedBy As Integer) As Boolean
        ' Load schedule details needed for EOC
        Dim sql As String =
            "SELECT s.vessel_id, s.crew_id, s.joining_date, " &
            "       r.outgoing_crew_id " &
            "FROM tbl_ccl_schedules s " &
            "JOIN tbl_ccl_relievers r ON r.id = s.reliever_id " &
            "WHERE s.id=@id AND s.schedule_status='Tentative'"
        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text,
                                                     New MySqlParameter("@id", scheduleId))
        If dt.Rows.Count = 0 Then Return False

        Dim row As DataRow = dt.Rows(0)
        Dim vesselId       As Integer = CInt(row("vessel_id"))
        Dim outgoingCrewId As Integer = CInt(row("outgoing_crew_id"))
        Dim joiningDate    As Date    = CDate(row("joining_date"))

        Using cn As MySqlConnection = DbHelper.GetConnection()
            Using tr As MySqlTransaction = cn.BeginTransaction()
                Try
                    ' Set schedule to Next
                    Using cmd As New MySqlCommand(
                            "UPDATE tbl_ccl_schedules SET schedule_status='Next', " &
                            "finalized_by=@uid, finalized_at=NOW(), date_updated=NOW() " &
                            "WHERE id=@id AND schedule_status='Tentative'", cn, tr)
                        cmd.Parameters.AddWithValue("@uid", finalizedBy)
                        cmd.Parameters.AddWithValue("@id", scheduleId)
                        If cmd.ExecuteNonQuery() = 0 Then
                            tr.Rollback()
                            Return False
                        End If
                    End Using

                    ' Auto-generate EOC for outgoing crew (if not already exists)
                    GenerateEOCInternal(scheduleId, outgoingCrewId, vesselId,
                                        joiningDate, finalizedBy, cn, tr)

                    tr.Commit()
                    LogCCLAudit("schedule", scheduleId, "Finalized", SCHED_TENTATIVE, SCHED_NEXT, Nothing, finalizedBy)
                    Return True
                Catch ex As Exception
                    tr.Rollback()
                    Return False
                End Try
            End Using
        End Using
    End Function

    ''' <summary>
    ''' Amend a Next schedule back to Tentative (Admin/Super Admin only).
    ''' Cancels the associated EOC (marks it Superseded).
    ''' </summary>
    Public Function AmendSchedule(scheduleId As Integer,
                                  amendedBy As Integer,
                                  Optional remarks As String = "") As Boolean
        Using cn As MySqlConnection = DbHelper.GetConnection()
            Using tr As MySqlTransaction = cn.BeginTransaction()
                Try
                    Using cmd As New MySqlCommand(
                            "UPDATE tbl_ccl_schedules SET schedule_status='Tentative', " &
                            "finalized_by=NULL, finalized_at=NULL, date_updated=NOW() " &
                            "WHERE id=@id AND schedule_status='Next'", cn, tr)
                        cmd.Parameters.AddWithValue("@id", scheduleId)
                        If cmd.ExecuteNonQuery() = 0 Then
                            tr.Rollback()
                            Return False
                        End If
                    End Using

                    ' Supersede any generated EOC
                    Using cmd As New MySqlCommand(
                            "UPDATE tbl_ccl_eoc SET eoc_status='Superseded', cancelled_at=NOW(), remarks=@rem " &
                            "WHERE schedule_id=@sid AND eoc_status='Generated'", cn, tr)
                        cmd.Parameters.AddWithValue("@rem", remarks)
                        cmd.Parameters.AddWithValue("@sid", scheduleId)
                        cmd.ExecuteNonQuery()
                    End Using

                    tr.Commit()
                    LogCCLAudit("schedule", scheduleId, "Amended", SCHED_NEXT, SCHED_TENTATIVE, remarks, amendedBy)
                    Return True
                Catch ex As Exception
                    tr.Rollback()
                    Return False
                End Try
            End Using
        End Using
    End Function

    ''' <summary>
    ''' Cancel a schedule (Admin/Super Admin). Cascades to cancel EOC.
    ''' </summary>
    Public Function CancelSchedule(scheduleId As Integer,
                                   cancelledBy As Integer,
                                   Optional remarks As String = "") As Boolean
        Using cn As MySqlConnection = DbHelper.GetConnection()
            Using tr As MySqlTransaction = cn.BeginTransaction()
                Try
                    Dim result As Boolean = CancelScheduleInternal(scheduleId, cancelledBy, remarks, cn, tr)
                    If result Then
                        tr.Commit()
                    Else
                        tr.Rollback()
                    End If
                    Return result
                Catch ex As Exception
                    tr.Rollback()
                    Return False
                End Try
            End Using
        End Using
    End Function

    ' Internal version used inside existing transactions
    Private Function CancelScheduleInternal(scheduleId As Integer,
                                            cancelledBy As Integer,
                                            remarks As String,
                                            cn As MySqlConnection,
                                            tr As MySqlTransaction) As Boolean
        ' Get current status
        Dim statusObj As Object
        Using cmd As New MySqlCommand(
                "SELECT schedule_status FROM tbl_ccl_schedules WHERE id=@id", cn, tr)
            cmd.Parameters.AddWithValue("@id", scheduleId)
            statusObj = cmd.ExecuteScalar()
        End Using
        If statusObj Is Nothing OrElse IsDBNull(statusObj) Then Return False
        Dim oldStatus As String = statusObj.ToString()
        If oldStatus = SCHED_CANCELLED OrElse oldStatus = SCHED_COMPLETED Then Return False

        Using cmd As New MySqlCommand(
                "UPDATE tbl_ccl_schedules SET schedule_status='Cancelled', date_updated=NOW() WHERE id=@id", cn, tr)
            cmd.Parameters.AddWithValue("@id", scheduleId)
            cmd.ExecuteNonQuery()
        End Using

        ' Cancel any Generated EOC
        Using cmd As New MySqlCommand(
                "UPDATE tbl_ccl_eoc SET eoc_status='Cancelled', cancelled_at=NOW(), remarks=@rem " &
                "WHERE schedule_id=@sid AND eoc_status='Generated'", cn, tr)
            cmd.Parameters.AddWithValue("@rem", remarks)
            cmd.Parameters.AddWithValue("@sid", scheduleId)
            cmd.ExecuteNonQuery()
        End Using

        LogCCLAudit("schedule", scheduleId, "Cancelled", oldStatus, SCHED_CANCELLED, remarks, cancelledBy)
        Return True
    End Function

    ' ════════════════════════════════════════════════════════
    ' SECTION 4: EOC AUTO-GENERATION
    ' ════════════════════════════════════════════════════════

    ''' <summary>Check if an EOC already exists for this schedule + crew.</summary>
    Public Function CheckDuplicateEOC(scheduleId As Integer, outgoingCrewId As Integer) As Boolean
        Dim cnt As Object = DbHelper.ExecuteScalar(
            "SELECT COUNT(*) FROM tbl_ccl_eoc WHERE schedule_id=@sid AND outgoing_crew_id=@cid",
            New MySqlParameter("@sid", scheduleId),
            New MySqlParameter("@cid", outgoingCrewId))
        Return (cnt IsNot Nothing AndAlso CInt(cnt) > 0)
    End Function

    Private Sub GenerateEOCInternal(scheduleId As Integer,
                                    outgoingCrewId As Integer,
                                    vesselId As Integer,
                                    signOffDate As Date,
                                    generatedBy As Integer,
                                    cn As MySqlConnection,
                                    tr As MySqlTransaction)
        ' Guard: skip if already exists
        Dim existing As Object
        Using cmd As New MySqlCommand(
                "SELECT COUNT(*) FROM tbl_ccl_eoc WHERE schedule_id=@sid AND outgoing_crew_id=@cid", cn, tr)
            cmd.Parameters.AddWithValue("@sid", scheduleId)
            cmd.Parameters.AddWithValue("@cid", outgoingCrewId)
            existing = cmd.ExecuteScalar()
        End Using
        If existing IsNot Nothing AndAlso CInt(existing) > 0 Then Return

        ' Get rank and sign-on date from the latest sea service record
        Dim rankId     As Object = DBNull.Value
        Dim signOnDate As Object = DBNull.Value
        Using cmd As New MySqlCommand(
                "SELECT rank_id, date_from FROM tbl_personnel_sea_service " &
                "WHERE personnel_id=@pid AND vessel_id=@vid " &
                "ORDER BY date_from DESC LIMIT 1", cn, tr)
            cmd.Parameters.AddWithValue("@pid", outgoingCrewId)
            cmd.Parameters.AddWithValue("@vid", vesselId)
            Using dr As MySqlDataReader = cmd.ExecuteReader()
                If dr.Read() Then
                    If Not IsDBNull(dr("rank_id")) Then rankId = dr("rank_id")
                    If Not IsDBNull(dr("date_from")) Then signOnDate = dr("date_from")
                End If
            End Using
        End Using

        ' Also fall back to pi.position if rank not in sea service
        If IsDBNull(rankId) Then
            Using cmd As New MySqlCommand(
                    "SELECT position FROM tbl_personnel_info WHERE id=@pid", cn, tr)
                cmd.Parameters.AddWithValue("@pid", outgoingCrewId)
                Dim pos As Object = cmd.ExecuteScalar()
                If pos IsNot Nothing AndAlso Not IsDBNull(pos) Then rankId = pos
            End Using
        End If

        Using cmd As New MySqlCommand(
                "INSERT INTO tbl_ccl_eoc " &
                "(schedule_id, outgoing_crew_id, vessel_id, rank_id, sign_on_date, " &
                " sign_off_date, eoc_status, generated_by) " &
                "VALUES (@sid, @cid, @vid, @rid, @son, @soff, 'Generated', @uid)", cn, tr)
            cmd.Parameters.AddWithValue("@sid",  scheduleId)
            cmd.Parameters.AddWithValue("@cid",  outgoingCrewId)
            cmd.Parameters.AddWithValue("@vid",  vesselId)
            cmd.Parameters.AddWithValue("@rid",  rankId)
            cmd.Parameters.AddWithValue("@son",  signOnDate)
            cmd.Parameters.AddWithValue("@soff", signOffDate.ToString("yyyy-MM-dd"))
            cmd.Parameters.AddWithValue("@uid",  generatedBy)
            cmd.ExecuteNonQuery()
            Dim eocId As Integer = CInt(cmd.LastInsertedId)
            LogCCLAudit("eoc", eocId, "Generated", Nothing, EOC_GENERATED, Nothing, generatedBy)
        End Using
    End Sub

    ' ════════════════════════════════════════════════════════
    ' SECTION 5: BULK APPLY
    ' ════════════════════════════════════════════════════════

    ''' <summary>
    ''' Apply a schedule template to multiple approved reliever records.
    ''' Skips ineligible (e.g., reliever not yet Approved, already has schedule).
    ''' </summary>
    Public Function ApplyScheduleToAll(relieverIds As List(Of Integer),
                                       template As CCLScheduleDTO) As ApplyResult
        Dim result As New ApplyResult()
        For Each rid As Integer In relieverIds
            ' Load reliever info
            Dim sql As String =
                "SELECT r.status, r.reliever_crew_id, r.vessel_id, pi.crew_status, " &
                "  TRIM(CONCAT(out.lastname, ', ', out.firstname)) AS out_name " &
                "FROM tbl_ccl_relievers r " &
                "JOIN tbl_personnel_info pi ON pi.id = r.reliever_crew_id " &
                "JOIN tbl_personnel_info out ON out.id = r.outgoing_crew_id " &
                "WHERE r.id = @rid"
            Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text,
                                                          New MySqlParameter("@rid", rid))
            If dt.Rows.Count = 0 Then
                result.SkippedList.Add("Reliever ID " & rid & ": record not found.")
                Continue For
            End If
            Dim row As DataRow = dt.Rows(0)
            Dim outName As String = row("out_name").ToString()

            If row("status").ToString() <> RELIEVER_APPROVED Then
                result.SkippedList.Add(outName & ": reliever not yet approved.")
                Continue For
            End If

            ' Check existing schedule
            Dim existCnt As Object = DbHelper.ExecuteScalar(
                "SELECT COUNT(*) FROM tbl_ccl_schedules WHERE reliever_id=@rid AND schedule_status NOT IN ('Cancelled')",
                New MySqlParameter("@rid", rid))
            If existCnt IsNot Nothing AndAlso CInt(existCnt) > 0 Then
                result.SkippedList.Add(outName & ": already has an active schedule.")
                Continue For
            End If

            Dim dto As New CCLScheduleDTO With {
                .ScheduleId = 0,
                .RelieverRecordId = rid,
                .VesselId = CInt(row("vessel_id")),
                .CrewId = CInt(row("reliever_crew_id")),
                .JoiningDate = template.JoiningDate,
                .JoiningPort = template.JoiningPort,
                .DepartureDate = template.DepartureDate,
                .ShipOnsignDate = template.ShipOnsignDate,
                .ScheduleStatus = SCHED_TENTATIVE,
                .CreatedBy = template.CreatedBy
            }

            Dim newId As Integer = SaveCCLSchedule(dto)
            If newId > 0 Then
                result.SuccessCount += 1
            Else
                result.Errors.Add(outName & ": schedule validation failed.")
            End If
        Next
        Return result
    End Function

    ' ════════════════════════════════════════════════════════
    ' SECTION 6: CCL AUDIT LOGGING
    ' ════════════════════════════════════════════════════════

    ''' <summary>
    ''' Write a structured entry to tbl_ccl_audit (does not throw on failure).
    ''' </summary>
    Public Sub LogCCLAudit(entityType As String,
                            entityId   As Integer,
                            action     As String,
                            oldStatus  As String,
                            newStatus  As String,
                            remarks    As String,
                            userId     As Integer)
        Try
            Dim ctx As HttpContext = HttpContext.Current
            Dim userName  As String = ""
            Dim ipAddress As String = "0.0.0.0"
            If ctx IsNot Nothing Then
                If ctx.Session("UserFullname") IsNot Nothing Then
                    userName = ctx.Session("UserFullname").ToString()
                End If
                Dim fwd As String = ctx.Request.ServerVariables("HTTP_X_FORWARDED_FOR")
                ipAddress = If(String.IsNullOrEmpty(fwd),
                               ctx.Request.ServerVariables("REMOTE_ADDR"), fwd)
            End If

            Dim sql As String =
                "INSERT INTO tbl_ccl_audit " &
                "(entity_type, entity_id, action, old_status, new_status, remarks, user_id, user_name, ip_address) " &
                "VALUES (@et, @eid, @act, @old, @new, @rem, @uid, @uname, @ip)"
            DbHelper.ExecuteNonQuery(sql,
                New MySqlParameter("@et",    entityType),
                New MySqlParameter("@eid",   entityId),
                New MySqlParameter("@act",   action),
                New MySqlParameter("@old",   If(oldStatus Is Nothing, CObj(DBNull.Value), CObj(oldStatus))),
                New MySqlParameter("@new",   If(newStatus Is Nothing, CObj(DBNull.Value), CObj(newStatus))),
                New MySqlParameter("@rem",   If(String.IsNullOrEmpty(remarks), CObj(DBNull.Value), CObj(remarks))),
                New MySqlParameter("@uid",   If(userId = 0, CObj(DBNull.Value), CObj(userId))),
                New MySqlParameter("@uname", userName),
                New MySqlParameter("@ip",    ipAddress))
        Catch
            ' Audit must never break main workflow
        End Try
    End Sub

    ' ════════════════════════════════════════════════════════
    ' SECTION 7: CONFLICT DETECTION
    ' ════════════════════════════════════════════════════════

    ''' <summary>
    ''' Returns True if a reliever crew member already has a Tentative or
    ''' Next schedule on any vessel, to detect double-booking conflicts.
    ''' </summary>
    Public Function HasScheduleConflict(relieverCrewId As Integer,
                                        Optional excludeScheduleId As Integer = 0) As Boolean
        Dim sql As String =
            "SELECT COUNT(*) FROM tbl_ccl_schedules s " &
            "JOIN tbl_ccl_relievers r ON r.id = s.reliever_id " &
            "WHERE r.reliever_crew_id = @cid " &
            "  AND s.schedule_status IN ('Tentative','Next') " &
            "  AND s.id <> @exid"
        Dim cnt As Object = DbHelper.ExecuteScalar(sql,
                                New MySqlParameter("@cid",  relieverCrewId),
                                New MySqlParameter("@exid", excludeScheduleId))
        Return (cnt IsNot Nothing AndAlso CInt(cnt) > 0)
    End Function

    ''' <summary>
    ''' Load EOC details for display in the EOC Preview modal.
    ''' </summary>
    Public Function LoadEOCDetails(eocId As Integer) As DataRow
        Dim sql As String =
            "SELECT e.id, e.eoc_status, e.sign_on_date, e.sign_off_date, " &
            "  e.generated_at, e.remarks, " &
            "  TRIM(CONCAT(pi.lastname, ', ', pi.firstname)) AS crew_name, " &
            "  r.rank_code, v.vesselName, s.joining_port " &
            "FROM tbl_ccl_eoc e " &
            "JOIN tbl_personnel_info pi ON pi.id = e.outgoing_crew_id " &
            "JOIN tbl_vessels v ON v.id = e.vessel_id " &
            "JOIN tbl_ccl_schedules s ON s.id = e.schedule_id " &
            "LEFT JOIN tbl_rank r ON r.id = e.rank_id " &
            "WHERE e.id = @id"
        Dim dt As DataTable = DbHelper.FillDataTable(sql, CommandType.Text,
                                                     New MySqlParameter("@id", eocId))
        If dt.Rows.Count > 0 Then Return dt.Rows(0)
        Return Nothing
    End Function

End Module
