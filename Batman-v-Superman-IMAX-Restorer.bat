@ECHO OFF

cd "docs"
if exist temp (
	::Deleting temp files from previous failed session
    cd "temp"
	del *.* /F /Q
	cd ..
	cd ..
) else (
	::Creating temp folder
	mkdir temp
    cd ..
)

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
pause


::Destination folder selection
setlocal

set "psCommand="(new-object -COM 'Shell.Application')^
.BrowseForFolder(0,'Please choose a destination folder for the IMAX Restoration:',0,0).self.path""

for /f "usebackq delims=" %%I in (`powershell %psCommand%`) do set "folder=%%I"

setlocal enabledelayedexpansion
echo You chose !folder!

::Define loop point for incorrect input
:a


echo Enter the number for the constant-width IMAX version you would like:
echo 1) IMAX 1.78:1 ^(IMAX scenes vertically centre-cropped^)
echo 2) IMAX 1.43:1 ^(Scope scenes windowboxed - unmasked 16:9 container^)

::Get input from user
set /p version=Input: 

::Check what version to use and make sure the user selected the right one
if %version%==1 (
	
	echo You have selected: IMAX 1.78:1 ^(Cropped^)
	echo If this is correct press Enter
	echo If this was the wrong choice please restart this program
	PAUSE
	
	docs\programs\mkvtoolnix\mkvmerge -o "docs\temp\BvS.mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "%file%"

	::Extracting 5 unaltered (scope) files
	echo Splitting BvS_2s.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 00:05:09.142 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 85890 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_2s.mkv"

	echo Splitting BvS_4s.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 01:09:18.715 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 77191 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_4s.mkv"

	echo Splitting BvS_6s.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:10:22.606 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 44494 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_6s.mkv"

	echo Splitting BvS_8s.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:50:35.850 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 4163 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_8s.mkv"

	echo Splitting BvS_10s.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:54:43.862 -noaccurate_seek -i "docs\temp\BvS.mkv" -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_10s.mkv"



	::Extracting, encoding(cropping) and deleting(original) for the 5 other files (IMAX)
	echo Splitting BvS_1i.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 7388 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_1i.mkv"

	echo Cropping BvS_1i.mkv
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_1i.mkv" -o "docs\temp\BvS_1i_Cropped.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 50800 -2 --cfr -w 3840 -l 2160 --crop 214:214:380:380

	echo Deleting BvS_1i.mkv
	del "docs\temp\BvS_1i.mkv"

	echo Splitting BvS_3i.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 01:04:51.470 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 6427 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_3i.mkv"

	echo Cropping BvS_3i.mkv
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_3i.mkv" -o "docs\temp\BvS_3i_Cropped.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 39400 -2 --cfr -w 3840 -l 2160 --crop 214:214:380:380

	echo Deleting BvS_3i.mkv
	del "docs\temp\BvS_3i.mkv"

	echo Splitting BvS_5i.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:02:58.190 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 10633 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_5i.mkv"

	echo Cropping BvS_5i.mkv
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_5i.mkv" -o "docs\temp\BvS_5i_Cropped.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 53000 -2 --cfr -w 3840 -l 2160 --crop 214:214:380:380

	echo Deleting BvS_5i.mkv
	del "docs\temp\BvS_5i.mkv"

	echo Splitting BvS_7i.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:41:18.377 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 13366 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_7i.mkv"

	echo Cropping BvS_7i.mkv
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_7i.mkv" -o "docs\temp\BvS_7i_Cropped.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 50000 -2 --cfr -w 3840 -l 2160 --crop 214:214:380:380

	echo Deleting BvS_7i.mkv
	del "docs\temp\BvS_7i.mkv"

	echo Splitting BvS_9i.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:53:29.482 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 1804 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -map_metadata -1 -y "docs\temp\BvS_9i.mkv"

	echo Cropping BvS_9i.mkv
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_9i.mkv" -o "docs\temp\BvS_9i_Cropped.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 50000 -2 --cfr -w 3840 -l 2160 --crop 214:214:380:380

	echo Deleting BvS_9i.mkv
	del "docs\temp\BvS_9i.mkv"


	
	::Deleting audioless source
	echo Deleting BvS.mkv
	del "docs\temp\BvS.mkv"



	::Concatenating all 10 files
	echo Exporting...
	docs\programs\avidemux\avidemux_cli --load "docs\temp\BvS_1i_Cropped.mkv" --append "docs\temp\BvS_2s.mkv" --append "docs\temp\BvS_3i_Cropped.mkv" --append "docs\temp\BvS_4s.mkv" --append "docs\temp\BvS_5i_Cropped.mkv" --append "docs\temp\BvS_6s.mkv" --append "docs\temp\BvS_7i_Cropped.mkv" --append "docs\temp\BvS_8s.mkv" --append "docs\temp\BvS_9i_Cropped.mkv" --append "docs\temp\BvS_10s.mkv" --video-codec copy --audio-codec copy --output-format mkv --save "docs\temp\BvS_1.78.mkv"



	::Deleting 10 split files
	echo Deleting Leftover Files
	del "docs\temp\BvS_1i_Cropped.mkv"
	del "docs\temp\BvS_2s.mkv"
	del "docs\temp\BvS_3i_Cropped.mkv"
	del "docs\temp\BvS_4s.mkv"
	del "docs\temp\BvS_5i_Cropped.mkv"
	del "docs\temp\BvS_6s.mkv"
	del "docs\temp\BvS_7i_Cropped.mkv"
	del "docs\temp\BvS_8s.mkv"
	del "docs\temp\BvS_9i_Cropped.mkv"
	del "docs\temp\BvS_10s.mkv"



	::Merging altered video with source rip, keeping only video track of the first and all but video track of the latter for the output file
	echo Remuxing audio and subtitles
	docs\programs\mkvtoolnix\mkvmerge -o "!folder!\Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.78.mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "docs\temp\BvS_1.78.mkv" -D --no-video "%file%"
	
	endlocal
	
	::Deleting altered video with incorrect non-video tracks
	echo Deleting BvS_1.78.mkv
	del "docs\temp\BvS_1.78.mkv"


) else if %version%==2 (
	
	echo You have selected: IMAX 1.43:1 ^(16:9, unmasked^)
	echo If this is correct press Enter
	echo If this was the wrong choice please restart this program
	PAUSE
	
	docs\programs\mkvtoolnix\mkvmerge -o "docs\temp\BvS.mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "%file%"
	
	::Extracting 5 unaltered (IMAX) files
	echo Spliting BvS_1i.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 7388 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_1i.mkv"

	echo Spliting BvS_3i.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 01:04:51.470 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 6427 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_3i.mkv"

	echo Spliting BvS_5i.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:02:58.190 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 10633 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_5i.mkv"

	echo Spliting BvS_7i.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:41:18.377 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 13366 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_7i.mkv"

	echo Spliting BvS_9i.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:53:29.482 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 1804 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_9i.mkv"



	::Extracting, encoding(windowboxing) and deleting(original) for the 5 other files (scope)
	echo Spliting BvS_2s.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 00:05:09.142 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 85890 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_2s.mkv"

	echo Windowboxing BvS_2s.mkv
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_2s.mkv" -o "docs\temp\BvS_2s_Windowboxed.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 51400 --cfr -2 -w 3080 -l 1732 --crop-mode "none" --non-anamorphic --pad "width=3840:height=2160"

	echo Deleting BvS_2s.mkv
	del "docs\temp\BvS_2s.mkv"

	echo Spliting BvS_4s.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 01:09:18.715 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 77191 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_4s.mkv"

	echo Windowboxing BvS_4s.mkv
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_4s.mkv" -o "docs\temp\BvS_4s_Windowboxed.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 51700 --cfr -2 -w 3080 -l 1732 --crop-mode "none" --non-anamorphic --pad "width=3840:height=2160"

	echo Deleting BvS_4s.mkv
	del "docs\temp\BvS_4s.mkv"

	echo Spliting BvS_6s.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:10:22.606 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 44494 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_6s.mkv"

	echo Windowboxing BvS_6s.mkv
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_6s.mkv" -o "docs\temp\BvS_6s_Windowboxed.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 59500 --cfr -2 -w 3080 -l 1732 --crop-mode "none" --non-anamorphic --pad "width=3840:height=2160"

	echo Deleting BvS_6s.mkv
	del "docs\temp\BvS_6s.mkv"

	echo Spliting BvS_8s.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:50:35.850 -noaccurate_seek -i "docs\temp\BvS.mkv" -vframes 4163 -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_8s.mkv"

	echo Windowboxing BvS_8s.mkv
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_8s.mkv" -o "docs\temp\BvS_8s_Windowboxed.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 48900 --cfr -2 -w 3080 -l 1732 --crop-mode "none" --non-anamorphic --pad "width=3840:height=2160"

	echo Deleting BvS_8s.mkv
	del "docs\temp\BvS_8s.mkv"

	echo Spliting BvS_10s.mkv
	docs\programs\ffmpeg\ffmpeg -threads 0 -ss 02:54:43.862 -noaccurate_seek -i "docs\temp\BvS.mkv" -c:v copy -map v:0 -map_chapters -1 -map_metadata -1 -y "docs\temp\BvS_10s.mkv"

	echo Windowboxing BvS_10s.mkv
	docs\programs\handbrake\HandBrakeCLI -i "docs\temp\BvS_10s.mkv" -o "docs\temp\BvS_10s_Windowboxed.mkv" -e x265_10bit --encoder-preset "fast" --encoder-profile "auto" --encoder-level "auto" -b 30000 --cfr -2 -w 3080 -l 1732 --crop-mode "none" --non-anamorphic --pad "width=3840:height=2160"

	echo Deleting BvS_10s.mkv
	del "docs\temp\BvS_10s.mkv"

	echo Deleting BvS.mkv
	del "docs\temp\BvS.mkv"

	::Concatenating all 10 files
	echo Exporting...
	docs\programs\avidemux\avidemux_cli --load "docs\temp\BvS_1i.mkv" --append "docs\temp\BvS_2s_Windowboxed.mkv" --append "docs\temp\BvS_3i.mkv" --append "docs\temp\BvS_4s_Windowboxed.mkv" --append "docs\temp\BvS_5i.mkv" --append "docs\temp\BvS_6s_Windowboxed.mkv" --append "docs\temp\BvS_7i.mkv" --append "docs\temp\BvS_8s_Windowboxed.mkv" --append "docs\temp\BvS_9i.mkv" --append "docs\temp\BvS_10s_Windowboxed.mkv" --video-codec copy --audio-codec copy --output-format mkv --save "docs\temp\BvS_1.43.mkv"



	::Deleting 10 split files
	echo Deleting Leftover Files
	del "docs\temp\BvS_1i.mkv"
	del "docs\temp\BvS_2s_Windowboxed.mkv"
	del "docs\temp\BvS_3i.mkv"
	del "docs\temp\BvS_4s_Windowboxed.mkv"
	del "docs\temp\BvS_5i.mkv"
	del "docs\temp\BvS_6s_Windowboxed.mkv"
	del "docs\temp\BvS_7i.mkv"
	del "docs\temp\BvS_8s_Windowboxed.mkv"
	del "docs\temp\BvS_9i.mkv"
	del "docs\temp\BvS_10s_Windowboxed.mkv"



	::Merging altered video with source rip, keeping only video track of the first and all but video track of the latter for the output file
	echo Remuxing audio and subtitles
	docs\programs\mkvtoolnix\mkvmerge -o "!folder!\Batman v Superman Dawn of Justice Ultimate Edition IMAX 1.43 (unmasked).mkv" -A --no-audio -S --no-subtitles -B --no-buttons --no-chapters -M --no-attachments --no-global-tags "docs\temp\BvS_1.43.mkv" -D --no-video "%file%"
	
	endlocal
	
	::Deleting altered video with incorrect non-video tracks
	echo Deleting BvS_1.43.mkv
	del "docs\temp\BvS_1.43.mkv"
	
	
) else (
	::Loop if input is not valid
	echo %version% is not a valid input
	goto a
)

::Deleting all files in temp
echo Deleting any temp files before closing the session
cd "docs\temp\"
del *.* /F /Q

::Deleting temp folder
rmdir /s /q temp
cd ..
cd ..

echo Done!
PAUSE