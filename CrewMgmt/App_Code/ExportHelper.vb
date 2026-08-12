Imports OfficeOpenXml
Imports OfficeOpenXml.Style
Imports System.Data
Imports System.Drawing
Imports System.Web

''' <summary>
''' Excel export helper using EPPlus — no FastMember dependency.
''' </summary>
Module ExportHelper

    ''' <summary>
    ''' Export a DataTable to an Excel file and stream it to the HTTP response.
    ''' </summary>
    Public Sub ExportToExcel(dt As DataTable, fileName As String,
                             sheetTitle As String, response As HttpResponse)
        ' EPPlus 6 requires license context (NonCommercial for dev)
        ExcelPackage.LicenseContext = LicenseContext.NonCommercial

        Try
            Using pkg As New ExcelPackage()
                Dim ws As ExcelWorksheet = pkg.Workbook.Worksheets.Add(Left(sheetTitle, 30))

                ' Title row
                ws.Cells(1, 1).Value = sheetTitle
                ws.Cells(1, 1).Style.Font.Bold = True
                ws.Cells(1, 1).Style.Font.Size = 14
                ws.Cells(1, 1, 1, dt.Columns.Count).Merge = True

                ' Date row
                ws.Cells(2, 1).Value = "Generated: " & DateTime.Now.ToString("MMMM dd, yyyy HH:mm")
                ws.Cells(2, 1, 2, dt.Columns.Count).Merge = True

                ' Header row (row 3)
                Dim col As Integer = 1
                For Each dc As DataColumn In dt.Columns
                    Dim hdr As ExcelRange = ws.Cells(3, col)
                    hdr.Value = dc.ColumnName
                    hdr.Style.Font.Bold = True
                    hdr.Style.Fill.PatternType = ExcelFillStyle.Solid
                    hdr.Style.Fill.BackgroundColor.SetColor(Color.FromArgb(44, 62, 80))
                    hdr.Style.Font.Color.SetColor(Color.White)
                    hdr.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center
                    col += 1
                Next

                ' Data rows
                Dim row As Integer = 4
                For Each dr As DataRow In dt.Rows
                    col = 1
                    For Each dc As DataColumn In dt.Columns
                        ws.Cells(row, col).Value = dr(dc).ToString()
                        col += 1
                    Next
                    row += 1
                Next

                ' Auto-fit columns
                ws.Cells(ws.Dimension.Address).AutoFitColumns()

                ' Thin border on data range
                If dt.Rows.Count > 0 Then
                    Dim dataRange As ExcelRange = ws.Cells(3, 1, row - 1, dt.Columns.Count)
                    dataRange.Style.Border.Top.Style    = ExcelBorderStyle.Thin
                    dataRange.Style.Border.Bottom.Style = ExcelBorderStyle.Thin
                    dataRange.Style.Border.Left.Style   = ExcelBorderStyle.Thin
                    dataRange.Style.Border.Right.Style  = ExcelBorderStyle.Thin
                End If

                response.Clear()
                response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                response.AddHeader("Content-Disposition", "attachment; filename=" & fileName & ".xlsx")
                response.BinaryWrite(pkg.GetAsByteArray())
                response.Flush()
                response.End()
            End Using
        Catch ex As Exception
            ' Swallow thread abort (expected on Response.End)
            If TypeOf ex Is System.Threading.ThreadAbortException Then Return
            Throw
        End Try
    End Sub

End Module
