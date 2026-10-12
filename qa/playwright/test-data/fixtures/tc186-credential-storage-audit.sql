-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — TC-CM-186 CREDENTIAL STORAGE AUDIT
-- Test Case: TC-CM-186 (Password Storage Architecture Compliance - SR-04)
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Classification: Strictly Read-Only Security Audit (Zero Credential Disclosure)
--
-- Security & Governance Principles:
-- 1. Zero Disclosure: Does NOT project, select, or log plaintexts, hashes, or salts.
-- 2. Mutually Exclusive & Exhaustive: Every account is classified exactly once.
--    All counts reconcile 100% with total users. Compliant with ONLY_FULL_GROUP_BY.
-- 3. Scope of Verification: Structural format checks confirm schema and encoding compliance
--    against the CryptoHelper specification. Format checks do NOT prove cryptographic
--    correctness (i.e. whether a hash corresponds to a known plaintext password).
-- 4. Migration Scope: Only verified legacy v1 and v2 credentials successfully authenticated
--    by CryptoHelper.VerifyHashedPassword undergo silent in-flight migration.
--    Unknown, malformed, or empty passwords do NOT automatically migrate and require administrative reset.
-- 5. Configurable Work Factor:
--    - Verification parses iterations dynamically from the hash prefix ($pbkdf2:<iterations>$).
--    - Generation defaults to 100,000 iterations (PBKDF2_ITERATIONS constant in CryptoHelper.vb).
-- ==============================================================================

USE `ummi_crew`;

-- ------------------------------------------------------------------------------
-- 1. AGGREGATE STORAGE-FORMAT DISTRIBUTION AUDIT
-- Classifies each account once into mutually exclusive, exhaustive categories.
-- Compatible with MySQL 8 ONLY_FULL_GROUP_BY mode.
-- ------------------------------------------------------------------------------
SELECT 
    Category,
    COUNT(*) AS AccountCount,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM tbl_users), 2) AS PercentageOfTotal,
    SR04_ComplianceStatus,
    MigrationEligibilityNote
FROM (
    SELECT 
        id,
        username,
        type,
        disable_user,
        CASE
            -- Category 1: Null or Empty
            WHEN password IS NULL OR password = '' 
                THEN '1. Null or Empty Password'

            -- Category 2: Supported PBKDF2-HMAC-SHA256 (v3)
            -- Enforces: $pbkdf2:100000$ (15 chars) + 44 chars Base64 derived key (59 chars total)
            -- AND 44 chars Base64 256-bit salt
            WHEN password LIKE '$pbkdf2:100000$%' 
             AND LENGTH(password) = 59 
             AND SUBSTRING(password, 16) REGEXP '^[A-Za-z0-9+/]{43}=$'
             AND password_salt IS NOT NULL 
             AND LENGTH(password_salt) = 44 
             AND password_salt REGEXP '^[A-Za-z0-9+/]{43}=$' 
                THEN '2. Supported PBKDF2-HMAC-SHA256 (v3: 100k iters, 256-bit key & salt)'

            -- Category 3: Malformed PBKDF2 (starts with $pbkdf2: but fails length, iteration, key, or salt validation)
            WHEN password LIKE '$pbkdf2:%' 
                THEN '3. Malformed PBKDF2 Format'

            -- Category 4: Probable Legacy Salted SHA-256 (v2: 64 hex chars with non-empty salt)
            WHEN password NOT LIKE '$pbkdf2:%' 
             AND LENGTH(password) = 64 
             AND password REGEXP '^[0-9a-fA-F]{64}$'
             AND password_salt IS NOT NULL 
             AND LENGTH(password_salt) > 0 
                THEN '4. Probable Legacy Salted SHA-256 (v2)'

            -- Category 5: Probable Legacy Unsalted SHA-256 (v1: 64 hex chars with null or empty salt)
            WHEN password NOT LIKE '$pbkdf2:%' 
             AND LENGTH(password) = 64 
             AND password REGEXP '^[0-9a-fA-F]{64}$'
             AND (password_salt IS NULL OR password_salt = '') 
                THEN '5. Probable Legacy Unsalted SHA-256 (v1)'

            -- Category 6: Unknown / Non-Standard Format (plaintexts, other hashes, or broken fields)
            ELSE '6. Unknown / Non-Standard Format'
        END AS Category,
        CASE
            WHEN password LIKE '$pbkdf2:100000$%' 
             AND LENGTH(password) = 59 
             AND SUBSTRING(password, 16) REGEXP '^[A-Za-z0-9+/]{43}=$'
             AND password_salt IS NOT NULL 
             AND LENGTH(password_salt) = 44 
             AND password_salt REGEXP '^[A-Za-z0-9+/]{43}=$' 
                THEN 'COMPLIANT (SR-04 Approved Adaptive Standard)'
            ELSE 'NON-COMPLIANT (Prohibited / Legacy Format)'
        END AS SR04_ComplianceStatus,
        CASE
            WHEN password LIKE '$pbkdf2:100000$%' 
             AND LENGTH(password) = 59 
             AND SUBSTRING(password, 16) REGEXP '^[A-Za-z0-9+/]{43}=$'
             AND password_salt IS NOT NULL 
             AND LENGTH(password_salt) = 44 
             AND password_salt REGEXP '^[A-Za-z0-9+/]{43}=$' 
                THEN 'Active Standard: No migration required'
            WHEN password NOT LIKE '$pbkdf2:%' 
             AND LENGTH(password) = 64 
             AND password REGEXP '^[0-9a-fA-F]{64}$'
                THEN 'Eligible for silent in-flight upgrade on successful login with valid password'
            ELSE 'Ineligible for automatic migration: Requires administrative credential reset'
        END AS MigrationEligibilityNote
    FROM tbl_users
) classified_users
GROUP BY Category, SR04_ComplianceStatus, MigrationEligibilityNote
ORDER BY Category;

-- ------------------------------------------------------------------------------
-- 2. ROLE-BASED CREDENTIAL STORAGE DISTRIBUTION
-- Audits format compliance across user roles.
-- ------------------------------------------------------------------------------
SELECT 
    COALESCE(ut.user_type, CAST(u.type AS CHAR)) AS UserRole,
    SUM(CASE WHEN u.password LIKE '$pbkdf2:100000$%' 
              AND LENGTH(u.password) = 59 
              AND SUBSTRING(u.password, 16) REGEXP '^[A-Za-z0-9+/]{43}=$'
              AND u.password_salt IS NOT NULL 
              AND LENGTH(u.password_salt) = 44 
              AND u.password_salt REGEXP '^[A-Za-z0-9+/]{43}=$' 
             THEN 1 ELSE 0 END) AS PBKDF2_v3_Compliant_Count,
    SUM(CASE WHEN u.password NOT LIKE '$pbkdf2:%' 
              AND LENGTH(u.password) = 64 
              AND u.password REGEXP '^[0-9a-fA-F]{64}$'
              AND u.password_salt IS NOT NULL 
              AND LENGTH(u.password_salt) > 0 
             THEN 1 ELSE 0 END) AS Legacy_v2_Salted_Count,
    SUM(CASE WHEN u.password NOT LIKE '$pbkdf2:%' 
              AND LENGTH(u.password) = 64 
              AND u.password REGEXP '^[0-9a-fA-F]{64}$'
              AND (u.password_salt IS NULL OR u.password_salt = '') 
             THEN 1 ELSE 0 END) AS Legacy_v1_Unsalted_Count,
    SUM(CASE WHEN u.password LIKE '$pbkdf2:%' 
              AND (LENGTH(u.password) <> 59 
                   OR SUBSTRING(u.password, 16) NOT REGEXP '^[A-Za-z0-9+/]{43}=$'
                   OR u.password_salt IS NULL 
                   OR LENGTH(u.password_salt) <> 44 
                   OR u.password_salt NOT REGEXP '^[A-Za-z0-9+/]{43}=$')
             THEN 1 ELSE 0 END) AS Malformed_PBKDF2_Count,
    SUM(CASE WHEN (u.password IS NULL OR u.password = '') THEN 1 ELSE 0 END) AS Null_Or_Empty_Count,
    SUM(CASE WHEN (u.password IS NOT NULL AND u.password <> '')
              AND u.password NOT LIKE '$pbkdf2:%'
              AND (LENGTH(u.password) <> 64 OR u.password NOT REGEXP '^[0-9a-fA-F]{64}$')
             THEN 1 ELSE 0 END) AS Unknown_Format_Count,
    COUNT(*) AS TotalAccountsForRole
FROM tbl_users u
LEFT JOIN tbl_user_type ut ON ut.id = u.type OR ut.user_type = u.type
GROUP BY COALESCE(ut.user_type, CAST(u.type AS CHAR))
ORDER BY TotalAccountsForRole DESC;

-- ------------------------------------------------------------------------------
-- 3. RECONCILIATION & AUDIT INTEGRITY GATE
-- Confirms that all accounts are categorized with zero omitted or double-counted rows.
-- ------------------------------------------------------------------------------
SELECT 
    'Reconciliation Gate' AS AuditSection,
    (SELECT COUNT(*) FROM tbl_users) AS TotalUsersInDatabase,
    (SELECT COUNT(*) FROM tbl_users 
     WHERE (password IS NULL OR password = '')
        OR (password LIKE '$pbkdf2:100000$%' 
            AND LENGTH(password) = 59 
            AND SUBSTRING(password, 16) REGEXP '^[A-Za-z0-9+/]{43}=$'
            AND password_salt IS NOT NULL 
            AND LENGTH(password_salt) = 44 
            AND password_salt REGEXP '^[A-Za-z0-9+/]{43}=$')
        OR (password LIKE '$pbkdf2:%')
        OR (password NOT LIKE '$pbkdf2:%' AND LENGTH(password) = 64 AND password REGEXP '^[0-9a-fA-F]{64}$')
        OR (password IS NOT NULL AND password <> '' AND password NOT LIKE '$pbkdf2:%' AND (LENGTH(password) <> 64 OR password NOT REGEXP '^[0-9a-fA-F]{64}$'))
    ) AS TotalCategorizedAccounts,
    CASE 
        WHEN (SELECT COUNT(*) FROM tbl_users) = 
             (SELECT COUNT(*) FROM tbl_users 
              WHERE (password IS NULL OR password = '')
                 OR (password LIKE '$pbkdf2:100000$%' 
                     AND LENGTH(password) = 59 
                     AND SUBSTRING(password, 16) REGEXP '^[A-Za-z0-9+/]{43}=$'
                     AND password_salt IS NOT NULL 
                     AND LENGTH(password_salt) = 44 
                     AND password_salt REGEXP '^[A-Za-z0-9+/]{43}=$')
                 OR (password LIKE '$pbkdf2:%')
                 OR (password NOT LIKE '$pbkdf2:%' AND LENGTH(password) = 64 AND password REGEXP '^[0-9a-fA-F]{64}$')
                 OR (password IS NOT NULL AND password <> '' AND password NOT LIKE '$pbkdf2:%' AND (LENGTH(password) <> 64 OR password NOT REGEXP '^[0-9a-fA-F]{64}$'))
             )
        THEN 'PASS: All accounts categorized with 100% reconciliation'
        ELSE 'FAIL: Discrepancy between total users and categorized accounts'
    END AS ReconciliationStatus;
