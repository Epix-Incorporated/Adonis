@echo off
SETLOCAL

where bash >nul 2>nul
IF %errorlevel% == 0 (
    SET SHELL_COMMAND=bash
) else (
	IF exist ".\bash.exe" (
		SET SHELL_COMMAND=.\bash.exe
	) else (
		where sh >nul 2>nul
		IF %errorlevel%==0 (
			SET SHELL_COMMAND=sh
		) else (
			IF exist ".\sh.exe" (
				SET SHELL_COMMAND=.\sh.exe
			) else (
				IF not exist ".\PortableGit" (
					echo You don't have portable git installed. Please install it from the following website inside the Adonis folder "https://git-scm.com/downloads/win"
					start "" "https://git-scm.com/downloads/win"
					exit /b 1
				) else (
					IF exist ".\PortableGit\bin\bash.exe" (
						SET SHELL_COMMAND=.\PortableGit\bin\bash.exe
					) else (
						IF exist ".\PortableGit\bin\sh.exe" (
							SET SHELL_COMMAND=.\PortableGit\bin\sh.exe
						) else (
							echo FATAL ERROR! NO COMPATIBLE BOURNE SHELL FOUND TO EXECUTE CHANGELOG SCRIPT!!!!
							exit /b 1
						)
					)
				)
			)
		)
	)
)

%SHELL_COMMAND% genchangelog.sh %*
pause
ENDLOCAL
