Option Infer On

Imports System
Imports System.Collections
Imports System.Collections.Generic
Imports System.Diagnostics
Imports PdsMappingModels

''' <summary>
''' PHASE E — Master PDS Extraction &amp; Field Mapping Orchestration Service (FR-CM-60 through FR-CM-78)
''' Coordinates raw AI JSON validation, Appendix D category mapping, reference resolution,
''' cross-document conflict handling, and repeating record deduplication into an in-memory package.
''' 
''' ARCHITECTURAL CONSTRAINTS:
''' - Pure in-memory processing. Strictly zero database INSERT or UPDATE operations (FR-CM-72).
''' - Reference queries are read-only; DB failures degrade gracefully without throwing exceptions.
''' - Conflicting values preserve all distinct alternatives; no automatic precedence (Safeguard #1).
''' - Ambiguous names and non-exact reference lookups are preserved for review (Safeguards #2 &amp; #3).
''' - Output encoding is deferred to Phase F presentation controls (Safeguard #6).
''' </summary>
Public Class PdsExtractionMappingService

    ''' <summary>
    ''' Master entry point: processes a list of Phase D document extraction results into a PDS suggestion package.
    ''' </summary>
    Public Shared Function ProcessExtractionResults(
        docResults As List(Of DocumentExtractionService.DocumentExtractionResult),
        Optional sessionId As String = ""
    ) As PdsExtractionSuggestionPackage

        Dim sw As Stopwatch = Stopwatch.StartNew()
        Dim package As New PdsExtractionSuggestionPackage With {
            .SessionId = If(String.IsNullOrWhiteSpace(sessionId), Guid.NewGuid().ToString("N"), sessionId),
            .IsSuccess = True
        }

        If docResults Is Nothing OrElse docResults.Count = 0 Then
            package.ErrorMessage = "No document extraction results were provided for mapping."
            Return package
        End If

        Dim totalPages As Integer = 0
        Dim totalFields As Integer = 0

        For Each docResult As DocumentExtractionService.DocumentExtractionResult In docResults
            If docResult Is Nothing Then Continue For

            Dim categoryKey As String = If(String.IsNullOrWhiteSpace(docResult.CategoryKey), "General", docResult.CategoryKey.Trim())

            For Each pageResult As DocumentExtractionService.PageExtractionResult In docResult.Pages
                If pageResult Is Nothing Then Continue For
                totalPages += 1

                Dim source As New SourceAttribution With {
                    .StagedFileId = docResult.StagedFileId,
                    .OriginalFileName = docResult.OriginalFileName,
                    .PageNumber = pageResult.PageNumber,
                    .CategoryKey = categoryKey,
                    .ExtractionTimestamp = DateTime.UtcNow
                }

                ' 1. Strict JSON Parsing & Sanitization (FR-CM-61)
                Dim parsedPayload As JsonExtractionValidator.ParsedExtractionPayload =
                    JsonExtractionValidator.ParseAndValidateJson(pageResult.RawJsonOutput, categoryKey)

                If Not parsedPayload.IsValidJson Then
                    ' Malformed or non-JSON output: record warning and continue to next page safely
                    Continue For
                End If

                ' 2. Category-Specific Field Mapping per Appendix D Matrix (FR-CM-62)
                Select Case categoryKey.ToLowerInvariant()
                    Case "resume", "cv"
                        MapResume(parsedPayload.ExtractedRoot, source, package, totalFields)

                    Case "passport"
                        MapPassport(parsedPayload.ExtractedRoot, source, package, totalFields)

                    Case "sirb", "seamansbook"
                        MapSirb(parsedPayload.ExtractedRoot, source, package, totalFields)

                    Case "certificate", "training", "coc", "cop"
                        MapCertificate(parsedPayload.ExtractedRoot, source, package, totalFields)

                    Case "license"
                        MapLicense(parsedPayload.ExtractedRoot, source, package, totalFields)

                    Case "seaservice"
                        MapSeaService(parsedPayload.ExtractedRoot, source, package, totalFields)

                    Case Else
                        MapGeneral(parsedPayload.ExtractedRoot, source, package, totalFields)
                End Select
            Next
        Next

        ' 3. Deduplication of Repeating Records (FR-CM-78)
        Dim preDedupSeaCount As Integer = package.SeaServiceRecords.Count
        package.SeaServiceRecords = ConflictAndDeduplicationHelper.DeduplicateSeaService(package.SeaServiceRecords)
        Dim dedupSeaCount As Integer = preDedupSeaCount - package.SeaServiceRecords.Count

        Dim preDedupDocCount As Integer = package.Documents.Count
        package.Documents = ConflictAndDeduplicationHelper.DeduplicateDocuments(package.Documents)
        Dim dedupDocCount As Integer = preDedupDocCount - package.Documents.Count

        ' 4. Calculate Diagnostic Audit Metrics (FR-CM-71)
        sw.Stop()
        Dim audit As ExtractionAuditSummary = package.AuditSummary
        audit.SessionId = package.SessionId
        audit.TotalDocumentsProcessed = docResults.Count
        audit.TotalPagesProcessed = totalPages
        audit.TotalFieldsExtracted = totalFields
        audit.TotalDuplicatesDeduplicated = dedupSeaCount + dedupDocCount
        audit.ExecutionTimeMs = sw.ElapsedMilliseconds
        audit.Timestamp = DateTime.UtcNow

        CountUnresolvedAndConflicts(package, audit)

        ' 5. Privacy-Safe Audit Logging (FR-CM-71)
        AuditHelper.LogApplicantMappingEvent(
            docsCount:=audit.TotalDocumentsProcessed,
            fieldsCount:=audit.TotalFieldsExtracted,
            conflictsCount:=audit.TotalConflictsDetected,
            unresolvedCount:=audit.TotalUnresolvedReferences,
            durationMs:=audit.ExecutionTimeMs,
            outcome:=If(package.IsSuccess, "Success", "Partial")
        )

        Return package
    End Function

    ' ── Category Mappers ─────────────────────────────────────────────────────

    Private Shared Sub MapResume(
        dict As Dictionary(Of String, Object),
        source As SourceAttribution,
        pkg As PdsExtractionSuggestionPackage,
        ByRef totalFields As Integer
    )
        Dim pd = pkg.PersonalDetails

        ' Full Name
        Dim rawFullName As String = JsonExtractionValidator.GetSafeString(dict, "full_name")
        If Not String.IsNullOrWhiteSpace(rawFullName) Then
            totalFields += 1
            Dim parsedName = JsonExtractionValidator.ParseNameSafely(rawFullName)

            If parsedName.IsAmbiguous Then
                ' Ambiguous name: preserve raw text, flag Ambiguous, do not guess splits (Safeguard #2)
                pd.FirstName.ExtractedRawValue = rawFullName
                pd.FirstName.NormalizedValue = parsedName.FirstName
                pd.FirstName.Status = ValidationStatus.Ambiguous
                pd.FirstName.StatusMessage = parsedName.AmbiguityNote
                pd.FirstName.Sources.Add(source)
            Else
                If Not String.IsNullOrWhiteSpace(parsedName.FirstName) Then
                    ConflictAndDeduplicationHelper.MergeStringField(pd.FirstName, parsedName.FirstName, rawFullName, source)
                End If
                If Not String.IsNullOrWhiteSpace(parsedName.MiddleName) Then
                    ConflictAndDeduplicationHelper.MergeStringField(pd.MiddleName, parsedName.MiddleName, rawFullName, source)
                End If
                If Not String.IsNullOrWhiteSpace(parsedName.LastName) Then
                    ConflictAndDeduplicationHelper.MergeStringField(pd.LastName, parsedName.LastName, rawFullName, source)
                End If
                If Not String.IsNullOrWhiteSpace(parsedName.Suffix) Then
                    ConflictAndDeduplicationHelper.MergeStringField(pd.Suffix, parsedName.Suffix, rawFullName, source)
                End If
            End If
        End If

        ' Date of Birth
        Dim rawDob As String = JsonExtractionValidator.GetSafeString(dict, "date_of_birth")
        If Not String.IsNullOrWhiteSpace(rawDob) Then
            totalFields += 1
            Dim normDob As Nullable(Of DateTime) = Nothing
            Dim warn As String = String.Empty
            If JsonExtractionValidator.ValidateDate(rawDob, True, normDob, warn) Then
                ConflictAndDeduplicationHelper.MergeDateField(pd.DateOfBirth, normDob, rawDob, source)
            Else
                pd.DateOfBirth.ExtractedRawValue = rawDob
                pd.DateOfBirth.Status = ValidationStatus.FormatWarning
                pd.DateOfBirth.StatusMessage = warn
                pd.DateOfBirth.Sources.Add(source)
            End If
        End If

        ' Nationality
        Dim rawNat As String = JsonExtractionValidator.GetSafeString(dict, "nationality")
        If Not String.IsNullOrWhiteSpace(rawNat) Then
            totalFields += 1
            Dim res = ReferenceResolutionService.ResolveNationality(rawNat)
            ConflictAndDeduplicationHelper.MergeStringField(pd.Nationality, If(res.IsResolved, res.MatchedCanonicalName, rawNat), rawNat, source, res.ResolvedId, res.CandidateSuggestions)
            If Not res.IsResolved Then pd.Nationality.Status = ValidationStatus.UnresolvedReference
        End If

        ' Contact Number
        Dim rawMobile As String = JsonExtractionValidator.GetSafeString(dict, "mobile_number")
        If Not String.IsNullOrWhiteSpace(rawMobile) Then
            totalFields += 1
            Dim warn As String = String.Empty
            Dim normContact As String = JsonExtractionValidator.NormalizeContactNumber(rawMobile, warn)
            ConflictAndDeduplicationHelper.MergeStringField(pd.ContactNumber, normContact, rawMobile, source)
            If Not String.IsNullOrEmpty(warn) Then pd.ContactNumber.Status = ValidationStatus.FormatWarning : pd.ContactNumber.StatusMessage = warn
        End If

        ' Email
        Dim rawEmail As String = JsonExtractionValidator.GetSafeString(dict, "email_address")
        If Not String.IsNullOrWhiteSpace(rawEmail) Then
            totalFields += 1
            Dim warn As String = String.Empty
            Dim normEmail As String = JsonExtractionValidator.ValidateEmail(rawEmail, warn)
            ConflictAndDeduplicationHelper.MergeStringField(pd.EmailAddress, normEmail, rawEmail, source)
            If Not String.IsNullOrEmpty(warn) Then pd.EmailAddress.Status = ValidationStatus.FormatWarning : pd.EmailAddress.StatusMessage = warn
        End If

        ' Address
        Dim rawAddr As String = JsonExtractionValidator.GetSafeString(dict, "home_address")
        If Not String.IsNullOrWhiteSpace(rawAddr) Then
            totalFields += 1
            ConflictAndDeduplicationHelper.MergeStringField(pd.Address, rawAddr, rawAddr, source)
        End If

        ' Applied Position (Appendix D: Only if explicitly stated, never inferred)
        Dim rawPos As String = JsonExtractionValidator.GetSafeString(dict, "position_applied")
        If Not String.IsNullOrWhiteSpace(rawPos) Then
            totalFields += 1
            Dim res = ReferenceResolutionService.ResolveRank(rawPos)
            ConflictAndDeduplicationHelper.MergeStringField(pd.AppliedRank, If(res.IsResolved, res.MatchedCanonicalName, rawPos), rawPos, source, res.ResolvedId, res.CandidateSuggestions)
            If Not res.IsResolved Then pd.AppliedRank.Status = ValidationStatus.UnresolvedReference
        End If

        ' Education (School & Course)
        If dict.ContainsKey("highest_education") AndAlso TypeOf dict("highest_education") Is Dictionary(Of String, Object) Then
            Dim edu = CType(dict("highest_education"), Dictionary(Of String, Object))
            Dim rawSchool = JsonExtractionValidator.GetSafeString(edu, "school")
            If Not String.IsNullOrWhiteSpace(rawSchool) Then
                totalFields += 1
                Dim res = ReferenceResolutionService.ResolveSchool(rawSchool)
                ConflictAndDeduplicationHelper.MergeStringField(pd.SchoolName, If(res.IsResolved, res.MatchedCanonicalName, rawSchool), rawSchool, source, res.ResolvedId, res.CandidateSuggestions)
                If Not res.IsResolved Then pd.SchoolName.Status = ValidationStatus.UnresolvedReference
            End If

            Dim rawCourse = JsonExtractionValidator.GetSafeString(edu, "course")
            If Not String.IsNullOrWhiteSpace(rawCourse) Then
                totalFields += 1
                Dim res = ReferenceResolutionService.ResolveCourse(rawCourse)
                ConflictAndDeduplicationHelper.MergeStringField(pd.Course, If(res.IsResolved, res.MatchedCanonicalName, rawCourse), rawCourse, source, res.ResolvedId, res.CandidateSuggestions)
                If Not res.IsResolved Then pd.Course.Status = ValidationStatus.UnresolvedReference
            End If
        End If

        ' Repeating Sea Service from Resume
        If dict.ContainsKey("sea_service_records") AndAlso TypeOf dict("sea_service_records") Is ArrayList Then
            Dim arr = CType(dict("sea_service_records"), ArrayList)
            For Each item As Object In arr
                If TypeOf item Is Dictionary(Of String, Object) Then
                    MapSingleSeaServiceEntry(CType(item, Dictionary(Of String, Object)), source, pkg, totalFields)
                End If
            Next
        End If
    End Sub

    Private Shared Sub MapPassport(
        dict As Dictionary(Of String, Object),
        source As SourceAttribution,
        pkg As PdsExtractionSuggestionPackage,
        ByRef totalFields As Integer
    )
        Dim pd = pkg.PersonalDetails

        Dim rawSurname = JsonExtractionValidator.GetSafeString(dict, "surname")
        Dim rawGiven = JsonExtractionValidator.GetSafeString(dict, "given_names")
        If Not String.IsNullOrWhiteSpace(rawSurname) OrElse Not String.IsNullOrWhiteSpace(rawGiven) Then
            totalFields += 1
            Dim parsed = JsonExtractionValidator.ParseNameSafely(String.Empty, surnameOverride:=rawSurname, givenNamesOverride:=rawGiven)
            If Not String.IsNullOrWhiteSpace(parsed.LastName) Then
                ConflictAndDeduplicationHelper.MergeStringField(pd.LastName, parsed.LastName, rawSurname, source)
            End If
            If Not String.IsNullOrWhiteSpace(parsed.FirstName) Then
                ConflictAndDeduplicationHelper.MergeStringField(pd.FirstName, parsed.FirstName, rawGiven, source)
            End If
        End If

        ' Date of Birth
        Dim rawDob = JsonExtractionValidator.GetSafeString(dict, "date_of_birth")
        If Not String.IsNullOrWhiteSpace(rawDob) Then
            totalFields += 1
            Dim normDob As Nullable(Of DateTime) = Nothing
            Dim warn As String = String.Empty
            If JsonExtractionValidator.ValidateDate(rawDob, True, normDob, warn) Then
                ConflictAndDeduplicationHelper.MergeDateField(pd.DateOfBirth, normDob, rawDob, source)
            End If
        End If

        ' Place of Birth
        Dim rawPob = JsonExtractionValidator.GetSafeString(dict, "place_of_birth")
        If Not String.IsNullOrWhiteSpace(rawPob) Then
            totalFields += 1
            ConflictAndDeduplicationHelper.MergeStringField(pd.PlaceOfBirth, rawPob, rawPob, source)
        End If

        ' Gender / Sex
        Dim rawSex = JsonExtractionValidator.GetSafeString(dict, "sex")
        If Not String.IsNullOrWhiteSpace(rawSex) Then
            totalFields += 1
            Dim normGender As String = If(rawSex.StartsWith("M", StringComparison.OrdinalIgnoreCase), "Male",
                                       If(rawSex.StartsWith("F", StringComparison.OrdinalIgnoreCase), "Female", rawSex))
            ConflictAndDeduplicationHelper.MergeStringField(pd.Gender, normGender, rawSex, source)
        End If

        ' Nationality
        Dim rawNat = JsonExtractionValidator.GetSafeString(dict, "nationality")
        If Not String.IsNullOrWhiteSpace(rawNat) Then
            totalFields += 1
            Dim res = ReferenceResolutionService.ResolveNationality(rawNat)
            ConflictAndDeduplicationHelper.MergeStringField(pd.Nationality, If(res.IsResolved, res.MatchedCanonicalName, rawNat), rawNat, source, res.ResolvedId, res.CandidateSuggestions)
        End If

        ' Repeating Document Entry: Passport
        Dim rawPassNum = JsonExtractionValidator.GetSafeString(dict, "passport_number")
        If Not String.IsNullOrWhiteSpace(rawPassNum) Then
            totalFields += 1
            Dim docRes = ReferenceResolutionService.ResolveDocumentType("Passport")
            Dim docSug As New PdsDocumentSuggestion With {
                .DocumentTypeId = docRes.ResolvedId,
                .DocumentTypeName = If(docRes.IsResolved, docRes.MatchedCanonicalName, "Passport"),
                .DocumentNumber = rawPassNum,
                .Status = If(docRes.IsResolved, ValidationStatus.ExtractedValid, ValidationStatus.UnresolvedReference)
            }
            docSug.Sources.Add(source)
            docSug.ExtractedRawValues("passport_number") = rawPassNum

            Dim rawIssue = JsonExtractionValidator.GetSafeString(dict, "date_of_issue")
            Dim dIssue As Nullable(Of DateTime) = Nothing
            Dim wIssue As String = String.Empty
            If JsonExtractionValidator.ValidateDate(rawIssue, False, dIssue, wIssue) Then
                docSug.DateIssued = dIssue
            End If

            Dim rawExpiry = JsonExtractionValidator.GetSafeString(dict, "date_of_expiry")
            Dim dExp As Nullable(Of DateTime) = Nothing
            Dim wExp As String = String.Empty
            If JsonExtractionValidator.ValidateDate(rawExpiry, False, dExp, wExp) Then
                docSug.DateExpiry = dExp
            End If

            ' Unsupported attributes preserved in metadata
            Dim rawAuth = JsonExtractionValidator.GetSafeString(dict, "issuing_authority")
            If Not String.IsNullOrWhiteSpace(rawAuth) Then docSug.UnsupportedAttributes("issuing_authority") = rawAuth
            Dim rawPlace = JsonExtractionValidator.GetSafeString(dict, "place_of_issue")
            If Not String.IsNullOrWhiteSpace(rawPlace) Then docSug.UnsupportedAttributes("place_of_issue") = rawPlace

            pkg.Documents.Add(docSug)
        End If
    End Sub

    Private Shared Sub MapSirb(
        dict As Dictionary(Of String, Object),
        source As SourceAttribution,
        pkg As PdsExtractionSuggestionPackage,
        ByRef totalFields As Integer
    )
        Dim pd = pkg.PersonalDetails

        Dim rawSurname = JsonExtractionValidator.GetSafeString(dict, "surname")
        Dim rawGiven = JsonExtractionValidator.GetSafeString(dict, "given_names")
        If Not String.IsNullOrWhiteSpace(rawSurname) OrElse Not String.IsNullOrWhiteSpace(rawGiven) Then
            totalFields += 1
            Dim parsed = JsonExtractionValidator.ParseNameSafely(String.Empty, surnameOverride:=rawSurname, givenNamesOverride:=rawGiven)
            If Not String.IsNullOrWhiteSpace(parsed.LastName) Then
                ConflictAndDeduplicationHelper.MergeStringField(pd.LastName, parsed.LastName, rawSurname, source)
            End If
            If Not String.IsNullOrWhiteSpace(parsed.FirstName) Then
                ConflictAndDeduplicationHelper.MergeStringField(pd.FirstName, parsed.FirstName, rawGiven, source)
            End If
        End If

        Dim rawDob = JsonExtractionValidator.GetSafeString(dict, "date_of_birth")
        If Not String.IsNullOrWhiteSpace(rawDob) Then
            totalFields += 1
            Dim normDob As Nullable(Of DateTime) = Nothing
            Dim warn As String = String.Empty
            If JsonExtractionValidator.ValidateDate(rawDob, True, normDob, warn) Then
                ConflictAndDeduplicationHelper.MergeDateField(pd.DateOfBirth, normDob, rawDob, source)
            End If
        End If

        Dim rawPob = JsonExtractionValidator.GetSafeString(dict, "place_of_birth")
        If Not String.IsNullOrWhiteSpace(rawPob) Then
            totalFields += 1
            ConflictAndDeduplicationHelper.MergeStringField(pd.PlaceOfBirth, rawPob, rawPob, source)
        End If

        ' Repeating Document Entry: SIRB
        Dim rawSirbNum = JsonExtractionValidator.GetSafeString(dict, "sirb_number")
        If Not String.IsNullOrWhiteSpace(rawSirbNum) Then
            totalFields += 1
            Dim docRes = ReferenceResolutionService.ResolveDocumentType("Seaman's Book (SIRB)")
            Dim docSug As New PdsDocumentSuggestion With {
                .DocumentTypeId = docRes.ResolvedId,
                .DocumentTypeName = If(docRes.IsResolved, docRes.MatchedCanonicalName, "Seaman's Book (SIRB)"),
                .DocumentNumber = rawSirbNum,
                .Status = If(docRes.IsResolved, ValidationStatus.ExtractedValid, ValidationStatus.UnresolvedReference)
            }
            docSug.Sources.Add(source)
            docSug.ExtractedRawValues("sirb_number") = rawSirbNum

            Dim rawIssue = JsonExtractionValidator.GetSafeString(dict, "date_of_issue")
            Dim dIssue As Nullable(Of DateTime) = Nothing
            Dim wIssue As String = String.Empty
            If JsonExtractionValidator.ValidateDate(rawIssue, False, dIssue, wIssue) Then
                docSug.DateIssued = dIssue
            End If

            Dim rawExpiry = JsonExtractionValidator.GetSafeString(dict, "date_of_expiry")
            Dim dExp As Nullable(Of DateTime) = Nothing
            Dim wExp As String = String.Empty
            If JsonExtractionValidator.ValidateDate(rawExpiry, False, dExp, wExp) Then
                docSug.DateExpiry = dExp
            End If

            Dim rawAuth = JsonExtractionValidator.GetSafeString(dict, "issuing_authority")
            If Not String.IsNullOrWhiteSpace(rawAuth) Then docSug.UnsupportedAttributes("issuing_authority") = rawAuth

            pkg.Documents.Add(docSug)
        End If
    End Sub

    Private Shared Sub MapCertificate(
        dict As Dictionary(Of String, Object),
        source As SourceAttribution,
        pkg As PdsExtractionSuggestionPackage,
        ByRef totalFields As Integer
    )
        Dim rawTitle = JsonExtractionValidator.GetSafeString(dict, "certificate_title")
        If String.IsNullOrWhiteSpace(rawTitle) Then
            rawTitle = JsonExtractionValidator.GetSafeString(dict, "course_or_training")
        End If
        If String.IsNullOrWhiteSpace(rawTitle) Then
            rawTitle = JsonExtractionValidator.GetSafeString(dict, "document_type")
        End If

        Dim rawNum = JsonExtractionValidator.GetSafeString(dict, "certificate_number")
        If Not String.IsNullOrWhiteSpace(rawTitle) OrElse Not String.IsNullOrWhiteSpace(rawNum) Then
            totalFields += 1
            Dim docRes = ReferenceResolutionService.ResolveDocumentType(rawTitle)
            Dim docSug As New PdsDocumentSuggestion With {
                .DocumentTypeId = docRes.ResolvedId,
                .DocumentTypeName = If(docRes.IsResolved, docRes.MatchedCanonicalName, rawTitle),
                .DocumentNumber = rawNum,
                .HolderName = JsonExtractionValidator.GetSafeString(dict, "holder_name"),
                .Status = If(docRes.IsResolved, ValidationStatus.ExtractedValid, ValidationStatus.UnresolvedReference),
                .CandidateSuggestions = docRes.CandidateSuggestions
            }
            docSug.Sources.Add(source)
            docSug.ExtractedRawValues("certificate_title") = rawTitle
            docSug.ExtractedRawValues("certificate_number") = rawNum

            Dim rawIssue = JsonExtractionValidator.GetSafeString(dict, "date_of_issue")
            Dim dIssue As Nullable(Of DateTime) = Nothing
            Dim wIssue As String = String.Empty
            If JsonExtractionValidator.ValidateDate(rawIssue, False, dIssue, wIssue) Then
                docSug.DateIssued = dIssue
            End If

            Dim rawExpiry = JsonExtractionValidator.GetSafeString(dict, "date_of_expiry")
            Dim dExp As Nullable(Of DateTime) = Nothing
            Dim wExp As String = String.Empty
            If JsonExtractionValidator.ValidateDate(rawExpiry, False, dExp, wExp) Then
                docSug.DateExpiry = dExp
            End If

            Dim rawOrg = JsonExtractionValidator.GetSafeString(dict, "issuing_organization")
            If Not String.IsNullOrWhiteSpace(rawOrg) Then docSug.UnsupportedAttributes("issuing_organization") = rawOrg
            Dim rawPlace = JsonExtractionValidator.GetSafeString(dict, "place_of_issue")
            If Not String.IsNullOrWhiteSpace(rawPlace) Then docSug.UnsupportedAttributes("place_of_issue") = rawPlace

            pkg.Documents.Add(docSug)
        End If
    End Sub

    Private Shared Sub MapLicense(
        dict As Dictionary(Of String, Object),
        source As SourceAttribution,
        pkg As PdsExtractionSuggestionPackage,
        ByRef totalFields As Integer
    )
        Dim rawType = JsonExtractionValidator.GetSafeString(dict, "license_type")
        If String.IsNullOrWhiteSpace(rawType) Then rawType = JsonExtractionValidator.GetSafeString(dict, "document_type")

        Dim rawNum = JsonExtractionValidator.GetSafeString(dict, "license_number")
        If Not String.IsNullOrWhiteSpace(rawType) OrElse Not String.IsNullOrWhiteSpace(rawNum) Then
            totalFields += 1
            Dim docRes = ReferenceResolutionService.ResolveDocumentType(rawType)
            Dim docSug As New PdsDocumentSuggestion With {
                .DocumentTypeId = docRes.ResolvedId,
                .DocumentTypeName = If(docRes.IsResolved, docRes.MatchedCanonicalName, rawType),
                .DocumentNumber = rawNum,
                .Grade = JsonExtractionValidator.GetSafeString(dict, "grade_or_rating"),
                .HolderName = JsonExtractionValidator.GetSafeString(dict, "holder_name"),
                .Status = If(docRes.IsResolved, ValidationStatus.ExtractedValid, ValidationStatus.UnresolvedReference),
                .CandidateSuggestions = docRes.CandidateSuggestions
            }
            docSug.Sources.Add(source)
            docSug.ExtractedRawValues("license_type") = rawType
            docSug.ExtractedRawValues("license_number") = rawNum

            Dim rawIssue = JsonExtractionValidator.GetSafeString(dict, "date_of_issue")
            Dim dIssue As Nullable(Of DateTime) = Nothing
            Dim wIssue As String = String.Empty
            If JsonExtractionValidator.ValidateDate(rawIssue, False, dIssue, wIssue) Then
                docSug.DateIssued = dIssue
            End If

            Dim rawExpiry = JsonExtractionValidator.GetSafeString(dict, "date_of_expiry")
            Dim dExp As Nullable(Of DateTime) = Nothing
            Dim wExp As String = String.Empty
            If JsonExtractionValidator.ValidateDate(rawExpiry, False, dExp, wExp) Then
                docSug.DateExpiry = dExp
            End If

            Dim rawAuth = JsonExtractionValidator.GetSafeString(dict, "issuing_authority")
            If Not String.IsNullOrWhiteSpace(rawAuth) Then docSug.UnsupportedAttributes("issuing_authority") = rawAuth

            pkg.Documents.Add(docSug)
        End If
    End Sub

    Private Shared Sub MapSeaService(
        dict As Dictionary(Of String, Object),
        source As SourceAttribution,
        pkg As PdsExtractionSuggestionPackage,
        ByRef totalFields As Integer
    )
        Dim defaultEmployer As String = JsonExtractionValidator.GetSafeString(dict, "employer_agency")

        If dict.ContainsKey("sea_service_records") AndAlso TypeOf dict("sea_service_records") Is ArrayList Then
            Dim arr As ArrayList = CType(dict("sea_service_records"), ArrayList)
            For Each item As Object In arr
                If TypeOf item Is Dictionary(Of String, Object) Then
                    Dim subDict As Dictionary(Of String, Object) = CType(item, Dictionary(Of String, Object))
                    If Not subDict.ContainsKey("employer_agency") AndAlso Not String.IsNullOrEmpty(defaultEmployer) Then
                        subDict("employer_agency") = defaultEmployer
                    End If
                    MapSingleSeaServiceEntry(subDict, source, pkg, totalFields)
                End If
            Next
        End If
    End Sub

    Private Shared Sub MapSingleSeaServiceEntry(
        subDict As Dictionary(Of String, Object),
        source As SourceAttribution,
        pkg As PdsExtractionSuggestionPackage,
        ByRef totalFields As Integer
    )
        Dim rawVessel As String = JsonExtractionValidator.GetSafeString(subDict, "vessel_name")
        Dim rawRank As String = JsonExtractionValidator.GetSafeString(subDict, "rank")
        Dim rawSignOn As String = JsonExtractionValidator.GetSafeString(subDict, "sign_on_date")
        Dim rawSignOff As String = JsonExtractionValidator.GetSafeString(subDict, "sign_off_date")

        If Not String.IsNullOrWhiteSpace(rawVessel) OrElse Not String.IsNullOrWhiteSpace(rawSignOn) Then
            totalFields += 1
            Dim vRes As ReferenceResolutionService.ResolutionResult = ReferenceResolutionService.ResolveVessel(rawVessel)
            Dim rRes As ReferenceResolutionService.ResolutionResult = ReferenceResolutionService.ResolveRank(rawRank)

            Dim ss As New PdsSeaServiceSuggestion With {
                .VesselId = vRes.ResolvedId,
                .VesselName = If(vRes.IsResolved, vRes.MatchedCanonicalName, rawVessel),
                .RankId = rRes.ResolvedId,
                .RankName = If(rRes.IsResolved, rRes.MatchedCanonicalName, rawRank),
                .CandidateVessels = vRes.CandidateSuggestions,
                .CandidateRanks = rRes.CandidateSuggestions,
                .EmployerAgency = JsonExtractionValidator.GetSafeString(subDict, "employer_agency"),
                .Status = If(vRes.IsResolved AndAlso rRes.IsResolved, ValidationStatus.ExtractedValid, ValidationStatus.UnresolvedReference)
            }
            ss.Sources.Add(source)
            ss.ExtractedRawValues("vessel_name") = rawVessel
            ss.ExtractedRawValues("rank") = rawRank

            If Not String.IsNullOrWhiteSpace(ss.EmployerAgency) Then
                ss.Remarks = "Agency: " & ss.EmployerAgency
            End If

            Dim dOn As Nullable(Of DateTime) = Nothing
            Dim wOn As String = String.Empty
            If JsonExtractionValidator.ValidateDate(rawSignOn, False, dOn, wOn) Then
                ss.DateFrom = dOn
            End If

            ' Appendix D: Never infer ongoing assignment or invent missing sign-off dates
            Dim dOff As Nullable(Of DateTime) = Nothing
            Dim wOff As String = String.Empty
            If JsonExtractionValidator.ValidateDate(rawSignOff, False, dOff, wOff) Then
                ss.DateTo = dOff
            End If

            Dim rawVslType As String = JsonExtractionValidator.GetSafeString(subDict, "vessel_type")
            If Not String.IsNullOrWhiteSpace(rawVslType) Then ss.UnsupportedAttributes("vessel_type") = rawVslType
            Dim rawFlag As String = JsonExtractionValidator.GetSafeString(subDict, "flag_state")
            If Not String.IsNullOrWhiteSpace(rawFlag) Then ss.UnsupportedAttributes("flag_state") = rawFlag

            pkg.SeaServiceRecords.Add(ss)
        End If
    End Sub

    Private Shared Sub MapGeneral(
        dict As Dictionary(Of String, Object),
        source As SourceAttribution,
        pkg As PdsExtractionSuggestionPackage,
        ByRef totalFields As Integer
    )
        Dim detectedType As String = JsonExtractionValidator.GetSafeString(dict, "document_type")
        Select Case detectedType.ToLowerInvariant()
            Case "resume", "cv"
                MapResume(dict, source, pkg, totalFields)
            Case "passport"
                MapPassport(dict, source, pkg, totalFields)
            Case "sirb", "seaman's book", "seamans book"
                MapSirb(dict, source, pkg, totalFields)
            Case "certificate", "training"
                MapCertificate(dict, source, pkg, totalFields)
            Case "license"
                MapLicense(dict, source, pkg, totalFields)
            Case "seaservice", "sea service"
                MapSeaService(dict, source, pkg, totalFields)
            Case Else
                ' Map any basic personal fields present
                Dim rawName As String = JsonExtractionValidator.GetSafeString(dict, "holder_name")
                If Not String.IsNullOrWhiteSpace(rawName) Then
                    totalFields += 1
                    Dim parsed As JsonExtractionValidator.ParsedNameResult = JsonExtractionValidator.ParseNameSafely(rawName)
                    If Not parsed.IsAmbiguous AndAlso Not String.IsNullOrWhiteSpace(parsed.FirstName) Then
                        ConflictAndDeduplicationHelper.MergeStringField(pkg.PersonalDetails.FirstName, parsed.FirstName, rawName, source)
                        ConflictAndDeduplicationHelper.MergeStringField(pkg.PersonalDetails.LastName, parsed.LastName, rawName, source)
                    End If
                End If
        End Select
    End Sub

    ' ── Counting Metrics ─────────────────────────────────────────────────────

    Private Shared Sub CountUnresolvedAndConflicts(pkg As PdsExtractionSuggestionPackage, audit As ExtractionAuditSummary)
        Dim unres As Integer = 0
        Dim conf As Integer = 0

        Dim pd As PdsPersonalDetailsSuggestions = pkg.PersonalDetails
        CheckFieldStatus(pd.LastName, unres, conf)
        CheckFieldStatus(pd.FirstName, unres, conf)
        CheckFieldStatus(pd.MiddleName, unres, conf)
        CheckDateStatus(pd.DateOfBirth, unres, conf)
        CheckFieldStatus(pd.PlaceOfBirth, unres, conf)
        CheckFieldStatus(pd.Gender, unres, conf)
        CheckFieldStatus(pd.CivilStatus, unres, conf)
        CheckFieldStatus(pd.Religion, unres, conf)
        CheckFieldStatus(pd.Nationality, unres, conf)
        CheckFieldStatus(pd.AppliedRank, unres, conf)
        CheckFieldStatus(pd.ContactNumber, unres, conf)
        CheckFieldStatus(pd.EmailAddress, unres, conf)
        CheckFieldStatus(pd.Address, unres, conf)
        CheckFieldStatus(pd.SchoolName, unres, conf)
        CheckFieldStatus(pd.Course, unres, conf)

        For Each d As PdsDocumentSuggestion In pkg.Documents
            If d.Status = ValidationStatus.UnresolvedReference Then unres += 1
            If d.ConflictingDates Then conf += 1
        Next

        For Each ss As PdsSeaServiceSuggestion In pkg.SeaServiceRecords
            If ss.Status = ValidationStatus.UnresolvedReference Then unres += 1
            If ss.IsNearDuplicate Then conf += 1
        Next

        audit.TotalUnresolvedReferences = unres
        audit.TotalConflictsDetected = conf
    End Sub

    Private Shared Sub CheckFieldStatus(fs As PdsFieldSuggestion(Of String), ByRef unres As Integer, ByRef conf As Integer)
        If fs Is Nothing Then Return
        If fs.Status = ValidationStatus.UnresolvedReference Then unres += 1
        If fs.Status = ValidationStatus.Conflicting OrElse fs.ConflictingAlternatives.Count > 0 Then conf += 1
    End Sub

    Private Shared Sub CheckDateStatus(fs As PdsFieldSuggestion(Of Nullable(Of DateTime)), ByRef unres As Integer, ByRef conf As Integer)
        If fs Is Nothing Then Return
        If fs.Status = ValidationStatus.UnresolvedReference Then unres += 1
        If fs.Status = ValidationStatus.Conflicting OrElse fs.ConflictingAlternatives.Count > 0 Then conf += 1
    End Sub

End Class
