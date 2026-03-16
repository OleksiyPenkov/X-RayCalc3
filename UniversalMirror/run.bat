@echo off
cd /d "%~dp0.."
XRC_CMD\Out\CMDBin\xrccmd.exe -u UniversalMirror\universal_mirror.json -v
pause
