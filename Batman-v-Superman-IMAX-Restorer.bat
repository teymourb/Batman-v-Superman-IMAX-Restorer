@ECHO OFF
setlocal DisableDelayedExpansion
if "%~1"=="--selected" goto selected_entry
if not exist "%~dp0docs\scripts\Select-Restoration.ps1" (
    echo.
    echo ================================================================
    echo [STOP] Setup helper is missing. Extract the complete updated program folder.
    echo ================================================================
    pause
    exit /b 2
)
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0docs\scripts\Select-Restoration.ps1" -Film BvS -Launcher "%~f0"
set "selection_result=%errorlevel%"
if "%selection_result%"=="2" pause
if "%selection_result%"=="0" pause
exit /b %selection_result%

:selected_entry
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0docs\scripts\Select-Restoration.ps1" -Film BvS -ValidateEnvironment
if errorlevel 1 exit /b 2
call :prepare_workspace
if errorlevel 1 exit /b 2
if not exist "docs\scripts\Test-SourceFingerprint.ps1" (
    echo.
    echo ================================================================
    echo [STOP] Source-check helper is missing. Extract the complete updated program folder.
    echo ================================================================
    pause
    exit /b 2
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "docs\scripts\Test-SourceFingerprint.ps1" -Film BvS -Source "%file%" -WorkDirectory "%RESTORER_LOG_DIRECTORY%" -ScratchDirectory "docs\temp"
set "fingerprint_result=%errorlevel%"
if not "%fingerprint_result%"=="0" (
    echo.
    echo ================================================================
    echo [STOP] Source verification did not complete successfully. Processing has stopped.
    echo ================================================================
    pause
    exit /b 2
)
setlocal EnableDelayedExpansion

::Making sure setup is confirmed before any processing starts.
echo.
echo ----------------------------------------------------------------
echo Processing started. Keep this window open and the PC awake.
echo Detailed tool progress: %RESTORER_LOG_DIRECTORY%\processing.log
echo Copying and encoding can take a long time. Detailed progress is saved in the log.


::Check what version to use and make sure the user selected the right one
if %version%==1 (
	

	if %dialog%==y (
		set "stage_name=mkvmerge: BvS.mkv"
		echo.
		echo ----------------------------------------------------------------
		echo [%TIME%] Preparing the video-only working copy...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
		docs\programs\mkvtoolnix\mkvmerge -o "docs\temp\BvS.mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "%file%" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
		if errorlevel 2 goto stage_failed
		if errorlevel 1 goto stage_warning
		if not errorlevel 0 goto stage_failed
		call :require_stage_output "docs\temp\BvS.mkv"
		if errorlevel 1 goto stage_failed
	) else if %dialog%==n (
		set "stage_name=mkvmerge: BvS.mkv"
		echo.
		echo ----------------------------------------------------------------
		echo [%TIME%] Preparing the video-only working copy...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
		docs\programs\mkvtoolnix\mkvmerge -o "docs\temp\BvS.mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags !file! >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
		if errorlevel 2 goto stage_failed
		if errorlevel 1 goto stage_warning
		if not errorlevel 0 goto stage_failed
		call :require_stage_output "docs\temp\BvS.mkv"
		if errorlevel 1 goto stage_failed
	)

	::Extracting 5 unaltered (scope) files
	set "stage_name=ffmpeg: BvS_2s.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -ss 00:05:09.142 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 85890 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_2s.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_2s.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=ffmpeg: BvS_4s.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -ss 01:09:18.715 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 77191 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_4s.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_4s.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=ffmpeg: BvS_6s.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -ss 02:10:22.606 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 44494 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_6s.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_6s.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=ffmpeg: BvS_8s.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -ss 02:50:35.850 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 4163 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_8s.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_8s.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=ffmpeg: BvS_10s.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -ss 02:54:43.862 -noaccurate_seek -i "docs\temp\BvS.mkv" -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_10s.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_10s.mkv"
	if errorlevel 1 goto stage_failed



	::Extracting, encoding(cropping) and deleting(original) for the 5 other files (IMAX)
	set "stage_name=ffmpeg: BvS_1i.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 7388 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_1i.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_1i.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=HandBrakeCLI: BvS_1i_Cropped.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Encoding a section - this can take a long time...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_1i.mkv" -o "docs\temp\BvS_1i_Cropped.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 50800 -2 --cfr -w 3840 -l 2160 --crop 214:214:380:380 >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_1i_Cropped.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=ffmpeg: BvS_3i.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -ss 01:04:51.470 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 6427 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_3i.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_3i.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=HandBrakeCLI: BvS_3i_Cropped.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Encoding a section - this can take a long time...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_3i.mkv" -o "docs\temp\BvS_3i_Cropped.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 39400 -2 --cfr -w 3840 -l 2160 --crop 214:214:380:380 >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_3i_Cropped.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=ffmpeg: BvS_5i.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -ss 02:02:58.190 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 10633 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_5i.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_5i.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=HandBrakeCLI: BvS_5i_Cropped.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Encoding a section - this can take a long time...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_5i.mkv" -o "docs\temp\BvS_5i_Cropped.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 53000 -2 --cfr -w 3840 -l 2160 --crop 214:214:380:380 >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_5i_Cropped.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=ffmpeg: BvS_7i.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -ss 02:41:18.377 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 13366 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_7i.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_7i.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=HandBrakeCLI: BvS_7i_Cropped.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Encoding a section - this can take a long time...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_7i.mkv" -o "docs\temp\BvS_7i_Cropped.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 50000 -2 --cfr -w 3840 -l 2160 --crop 214:214:380:380 >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_7i_Cropped.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=ffmpeg: BvS_9i.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -ss 02:53:29.482 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 1804 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -map_metadata -1 -y "docs\temp\BvS_9i.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_9i.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=HandBrakeCLI: BvS_9i_Cropped.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Encoding a section - this can take a long time...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_9i.mkv" -o "docs\temp\BvS_9i_Cropped.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 50000 -2 --cfr -w 3840 -l 2160 --crop 214:214:380:380 >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_9i_Cropped.mkv"
	if errorlevel 1 goto stage_failed



	



	::Concatenating all 10 files
	set "stage_name=avidemux_cli: BvS_1.78.mkv"
	call :require_stage_output "docs\temp\BvS_1i_Cropped.mkv"
	if errorlevel 1 goto stage_failed
	call :require_stage_output "docs\temp\BvS_2s.mkv"
	if errorlevel 1 goto stage_failed
	call :require_stage_output "docs\temp\BvS_3i_Cropped.mkv"
	if errorlevel 1 goto stage_failed
	call :require_stage_output "docs\temp\BvS_4s.mkv"
	if errorlevel 1 goto stage_failed
	call :require_stage_output "docs\temp\BvS_5i_Cropped.mkv"
	if errorlevel 1 goto stage_failed
	call :require_stage_output "docs\temp\BvS_6s.mkv"
	if errorlevel 1 goto stage_failed
	call :require_stage_output "docs\temp\BvS_7i_Cropped.mkv"
	if errorlevel 1 goto stage_failed
	call :require_stage_output "docs\temp\BvS_8s.mkv"
	if errorlevel 1 goto stage_failed
	call :require_stage_output "docs\temp\BvS_9i_Cropped.mkv"
	if errorlevel 1 goto stage_failed
	call :require_stage_output "docs\temp\BvS_10s.mkv"
	if errorlevel 1 goto stage_failed
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Joining the processed sections...
	echo Assembly diagnostics and any questions appear in this window, not processing.log.
	echo Answer only an explicit assembly question: y continues despite its warning; n declines.
	echo Continuing does not establish codec compatibility or seamless joins.
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\avidemux\avidemux_cli --load "docs\temp\BvS_1i_Cropped.mkv" --append "docs\temp\BvS_2s.mkv" --append "docs\temp\BvS_3i_Cropped.mkv" --append "docs\temp\BvS_4s.mkv" --append "docs\temp\BvS_5i_Cropped.mkv" --append "docs\temp\BvS_6s.mkv" --append "docs\temp\BvS_7i_Cropped.mkv" --append "docs\temp\BvS_8s.mkv" --append "docs\temp\BvS_9i_Cropped.mkv" --append "docs\temp\BvS_10s.mkv" --video-codec copy --audio-codec copy --output-format mkv --save "docs\temp\BvS_1.78.mkv"
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_1.78.mkv"
	if errorlevel 1 goto stage_failed



	::Merging altered video with source rip, keeping only video track of the first and all but video track of the latter for the output file
	echo Remuxing audio and subtitles
	set "hello=Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.78.mkv"
	set "result=!folder!!hello!"
	set "final_output=!result!"
	if "%dialog2%"=="y" set "final_output=!folder!\!hello!"
	if exist "!final_output!" goto output_exists
	if %dialog%==y (
		if %dialog2%==y (
			docs\programs\mkvtoolnix\mkvmerge -o "!folder!\Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.78.mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "docs\temp\BvS_1.78.mkv" -D --no-video "%file%" > "%RESTORER_LOG_DIRECTORY%\final-remux.log" 2>&1
			if errorlevel 2 goto remux_failed
			if errorlevel 1 goto remux_warning
			if not errorlevel 0 goto remux_failed
		) else if %dialog2%==n (
			docs\programs\mkvtoolnix\mkvmerge -o "!result!" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "docs\temp\BvS_1.78.mkv" -D --no-video "%file%" > "%RESTORER_LOG_DIRECTORY%\final-remux.log" 2>&1
			if errorlevel 2 goto remux_failed
			if errorlevel 1 goto remux_warning
			if not errorlevel 0 goto remux_failed
		)
	) else if %dialog%==n (
		if %dialog2%==y (
			docs\programs\mkvtoolnix\mkvmerge -o "!folder!\Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.78.mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "docs\temp\BvS_1.78.mkv" -D --no-video !file! > "%RESTORER_LOG_DIRECTORY%\final-remux.log" 2>&1
			if errorlevel 2 goto remux_failed
			if errorlevel 1 goto remux_warning
			if not errorlevel 0 goto remux_failed
		) else if %dialog2%==n (
			docs\programs\mkvtoolnix\mkvmerge -o "!result!" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "docs\temp\BvS_1.78.mkv" -D --no-video !file! > "%RESTORER_LOG_DIRECTORY%\final-remux.log" 2>&1
			if errorlevel 2 goto remux_failed
			if errorlevel 1 goto remux_warning
			if not errorlevel 0 goto remux_failed
		)
	)
	
	if not exist "!final_output!" goto remux_failed
	for %%F in ("!final_output!") do if %%~zF EQU 0 goto remux_failed

	for %%O in ("!final_output!") do (endlocal & set "completed_output=%%~O")
	


) else if %version%==2 (
	

	if %dialog%==y (
		set "stage_name=mkvmerge: BvS.mkv"
		echo.
		echo ----------------------------------------------------------------
		echo [%TIME%] Preparing the video-only working copy...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
		docs\programs\mkvtoolnix\mkvmerge -o "docs\temp\BvS.mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "%file%" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
		if errorlevel 2 goto stage_failed
		if errorlevel 1 goto stage_warning
		if not errorlevel 0 goto stage_failed
		call :require_stage_output "docs\temp\BvS.mkv"
		if errorlevel 1 goto stage_failed
	) else if %dialog%==n (
		set "stage_name=mkvmerge: BvS.mkv"
		echo.
		echo ----------------------------------------------------------------
		echo [%TIME%] Preparing the video-only working copy...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
		docs\programs\mkvtoolnix\mkvmerge -o "docs\temp\BvS.mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags !file! >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
		if errorlevel 2 goto stage_failed
		if errorlevel 1 goto stage_warning
		if not errorlevel 0 goto stage_failed
		call :require_stage_output "docs\temp\BvS.mkv"
		if errorlevel 1 goto stage_failed
	)

	::Extracting 5 unaltered (IMAX) files
	set "stage_name=ffmpeg: BvS_1i.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 7388 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_1i.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_1i.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=ffmpeg: BvS_3i.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -ss 01:04:51.470 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 6427 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_3i.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_3i.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=ffmpeg: BvS_5i.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -ss 02:02:58.190 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 10633 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_5i.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_5i.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=ffmpeg: BvS_7i.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -ss 02:41:18.377 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 13366 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_7i.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_7i.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=ffmpeg: BvS_9i.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -ss 02:53:29.482 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 1804 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_9i.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_9i.mkv"
	if errorlevel 1 goto stage_failed



	::Extracting, encoding(windowboxing) and deleting(original) for the 5 other files (scope)
	set "stage_name=ffmpeg: BvS_2s.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -ss 00:05:09.142 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 85890 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_2s.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_2s.mkv"
	if errorlevel 1 goto stage_failed

	echo Windowboxing BvS_2s.mkv
	set "stage_name=HandBrakeCLI: BvS_2s_Windowboxed.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Encoding a section - this can take a long time...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_2s.mkv" -o "docs\temp\BvS_2s_Windowboxed.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 51400 --cfr -2 -w 3080 -l 1732 --crop-mode "none" --non-anamorphic --pad "width=3840:height=2160" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_2s_Windowboxed.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=ffmpeg: BvS_4s.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -ss 01:09:18.715 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 77191 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_4s.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_4s.mkv"
	if errorlevel 1 goto stage_failed

	echo Windowboxing BvS_4s.mkv
	set "stage_name=HandBrakeCLI: BvS_4s_Windowboxed.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Encoding a section - this can take a long time...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_4s.mkv" -o "docs\temp\BvS_4s_Windowboxed.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 51700 --cfr -2 -w 3080 -l 1732 --crop-mode "none" --non-anamorphic --pad "width=3840:height=2160" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_4s_Windowboxed.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=ffmpeg: BvS_6s.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -ss 02:10:22.606 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 44494 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_6s.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_6s.mkv"
	if errorlevel 1 goto stage_failed

	echo Windowboxing BvS_6s.mkv
	set "stage_name=HandBrakeCLI: BvS_6s_Windowboxed.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Encoding a section - this can take a long time...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_6s.mkv" -o "docs\temp\BvS_6s_Windowboxed.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 59500 --cfr -2 -w 3080 -l 1732 --crop-mode "none" --non-anamorphic --pad "width=3840:height=2160" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_6s_Windowboxed.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=ffmpeg: BvS_8s.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -ss 02:50:35.850 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 4163 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_8s.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_8s.mkv"
	if errorlevel 1 goto stage_failed

	echo Windowboxing BvS_8s.mkv
	set "stage_name=HandBrakeCLI: BvS_8s_Windowboxed.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Encoding a section - this can take a long time...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_8s.mkv" -o "docs\temp\BvS_8s_Windowboxed.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 48900 --cfr -2 -w 3080 -l 1732 --crop-mode "none" --non-anamorphic --pad "width=3840:height=2160" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_8s_Windowboxed.mkv"
	if errorlevel 1 goto stage_failed
	set "stage_name=ffmpeg: BvS_10s.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Copying a video section without encoding...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\ffmpeg\ffmpeg -nostdin -threads 0 -ss 02:54:43.862 -noaccurate_seek -i "docs\temp\BvS.mkv" -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_10s.mkv" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_10s.mkv"
	if errorlevel 1 goto stage_failed

	echo Windowboxing BvS_10s.mkv
	set "stage_name=HandBrakeCLI: BvS_10s_Windowboxed.mkv"
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Encoding a section - this can take a long time...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_10s.mkv" -o "docs\temp\BvS_10s_Windowboxed.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 30000 --cfr -2 -w 3080 -l 1732 --crop-mode "none" --non-anamorphic --pad "width=3840:height=2160" >> "%RESTORER_LOG_DIRECTORY%\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_10s_Windowboxed.mkv"
	if errorlevel 1 goto stage_failed



	::Concatenating all 10 files
	set "stage_name=avidemux_cli: BvS_1.43.mkv"
	call :require_stage_output "docs\temp\BvS_1i.mkv"
	if errorlevel 1 goto stage_failed
	call :require_stage_output "docs\temp\BvS_2s_Windowboxed.mkv"
	if errorlevel 1 goto stage_failed
	call :require_stage_output "docs\temp\BvS_3i.mkv"
	if errorlevel 1 goto stage_failed
	call :require_stage_output "docs\temp\BvS_4s_Windowboxed.mkv"
	if errorlevel 1 goto stage_failed
	call :require_stage_output "docs\temp\BvS_5i.mkv"
	if errorlevel 1 goto stage_failed
	call :require_stage_output "docs\temp\BvS_6s_Windowboxed.mkv"
	if errorlevel 1 goto stage_failed
	call :require_stage_output "docs\temp\BvS_7i.mkv"
	if errorlevel 1 goto stage_failed
	call :require_stage_output "docs\temp\BvS_8s_Windowboxed.mkv"
	if errorlevel 1 goto stage_failed
	call :require_stage_output "docs\temp\BvS_9i.mkv"
	if errorlevel 1 goto stage_failed
	call :require_stage_output "docs\temp\BvS_10s_Windowboxed.mkv"
	if errorlevel 1 goto stage_failed
	echo.
	echo ----------------------------------------------------------------
	echo [%TIME%] Joining the processed sections...
	echo Stage: !stage_name!>> "%RESTORER_LOG_DIRECTORY%\processing.log"
	echo Assembly diagnostics and any questions appear in this window, not processing.log.
	echo Answer only an explicit assembly question: y continues despite its warning; n declines.
	echo Continuing does not establish codec compatibility or seamless joins.
	docs\programs\avidemux\avidemux_cli --load "docs\temp\BvS_1i.mkv" --append "docs\temp\BvS_2s_Windowboxed.mkv" --append "docs\temp\BvS_3i.mkv" --append "docs\temp\BvS_4s_Windowboxed.mkv" --append "docs\temp\BvS_5i.mkv" --append "docs\temp\BvS_6s_Windowboxed.mkv" --append "docs\temp\BvS_7i.mkv" --append "docs\temp\BvS_8s_Windowboxed.mkv" --append "docs\temp\BvS_9i.mkv" --append "docs\temp\BvS_10s_Windowboxed.mkv" --video-codec copy --audio-codec copy --output-format mkv --save "docs\temp\BvS_1.43.mkv"
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_1.43.mkv"
	if errorlevel 1 goto stage_failed



	::Merging altered video with source rip, keeping only video track of the first and all but video track of the latter for the output file
	echo Remuxing audio and subtitles
	set "hello=Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.43 (unmasked).mkv"
	set "result=!folder!!hello!"
	set "final_output=!result!"
	if "%dialog2%"=="y" set "final_output=!folder!\!hello!"
	if exist "!final_output!" goto output_exists
	if %dialog%==y (
		if %dialog2%==y (
			docs\programs\mkvtoolnix\mkvmerge -o "!folder!\Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.43 (unmasked).mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "docs\temp\BvS_1.43.mkv" -D --no-video "%file%" > "%RESTORER_LOG_DIRECTORY%\final-remux.log" 2>&1
			if errorlevel 2 goto remux_failed
			if errorlevel 1 goto remux_warning
			if not errorlevel 0 goto remux_failed
		) else if %dialog2%==n (
			docs\programs\mkvtoolnix\mkvmerge -o "!result!" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "docs\temp\BvS_1.43.mkv" -D --no-video "%file%" > "%RESTORER_LOG_DIRECTORY%\final-remux.log" 2>&1
			if errorlevel 2 goto remux_failed
			if errorlevel 1 goto remux_warning
			if not errorlevel 0 goto remux_failed
		)
	) else if %dialog%==n (
		if %dialog2%==y (
			docs\programs\mkvtoolnix\mkvmerge -o "!folder!\Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.43 (unmasked).mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "docs\temp\BvS_1.43.mkv" -D --no-video !file! > "%RESTORER_LOG_DIRECTORY%\final-remux.log" 2>&1
			if errorlevel 2 goto remux_failed
			if errorlevel 1 goto remux_warning
			if not errorlevel 0 goto remux_failed
		) else if %dialog2%==n (
			docs\programs\mkvtoolnix\mkvmerge -o "!result!" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "docs\temp\BvS_1.43.mkv" -D --no-video !file! > "%RESTORER_LOG_DIRECTORY%\final-remux.log" 2>&1
			if errorlevel 2 goto remux_failed
			if errorlevel 1 goto remux_warning
			if not errorlevel 0 goto remux_failed
		)
	)

	if not exist "!final_output!" goto remux_failed
	for %%F in ("!final_output!") do if %%~zF EQU 0 goto remux_failed

	for %%O in ("!final_output!") do (endlocal & set "completed_output=%%~O")
	
	
	
) else (
	::Loop if input is not valid
	echo %version% is not a valid input
	goto a
)

echo.
echo ================================================================
echo [OK] Restoration complete.
echo ================================================================
echo Output: "%completed_output%"
echo The final MKV contains the restored video and the selected original audio and subtitles.
echo Logs: "%RESTORER_LOG_DIRECTORY%"

popd
exit /b 0

:: Workspace helpers: shared structure in both film launchers.
:prepare_workspace
rem Caller owns environment scope; keep pushd active until the final popd.
pushd "%~dp0"
if errorlevel 1 (
    echo.
    echo ================================================================
    echo [STOP] Cannot open the restorer program folder. Processing has not started.
    echo ================================================================
    exit /b 2
)
if not exist "docs\" (
    echo.
    echo ================================================================
    echo [STOP] The docs folder is missing. Extract the complete application archive.
    echo ================================================================
    popd
    exit /b 2
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "docs\scripts\Manage-Workspace.ps1" -Action CheckOwned -Film BvS
if errorlevel 1 (
    echo [STOP] Cannot use the temporary workspace. Close any previous restoration and try again.
    popd
    exit /b 2
)
exit /b 0



:: Structural output check only; does not qualify media contents.
:require_stage_output
setlocal DisableDelayedExpansion
if not exist "%~1" (endlocal & exit /b 1)
if exist "%~1\" (endlocal & exit /b 1)
for %%F in ("%~1") do if %%~zF EQU 0 (endlocal & exit /b 1)
endlocal & exit /b 0

:stage_warning
echo.
echo ================================================================
echo [STOP] Processing stopped with a warning at !stage_name!.
echo ================================================================
echo Temporary videos remain in docs\temp. Logs are kept separately.
echo Logs: "%RESTORER_LOG_DIRECTORY%"
echo You can start a new restoration after closing this run.
PAUSE
popd
exit /b 1

:stage_failed
echo.
echo ================================================================
echo [STOP] Processing failed at !stage_name!.
echo ================================================================
echo Temporary videos remain in docs\temp. Logs are kept separately.
echo Logs: "%RESTORER_LOG_DIRECTORY%"
echo You can start a new restoration after closing this run.
PAUSE
popd
exit /b 2

:remux_warning
echo.
echo ================================================================
echo [STOP] Final remux completed with warnings. The output needs review.
echo ================================================================
echo The assembled video is retained at docs\temp\BvS_1.78.mkv or docs\temp\BvS_1.43.mkv
echo Details are in %RESTORER_LOG_DIRECTORY%\final-remux.log
echo Temporary work is cleared automatically when you start a new restoration.
PAUSE
popd
exit /b 1

:remux_failed
echo.
echo ================================================================
echo [STOP] Final remux failed. Any destination output may be incomplete; do not use it.
echo ================================================================
echo The assembled video is retained at docs\temp\BvS_1.78.mkv or docs\temp\BvS_1.43.mkv
echo Details are in %RESTORER_LOG_DIRECTORY%\final-remux.log
echo Temporary work is cleared automatically when you start a new restoration.
PAUSE
popd
exit /b 2

:output_exists
echo.
echo ================================================================
echo [STOP] Output appeared after setup. Final remux was not started.
echo ================================================================
echo Existing output and all intermediate work have been preserved.
echo Choose another destination before starting again.
PAUSE
popd
exit /b 2
