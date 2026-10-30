@echo off
rem Compiles all sources into .\out
cd /d "%~dp0"
if not exist out mkdir out
javac -Xlint:all -d out src\com\fintech\ledger\*.java
if errorlevel 1 (
  echo Build failed.
  exit /b 1
)
echo Build successful: classes are in .\out
