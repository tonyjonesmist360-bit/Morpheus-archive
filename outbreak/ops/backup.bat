@echo off
REM Nightly backup: database dump + resources zip. Schedule with Task Scheduler (daily 04:00).
REM Edit these three lines:
set DB=outbreak
set DBPASS=outbreak123
set SERVER=C:\FXServer\txData\QBoxProject_XXXX.base
set OUT=C:\FXServer\backups
set STAMP=%date:~-4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%
set STAMP=%STAMP: =0%
if not exist "%OUT%" mkdir "%OUT%"
"C:\Program Files\MariaDB 11.4\bin\mariadb-dump.exe" -u root -p%DBPASS% %DB% > "%OUT%\db_%STAMP%.sql"
powershell -command "Compress-Archive -Path '%SERVER%\resources\[outbreak]','%SERVER%\resources\[outbreak_extended]','%SERVER%\resources\[outbreak_progression]','%SERVER%\server.cfg' -DestinationPath '%OUT%\resources_%STAMP%.zip' -Force"
forfiles /p "%OUT%" /m *.* /d -14 /c "cmd /c del @path" 2>nul
echo Backup done: %STAMP%
