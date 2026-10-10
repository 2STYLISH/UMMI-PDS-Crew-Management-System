Imports System.Configuration
Imports System.Net
Imports System.Net.Mail
Imports System.Web
Imports MySql.Data.MySqlClient

''' <summary>Server-side SMTP dispatch for applicant encoding links and system notifications.</summary>
Module EmailHelper

    Public Class EmailResult
        Public Property Success As Boolean
        Public Property ErrorMessage As String = ""
    End Class

    Private Function SmtpEnabled() As Boolean
        Dim host As String = ConfigurationManager.AppSettings("SmtpHost")
        Return Not String.IsNullOrWhiteSpace(host)
    End Function

    Public Function SendMail(toAddress As String, subject As String, bodyPlain As String) As EmailResult
        Dim result As New EmailResult()
        If String.IsNullOrWhiteSpace(toAddress) Then
            result.ErrorMessage = "Recipient email is required."
            Return result
        End If
        If Not SmtpEnabled() Then
            result.ErrorMessage = "SMTP is not configured. Set SmtpHost, SmtpPort, SmtpFrom in Web.config."
            Return result
        End If

        Dim host As String = ConfigurationManager.AppSettings("SmtpHost")
        Dim port As Integer = 587
        Integer.TryParse(If(ConfigurationManager.AppSettings("SmtpPort"), "587"), port)
        Dim fromAddr As String = If(ConfigurationManager.AppSettings("SmtpFrom"), "noreply@ummi.local")
        Dim fromName As String = If(ConfigurationManager.AppSettings("SmtpFromDisplayName"), "UMMI Manning Office")
        Dim enableSsl As Boolean = String.Equals(ConfigurationManager.AppSettings("SmtpEnableSsl"), "true", StringComparison.OrdinalIgnoreCase)
        Dim user As String = ConfigurationManager.AppSettings("SmtpUser")
        Dim pass As String = ConfigurationManager.AppSettings("SmtpPassword")

        Try
            Using msg As New MailMessage()
                msg.From = New MailAddress(fromAddr, fromName)
                msg.To.Add(New MailAddress(toAddress.Trim()))
                msg.Subject = subject
                msg.Body = bodyPlain
                msg.IsBodyHtml = False

                Using client As New SmtpClient(host, port)
                    client.EnableSsl = enableSsl
                    client.DeliveryMethod = SmtpDeliveryMethod.Network
                    If Not String.IsNullOrWhiteSpace(user) Then
                        client.Credentials = New NetworkCredential(user, pass)
                    End If
                    client.Send(msg)
                End Using
            End Using
            result.Success = True
        Catch ex As Exception
            result.ErrorMessage = ex.Message
        End Try
        Return result
    End Function

    Public Function BuildApplicantLinkEmailBody(name As String, link As String, expiryLine As String) As String
        Return "Dear " & name & "," & vbCrLf & vbCrLf &
            "Please use the link below to encode your application information:" & vbCrLf & vbCrLf &
            link & vbCrLf & vbCrLf &
            expiryLine &
            "Thank you," & vbCrLf & "UMMI Manning Office"
    End Function

    Public Sub RecordApplicantLinkEmail(linkId As Integer, result As EmailResult)
        Dim st As String = If(result.Success, "Sent", "Failed")
        DbHelper.ExecuteNonQuery(
            "UPDATE tbl_applicant_generated_link SET email_status=@st, email_sent_at=NOW(), email_error=@err WHERE id=@id",
            New MySqlParameter("@st", st),
            New MySqlParameter("@err", If(result.Success, DBNull.Value, CObj(Left(result.ErrorMessage, 500)))),
            New MySqlParameter("@id", linkId))
    End Sub

End Module
