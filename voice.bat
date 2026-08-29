@echo off
REM uses the embeddable Python (Store Python crashes ctranslate2)
"%~dp0pyembed\python.exe" "%~dp0voice.py" %*
