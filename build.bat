@echo off
SETLOCAL

:: Backup if selene is not globally installed
where selene >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
	SET SELENE_COMMAND=.\selene.exe
) ELSE (
	SET SELENE_COMMAND=selene
)

:: Backup if rojo is not globally installed
where rojo >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
	SET ROJO_COMMAND=.\rojo.exe
) ELSE (
	SET ROJO_COMMAND=rojo
)

:: Run selene linter for loader and mainmodule
echo Running %SELENE_COMMAND% ./MainModule ./Loader
%SELENE_COMMAND% ./MainModule ./Loader

:: Run rojo build
echo Running %ROJO_COMMAND% build -o Adonis.rbxm
%ROJO_COMMAND% build -o Adonis.rbxm

ENDLOCAL
