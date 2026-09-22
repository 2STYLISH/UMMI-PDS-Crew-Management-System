Imports System
Imports System.Collections.Generic

''' <summary>
''' PHASE E — PDS Extraction and Field Mapping Models (FR-CM-60, FR-CM-61, FR-CM-62, FR-CM-64, FR-CM-77)
''' Encapsulates strongly-typed in-memory suggestion packages, transparent validation statuses,
''' source attributions, candidate lookup suggestions, and conflict tracking.
''' 
''' ARCHITECTURAL CONSTRAINTS:
''' - Pure in-memory data structures. Zero database dependencies.
''' - Stores raw extracted text verbatim alongside normalized values (no premature HTML-encoding).
''' - Uses deterministic ValidationStatus enums instead of artificial numerical AI confidence ratings.
''' - Explicitly separates Core PDS fields (Step 1 &amp; 2) from Repeating Records (Phase F).
''' </summary>
Namespace PdsMappingModels

    ''' <summary>
    ''' Transparent, deterministic validation status for an extracted field or record.
    ''' Replaces unsupported numerical AI confidence percentages with verifiable states (FR-CM-77).
    ''' </summary>
    Public Enum ValidationStatus
        ''' <summary>Field was not present or returned null in the source document(s).</summary>
        Missing = 0
        ''' <summary>Field was extracted, passes format validation, and is unambiguous.</summary>
        ExtractedValid = 1
        ''' <summary>Field contains an extracted text value, but matching against reference tables requires applicant selection (FR-CM-63).</summary>
        UnresolvedReference = 2
        ''' <summary>Multiple documents provide conflicting values for this field; all options preserved for applicant decision (FR-CM-66).</summary>
        Conflicting = 3
        ''' <summary>Extracted structure cannot be split or parsed without guessing (e.g. compound name); preserved raw for review.</summary>
        Ambiguous = 4
        ''' <summary>Value was extracted but has format irregularities (e.g. non-standard phone digits).</summary>
        FormatWarning = 5
        ''' <summary>Record is a near-duplicate or has conflicting dates; requires applicant review before adding.</summary>
        ReviewRequired = 6
    End Enum

    ''' <summary>
    ''' Tracks the origin document, page, category, and timestamp for an extracted suggestion (FR-CM-76).
    ''' </summary>
    Public Class SourceAttribution
        Public Property StagedFileId As String = String.Empty
        Public Property OriginalFileName As String = String.Empty
        Public Property PageNumber As Integer = 1
        Public Property CategoryKey As String = String.Empty
        Public Property ExtractionTimestamp As DateTime = DateTime.UtcNow

        Public Overrides Function ToString() As String
            Return String.Format("{0} (p.{1})", OriginalFileName, PageNumber)
        End Function
    End Class

    ''' <summary>
    ''' Represents a potential reference database match proposed as a non-binding suggestion.
    ''' </summary>
    Public Class ReferenceMatchCandidate
        Public Property Id As Integer = 0
        Public Property MatchedCodeOrName As String = String.Empty
        Public Property DisplayText As String = String.Empty
        Public Property SimilarityScore As Double = 0.0 ' Provisional similarity metric
        Public Property MatchType As String = "Fuzzy"   ' "Exact", "Alias", "Fuzzy"
    End Class

    ''' <summary>
    ''' Stores a conflicting alternative value extracted from a different document source (FR-CM-66).
    ''' </summary>
    Public Class ConflictingAlternative(Of T)
        Public Property Value As T
        Public Property RawText As String = String.Empty
        Public Property Source As SourceAttribution

        Public Sub New()
        End Sub

        Public Sub New(val As T, raw As String, src As SourceAttribution)
            Me.Value = val
            Me.RawText = raw
            Me.Source = src
        End Sub
    End Class

    ''' <summary>
    ''' Generic wrapper for a PDS field suggestion.
    ''' Maintains pristine raw text, normalized typed value, validation status, reference resolution,
    ''' conflicting alternatives, and complete source citations.
    ''' </summary>
    Public Class PdsFieldSuggestion(Of T)
        Public Property FieldName As String = String.Empty
        Public Property DisplayLabel As String = String.Empty
        Public Property ExtractedRawValue As String = String.Empty
        Public Property NormalizedValue As T = Nothing
        Public Property Status As ValidationStatus = ValidationStatus.Missing
        Public Property StatusMessage As String = String.Empty

        ''' <summary>
        ''' The resolved foreign key ID if an exact or approved unambiguous alias match succeeded.
        ''' Must NEVER be automatically assigned for fuzzy or ambiguous lookups (Safeguard #3).
        ''' </summary>
        Public Property ResolvedForeignKeyId As Nullable(Of Integer) = Nothing

        Public Property CandidateSuggestions As New List(Of ReferenceMatchCandidate)()
        Public Property ConflictingAlternatives As New List(Of ConflictingAlternative(Of T))()
        Public Property Sources As New List(Of SourceAttribution)()

        Public ReadOnly Property HasValue As Boolean
            Get
                If GetType(T) Is GetType(String) Then
                    Return Not String.IsNullOrWhiteSpace(TryCast(CObj(NormalizedValue), String))
                End If
                Return NormalizedValue IsNot Nothing
            End Get
        End Property

        Public ReadOnly Property HasConflict As Boolean
            Get
                Return Status = ValidationStatus.Conflicting OrElse ConflictingAlternatives.Count > 0
            End Get
        End Property
    End Class

    ''' <summary>
    ''' Group 1: Core PDS Applicant Fields supported in the current SelfEncode.aspx form (Step 1 &amp; Step 2).
    ''' </summary>
    Public Class PdsPersonalDetailsSuggestions
        ' Step 1: Personal Information
        Public Property LastName As New PdsFieldSuggestion(Of String) With {.FieldName = "lastname", .DisplayLabel = "Last Name"}
        Public Property FirstName As New PdsFieldSuggestion(Of String) With {.FieldName = "firstname", .DisplayLabel = "First Name"}
        Public Property MiddleName As New PdsFieldSuggestion(Of String) With {.FieldName = "middlename", .DisplayLabel = "Middle Name"}
        Public Property Suffix As New PdsFieldSuggestion(Of String) With {.FieldName = "suffix", .DisplayLabel = "Suffix"}
        Public Property DateOfBirth As New PdsFieldSuggestion(Of Nullable(Of DateTime)) With {.FieldName = "date_of_birth", .DisplayLabel = "Date of Birth"}
        Public Property PlaceOfBirth As New PdsFieldSuggestion(Of String) With {.FieldName = "place_of_birth", .DisplayLabel = "Place of Birth"}
        Public Property Gender As New PdsFieldSuggestion(Of String) With {.FieldName = "gender", .DisplayLabel = "Gender"}
        Public Property CivilStatus As New PdsFieldSuggestion(Of String) With {.FieldName = "civil_status", .DisplayLabel = "Civil Status"}
        Public Property Religion As New PdsFieldSuggestion(Of String) With {.FieldName = "religion", .DisplayLabel = "Religion"}
        Public Property Nationality As New PdsFieldSuggestion(Of String) With {.FieldName = "nationality", .DisplayLabel = "Nationality"}
        Public Property Height As New PdsFieldSuggestion(Of Nullable(Of Decimal)) With {.FieldName = "height", .DisplayLabel = "Height (cm)"}
        Public Property Weight As New PdsFieldSuggestion(Of Nullable(Of Decimal)) With {.FieldName = "weight", .DisplayLabel = "Weight (kg)"}
        Public Property AppliedRank As New PdsFieldSuggestion(Of String) With {.FieldName = "position", .DisplayLabel = "Applied Rank"}

        ' Step 2: Contact & Educational Background
        Public Property ContactNumber As New PdsFieldSuggestion(Of String) With {.FieldName = "applicant_contact_num", .DisplayLabel = "Contact Number"}
        Public Property EmailAddress As New PdsFieldSuggestion(Of String) With {.FieldName = "email_address", .DisplayLabel = "Email Address"}
        Public Property Address As New PdsFieldSuggestion(Of String) With {.FieldName = "address", .DisplayLabel = "Address"}
        Public Property Province As New PdsFieldSuggestion(Of String) With {.FieldName = "province", .DisplayLabel = "Province"}
        Public Property City As New PdsFieldSuggestion(Of String) With {.FieldName = "city", .DisplayLabel = "City / Municipality"}
        Public Property SchoolName As New PdsFieldSuggestion(Of String) With {.FieldName = "school_name", .DisplayLabel = "School / University"}
        Public Property Course As New PdsFieldSuggestion(Of String) With {.FieldName = "course", .DisplayLabel = "Course"}
    End Class

    ''' <summary>
    ''' Group 2: Repeating Personal Document, Certificate, or License suggestion (tbl_personnel_documents).
    ''' Requires dedicated review controls in Phase F.
    ''' </summary>
    Public Class PdsDocumentSuggestion
        Public Property DocumentTypeId As Nullable(Of Integer) = Nothing
        Public Property DocumentTypeName As String = String.Empty
        Public Property DocumentNumber As String = String.Empty
        Public Property DateIssued As Nullable(Of DateTime) = Nothing
        Public Property DateExpiry As Nullable(Of DateTime) = Nothing
        Public Property Grade As String = String.Empty
        Public Property HolderName As String = String.Empty

        Public Property Status As ValidationStatus = ValidationStatus.ExtractedValid
        Public Property StatusMessage As String = String.Empty
        Public Property IsNearDuplicate As Boolean = False
        Public Property ConflictingDates As Boolean = False

        Public Property CandidateSuggestions As New List(Of ReferenceMatchCandidate)()
        Public Property Sources As New List(Of SourceAttribution)()
        Public Property ExtractedRawValues As New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase)
        Public Property UnsupportedAttributes As New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase)
    End Class

    ''' <summary>
    ''' Group 2: Repeating Sea Service record suggestion (tbl_personnel_sea_service).
    ''' Requires dedicated review controls in Phase F.
    ''' </summary>
    Public Class PdsSeaServiceSuggestion
        Public Property VesselId As Nullable(Of Integer) = Nothing
        Public Property VesselName As String = String.Empty
        Public Property RankId As Nullable(Of Integer) = Nothing
        Public Property RankName As String = String.Empty
        Public Property Port As String = String.Empty
        Public Property DateFrom As Nullable(Of DateTime) = Nothing
        Public Property DateTo As Nullable(Of DateTime) = Nothing
        Public Property Remarks As String = String.Empty
        Public Property EmployerAgency As String = String.Empty

        Public Property Status As ValidationStatus = ValidationStatus.ExtractedValid
        Public Property StatusMessage As String = String.Empty
        Public Property IsNearDuplicate As Boolean = False
        Public Property NearDuplicateNote As String = String.Empty

        Public Property CandidateVessels As New List(Of ReferenceMatchCandidate)()
        Public Property CandidateRanks As New List(Of ReferenceMatchCandidate)()
        Public Property Sources As New List(Of SourceAttribution)()
        Public Property ExtractedRawValues As New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase)
        Public Property UnsupportedAttributes As New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase)
    End Class

    ''' <summary>
    ''' Privacy-safe diagnostic metrics for audit logging (FR-CM-71).
    ''' Captures job counts, conflict rates, and performance without storing PII or document text.
    ''' </summary>
    Public Class ExtractionAuditSummary
        Public Property SessionId As String = String.Empty
        Public Property TotalDocumentsProcessed As Integer = 0
        Public Property TotalPagesProcessed As Integer = 0
        Public Property TotalFieldsExtracted As Integer = 0
        Public Property TotalUnresolvedReferences As Integer = 0
        Public Property TotalConflictsDetected As Integer = 0
        Public Property TotalDuplicatesDeduplicated As Integer = 0
        Public Property TotalNearDuplicatesFlagged As Integer = 0
        Public Property ExecutionTimeMs As Long = 0
        Public Property Timestamp As DateTime = DateTime.UtcNow
    End Class

    ''' <summary>
    ''' Complete in-memory transfer package delivered to Phase F applicant review.
    ''' </summary>
    Public Class PdsExtractionSuggestionPackage
        Public Property SessionId As String = String.Empty
        Public Property IsSuccess As Boolean = True
        Public Property ErrorMessage As String = String.Empty

        Public Property PersonalDetails As New PdsPersonalDetailsSuggestions()
        Public Property Documents As New List(Of PdsDocumentSuggestion)()
        Public Property SeaServiceRecords As New List(Of PdsSeaServiceSuggestion)()
        Public Property AuditSummary As New ExtractionAuditSummary()
    End Class

End Namespace
