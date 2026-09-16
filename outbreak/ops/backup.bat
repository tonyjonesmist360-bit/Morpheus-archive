@echo off
REM Nightly backup: database dump + resources zip. Schedule with Task Scheduler (daily 04:00).
REM Edit these four lines:
set DB=QboxProject_A70B55
set DBPASS=CHANGE_ME
set SERVER=C:\Outbreak\txData
set OUT=C:\Outbreak\backups

REM Locate mariadb-dump.exe whatever the installed major version is.
set DUMP=
for /d %%D in ("C:\Program Files\MariaDB *") do if exist "%%D\bin\mariadb-dump.exe" set DUMP=%%D\bin\mariadb-dump.exe
if not defined DUMP (
  echo ERROR: mariadb-dump.exe not found under "C:\Program Files\MariaDB *".
  exit /b 1
)

set STAMP=%date:~-4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%
set STAMP=%STAMP: =0%
if not exist "%OUT%" mkdir "%OUT%"

"%DUMP%" -u root -p%DBPASS% %DB% > "%OUT%\db_%STAMP%.sql"
if errorlevel 1 echo WARNING: database dump reported an error.

REM -LiteralPath, not -Path: [outbreak] is a wildcard character class to PowerShell,
REM so -Path silently matches nothing and the zip comes out missing the resources.
powershell -NoProfile -command "Compress-Archive -LiteralPath '%SERVER%\resources\[outbreak]','%SERVER%\resources\[outbreak_extended]','%SERVER%\resources\[outbreak_progression]','%SERVER%\server.cfg' -DestinationPath '%OUT%\resources_%STAMP%.zip' -Force"
if errorlevel 1 echo WARNING: resource archive reported an error.

REM Retention: KEEP_DAYS of backups (7 per the ops sheet). Older dumps/zips are deleted by this line only.
set KEEP_DAYS=7
forfiles /p "%OUT%" /m db_*.sql /d -%KEEP_DAYS% /c "cmd /c del @path" 2>nul
forfiles /p "%OUT%" /m resources_*.zip /d -%KEEP_DAYS% /c "cmd /c del @path" 2>nul
echo Backup done: %STAMP%
