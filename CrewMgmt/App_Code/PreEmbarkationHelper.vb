Imports MySql.Data.MySqlClient
Imports System.Data

Module PreEmbarkationHelper

    Public Function GenerateTicketNumber() As String
        Return "ET-" & DateTime.UtcNow.ToString("yyyyMMddHHmmss")
    End Function

    ''' <summary>Queue crew for pre-embarkation and persist electronic dispatch directive / e-ticket.</summary>
    Public Function RouteToPreEmbarkation(personnelId As Integer, vesselId As Integer,
                                        batchNumber As String, terminal As String,
                                        portAgentContact As String, reportingDetails As String,
                                        instructions As String, queuedBy As Integer) As Integer
        Dim ticket As String = GenerateTicketNumber()
        Using cn As MySqlConnection = DbHelper.GetConnection()
            Using tr As MySqlTransaction = cn.BeginTransaction()
                Try
                    Dim directiveId As Integer
                    Using cmd As New MySqlCommand(
                        "INSERT INTO tbl_dispatch_directive " &
                        "(personnel_id, vessel_id, ticket_number, batch_number, terminal, port_agent_contact, reporting_details, terminal_instructions, created_by) " &
                        "VALUES (@pid,@vid,@tk,@bn,@term,@pac,@rep,@ins,@uid)", cn, tr)
                        cmd.Parameters.AddWithValue("@pid", personnelId)
                        cmd.Parameters.AddWithValue("@vid", vesselId)
                        cmd.Parameters.AddWithValue("@tk", ticket)
                        cmd.Parameters.AddWithValue("@bn", If(String.IsNullOrEmpty(batchNumber), DBNull.Value, CObj(batchNumber)))
                        cmd.Parameters.AddWithValue("@term", If(String.IsNullOrEmpty(terminal), DBNull.Value, CObj(terminal)))
                        cmd.Parameters.AddWithValue("@pac", If(String.IsNullOrEmpty(portAgentContact), DBNull.Value, CObj(portAgentContact)))
                        cmd.Parameters.AddWithValue("@rep", If(String.IsNullOrEmpty(reportingDetails), DBNull.Value, CObj(reportingDetails)))
                        cmd.Parameters.AddWithValue("@ins", If(String.IsNullOrEmpty(instructions), DBNull.Value, CObj(instructions)))
                        cmd.Parameters.AddWithValue("@uid", queuedBy)
                        cmd.ExecuteNonQuery()
                        directiveId = CInt(cmd.LastInsertedId)
                    End Using

                    Using cmd As New MySqlCommand(
                        "INSERT INTO tbl_pre_embarkation_queue (personnel_id, vessel_id, directive_id, queue_status, queued_by) " &
                        "VALUES (@pid,@vid,@did,'Queued',@uid)", cn, tr)
                        cmd.Parameters.AddWithValue("@pid", personnelId)
                        cmd.Parameters.AddWithValue("@vid", vesselId)
                        cmd.Parameters.AddWithValue("@did", directiveId)
                        cmd.Parameters.AddWithValue("@uid", queuedBy)
                        cmd.ExecuteNonQuery()
                    End Using

                    tr.Commit()
                    Return directiveId
                Catch
                    tr.Rollback()
                    Return 0
                End Try
            End Using
        End Using
    End Function

End Module
