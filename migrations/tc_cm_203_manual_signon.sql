-- ============================================================
-- TC-CM-203 Migration: Manual Sign-On columns for tbl_ccl_schedules
-- Run once against ummi_crew before deploying branch 10-4_Pablo_BugFixes.
-- Safe to run repeatedly (checks column existence before adding).
-- ============================================================

-- Add signed_on_at (timestamp when the manual sign-on was recorded)
SET @col_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'tbl_ccl_schedules'
      AND COLUMN_NAME  = 'signed_on_at'
);
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE tbl_ccl_schedules ADD COLUMN signed_on_at DATETIME DEFAULT NULL COMMENT ''TC-CM-203: Manual sign-on timestamp'' AFTER finalized_at',
    'SELECT ''signed_on_at already exists, skipped'' AS msg'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Add signed_on_by (FK to tbl_users.id — the staff member who performed the sign-on)
SET @col_exists2 = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'tbl_ccl_schedules'
      AND COLUMN_NAME  = 'signed_on_by'
);
SET @sql2 = IF(@col_exists2 = 0,
    'ALTER TABLE tbl_ccl_schedules ADD COLUMN signed_on_by INT(11) DEFAULT NULL COMMENT ''TC-CM-203: User who performed the manual sign-on'' AFTER signed_on_at',
    'SELECT ''signed_on_by already exists, skipped'' AS msg'
);
PREPARE stmt2 FROM @sql2; EXECUTE stmt2; DEALLOCATE PREPARE stmt2;

-- Optional index for audit queries
SET @idx_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'tbl_ccl_schedules'
      AND INDEX_NAME   = 'idx_ccls_signed_on'
);
SET @sql3 = IF(@idx_exists = 0,
    'ALTER TABLE tbl_ccl_schedules ADD INDEX idx_ccls_signed_on (signed_on_at)',
    'SELECT ''index already exists, skipped'' AS msg'
);
PREPARE stmt3 FROM @sql3; EXECUTE stmt3; DEALLOCATE PREPARE stmt3;
