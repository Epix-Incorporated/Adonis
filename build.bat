@echo off
SETLOCAL

where selene >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
	SET SELENE_COMMAND=.\selene.exe
) ELSE (
	SET SELENE_COMMAND=selene
)

where rojo >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
	SET ROJO_COMMAND=.\rojo.exe
) ELSE (
	SET ROJO_COMMAND=rojo
)

echo Updating Roblox standard library with %SELENE_COMMAND%
%SELENE_COMMAND% generate-roblox-std

echo Checking for lint errors with %SELENE_COMMAND% from ./Loader and ./MainModule 
%SELENE_COMMAND% ./MainModule ./Loader

echo Running %ROJO_COMMAND% build -o Adonis.rbxl
%ROJO_COMMAND% build -o Adonis.rbxl

ENDLOCAL
