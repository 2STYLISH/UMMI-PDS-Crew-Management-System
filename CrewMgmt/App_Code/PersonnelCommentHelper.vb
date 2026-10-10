Imports MySql.Data.MySqlClient
Imports System.Data
Imports System.IO
Imports System.Web

Module PersonnelCommentHelper

    Public Function LoadComments(personnelId As Integer) As DataTable
        Return DbHelper.FillDataTable(
            "SELECT id, date_sent, comments, added_by, added_by_name, img_id, updated_by " &
            "FROM tbl_personnel_comment WHERE personnel_id=@pid AND is_deleted=0 ORDER BY date_sent DESC",
            CommandType.Text, New MySqlParameter("@pid", personnelId))
    End Function

    Public Function AddComment(personnelId As Integer, commentText As String,
                               userId As Integer, userName As String,
                               Optional attachmentFile As HttpPostedFile = Nothing) As Integer
        Dim imgId As String = Nothing
        If attachmentFile IsNot Nothing AndAlso attachmentFile.ContentLength > 0 Then
            imgId = SaveAssessmentAttachment(personnelId, attachmentFile)
        End If
        DbHelper.ExecuteNonQuery(
            "INSERT INTO tbl_personnel_comment (personnel_id, comments, date_sent, img_id, added_by, added_by_name) " &
            "VALUES (@pid,@c,CURDATE(),@img,@uid,@un)",
            New MySqlParameter("@pid", personnelId),
            New MySqlParameter("@c", commentText.Trim()),
            New MySqlParameter("@img", If(String.IsNullOrEmpty(imgId), DBNull.Value, CObj(imgId))),
            New MySqlParameter("@uid", userId),
            New MySqlParameter("@un", userName))
        Dim newId As Object = DbHelper.ExecuteScalar("SELECT LAST_INSERT_ID()")
        Return If(newId Is Nothing, 0, CInt(newId))
    End Function

    Public Function UpdateComment(commentId As Integer, personnelId As Integer, commentText As String,
                                  userId As Integer) As Boolean
        Dim rows As Integer = DbHelper.ExecuteNonQuery(
            "UPDATE tbl_personnel_comment SET comments=@c, date_updated=NOW(), updated_by=@uid " &
            "WHERE id=@id AND personnel_id=@pid AND is_deleted=0 AND (added_by=@uid OR @adm=1)",
            New MySqlParameter("@c", commentText.Trim()),
            New MySqlParameter("@uid", userId),
            New MySqlParameter("@adm", If(HasAdministrativeAccess(), 1, 0)),
            New MySqlParameter("@id", commentId),
            New MySqlParameter("@pid", personnelId))
        Return rows > 0
    End Function

    Public Function SoftDeleteComment(commentId As Integer, personnelId As Integer,
                                      userId As Integer, reason As String) As Boolean
        If Not CanDeleteAnyComment() AndAlso Not IsCommentAuthor(commentId, userId) Then Return False
        Dim rows As Integer = DbHelper.ExecuteNonQuery(
            "UPDATE tbl_personnel_comment SET is_deleted=1, deleted_by=@uid, deleted_at=NOW(), delete_reason=@r " &
            "WHERE id=@id AND personnel_id=@pid AND is_deleted=0",
            New MySqlParameter("@uid", userId),
            New MySqlParameter("@r", reason.Trim()),
            New MySqlParameter("@id", commentId),
            New MySqlParameter("@pid", personnelId))
        Return rows > 0
    End Function

    Private Function IsCommentAuthor(commentId As Integer, userId As Integer) As Boolean
        Dim v As Object = DbHelper.ExecuteScalar(
            "SELECT added_by FROM tbl_personnel_comment WHERE id=@id",
            New MySqlParameter("@id", commentId))
        Return v IsNot Nothing AndAlso Not IsDBNull(v) AndAlso CInt(v) = userId
    End Function

    Private Function SaveAssessmentAttachment(personnelId As Integer, file As HttpPostedFile) As String
        Dim uploadRoot As String = HttpContext.Current.Server.MapPath("~/Uploads/assessments/")
        If Not Directory.Exists(uploadRoot) Then Directory.CreateDirectory(uploadRoot)
        Dim safeName As String = Path.GetFileName(file.FileName)
        Dim stored As String = personnelId.ToString() & "_" & Guid.NewGuid().ToString("N") & "_" & safeName
        Dim fullPath As String = Path.Combine(uploadRoot, stored)
        file.SaveAs(fullPath)
        Return stored
    End Function

    Public Function VerifyPersonnelDocument(pdId As Integer, personnelId As Integer,
                                            verifiedBy As Integer, remarks As String) As Boolean
        Dim rows As Integer = DbHelper.ExecuteNonQuery(
            "UPDATE tbl_personnel_documents SET is_verified=1, verified_by=@uid, verified_at=NOW(), verification_remarks=@r " &
            "WHERE id=@id AND personnel_id=@pid",
            New MySqlParameter("@uid", verifiedBy),
            New MySqlParameter("@r", If(String.IsNullOrEmpty(remarks), DBNull.Value, CObj(remarks.Trim()))),
            New MySqlParameter("@id", pdId),
            New MySqlParameter("@pid", personnelId))
        Return rows > 0
    End Function

End Module
