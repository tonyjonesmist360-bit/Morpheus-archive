@echo off
REM Restore a database dump: restore.bat C:\FXServer\backups\db_20260914_0400.sql
set DB=outbreak
set DBPASS=outbreak123
"C:\Program Files\MariaDB 11.4\bin\mariadb.exe" -u root -p%DBPASS% %DB% < %1
echo Restored %1 into %DB%
