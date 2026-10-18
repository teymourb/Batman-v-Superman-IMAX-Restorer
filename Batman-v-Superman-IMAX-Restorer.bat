@ECHO OFF

setlocal DisableDelayedExpansion
call :prepare_workspace
if errorlevel 1 exit /b 2

::Making sure batch file drive location has enough space
echo Please make sure you have extracted the 7z zip file to a drive with 160GB of free space.
echo If this is correct press Enter
echo If not, please close this program and extract the 7z zip file to an appropriate location.
pause

echo Please select your 4K Blu-ray Batman v Superman Dawn of Justice Ultimated Edition ^(Remastered^) rip .mkv file
echo DISCLAIMER: This will not work with any other version of the movie. Only an unaltered file (video track) ripped from this specific disc will work with the program.
::File selection
Title Batman v Superman: Dawn of Justice Ultimate Edition IMAX Restorer
(
    echo Function GetFileDlgEx(sIniDir,sFilter,sTitle^) 
    echo Set oDlg = CreateObject("WScript.Shell"^).Exec("mshta.exe ""about:<object id=d classid=clsid:3050f4e1-98b5-11cf-bb82-00aa00bdce0b></object><script>moveTo(0,-9999);eval(new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(0).Read("^&Len(sIniDir^)^+Len(sFilter^)^+Len(sTitle^)+41^&"));function window.onload(){var p=/[^\0]*/;new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).Write(p.exec(d.object.openfiledlg(iniDir,null,filter,title)));close();}</script><hta:application showintaskbar=no />"""^) 
    echo oDlg.StdIn.Write "var iniDir='" ^& sIniDir ^& "';var filter='" ^& sFilter ^& "';var title='" ^& sTitle ^& "';"
    echo GetFileDlgEx = oDlg.StdOut.ReadAll 
    echo End Function
    echo sIniDir = "C:\Movie_Rip.mkv.mkv"
    echo sFilter = "MKV files (*.mkv)|*.mkv|"
    echo sTitle = "Selecting source rip .mkv file" 
    echo MyFile = GetFileDlgEx(Replace(sIniDir,"\","\\"^),sFilter,sTitle^) 
    echo wscript.echo MyFile
)>"%tmp%\%~n0.vbs"
for /f "tokens=* delims=" %%p in ('Cscript /NoLogo "%tmp%\%~n0.vbs"') do set "file=%%p"
echo %file%


::In case file path prompt wasn't successful
echo Did a dialog prompt you to select your file and if so, were you successful? [y/n]

set /p dialog=Input:

if %dialog%==n (
	echo Please enter the full path to your file.
	echo You may be able to drag and drop the file on the terminal for the same result:
	set /p "file=Enter file path: "
)
pause


::Destination folder selection
setlocal

set "psCommand="(new-object -COM 'Shell.Application')^
.BrowseForFolder(0,'Please choose a destination folder for the IMAX Restoration:',0,0).self.path""

for /f "usebackq delims=" %%I in (`powershell %psCommand%`) do set "folder=%%I"

setlocal enabledelayedexpansion
echo You chose !folder!


::In case file path prompt wasn't successful
echo Did a dialog prompt you to select your folder and if so, were you successful? [y/n]

set /p dialog2=Input:

if %dialog2%==n (
	echo Please enter the full path to your folder:
	echo You may be able to drag and drop the folder on the terminal for the same result:
	set /p "folder=Enter folder path: "
	set "folder=!folder:"=!"
	if not "!folder:~-1!"=="\" set "folder=!folder!\"
	echo !folder!
)
pause


::Define loop point for incorrect input
:a


echo Enter the number for the constant-width IMAX version you would like:
echo 1) IMAX 1.78:1 ^(IMAX scenes vertically centre-cropped^)
echo 2) IMAX 1.43:1 ^(Scope scenes windowboxed - unmasked 16:9 container^)

::Get input from user
set /p version=Input: 

echo Tool diagnostics are written to docs\temp\processing.log during processing.
::Check what version to use and make sure the user selected the right one
if %version%==1 (
	
	echo You have selected: IMAX 1.78:1 ^(Cropped^)
	echo If this is correct press Enter
	echo If this was the wrong choice please restart this program
	PAUSE

	if %dialog%==y (
		set "stage_name=mkvmerge: BvS.mkv"
		echo Stage: !stage_name!>> "docs\temp\processing.log"
		docs\programs\mkvtoolnix\mkvmerge -o "docs\temp\BvS.mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "%file%" >> "docs\temp\processing.log" 2>&1
		if errorlevel 2 goto stage_failed
		if errorlevel 1 goto stage_warning
		if not errorlevel 0 goto stage_failed
		call :require_stage_output "docs\temp\BvS.mkv"
		if errorlevel 1 goto stage_failed
	) else if %dialog%==n (
		set "stage_name=mkvmerge: BvS.mkv"
		echo Stage: !stage_name!>> "docs\temp\processing.log"
		docs\programs\mkvtoolnix\mkvmerge -o "docs\temp\BvS.mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags !file! >> "docs\temp\processing.log" 2>&1
		if errorlevel 2 goto stage_failed
		if errorlevel 1 goto stage_warning
		if not errorlevel 0 goto stage_failed
		call :require_stage_output "docs\temp\BvS.mkv"
		if errorlevel 1 goto stage_failed
	)

	::Extracting 5 unaltered (scope) files
	echo Splitting BvS_2s.mkv
	set "stage_name=ffmpeg: BvS_2s.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 00:05:09.142 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 85890 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_2s.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_2s.mkv"
	if errorlevel 1 goto stage_failed

	echo Splitting BvS_4s.mkv
	set "stage_name=ffmpeg: BvS_4s.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 01:09:18.715 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 77191 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_4s.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_4s.mkv"
	if errorlevel 1 goto stage_failed

	echo Splitting BvS_6s.mkv
	set "stage_name=ffmpeg: BvS_6s.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:10:22.606 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 44494 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_6s.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_6s.mkv"
	if errorlevel 1 goto stage_failed

	echo Splitting BvS_8s.mkv
	set "stage_name=ffmpeg: BvS_8s.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:50:35.850 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 4163 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_8s.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_8s.mkv"
	if errorlevel 1 goto stage_failed

	echo Splitting BvS_10s.mkv
	set "stage_name=ffmpeg: BvS_10s.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:54:43.862 -noaccurate_seek -i "docs\temp\BvS.mkv" -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_10s.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_10s.mkv"
	if errorlevel 1 goto stage_failed



	::Extracting, encoding(cropping) and deleting(original) for the 5 other files (IMAX)
	echo Splitting BvS_1i.mkv
	set "stage_name=ffmpeg: BvS_1i.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 7388 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_1i.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_1i.mkv"
	if errorlevel 1 goto stage_failed

	echo Cropping BvS_1i.mkv
	set "stage_name=HandBrakeCLI: BvS_1i_Cropped.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_1i.mkv" -o "docs\temp\BvS_1i_Cropped.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 50800 -2 --cfr -w 3840 -l 2160 --crop 214:214:380:380 >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_1i_Cropped.mkv"
	if errorlevel 1 goto stage_failed


	echo Splitting BvS_3i.mkv
	set "stage_name=ffmpeg: BvS_3i.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 01:04:51.470 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 6427 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_3i.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_3i.mkv"
	if errorlevel 1 goto stage_failed

	echo Cropping BvS_3i.mkv
	set "stage_name=HandBrakeCLI: BvS_3i_Cropped.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_3i.mkv" -o "docs\temp\BvS_3i_Cropped.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 39400 -2 --cfr -w 3840 -l 2160 --crop 214:214:380:380 >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_3i_Cropped.mkv"
	if errorlevel 1 goto stage_failed


	echo Splitting BvS_5i.mkv
	set "stage_name=ffmpeg: BvS_5i.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:02:58.190 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 10633 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_5i.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_5i.mkv"
	if errorlevel 1 goto stage_failed

	echo Cropping BvS_5i.mkv
	set "stage_name=HandBrakeCLI: BvS_5i_Cropped.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_5i.mkv" -o "docs\temp\BvS_5i_Cropped.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 53000 -2 --cfr -w 3840 -l 2160 --crop 214:214:380:380 >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_5i_Cropped.mkv"
	if errorlevel 1 goto stage_failed


	echo Splitting BvS_7i.mkv
	set "stage_name=ffmpeg: BvS_7i.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:41:18.377 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 13366 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_7i.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_7i.mkv"
	if errorlevel 1 goto stage_failed

	echo Cropping BvS_7i.mkv
	set "stage_name=HandBrakeCLI: BvS_7i_Cropped.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_7i.mkv" -o "docs\temp\BvS_7i_Cropped.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 50000 -2 --cfr -w 3840 -l 2160 --crop 214:214:380:380 >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_7i_Cropped.mkv"
	if errorlevel 1 goto stage_failed


	echo Splitting BvS_9i.mkv
	set "stage_name=ffmpeg: BvS_9i.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:53:29.482 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 1804 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -map_metadata -1 -y "docs\temp\BvS_9i.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_9i.mkv"
	if errorlevel 1 goto stage_failed

	echo Cropping BvS_9i.mkv
	set "stage_name=HandBrakeCLI: BvS_9i_Cropped.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_9i.mkv" -o "docs\temp\BvS_9i_Cropped.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 50000 -2 --cfr -w 3840 -l 2160 --crop 214:214:380:380 >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_9i_Cropped.mkv"
	if errorlevel 1 goto stage_failed



	



	::Concatenating all 10 files
	echo Exporting...
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
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\avidemux\avidemux_cli --load "docs\temp\BvS_1i_Cropped.mkv" --append "docs\temp\BvS_2s.mkv" --append "docs\temp\BvS_3i_Cropped.mkv" --append "docs\temp\BvS_4s.mkv" --append "docs\temp\BvS_5i_Cropped.mkv" --append "docs\temp\BvS_6s.mkv" --append "docs\temp\BvS_7i_Cropped.mkv" --append "docs\temp\BvS_8s.mkv" --append "docs\temp\BvS_9i_Cropped.mkv" --append "docs\temp\BvS_10s.mkv" --video-codec copy --audio-codec copy --output-format mkv --save "docs\temp\BvS_1.78.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_1.78.mkv"
	if errorlevel 1 goto stage_failed



	echo Deleting Leftover Files



	::Merging altered video with source rip, keeping only video track of the first and all but video track of the latter for the output file
	echo Remuxing audio and subtitles
	set "hello=Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.78.mkv"
	set "result=!folder!!hello!"
	set "final_output=!result!"
	if "%dialog2%"=="y" set "final_output=!folder!\!hello!"
	if %dialog%==y (
		if %dialog2%==y (
			docs\programs\mkvtoolnix\mkvmerge -o "!folder!\Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.78.mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "docs\temp\BvS_1.78.mkv" -D --no-video "%file%" > "docs\temp\final-remux.log" 2>&1
			if errorlevel 2 goto remux_failed
			if errorlevel 1 goto remux_warning
			if not errorlevel 0 goto remux_failed
		) else if %dialog2%==n (
			docs\programs\mkvtoolnix\mkvmerge -o "!result!" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "docs\temp\BvS_1.78.mkv" -D --no-video "%file%" > "docs\temp\final-remux.log" 2>&1
			if errorlevel 2 goto remux_failed
			if errorlevel 1 goto remux_warning
			if not errorlevel 0 goto remux_failed
		)
	) else if %dialog%==n (
		if %dialog2%==y (
			docs\programs\mkvtoolnix\mkvmerge -o "!folder!\Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.78.mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "docs\temp\BvS_1.78.mkv" -D --no-video !file! > "docs\temp\final-remux.log" 2>&1
			if errorlevel 2 goto remux_failed
			if errorlevel 1 goto remux_warning
			if not errorlevel 0 goto remux_failed
		) else if %dialog2%==n (
			docs\programs\mkvtoolnix\mkvmerge -o "!result!" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "docs\temp\BvS_1.78.mkv" -D --no-video !file! > "docs\temp\final-remux.log" 2>&1
			if errorlevel 2 goto remux_failed
			if errorlevel 1 goto remux_warning
			if not errorlevel 0 goto remux_failed
		)
	)
	
	if not exist "!final_output!" goto remux_failed
	for %%F in ("!final_output!") do if %%~zF EQU 0 goto remux_failed

	endlocal
	


) else if %version%==2 (
	
	echo You have selected: IMAX 1.43:1 ^(16:9, unmasked^)
	echo If this is correct press Enter
	echo If this was the wrong choice please restart this program
	PAUSE

	if %dialog%==y (
		set "stage_name=mkvmerge: BvS.mkv"
		echo Stage: !stage_name!>> "docs\temp\processing.log"
		docs\programs\mkvtoolnix\mkvmerge -o "docs\temp\BvS.mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "%file%" >> "docs\temp\processing.log" 2>&1
		if errorlevel 2 goto stage_failed
		if errorlevel 1 goto stage_warning
		if not errorlevel 0 goto stage_failed
		call :require_stage_output "docs\temp\BvS.mkv"
		if errorlevel 1 goto stage_failed
	) else if %dialog%==n (
		set "stage_name=mkvmerge: BvS.mkv"
		echo Stage: !stage_name!>> "docs\temp\processing.log"
		docs\programs\mkvtoolnix\mkvmerge -o "docs\temp\BvS.mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags !file! >> "docs\temp\processing.log" 2>&1
		if errorlevel 2 goto stage_failed
		if errorlevel 1 goto stage_warning
		if not errorlevel 0 goto stage_failed
		call :require_stage_output "docs\temp\BvS.mkv"
		if errorlevel 1 goto stage_failed
	)

	::Extracting 5 unaltered (IMAX) files
	echo Spliting BvS_1i.mkv
	set "stage_name=ffmpeg: BvS_1i.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 7388 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_1i.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_1i.mkv"
	if errorlevel 1 goto stage_failed

	echo Spliting BvS_3i.mkv
	set "stage_name=ffmpeg: BvS_3i.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 01:04:51.470 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 6427 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_3i.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_3i.mkv"
	if errorlevel 1 goto stage_failed

	echo Spliting BvS_5i.mkv
	set "stage_name=ffmpeg: BvS_5i.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:02:58.190 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 10633 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_5i.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_5i.mkv"
	if errorlevel 1 goto stage_failed

	echo Spliting BvS_7i.mkv
	set "stage_name=ffmpeg: BvS_7i.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:41:18.377 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 13366 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_7i.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_7i.mkv"
	if errorlevel 1 goto stage_failed

	echo Spliting BvS_9i.mkv
	set "stage_name=ffmpeg: BvS_9i.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:53:29.482 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 1804 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_9i.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_9i.mkv"
	if errorlevel 1 goto stage_failed



	::Extracting, encoding(windowboxing) and deleting(original) for the 5 other files (scope)
	echo Spliting BvS_2s.mkv
	set "stage_name=ffmpeg: BvS_2s.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 00:05:09.142 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 85890 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_2s.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_2s.mkv"
	if errorlevel 1 goto stage_failed

	echo Windowboxing BvS_2s.mkv
	set "stage_name=HandBrakeCLI: BvS_2s_Windowboxed.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_2s.mkv" -o "docs\temp\BvS_2s_Windowboxed.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 51400 --cfr -2 -w 3080 -l 1732 --crop-mode "none" --non-anamorphic --pad "width=3840:height=2160" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_2s_Windowboxed.mkv"
	if errorlevel 1 goto stage_failed


	echo Spliting BvS_4s.mkv
	set "stage_name=ffmpeg: BvS_4s.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 01:09:18.715 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 77191 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_4s.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_4s.mkv"
	if errorlevel 1 goto stage_failed

	echo Windowboxing BvS_4s.mkv
	set "stage_name=HandBrakeCLI: BvS_4s_Windowboxed.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_4s.mkv" -o "docs\temp\BvS_4s_Windowboxed.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 51700 --cfr -2 -w 3080 -l 1732 --crop-mode "none" --non-anamorphic --pad "width=3840:height=2160" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_4s_Windowboxed.mkv"
	if errorlevel 1 goto stage_failed


	echo Spliting BvS_6s.mkv
	set "stage_name=ffmpeg: BvS_6s.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:10:22.606 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 44494 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_6s.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_6s.mkv"
	if errorlevel 1 goto stage_failed

	echo Windowboxing BvS_6s.mkv
	set "stage_name=HandBrakeCLI: BvS_6s_Windowboxed.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_6s.mkv" -o "docs\temp\BvS_6s_Windowboxed.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 59500 --cfr -2 -w 3080 -l 1732 --crop-mode "none" --non-anamorphic --pad "width=3840:height=2160" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_6s_Windowboxed.mkv"
	if errorlevel 1 goto stage_failed


	echo Spliting BvS_8s.mkv
	set "stage_name=ffmpeg: BvS_8s.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:50:35.850 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 4163 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_8s.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_8s.mkv"
	if errorlevel 1 goto stage_failed

	echo Windowboxing BvS_8s.mkv
	set "stage_name=HandBrakeCLI: BvS_8s_Windowboxed.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_8s.mkv" -o "docs\temp\BvS_8s_Windowboxed.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 48900 --cfr -2 -w 3080 -l 1732 --crop-mode "none" --non-anamorphic --pad "width=3840:height=2160" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_8s_Windowboxed.mkv"
	if errorlevel 1 goto stage_failed


	echo Spliting BvS_10s.mkv
	set "stage_name=ffmpeg: BvS_10s.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:54:43.862 -noaccurate_seek -i "docs\temp\BvS.mkv" -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_10s.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_10s.mkv"
	if errorlevel 1 goto stage_failed

	echo Windowboxing BvS_10s.mkv
	set "stage_name=HandBrakeCLI: BvS_10s_Windowboxed.mkv"
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_10s.mkv" -o "docs\temp\BvS_10s_Windowboxed.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 30000 --cfr -2 -w 3080 -l 1732 --crop-mode "none" --non-anamorphic --pad "width=3840:height=2160" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_10s_Windowboxed.mkv"
	if errorlevel 1 goto stage_failed



	::Concatenating all 10 files
	echo Exporting...
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
	echo Stage: !stage_name!>> "docs\temp\processing.log"
	docs\programs\avidemux\avidemux_cli --load "docs\temp\BvS_1i.mkv" --append "docs\temp\BvS_2s_Windowboxed.mkv" --append "docs\temp\BvS_3i.mkv" --append "docs\temp\BvS_4s_Windowboxed.mkv" --append "docs\temp\BvS_5i.mkv" --append "docs\temp\BvS_6s_Windowboxed.mkv" --append "docs\temp\BvS_7i.mkv" --append "docs\temp\BvS_8s_Windowboxed.mkv" --append "docs\temp\BvS_9i.mkv" --append "docs\temp\BvS_10s_Windowboxed.mkv" --video-codec copy --audio-codec copy --output-format mkv --save "docs\temp\BvS_1.43.mkv" >> "docs\temp\processing.log" 2>&1
	if errorlevel 1 goto stage_failed
	if not errorlevel 0 goto stage_failed
	call :require_stage_output "docs\temp\BvS_1.43.mkv"
	if errorlevel 1 goto stage_failed



	echo Deleting Leftover Files



	::Merging altered video with source rip, keeping only video track of the first and all but video track of the latter for the output file
	echo Remuxing audio and subtitles
	set "hello=Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.43 (unmasked).mkv"
	set "result=!folder!!hello!"
	set "final_output=!result!"
	if "%dialog2%"=="y" set "final_output=!folder!\!hello!"
	if %dialog%==y (
		if %dialog2%==y (
			docs\programs\mkvtoolnix\mkvmerge -o "!folder!\Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.43 (unmasked).mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "docs\temp\BvS_1.43.mkv" -D --no-video "%file%" > "docs\temp\final-remux.log" 2>&1
			if errorlevel 2 goto remux_failed
			if errorlevel 1 goto remux_warning
			if not errorlevel 0 goto remux_failed
		) else if %dialog2%==n (
			docs\programs\mkvtoolnix\mkvmerge -o "!result!" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "docs\temp\BvS_1.43.mkv" -D --no-video "%file%" > "docs\temp\final-remux.log" 2>&1
			if errorlevel 2 goto remux_failed
			if errorlevel 1 goto remux_warning
			if not errorlevel 0 goto remux_failed
		)
	) else if %dialog%==n (
		if %dialog2%==y (
			docs\programs\mkvtoolnix\mkvmerge -o "!folder!\Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.43 (unmasked).mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "docs\temp\BvS_1.43.mkv" -D --no-video !file! > "docs\temp\final-remux.log" 2>&1
			if errorlevel 2 goto remux_failed
			if errorlevel 1 goto remux_warning
			if not errorlevel 0 goto remux_failed
		) else if %dialog2%==n (
			docs\programs\mkvtoolnix\mkvmerge -o "!result!" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "docs\temp\BvS_1.43.mkv" -D --no-video !file! > "docs\temp\final-remux.log" 2>&1
			if errorlevel 2 goto remux_failed
			if errorlevel 1 goto remux_warning
			if not errorlevel 0 goto remux_failed
		)
	)

	if not exist "!final_output!" goto remux_failed
	for %%F in ("!final_output!") do if %%~zF EQU 0 goto remux_failed

	endlocal
	
	
	
) else (
	::Loop if input is not valid
	echo %version% is not a valid input
	goto a
)

::Remove only the known log; unexpected work must survive cleanup.
call :cleanup_workspace
if errorlevel 1 goto cleanup_incomplete

echo Done!
PAUSE
popd
exit /b 0

:cleanup_incomplete
echo An output was created; assembly completeness still needs review.
echo Intermediate files and logs remain in "%~dp0docs\temp".
echo Review or move them before starting another restoration.
PAUSE
popd
exit /b 1

:: Workspace helpers: shared structure in both film launchers.
:prepare_workspace
rem Caller owns environment scope; keep pushd active until the final popd.
pushd "%~dp0"
if errorlevel 1 (
    echo Cannot open the restorer program folder. Processing has not started.
    exit /b 2
)
if not exist "docs\" (
    echo The docs folder is missing. Extract the complete application archive.
    popd
    exit /b 2
)
if exist "docs\temp" (
    echo Temporary work already exists in "%~dp0docs\temp".
    echo Preserve or move that folder before starting another restoration.
    echo No existing temporary files have been deleted.
    popd
    exit /b 2
)
mkdir "docs\temp"
if errorlevel 1 (
    echo Cannot create the temporary workspace. Processing has not started.
    popd
    exit /b 2
)
exit /b 0

:cleanup_workspace
setlocal DisableDelayedExpansion
rem Avidemux may report success after incomplete assembly; retain evidence.
if exist "docs\temp\processing.log" (
    endlocal & exit /b 1
)
if exist "docs\temp\final-remux.log" del /q "docs\temp\final-remux.log"
rem Nonrecursive removal preserves any unexpected files or subdirectories.
rmdir "docs\temp" 2>nul
if exist "docs\temp" (
    endlocal & exit /b 1
)
endlocal & exit /b 0

:: Structural output check only; does not qualify media contents.
:require_stage_output
setlocal DisableDelayedExpansion
if not exist "%~1" (endlocal & exit /b 1)
if exist "%~1\" (endlocal & exit /b 1)
for %%F in ("%~1") do if %%~zF EQU 0 (endlocal & exit /b 1)
endlocal & exit /b 0

:stage_warning
echo Processing stopped with a warning at !stage_name!.
echo Intermediate files and diagnostics are retained in docs\temp.
echo Review docs\temp\processing.log before moving the folder aside.
PAUSE
popd
exit /b 1

:stage_failed
echo Processing failed at !stage_name!.
echo Intermediate files and diagnostics are retained in docs\temp.
echo Review docs\temp\processing.log before moving the folder aside.
PAUSE
popd
exit /b 2

:remux_warning
echo Final remux completed with warnings. The output needs review.
echo The assembled video is retained at docs\temp\BvS_1.78.mkv or docs\temp\BvS_1.43.mkv
echo Details are in docs\temp\final-remux.log
echo A new run will preserve this folder and stop until you move it aside.
PAUSE
popd
exit /b 1

:remux_failed
echo Final remux failed. Any destination output may be incomplete; do not use it.
echo The assembled video is retained at docs\temp\BvS_1.78.mkv or docs\temp\BvS_1.43.mkv
echo Details are in docs\temp\final-remux.log
echo A new run will preserve this folder and stop until you move it aside.
PAUSE
popd
exit /b 2
