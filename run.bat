@echo off
rem Builds and runs the simulation
cd /d "%~dp0"
call build.bat
if errorlevel 1 exit /b 1
java -cp out com.fintech.ledger.FintechLedgerApp
