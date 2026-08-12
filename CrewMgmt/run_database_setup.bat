@echo off
REM ============================================================
REM UMMI Crew Management Module ? Database Setup
REM Runs all three SQL scripts in order against MySQL 8.4 local
REM Usage: run_database_setup.bat [mysql_path]
REM Default path: C:\mysql-8.4.9\bin\mysql.exe
REM ============================================================

SET MYSQL=mysql.exe
IF NOT "%1"=="" SET MYSQL=%1

SET DB_HOST=127.0.0.1
SET DB_PORT=3306
SET DB_USER=root
SET DB_PASS=

ECHO.
ECHO ============================================================
ECHO  UMMI Crew Management Module - Database Setup
ECHO ============================================================
ECHO.
ECHO [1/3] Creating schema (29 tables)...
"%MYSQL%" -h%DB_HOST% -P%DB_PORT% -u%DB_USER% -p%DB_PASS% < "%~dp0Database\01_schema.sql"
IF %ERRORLEVEL% NEQ 0 (
    ECHO ERROR: Schema creation failed. Check MySQL credentials and try again.
    PAUSE
    EXIT /B 1
)
ECHO       Schema created successfully.

ECHO.
ECHO [2/3] Creating stored procedures...
"%MYSQL%" -h%DB_HOST% -P%DB_PORT% -u%DB_USER% -p%DB_PASS% ummi_crew < "%~dp0Database\02_stored_procedures.sql"
IF %ERRORLEVEL% NEQ 0 (
    ECHO ERROR: Stored procedure creation failed.
    PAUSE
    EXIT /B 1
)
ECHO       Stored procedures created successfully.

ECHO.
ECHO [3/3] Inserting seed data (15 demo crew, 4 demo accounts)...
"%MYSQL%" -h%DB_HOST% -P%DB_PORT% -u%DB_USER% -p%DB_PASS% ummi_crew < "%~dp0Database\03_seed_data.sql"
IF %ERRORLEVEL% NEQ 0 (
    ECHO ERROR: Seed data insertion failed.
    PAUSE
    EXIT /B 1
)
ECHO       Seed data inserted successfully.

ECHO.
ECHO ============================================================
ECHO  Setup Complete!
ECHO  Database: ummi_crew
ECHO  Open CrewMgmt.sln in Visual Studio and press F5 to run.
ECHO ============================================================
ECHO.
PAUSE
