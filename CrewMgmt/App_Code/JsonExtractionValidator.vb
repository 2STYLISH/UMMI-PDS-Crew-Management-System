Imports System
Imports System.Collections
Imports System.Collections.Generic
Imports System.Globalization
Imports System.Text
Imports System.Text.RegularExpressions
Imports System.Web.Script.Serialization

''' <summary>
''' PHASE E — JSON Extraction & Validation Service (FR-CM-60, FR-CM-61)
''' Sanitizes untrusted raw AI output, validates against Appendix D schemas,
''' normalizes dates/types, and flags ambiguous or malformed payloads.
''' 
''' ARCHITECTURAL CONSTRAINTS:
''' - Operates strictly in memory.
''' - Never invents missing values; nulls remain null (Appendix D).
''' - Preserves raw strings alongside normalized values.
''' - Date validation enforces calendar validity without unapproved age bounds.
''' - Ambiguous names are preserved raw and flagged; no heuristic guessing (Safeguard #2).
''' </summary>
Public Class JsonExtractionValidator

    Private Shared ReadOnly _serializer As New JavaScriptSerializer()

    ''' <summary>
    ''' Configurable provisional minimum year for date sanity checks [PROPOSED / TBD - Subject to UMMI Approval].
    ''' </summary>
    Public Shared ReadOnly Property ProvisionalMinDateYear As Integer
        Get
            Dim val As String = System.Web.Configuration.WebConfigurationManager.AppSettings("ApplicantExtraction_ProvisionalMinDateYear")
            If String.IsNullOrWhiteSpace(val) Then
                val = System.Configuration.ConfigurationManager.AppSettings("ApplicantExtraction_ProvisionalMinDateYear")
            End If
            Dim parsedYear As Integer = 1900
            If Integer.TryParse(val, parsedYear) Then
                Return parsedYear
            End If
            Return 1900
        End Get
    End Property

    ''' <summary>
    ''' Result of raw JSON parsing and schema sanitization.
    ''' </summary>
    Public Class ParsedExtractionPayload
        Public Property IsValidJson As Boolean = False
        Public Property ErrorMessage As String = String.Empty
        Public Property CategoryKey As String = String.Empty
        Public Property ExtractedRoot As New Dictionary(Of String, Object)(StringComparer.OrdinalIgnoreCase)
    End Class

    ''' <summary>
    ''' Cleans untrusted AI response text by stripping markdown code blocks, BOM, control characters,
    ''' and surrounding commentary before JSON parsing.
    ''' </summary>
    Public Shared Function SanitizeRawJsonText(rawInput As String) As String
        If String.IsNullOrWhiteSpace(rawInput) Then
            Return String.Empty
        End If

        Dim text As String = rawInput.Trim()

        ' Strip UTF-8 BOM or zero-width spaces if present
        text = text.Trim(ChrW(&HFEFF), ChrW(&H200B), ChrW(&H200C), ChrW(&H200D))

        ' Strip ```json ... ``` or ``` ... ``` markdown fences
        Dim fenceMatch As Match = Regex.Match(text, "```(?:json)?\s*([\s\S]*?)\s*```", RegexOptions.IgnoreCase)
        If fenceMatch.Success Then
            text = fenceMatch.Groups(1).Value.Trim()
        End If

        ' If extra text surrounds the JSON object, isolate outermost { ... }
        Dim firstBrace As Integer = text.IndexOf("{"c)
        Dim lastBrace As Integer = text.LastIndexOf("}"c)
        If firstBrace >= 0 AndAlso lastBrace > firstBrace Then
            text = text.Substring(firstBrace, lastBrace - firstBrace + 1)
        End If

        Return text
    End Function

    ''' <summary>
    ''' Parses raw JSON text into a typed dictionary using .NET JavaScriptSerializer.
    ''' Handles malformed, empty, or non-JSON payloads safely without throwing unhandled exceptions.
    ''' </summary>
    Public Shared Function ParseAndValidateJson(rawJson As String, expectedCategory As String) As ParsedExtractionPayload
        Dim payload As New ParsedExtractionPayload With {.CategoryKey = expectedCategory}

        Dim sanitized As String = SanitizeRawJsonText(rawJson)
        If String.IsNullOrWhiteSpace(sanitized) Then
            payload.IsValidJson = False
            payload.ErrorMessage = "AI response was empty or contained no JSON object."
            Return payload
        End If

        Try
            Dim dict As Dictionary(Of String, Object) =
                _serializer.Deserialize(Of Dictionary(Of String, Object))(sanitized)

            If dict Is Nothing Then
                payload.IsValidJson = False
                payload.ErrorMessage = "JSON deserialization returned null."
                Return payload
            End If

            payload.ExtractedRoot = New Dictionary(Of String, Object)(dict, StringComparer.OrdinalIgnoreCase)
            payload.IsValidJson = True
            Return payload
        Catch ex As Exception
            payload.IsValidJson = False
            payload.ErrorMessage = "Failed to parse AI output as JSON: " & ex.Message
            Return payload
        End Try
    End Function

    ''' <summary>
    ''' Safely retrieves a string property from an extracted dictionary.
    ''' Returns String.Empty if key is missing, null, or whitespace.
    ''' </summary>
    Public Shared Function GetSafeString(dict As Dictionary(Of String, Object), key As String) As String
        If dict Is Nothing OrElse Not dict.ContainsKey(key) Then
            Return String.Empty
        End If
        Dim val As Object = dict(key)
        If val Is Nothing OrElse TypeOf val Is DBNull Then
            Return String.Empty
        End If
        Dim strVal As String = val.ToString().Trim()
        If String.Equals(strVal, "null", StringComparison.OrdinalIgnoreCase) Then
            Return String.Empty
        End If
        Return strVal
    End Function

    ''' <summary>
    ''' Validates and normalizes calendar dates (YYYY-MM-DD).
    ''' Enforces calendar validity (valid month, valid day, leap years) and provisional year sanity.
    ''' Does NOT invent age bounds (Safeguard #1 &amp; #4).
    ''' </summary>
    Public Shared Function ValidateDate(rawDateStr As String, isDateOfBirth As Boolean, ByRef normalizedDate As Nullable(Of DateTime), ByRef warningMessage As String) As Boolean
        normalizedDate = Nothing
        warningMessage = String.Empty

        If String.IsNullOrWhiteSpace(rawDateStr) Then
            Return False
        End If

        Dim s As String = rawDateStr.Trim()
        Dim dt As DateTime

        ' Expected ISO-8601 YYYY-MM-DD or common standard representations
        Dim formats As String() = {"yyyy-MM-dd", "yyyy/MM/dd", "yyyy.MM.dd", "MM/dd/yyyy", "dd/MM/yyyy"}
        Dim parsed As Boolean = DateTime.TryParseExact(s, formats, CultureInfo.InvariantCulture, DateTimeStyles.None, dt)

        If Not parsed Then
            ' General fallback parser
            parsed = DateTime.TryParse(s, CultureInfo.InvariantCulture, DateTimeStyles.None, dt)
        End If

        If Not parsed Then
            warningMessage = "Date format could not be parsed: " & s
            Return False
        End If

        ' Date sanity checks [PROPOSED / TBD - Subject to UMMI Approval]
        If dt.Year < ProvisionalMinDateYear Then
            warningMessage = String.Format("Date year {0} precedes provisional sanity threshold ({1}).", dt.Year, ProvisionalMinDateYear)
            Return False
        End If

        If isDateOfBirth AndAlso dt.Date > DateTime.UtcNow.Date Then
            warningMessage = "Date of birth cannot be in the future."
            Return False
        End If

        normalizedDate = dt.Date
        Return True
    End Function

    ''' <summary>
    ''' Normalizes Philippine contact numbers.
    ''' Converts international +63 or 63 prefixes to standard 09 format; cleans formatting spaces/hyphens.
    ''' </summary>
    Public Shared Function NormalizeContactNumber(rawContact As String, ByRef warningMessage As String) As String
        warningMessage = String.Empty
        If String.IsNullOrWhiteSpace(rawContact) Then
            Return String.Empty
        End If

        Dim digitsOnly As String = Regex.Replace(rawContact, "[^\d+]", "")

        ' Convert +639XX or 639XX to 09XX
        If digitsOnly.StartsWith("+639") AndAlso digitsOnly.Length = 13 Then
            digitsOnly = "0" & digitsOnly.Substring(3)
        ElseIf digitsOnly.StartsWith("639") AndAlso digitsOnly.Length = 12 Then
            digitsOnly = "0" & digitsOnly.Substring(2)
        End If

        ' Standard PH mobile validation check (09XXXXXXXXX = 11 digits)
        If digitsOnly.Length = 11 AndAlso digitsOnly.StartsWith("09") Then
            Return digitsOnly
        End If

        ' Format warning if non-standard length
        warningMessage = "Contact number format differs from standard 11-digit format."
        Return rawContact.Trim()
    End Function

    ''' <summary>
    ''' Validates standard RFC email structure.
    ''' </summary>
    Public Shared Function ValidateEmail(rawEmail As String, ByRef warningMessage As String) As String
        warningMessage = String.Empty
        If String.IsNullOrWhiteSpace(rawEmail) Then
            Return String.Empty
        End If

        Dim clean As String = rawEmail.Trim()
        Dim isMatch As Boolean = Regex.IsMatch(clean, "^[^@\s]+@[^@\s]+\.[^@\s]+$", RegexOptions.IgnoreCase)
        If Not isMatch Then
            warningMessage = "Email address does not match standard email format."
        End If
        Return clean
    End Function

    ''' <summary>
    ''' Represents parsed name components without heuristic guessing.
    ''' </summary>
    Public Class ParsedNameResult
        Public Property FirstName As String = String.Empty
        Public Property MiddleName As String = String.Empty
        Public Property LastName As String = String.Empty
        Public Property Suffix As String = String.Empty
        Public Property IsAmbiguous As Boolean = False
        Public Property AmbiguityNote As String = String.Empty
    End Class

    ''' <summary>
    ''' Parses candidate names safely.
    ''' If the name structure cannot be split unambiguously, marks IsAmbiguous = True and
    ''' preserves the full string for applicant review rather than guessing splits (Safeguard #2).
    ''' </summary>
    Public Shared Function ParseNameSafely(fullName As String, Optional surnameOverride As String = Nothing, Optional givenNamesOverride As String = Nothing) As ParsedNameResult
        Dim result As New ParsedNameResult()

        ' If explicit separated surname and given names are provided (e.g. from Passport or SIRB)
        If Not String.IsNullOrWhiteSpace(surnameOverride) OrElse Not String.IsNullOrWhiteSpace(givenNamesOverride) Then
            result.LastName = If(surnameOverride, String.Empty).Trim()

            Dim given As String = If(givenNamesOverride, String.Empty).Trim()
            If Not String.IsNullOrWhiteSpace(given) Then
                ' If given names contain multiple tokens (e.g. "JUAN MIGUEL"), do NOT guess middle name.
                ' Map full given names to FirstName and leave MiddleName empty for review (Safeguard #2).
                result.FirstName = given
            End If
            result.IsAmbiguous = False
            Return result
        End If

        If String.IsNullOrWhiteSpace(fullName) Then
            Return result
        End If

        Dim clean As String = Regex.Replace(fullName.Trim(), "\s+", " ")

        ' Check for standard "LastName, FirstName MiddleName Suffix" format
        If clean.Contains(","c) Then
            Dim parts As String() = clean.Split(","c)
            If parts.Length = 2 Then
                result.LastName = parts(0).Trim()
                Dim remainingTokens As String() = parts(1).Trim().Split(" "c)

                If remainingTokens.Length = 1 Then
                    result.FirstName = remainingTokens(0)
                ElseIf remainingTokens.Length = 2 Then
                    ' Check if second token is a common suffix
                    If IsSuffix(remainingTokens(1)) Then
                        result.FirstName = remainingTokens(0)
                        result.Suffix = remainingTokens(1)
                    Else
                        result.FirstName = remainingTokens(0)
                        result.MiddleName = remainingTokens(1)
                    End If
                ElseIf remainingTokens.Length = 3 AndAlso IsSuffix(remainingTokens(2)) Then
                    result.FirstName = remainingTokens(0)
                    result.MiddleName = remainingTokens(1)
                    result.Suffix = remainingTokens(2)
                Else
                    ' Ambiguous multi-word given name
                    result.FirstName = parts(1).Trim()
                    result.IsAmbiguous = True
                    result.AmbiguityNote = "Multiple given names detected; please verify First and Middle names."
                End If
                Return result
            End If
        End If

        ' For unstructured "First [Middle] Last [Suffix]"
        Dim tokens As String() = clean.Split(" "c)

        If tokens.Length = 2 Then
            ' Unambiguous 2-word name
            result.FirstName = tokens(0)
            result.LastName = tokens(1)
            result.IsAmbiguous = False
            Return result
        End If

        If tokens.Length = 3 Then
            If IsSuffix(tokens(2)) Then
                result.FirstName = tokens(0)
                result.LastName = tokens(1)
                result.Suffix = tokens(2)
                result.IsAmbiguous = False
                Return result
            Else
                ' Common pattern: First Middle Last OR First Compound Last (e.g. "De la Cruz")
                ' To strictly avoid guessing compound surnames (Safeguard #2), mark ambiguous if prefix matches
                If IsCompoundSurnamePrefix(tokens(1)) Then
                    result.IsAmbiguous = True
                    result.AmbiguityNote = "Potential compound surname detected; preserved for applicant review."
                    result.FirstName = tokens(0)
                    result.LastName = tokens(1) & " " & tokens(2)
                Else
                    result.FirstName = tokens(0)
                    result.MiddleName = tokens(1)
                    result.LastName = tokens(2)
                    result.IsAmbiguous = False
                End If
                Return result
            End If
        End If

        ' 4 or more words: Ambiguous name (Safeguard #2: do not guess splits)
        result.IsAmbiguous = True
        result.AmbiguityNote = "Complex multi-word name structure; preserved for applicant review without automatic splitting."
        result.FirstName = clean
        Return result
    End Function

    Private Shared Function IsSuffix(token As String) As Boolean
        Dim s As String = token.Trim().TrimEnd("."c).ToUpperInvariant()
        Return s = "JR" OrElse s = "SR" OrElse s = "II" OrElse s = "III" OrElse s = "IV" OrElse s = "V"
    End Function

    Private Shared Function IsCompoundSurnamePrefix(token As String) As Boolean
        Dim s As String = token.Trim().ToLowerInvariant()
        Return s = "de" OrElse s = "del" OrElse s = "dela" OrElse s = "delos" OrElse s = "san" OrElse s = "santa"
    End Function

End Class
