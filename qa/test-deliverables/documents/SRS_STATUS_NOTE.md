# Item 1: Software Requirements Specification (SRS) Status Note

- **Submission Item:** Item 1 (Software Requirements Specification)
- **Authoritative Baseline Document:** [`documents/ByteMe SRS - UMMI.docx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/ByteMe%20SRS%20-%20UMMI.docx)
- **Document Verified Size & Hash:** 1,422,993 bytes | SHA-256: `96b220779905dd31f49083ad6606398812269825d4d0200a2657a0bca950ed45`
- **Repository Location:** Packaged directly within QA deliverables under `qa/test-deliverables/documents/`
- **Functional Requirements Baseline:** `FR-CM-01` through `FR-CM-79` (79 total; 78 active, `FR-CM-20` retired via `REQ-CM-006`)
- **Security & Performance Requirements Baseline:** `SR-01` through `SR-18` (17 active, `SR-03` retired via `REQ-CM-005`), `PR-01` through `PR-08` (8 Performance Requirements)
- **Use Cases Baseline:** `UC-CM-01` through `UC-CM-28` (28 Use Cases)
- **Authoritative Workbooks:**
  - [`documents/QA TEST PLAN UMMI.xlsx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/QA%20TEST%20PLAN%20UMMI.xlsx) (Contains dedicated authoritative `RTM` worksheet reconciling all requirements against all 229 test cases)
  - [`documents/QA TEST PLAN UMMI.xlsx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/QA%20TEST%20PLAN%20UMMI.xlsx) (Authoritative execution workbook with 250 embedded screenshots in `Evidence` tab)
- **Authoritative Traceability Matrix:** Codified in [`documents/cycle2-traceability-reviewed.md`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/cycle2-traceability-reviewed.md) and the `RTM` worksheet of [`documents/QA TEST PLAN UMMI.xlsx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/QA%20TEST%20PLAN%20UMMI.xlsx).

---

### Verification & Reconciliation Notice

The authoritative Software Requirements Specification for the UMMI Crew Management System is **packaged locally** in this deliverables repository at `documents/ByteMe SRS - UMMI.docx`. Previous working claims that the SRS was unavailable or maintained only externally are superseded by this packaged baseline.

All QA deliverables, test cases, and matrices have been reconciled directly against this uploaded SRS:
1. **Scope Alignment:** Incorporates all features including AI-assisted applicant self-encoding (`FR-CM-54` through `FR-CM-78`, `UC-CM-28`, `SR-11..18`, `PR-07..08`) and Crew Change List management (`FR-CM-79`, `UC-CM-07`).
2. **Retired Scope:** Reconciles retired requirements including `FR-CM-20` (extra PDS columns display, retired via `REQ-CM-006`; `TC-CM-099` classified as Out of Scope) and `SR-03` (supplier account approval workflow, retired via `REQ-CM-005`; `TC-CM-185` classified as Out of Scope).
3. **Unmapped Requirements:** Confirms that `SR-07` (Audit Logging of Critical User Activities) has no mapped test case in the workbook repository and is explicitly labeled "No mapped test". Password complexity enforcement cannot be declared verified merely because strong passwords were used during administrative provisioning (`FIX-CM-001`).
4. **Excel RTM Worksheet:** The workbook `QA TEST PLAN UMMI.xlsx` provides a dedicated `RTM` tab with 11 standardized columns, active internal hyperlinks to test rows and evidence entries, auto-filters, wrapped text, and frozen headers.
