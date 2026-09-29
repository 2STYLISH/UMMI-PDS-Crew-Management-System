Imports System
Imports System.Collections.Concurrent
Imports System.Collections.Generic
Imports System.Data
Imports System.Text.RegularExpressions
Imports MySql.Data.MySqlClient
Imports PdsMappingModels

''' <summary>
''' PHASE E — Dynamic Reference Resolution Service (FR-CM-63)
''' Queries existing database lookup tables dynamically (read-only) with thread-safe caching.
''' Resolves exact matches and approved aliases automatically.
''' 
''' CRITICAL SAFEGUARDS:
''' - Fuzzy matches are suggestions ONLY; they NEVER automatically assign foreign keys (Safeguard #3).
''' - Zero database INSERT or UPDATE operations; shared reference tables are never modified.
''' - Gracefully degrades to UnresolvedReference on database connectivity failure.
''' - Provisional 0.85 fuzzy threshold is configurable [PROPOSED / TBD - Subject to UMMI Approval].
''' </summary>
Public Class ReferenceResolutionService

    Public Class ReferenceItem
        Public Property Id As Integer
        Public Property CodeOrName As String
        Public Property NormalizedCodeOrName As String
        Public Property CategoryOrType As String
        Public Property ParentId As Nullable(Of Integer)
    End Class

    ' Thread-safe in-memory cache of reference tables (reloaded periodically or on demand)
    Private Shared ReadOnly _cacheLock As New Object()
    Private Shared _cacheLastLoaded As DateTime = DateTime.MinValue
    Private Shared ReadOnly _cacheDuration As TimeSpan = TimeSpan.FromMinutes(30)

    Private Shared _ranks As List(Of ReferenceItem) = Nothing
    Private Shared _documents As List(Of ReferenceItem) = Nothing
    Private Shared _nationalities As List(Of ReferenceItem) = Nothing
    Private Shared _religions As List(Of ReferenceItem) = Nothing
    Private Shared _schools As List(Of ReferenceItem) = Nothing
    Private Shared _courses As List(Of ReferenceItem) = Nothing
    Private Shared _provinces As List(Of ReferenceItem) = Nothing
    Private Shared _cities As List(Of ReferenceItem) = Nothing
    Private Shared _vessels As List(Of ReferenceItem) = Nothing

    ''' <summary>
    ''' Configurable provisional threshold for proposing candidate suggestions [PROPOSED / TBD].
    ''' </summary>
    Public Shared ReadOnly Property ProvisionalFuzzyThreshold As Double
        Get
            Dim val As String = System.Web.Configuration.WebConfigurationManager.AppSettings("ApplicantExtraction_ProvisionalFuzzyThreshold")
            If String.IsNullOrWhiteSpace(val) Then
                val = System.Configuration.ConfigurationManager.AppSettings("ApplicantExtraction_ProvisionalFuzzyThreshold")
            End If
            Dim parsed As Double = 0.85
            If Double.TryParse(val, parsed) Then
                Return parsed
            End If
            Return 0.85
        End Get
    End Property

    ''' <summary>
    ''' Result of a reference lookup attempt.
    ''' </summary>
    Public Class ResolutionResult
        Public Property IsResolved As Boolean = False
        Public Property ResolvedId As Nullable(Of Integer) = Nothing
        Public Property MatchedCanonicalName As String = String.Empty
        Public Property MatchType As String = "None" ' "Exact", "Alias", "Fuzzy", "None"
        Public Property Status As ValidationStatus = ValidationStatus.UnresolvedReference
        Public Property CandidateSuggestions As New List(Of ReferenceMatchCandidate)()
    End Class

    ' ── Cache Loading (Read-Only & Fault-Tolerant) ───────────────────────────

    ''' <summary>
    ''' Ensures reference cache is loaded from the database using read-only SELECT queries.
    ''' Degrades gracefully if database is unreachable.
    ''' </summary>
    Public Shared Sub EnsureCacheLoaded(Optional forceReload As Boolean = False)
        SyncLock _cacheLock
            If Not forceReload AndAlso _ranks IsNot Nothing AndAlso (DateTime.UtcNow - _cacheLastLoaded) < _cacheDuration Then
                Return
            End If

            Try
                _ranks = LoadReferenceList("SELECT id, rank_code AS name, rank_type AS cat FROM tbl_rank ORDER BY sequence, id")
                _documents = LoadReferenceList("SELECT id, documentName AS name, docType AS cat FROM tbl_documents ORDER BY sequence, id")
                _nationalities = LoadReferenceList("SELECT id, nationality AS name, '' AS cat FROM tbl_nationality ORDER BY id")
                _religions = LoadReferenceList("SELECT id, religion AS name, '' AS cat FROM tbl_religion ORDER BY id")
                _schools = LoadReferenceList("SELECT id, school_name AS name, '' AS cat FROM tbl_school ORDER BY id")
                _courses = LoadReferenceList("SELECT id, course AS name, '' AS cat FROM tbl_course ORDER BY id")
                _provinces = LoadReferenceList("SELECT id, provinces AS name, '' AS cat FROM tbl_provinces ORDER BY id")
                _cities = LoadReferenceList("SELECT id, cities AS name, province AS parent FROM tbl_cities ORDER BY id", hasParent:=True)
                _vessels = LoadReferenceList("SELECT id, vesselName AS name, active AS cat FROM tbl_vessels ORDER BY id")

                _cacheLastLoaded = DateTime.UtcNow
            Catch ex As Exception
                ' Graceful degradation: initialize empty lists so lookups degrade to UnresolvedReference
                If forceReload OrElse _ranks Is Nothing Then _ranks = New List(Of ReferenceItem)()
                If forceReload OrElse _documents Is Nothing Then _documents = New List(Of ReferenceItem)()
                If forceReload OrElse _nationalities Is Nothing Then _nationalities = New List(Of ReferenceItem)()
                If forceReload OrElse _religions Is Nothing Then _religions = New List(Of ReferenceItem)()
                If forceReload OrElse _schools Is Nothing Then _schools = New List(Of ReferenceItem)()
                If forceReload OrElse _courses Is Nothing Then _courses = New List(Of ReferenceItem)()
                If forceReload OrElse _provinces Is Nothing Then _provinces = New List(Of ReferenceItem)()
                If forceReload OrElse _cities Is Nothing Then _cities = New List(Of ReferenceItem)()
                If forceReload OrElse _vessels Is Nothing Then _vessels = New List(Of ReferenceItem)()
            End Try
        End SyncLock
    End Sub

    Private Shared Function LoadReferenceList(sql As String, Optional hasParent As Boolean = False) As List(Of ReferenceItem)
        Dim list As New List(Of ReferenceItem)()
        Using cn As New MySqlConnection(DbHelper.ConnStr)
            cn.Open()
            Using cmd As New MySqlCommand(sql, cn)
                Using dr As MySqlDataReader = cmd.ExecuteReader()
                    Do While dr.Read()
                        Dim item As New ReferenceItem With {
                            .Id = Convert.ToInt32(dr("id")),
                            .CodeOrName = If(dr("name") IsNot DBNull.Value, dr("name").ToString(), String.Empty),
                            .NormalizedCodeOrName = NormalizeForMatching(If(dr("name") IsNot DBNull.Value, dr("name").ToString(), String.Empty))
                        }
                        If Not hasParent AndAlso dr.FieldCount > 2 Then
                            item.CategoryOrType = If(dr("cat") IsNot DBNull.Value, dr("cat").ToString(), String.Empty)
                        ElseIf hasParent AndAlso dr.FieldCount > 2 Then
                            item.ParentId = If(dr("parent") IsNot DBNull.Value, Convert.ToInt32(dr("parent")), CType(Nothing, Nullable(Of Integer)))
                        End If
                        list.Add(item)
                    Loop
                End Using
            End Using
        End Using
        Return list
    End Function

    ' ── Matching Core ────────────────────────────────────────────────────────

    ''' <summary>
    ''' Resolves an extracted text string against a specified reference lookup list.
    ''' - Exact match -> Resolves automatically.
    ''' - Approved alias -> Resolves automatically.
    ''' - Fuzzy match (>= provisional threshold) -> SUGGESTION ONLY. IsResolved remains False (Safeguard #3).
    ''' - Unmatched -> IsResolved remains False, Status = UnresolvedReference.
    ''' </summary>
    Public Shared Function ResolveReference(rawText As String, refType As String, Optional parentIdFilter As Nullable(Of Integer) = Nothing) As ResolutionResult
        Dim res As New ResolutionResult()

        If String.IsNullOrWhiteSpace(rawText) Then
            res.Status = ValidationStatus.Missing
            Return res
        End If

        EnsureCacheLoaded()

        Dim candidateList As List(Of ReferenceItem) = GetReferenceList(refType)
        If candidateList Is Nothing OrElse candidateList.Count = 0 Then
            res.Status = ValidationStatus.UnresolvedReference
            Return res
        End If

        Dim normalizedInput As String = NormalizeForMatching(rawText)

        ' TIER 1: Exact Match
        For Each item As ReferenceItem In candidateList
            If parentIdFilter.HasValue AndAlso item.ParentId.HasValue AndAlso item.ParentId.Value <> parentIdFilter.Value Then
                Continue For
            End If

            If String.Equals(item.NormalizedCodeOrName, normalizedInput, StringComparison.OrdinalIgnoreCase) Then
                res.IsResolved = True
                res.ResolvedId = item.Id
                res.MatchedCanonicalName = item.CodeOrName
                res.MatchType = "Exact"
                res.Status = ValidationStatus.ExtractedValid
                Return res
            End If
        Next

        ' TIER 2: Approved Unambiguous Alias Match
        Dim canonicalAlias As String = ResolveApprovedAlias(normalizedInput, refType)
        If Not String.IsNullOrEmpty(canonicalAlias) Then
            Dim normAlias As String = NormalizeForMatching(canonicalAlias)
            For Each item As ReferenceItem In candidateList
                If String.Equals(item.NormalizedCodeOrName, normAlias, StringComparison.OrdinalIgnoreCase) Then
                    res.IsResolved = True
                    res.ResolvedId = item.Id
                    res.MatchedCanonicalName = item.CodeOrName
                    res.MatchType = "Alias"
                    res.Status = ValidationStatus.ExtractedValid
                    Return res
                End If
            Next
        End If

        ' TIER 3: Fuzzy Match (Provisional Threshold) -> SUGGESTION ONLY (Safeguard #3)
        Dim bestScore As Double = 0.0
        Dim topCandidates As New List(Of ReferenceMatchCandidate)()

        For Each item As ReferenceItem In candidateList
            If parentIdFilter.HasValue AndAlso item.ParentId.HasValue AndAlso item.ParentId.Value <> parentIdFilter.Value Then
                Continue For
            End If

            ' Ignore "Others (Please specify)" entries from fuzzy comparisons
            If item.CodeOrName.StartsWith("Other", StringComparison.OrdinalIgnoreCase) Then
                Continue For
            End If

            Dim score As Double = ComputeSimilarity(normalizedInput, item.NormalizedCodeOrName)
            If score >= ProvisionalFuzzyThreshold Then
                topCandidates.Add(New ReferenceMatchCandidate With {
                    .Id = item.Id,
                    .MatchedCodeOrName = item.CodeOrName,
                    .DisplayText = item.CodeOrName,
                    .SimilarityScore = score,
                    .MatchType = "Fuzzy"
                })
            End If
        Next

        topCandidates.Sort(Function(a, b) b.SimilarityScore.CompareTo(a.SimilarityScore))

        If topCandidates.Count > 0 Then
            ' CRITICAL SAFEGUARD: Do NOT assign FK for fuzzy matches. Leave as suggestion only.
            res.IsResolved = False
            res.ResolvedId = Nothing
            res.MatchType = "Fuzzy"
            res.Status = ValidationStatus.UnresolvedReference
            res.CandidateSuggestions = topCandidates
            Return res
        End If

        ' TIER 4: Unmatched Reference
        res.IsResolved = False
        res.ResolvedId = Nothing
        res.MatchType = "None"
        res.Status = ValidationStatus.UnresolvedReference
        Return res
    End Function

    ' ── Specific Lookup Wrappers ─────────────────────────────────────────────

    Public Shared Function ResolveRank(rawRank As String) As ResolutionResult
        Return ResolveReference(rawRank, "Rank")
    End Function

    Public Shared Function ResolveDocumentType(rawDocTitle As String, Optional docTypeFilter As String = Nothing) As ResolutionResult
        Dim res As ResolutionResult = ResolveReference(rawDocTitle, "Document")
        Return res
    End Function

    Public Shared Function ResolveNationality(rawNationality As String) As ResolutionResult
        Return ResolveReference(rawNationality, "Nationality")
    End Function

    Public Shared Function ResolveReligion(rawReligion As String) As ResolutionResult
        Return ResolveReference(rawReligion, "Religion")
    End Function

    Public Shared Function ResolveSchool(rawSchool As String) As ResolutionResult
        Return ResolveReference(rawSchool, "School")
    End Function

    Public Shared Function ResolveCourse(rawCourse As String) As ResolutionResult
        Return ResolveReference(rawCourse, "Course")
    End Function

    Public Shared Function ResolveProvince(rawProvince As String) As ResolutionResult
        Return ResolveReference(rawProvince, "Province")
    End Function

    Public Shared Function ResolveCity(rawCity As String, Optional provinceId As Nullable(Of Integer) = Nothing) As ResolutionResult
        Return ResolveReference(rawCity, "City", provinceId)
    End Function

    Public Shared Function ResolveVessel(rawVessel As String) As ResolutionResult
        Return ResolveReference(rawVessel, "Vessel")
    End Function

    ' ── Helper & Alias Methods ───────────────────────────────────────────────

    Private Shared Function GetReferenceList(refType As String) As List(Of ReferenceItem)
        Select Case refType.ToLowerInvariant()
            Case "rank" : Return _ranks
            Case "document" : Return _documents
            Case "nationality" : Return _nationalities
            Case "religion" : Return _religions
            Case "school" : Return _schools
            Case "course" : Return _courses
            Case "province" : Return _provinces
            Case "city" : Return _cities
            Case "vessel" : Return _vessels
            Case Else : Return Nothing
        End Select
    End Function

    Private Shared Function NormalizeForMatching(str As String) As String
        If String.IsNullOrWhiteSpace(str) Then Return String.Empty
        ' Lowercase, remove non-alphanumeric except spaces, collapse multiple spaces
        Dim clean As String = Regex.Replace(str.ToLowerInvariant(), "[^a-z0-9\s]", " ")
        Return Regex.Replace(clean, "\s+", " ").Trim()
    End Function

    ''' <summary>
    ''' Approved maritime aliases mapping common abbreviations to canonical database names.
    ''' </summary>
    Private Shared Function ResolveApprovedAlias(normalizedInput As String, refType As String) As String
        Select Case refType.ToLowerInvariant()
            Case "rank"
                Select Case normalizedInput
                    Case "ab", "able seaman", "able bodied seaman" : Return "AB SEAMAN"
                    Case "co", "c o", "chief mate", "first mate", "1st officer" : Return "CHIEF OFFICER"
                    Case "2o", "2 o", "2nd mate", "second officer" : Return "2ND OFFICER"
                    Case "3o", "3 o", "3rd mate", "third officer" : Return "3RD OFFICER"
                    Case "ce", "c e", "chief eng", "chief engineer" : Return "CHIEF ENGINEER"
                    Case "2e", "2 e", "second engineer", "2nd eng" : Return "2ND ENGINEER"
                    Case "3e", "3 e", "third engineer", "3rd eng" : Return "3RD ENGINEER"
                    Case "4e", "4 e", "fourth engineer", "4th eng" : Return "4TH ENGINEER"
                    Case "dc", "d c", "deck cadet" : Return "DECK CADET"
                    Case "ec", "e c", "engine cadet" : Return "ENGINE CADET"
                    Case "os", "o s", "ordinary seaman" : Return "OS"
                    Case "cook", "c cook", "chief cook" : Return "CHIEF COOK"
                    Case "steward", "messman" : Return "STEWARD"
                    Case "master", "captain" : Return "MASTER"
                End Select

            Case "course"
                Select Case normalizedInput
                    Case "bsmt", "bs marine transportation", "b s marine transportation"
                        Return "Bachelor of Science in Marine Transportation"
                    Case "bsmare", "bsme", "bs marine engineering", "b s marine engineering"
                        Return "Bachelor of Science in Marine Engineering"
                End Select

            Case "school"
                Select Case normalizedInput
                    Case "pmma" : Return "Philippine Merchant Marine Academy"
                    Case "jblfmu", "john b lacson", "john b lacson foundation" : Return "John B. Lacson Foundation Maritime University"
                    Case "pmi", "pmi colleges" : Return "Philippine Maritime Institute"
                    Case "sti", "sti college" : Return "STI College"
                    Case "ama", "ama computer university" : Return "AMA Computer University"
                End Select

            Case "nationality"
                Select Case normalizedInput
                    Case "ph", "phl", "philippines", "filipino", "filipina" : Return "Filipino"
                End Select

            Case "religion"
                Select Case normalizedInput
                    Case "rc", "roman catholic", "catholic" : Return "Roman Catholic"
                    Case "inc", "iglesia ni cristo" : Return "Iglesia ni Cristo"
                    Case "sda", "seventh day adventist" : Return "Seventh Day Adventist"
                    Case "muslim", "islam" : Return "Islam"
                End Select

            Case "document"
                Select Case normalizedInput
                    Case "passport", "philippine passport" : Return "Passport"
                    Case "sirb", "seamans book", "seaman book", "seafarers identification" : Return "Seaman's Book (SIRB)"
                    Case "bst", "basic safety training", "stcw bst", "solas" : Return "STCW BST Certificate"
                    Case "pdos" : Return "PDOS Certificate"
                    Case "coc", "certificate of competency" : Return "Certificate of Competency (COC)"
                    Case "gmdss", "goc" : Return "GMDSS / General Operator Certificate"
                    Case "watch permit", "officers watch permit" : Return "Officer's Watch Permit"
                End Select
        End Select

        Return String.Empty
    End Function

    ''' <summary>
    ''' Computes similarity score between 0.0 and 1.0.
    ''' Returns the best (maximum) of Levenshtein ratio and Jaro-Winkler similarity,
    ''' so that common OCR and typographical transpositions are captured as candidates.
    ''' NOTE: This is a suggestion-only mechanism; no FK is ever auto-assigned (Safeguard #3).
    ''' </summary>
    Public Shared Function ComputeSimilarity(s1 As String, s2 As String) As Double
        If String.IsNullOrEmpty(s1) AndAlso String.IsNullOrEmpty(s2) Then Return 1.0
        If String.IsNullOrEmpty(s1) OrElse String.IsNullOrEmpty(s2) Then Return 0.0
        If String.Equals(s1, s2, StringComparison.OrdinalIgnoreCase) Then Return 1.0

        Dim levScore As Double = ComputeLevenshteinSimilarity(s1, s2)
        Dim jaroScore As Double = ComputeJaroWinkler(s1, s2)
        Return Math.Max(levScore, jaroScore)
    End Function

    Private Shared Function ComputeLevenshteinSimilarity(s1 As String, s2 As String) As Double
        Dim maxLen As Integer = Math.Max(s1.Length, s2.Length)
        Dim dist As Integer = ComputeLevenshteinDistance(s1, s2)
        Return 1.0 - (dist / CDbl(maxLen))
    End Function

    Private Shared Function ComputeLevenshteinDistance(s1 As String, s2 As String) As Integer
        Dim n As Integer = s1.Length
        Dim m As Integer = s2.Length
        Dim d(n, m) As Integer

        For i As Integer = 0 To n
            d(i, 0) = i
        Next
        For j As Integer = 0 To m
            d(0, j) = j
        Next

        For i As Integer = 1 To n
            For j As Integer = 1 To m
                Dim cost As Integer = If(s1(i - 1) = s2(j - 1), 0, 1)
                d(i, j) = Math.Min(
                    Math.Min(d(i - 1, j) + 1, d(i, j - 1) + 1),
                    d(i - 1, j - 1) + cost
                )
            Next
        Next

        Return d(n, m)
    End Function

    ''' <summary>
    ''' Computes Jaro-Winkler similarity, which handles character transpositions well.
    ''' Returns value in [0.0, 1.0]. Prefix scaling constant p = 0.1 (standard).
    ''' </summary>
    Private Shared Function ComputeJaroWinkler(s1 As String, s2 As String) As Double
        If String.IsNullOrEmpty(s1) OrElse String.IsNullOrEmpty(s2) Then Return 0.0

        Dim jaro As Double = ComputeJaro(s1, s2)
        ' Prefix bonus: up to 4 common leading chars (standard Winkler p=0.1)
        Dim prefixLen As Integer = 0
        Dim maxPrefix As Integer = Math.Min(4, Math.Min(s1.Length, s2.Length))
        For i As Integer = 0 To maxPrefix - 1
            If s1(i) = s2(i) Then
                prefixLen += 1
            Else
                Exit For
            End If
        Next
        Return jaro + (prefixLen * 0.1 * (1.0 - jaro))
    End Function

    Private Shared Function ComputeJaro(s1 As String, s2 As String) As Double
        If String.IsNullOrEmpty(s1) OrElse String.IsNullOrEmpty(s2) Then Return 0.0
        If String.Equals(s1, s2, StringComparison.OrdinalIgnoreCase) Then Return 1.0

        Dim matchDist As Integer = Math.Max(0, (Math.Max(s1.Length, s2.Length) \ 2) - 1)
        Dim s1Matches(s1.Length - 1) As Boolean
        Dim s2Matches(s2.Length - 1) As Boolean

        Dim matches As Integer = 0
        Dim transpositions As Integer = 0

        For i As Integer = 0 To s1.Length - 1
            Dim start As Integer = Math.Max(0, i - matchDist)
            Dim finish As Integer = Math.Min(i + matchDist, s2.Length - 1)
            For j As Integer = start To finish
                If s2Matches(j) Then Continue For
                If s1(i) <> s2(j) Then Continue For
                s1Matches(i) = True
                s2Matches(j) = True
                matches += 1
                Exit For
            Next
        Next

        If matches = 0 Then Return 0.0

        Dim k As Integer = 0
        For i As Integer = 0 To s1.Length - 1
            If Not s1Matches(i) Then Continue For
            Do While Not s2Matches(k)
                k += 1
            Loop
            If s1(i) <> s2(k) Then transpositions += 1
            k += 1
        Next

        Return ((matches / CDbl(s1.Length)) +
                (matches / CDbl(s2.Length)) +
                ((matches - transpositions / 2) / CDbl(matches))) / 3.0
    End Function

End Class

