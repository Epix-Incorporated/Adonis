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

echo Checking for lint errors with %SELENE_COMMAND% from ./Loader and ./MainModule 
%SELENE_COMMAND% ./MainModule ./Loader

echo Running %ROJO_COMMAND% build -o Adonis.rbxm
%ROJO_COMMAND% build -o Adonis.rbxm

ENDLOCAL
