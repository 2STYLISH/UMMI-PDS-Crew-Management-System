Imports System
Imports System.Collections.Generic
Imports System.Text.RegularExpressions
Imports PdsMappingModels

''' <summary>
''' PHASE E — Conflict Detection &amp; Record Deduplication Helper (FR-CM-66, FR-CM-78)
''' Detects cross-document contradictions and performs identical-only record deduplication.
''' 
''' CRITICAL SAFEGUARDS:
''' - No automatic documentary precedence: all conflicting alternatives are preserved with full source citations (Safeguard #1).
''' - Strict deduplication: merges only records that are identical after safe normalization.
''' - Near-duplicate sea-service and conflicting certificate dates are flagged for applicant review, not silently merged (Safeguard #3).
''' </summary>
Public Class ConflictAndDeduplicationHelper

    ' ── Single-Value Field Conflict Merging ──────────────────────────────────

    ''' <summary>
    ''' Merges a newly extracted string field suggestion into an existing target field suggestion.
    ''' If identical, appends source attribution. If differing, tracks as a conflict without automated precedence.
    ''' </summary>
    Public Shared Sub MergeStringField(
        target As PdsFieldSuggestion(Of String),
        newVal As String,
        newRaw As String,
        source As SourceAttribution,
        Optional resolvedFk As Nullable(Of Integer) = Nothing,
        Optional candidates As List(Of ReferenceMatchCandidate) = Nothing
    )
        If String.IsNullOrWhiteSpace(newVal) Then
            Return
        End If

        Dim cleanNew As String = newVal.Trim()

        ' If target was previously empty, assign as initial candidate
        If Not target.HasValue Then
            target.NormalizedValue = cleanNew
            target.ExtractedRawValue = newRaw
            target.Sources.Add(source)
            target.Status = ValidationStatus.ExtractedValid
            If resolvedFk.HasValue Then
                target.ResolvedForeignKeyId = resolvedFk
            End If
            If candidates IsNot Nothing AndAlso candidates.Count > 0 Then
                target.CandidateSuggestions.AddRange(candidates)
            End If
            Return
        End If

        ' Target already has a value: compare for equality
        If String.Equals(target.NormalizedValue, cleanNew, StringComparison.OrdinalIgnoreCase) Then
            ' Identical value across documents: confirm validity and add source attribution
            If Not ContainsSource(target.Sources, source) Then
                target.Sources.Add(source)
            End If
            If target.Status = ValidationStatus.Missing Then
                target.Status = ValidationStatus.ExtractedValid
            End If
        Else
            ' Differing values detected: CONFLICT (Safeguard #1: No automatic winner)
            target.Status = ValidationStatus.Conflicting
            target.StatusMessage = "Conflicting values extracted across documents; applicant confirmation required."

            ' Ensure primary value is tracked in alternatives list if not already
            If target.ConflictingAlternatives.Count = 0 AndAlso target.Sources.Count > 0 Then
                target.ConflictingAlternatives.Add(New ConflictingAlternative(Of String)(target.NormalizedValue, target.ExtractedRawValue, target.Sources(0)))
            End If

            ' Add new conflicting alternative
            target.ConflictingAlternatives.Add(New ConflictingAlternative(Of String)(cleanNew, newRaw, source))

            If Not ContainsSource(target.Sources, source) Then
                target.Sources.Add(source)
            End If
        End If
    End Sub

    ''' <summary>
    ''' Merges a newly extracted date field suggestion into an existing target date suggestion.
    ''' </summary>
    Public Shared Sub MergeDateField(
        target As PdsFieldSuggestion(Of Nullable(Of DateTime)),
        newDate As Nullable(Of DateTime),
        newRaw As String,
        source As SourceAttribution
    )
        If Not newDate.HasValue Then
            Return
        End If

        If Not target.HasValue Then
            target.NormalizedValue = newDate
            target.ExtractedRawValue = newRaw
            target.Sources.Add(source)
            target.Status = ValidationStatus.ExtractedValid
            Return
        End If

        If target.NormalizedValue.Value.Date = newDate.Value.Date Then
            ' Identical date across documents
            If Not ContainsSource(target.Sources, source) Then
                target.Sources.Add(source)
            End If
        Else
            ' Differing dates: CONFLICT
            target.Status = ValidationStatus.Conflicting
            target.StatusMessage = "Conflicting dates extracted across documents; applicant confirmation required."

            If target.ConflictingAlternatives.Count = 0 AndAlso target.Sources.Count > 0 Then
                target.ConflictingAlternatives.Add(New ConflictingAlternative(Of Nullable(Of DateTime))(target.NormalizedValue, target.ExtractedRawValue, target.Sources(0)))
            End If

            target.ConflictingAlternatives.Add(New ConflictingAlternative(Of Nullable(Of DateTime))(newDate, newRaw, source))

            If Not ContainsSource(target.Sources, source) Then
                target.Sources.Add(source)
            End If
        End If
    End Sub

    ' ── Repeating Records Deduplication (Sea Service) ────────────────────────

    ''' <summary>
    ''' Deduplicates repeating sea service records.
    ''' - Identical records (same normalized vessel, dates, rank) are merged with combined sources.
    ''' - Near-duplicate records (overlapping dates on same vessel) are preserved as separate entries flagged with ReviewRequired.
    ''' </summary>
    Public Shared Function DeduplicateSeaService(records As List(Of PdsSeaServiceSuggestion)) As List(Of PdsSeaServiceSuggestion)
        If records Is Nothing OrElse records.Count <= 1 Then
            Return If(records, New List(Of PdsSeaServiceSuggestion)())
        End If

        Dim resultList As New List(Of PdsSeaServiceSuggestion)()

        For Each candidate As PdsSeaServiceSuggestion In records
            Dim matchedExact As PdsSeaServiceSuggestion = Nothing

            For Each existing As PdsSeaServiceSuggestion In resultList
                If IsExactSeaServiceMatch(existing, candidate) Then
                    matchedExact = existing
                    Exit For
                End If
            Next

            If matchedExact IsNot Nothing Then
                ' Identical record: merge citations and remarks
                For Each src As SourceAttribution In candidate.Sources
                    If Not ContainsSource(matchedExact.Sources, src) Then
                        matchedExact.Sources.Add(src)
                    End If
                Next
                If String.IsNullOrWhiteSpace(matchedExact.Remarks) AndAlso Not String.IsNullOrWhiteSpace(candidate.Remarks) Then
                    matchedExact.Remarks = candidate.Remarks
                End If
            Else
                ' Check for near-duplicates (overlapping dates on same vessel)
                For Each existing As PdsSeaServiceSuggestion In resultList
                    If IsNearDuplicateSeaService(existing, candidate) Then
                        existing.IsNearDuplicate = True
                        existing.Status = ValidationStatus.ReviewRequired
                        existing.NearDuplicateNote = String.Format("Potential overlapping voyage with {0} to {1}.",
                            If(candidate.DateFrom.HasValue, candidate.DateFrom.Value.ToString("yyyy-MM-dd"), "?"),
                            If(candidate.DateTo.HasValue, candidate.DateTo.Value.ToString("yyyy-MM-dd"), "?"))

                        candidate.IsNearDuplicate = True
                        candidate.Status = ValidationStatus.ReviewRequired
                        candidate.NearDuplicateNote = String.Format("Potential overlapping voyage with {0} to {1}.",
                            If(existing.DateFrom.HasValue, existing.DateFrom.Value.ToString("yyyy-MM-dd"), "?"),
                            If(existing.DateTo.HasValue, existing.DateTo.Value.ToString("yyyy-MM-dd"), "?"))
                    End If
                Next

                resultList.Add(candidate)
            End If
        Next

        Return resultList
    End Function

    Private Shared Function IsExactSeaServiceMatch(a As PdsSeaServiceSuggestion, b As PdsSeaServiceSuggestion) As Boolean
        Dim vA As String = NormalizeString(a.VesselName)
        Dim vB As String = NormalizeString(b.VesselName)
        If vA <> vB OrElse String.IsNullOrEmpty(vA) Then Return False

        If a.DateFrom.HasValue <> b.DateFrom.HasValue Then Return False
        If a.DateFrom.HasValue AndAlso a.DateFrom.Value.Date <> b.DateFrom.Value.Date Then Return False

        If a.DateTo.HasValue <> b.DateTo.HasValue Then Return False
        If a.DateTo.HasValue AndAlso a.DateTo.Value.Date <> b.DateTo.Value.Date Then Return False

        Dim rA As String = NormalizeString(a.RankName)
        Dim rB As String = NormalizeString(b.RankName)
        If rA <> rB Then Return False

        Return True
    End Function

    Private Shared Function IsNearDuplicateSeaService(a As PdsSeaServiceSuggestion, b As PdsSeaServiceSuggestion) As Boolean
        Dim vA As String = NormalizeString(a.VesselName)
        Dim vB As String = NormalizeString(b.VesselName)
        If vA <> vB OrElse String.IsNullOrEmpty(vA) Then Return False

        ' If sign-on date matches but sign-off date or rank differs slightly
        If a.DateFrom.HasValue AndAlso b.DateFrom.HasValue Then
            If a.DateFrom.Value.Date = b.DateFrom.Value.Date Then
                Return True
            End If

            ' If date ranges overlap
            If a.DateTo.HasValue AndAlso b.DateTo.HasValue Then
                Dim overlap As Boolean = (a.DateFrom.Value.Date <= b.DateTo.Value.Date) AndAlso (b.DateFrom.Value.Date <= a.DateTo.Value.Date)
                If overlap Then Return True
            End If
        End If

        Return False
    End Function

    ' ── Repeating Records Deduplication (Documents & Certificates) ───────────

    ''' <summary>
    ''' Deduplicates repeating document suggestions.
    ''' - Identical doc type + number + dates are merged with combined source tags.
    ''' - Identical doc type + number with conflicting dates are flagged ConflictingDates = True.
    ''' </summary>
    Public Shared Function DeduplicateDocuments(docs As List(Of PdsDocumentSuggestion)) As List(Of PdsDocumentSuggestion)
        If docs Is Nothing OrElse docs.Count <= 1 Then
            Return If(docs, New List(Of PdsDocumentSuggestion)())
        End If

        Dim resultList As New List(Of PdsDocumentSuggestion)()

        For Each candidate As PdsDocumentSuggestion In docs
            Dim matchedDoc As PdsDocumentSuggestion = Nothing

            For Each existing As PdsDocumentSuggestion In resultList
                If IsDocumentMatch(existing, candidate) Then
                    matchedDoc = existing
                    Exit For
                End If
            Next

            If matchedDoc IsNot Nothing Then
                ' Check if issue or expiry dates conflict
                Dim datesConflict As Boolean = False
                If matchedDoc.DateIssued.HasValue AndAlso candidate.DateIssued.HasValue AndAlso
                   matchedDoc.DateIssued.Value.Date <> candidate.DateIssued.Value.Date Then
                    datesConflict = True
                End If
                If matchedDoc.DateExpiry.HasValue AndAlso candidate.DateExpiry.HasValue AndAlso
                   matchedDoc.DateExpiry.Value.Date <> candidate.DateExpiry.Value.Date Then
                    datesConflict = True
                End If

                If datesConflict Then
                    ' Flag conflicting dates (Safeguard #3: Do NOT silently merge conflicting dates)
                    matchedDoc.ConflictingDates = True
                    matchedDoc.Status = ValidationStatus.ReviewRequired
                    matchedDoc.StatusMessage = "Differing issue or expiry dates extracted across documents; applicant verification required."

                    candidate.ConflictingDates = True
                    candidate.Status = ValidationStatus.ReviewRequired
                    candidate.StatusMessage = "Differing issue or expiry dates extracted across documents; applicant verification required."
                    resultList.Add(candidate)
                Else
                    ' Identical document: merge citations and populate any missing date
                    For Each src As SourceAttribution In candidate.Sources
                        If Not ContainsSource(matchedDoc.Sources, src) Then
                            matchedDoc.Sources.Add(src)
                        End If
                    Next
                    If Not matchedDoc.DateIssued.HasValue AndAlso candidate.DateIssued.HasValue Then
                        matchedDoc.DateIssued = candidate.DateIssued
                    End If
                    If Not matchedDoc.DateExpiry.HasValue AndAlso candidate.DateExpiry.HasValue Then
                        matchedDoc.DateExpiry = candidate.DateExpiry
                    End If
                End If
            Else
                resultList.Add(candidate)
            End If
        Next

        Return resultList
    End Function

    Private Shared Function IsDocumentMatch(a As PdsDocumentSuggestion, b As PdsDocumentSuggestion) As Boolean
        Dim numA As String = NormalizeAlphanumeric(a.DocumentNumber)
        Dim numB As String = NormalizeAlphanumeric(b.DocumentNumber)

        ' If both have document numbers, compare normalized numbers
        If Not String.IsNullOrEmpty(numA) AndAlso Not String.IsNullOrEmpty(numB) Then
            If numA = numB Then
                ' If either document types match or one is unclassified
                If a.DocumentTypeId.HasValue AndAlso b.DocumentTypeId.HasValue Then
                    Return a.DocumentTypeId.Value = b.DocumentTypeId.Value
                End If
                Return True
            End If
            Return False
        End If

        ' If no numbers, compare document type and dates
        If a.DocumentTypeId.HasValue AndAlso b.DocumentTypeId.HasValue AndAlso a.DocumentTypeId.Value = b.DocumentTypeId.Value Then
            If a.DateIssued.HasValue AndAlso b.DateIssued.HasValue AndAlso a.DateIssued.Value.Date = b.DateIssued.Value.Date Then
                Return True
            End If
        End If

        Return False
    End Function

    ' ── Utilities ────────────────────────────────────────────────────────────

    Private Shared Function ContainsSource(list As List(Of SourceAttribution), item As SourceAttribution) As Boolean
        For Each s As SourceAttribution In list
            If s.StagedFileId = item.StagedFileId AndAlso s.PageNumber = item.PageNumber Then
                Return True
            End If
        Next
        Return False
    End Function

    Private Shared Function NormalizeString(str As String) As String
        If String.IsNullOrWhiteSpace(str) Then Return String.Empty
        Dim clean As String = Regex.Replace(str.Trim().ToLowerInvariant(), "\s+", " ")
        Return clean
    End Function

    Private Shared Function NormalizeAlphanumeric(str As String) As String
        If String.IsNullOrWhiteSpace(str) Then Return String.Empty
        Return Regex.Replace(str.Trim().ToUpperInvariant(), "[^A-Z0-9]", "")
    End Function

End Class
