

@echo off
setlocal enabledelayedexpansion


rem Script to convert animations and images to AVIF format
rem Version 1.01

rem See "User Settings" below to set the input directory and to set the options.

rem This Windows batch script can do the following:
rem [1] Convert animated GIF to animated AVIF.
rem [2] Convert animated WEBP to animated AVIF.
rem [3] Convert static GIF/WEBP image to static AVIF image.
rem [4] Optional: Convert static PNG/JPG/JPEG image to static AVIF image.
rem [5] Optional: For an animation: Add a suffix to output filename which indicates it is an animation.
rem [6] Optional: Automatically skip overwriting of existing files in the output directory.
rem [7] Optional: Preserve the file date and time of the input file in the output file.
rem [8] Optional: Make the output files read-only.
rem [9] Optional: Delete all existing files from the output directory when this script starts.
rem [10] Optional: Reduce the size (width x height) of a static image during conversion, if it is bigger than a specified maximum.

rem This script requires certain files to be present on the computer. The following programs should be available and their location should be added to PATH in the system environment variables of Windows:
rem [1] FFmpeg (only this file is required: ffmpeg.exe) -- [https://phoenixnap.com/kb/ffmpeg-windows].
rem [2] ImageMagick (only this file is required: magick.exe) -- [https://imagemagick.org/script/download.php].
rem [3] ExifTool (only this file is required: exiftool.exe) -- [https://oliverbetz.de/pages/Artikel/ExifTool-for-Windows].
rem [4] NirCmd (only this file is required: nircmdc.exe) - Only needed for the option to preserve the file date and time. For this, download "NirCmd" from [https://www.nirsoft.net/utils/nircmd.html] and put "nircmdc.exe" in "C:\Windows".

rem Note: The output directory is a subdirectory of the input directory.
rem Note: The output directory will be created if it does not exist. 
rem Note: Limitation 1: Animations with unequal frame durations are not fully supported. After conversion, each frame will have the same duration and the total duration will be the same as in the original animation. 
rem Note: Limitation 2: For animations, all metadata will be lost during the conversion process.




rem BEGINNING OF: USER SETTINGS

rem [1] Path to the input directory containing your image/animation files that should be converted
set "input_dir=D:\Images to convert"
Rem Note: The output directory is by default a subdirectory of the input directory, which will be created if it doesn't exist
Rem Note: See below for the name of the output directory

rem [2] Decide whether or not to also convert JPG, JPEG, and PNG files to AVIF files
set "convert_jpg_jpeg_png=true"  Rem If true, also convert jpg, jpeg and png files
rem Note: GIF and WEBP files are converted by default to AVIF files

rem [3] Only for files that contain an animation: Decide whether or not to add a suffix to the output filename (indicating that it is an animation)
set "add_suffix=true"  Rem If true, add a suffix to the output file name of an animation
Rem Note: See below for the text of this suffix

rem [4] Decide whether or not to automatically skip overwriting of existing files in the output directory
set "always_skip_overwriting=false"  Rem If true, always automatically skip overwriting of existing files in the output directory
rem Note: If not true, users will be asked for each existing file whether to overwrite it or not

rem [5] Decide whether or not to always preserve the file date and time of the input file in the output file
set "keep_file_date_time=false"  Rem If true, keep file date and time of input file in output file

rem [6] Decide whether or not to always make each output file read-only
set "make_output_files_read_only=false"  Rem If true, make each output file read-only

rem [7] Decide whether or not to always delete all existing files from the output directory when this script starts
set "del_output_dir=false"  Rem If true, delete existing files from output directory when this script starts

rem [8] Decide whether or not to reduce the size of static images, if their area (width x height) is bigger than a specified maximum (see below for this maximum)
set "reduce_size_of_large_static_images=false"  Rem If true, reduce the size of large static images
rem Note: The size of an image will be reduced to just under the specified maximum

rem [9] If reducing the size of static images, decide what their maximum allowed area (width x height) is
set "max_area=2073600"  rem Example value: 2073600 (= 1920 x 1080)
rem Note: If an image is just over the maximum, its size will not be reduced

rem END OF: USER SETTINGS




rem Path to the output directory for your converted image/animation files
set "output_dir=!input_dir!\Output to AVIF"  Rem Output directory is subdirectory of input directory

rem Notify conversion starting
echo Conversion starting...

rem Check for required programs
set "missing_programs="
set "missing_count=0"

for %%p in (ffmpeg magick exiftool) do (
where %%p >nul 2>&1
if errorlevel 1 (
if "!missing_programs!"=="" (
set "missing_programs=%%p.exe"
) else (
set "missing_programs=!missing_programs!, %%p.exe"
)
set /a missing_count+=1
)
)

rem Display error message if required program is not available
if not "!missing_programs!"=="" (
echo.
if !missing_count! gtr 1 (
echo Error: The following required programs are not available: !missing_programs!
echo Please ensure these programs are installed and available in the PATH.
) else (
echo Error: The following required program is not available: !missing_programs!
echo Please ensure this program is installed and available in the PATH.
)
echo.
goto :end
)

rem Check for the program nircmdc.exe
if /i "!keep_file_date_time!"=="true" (
where nircmdc >nul 2>&1
if errorlevel 1 (
set "continue=N"   rem Initialize continue
echo Warning: The program nircmdc.exe is not available. The file date and time of the input file will not be preserved in the output file.
set /p "continue=Continue? [y/N]: "
if /i "!continue!" neq "y" (
goto :end
)
)
)

rem Check if the output directory exists
if exist "!output_dir!" (
if /i "!del_output_dir!"=="true" (
rem Remove the output directory and all its contents
rmdir /s /q "!output_dir!"
)
)

rem Create the output directory if it does not exist
if not exist "!output_dir!" (
mkdir "!output_dir!"
)

rem Set text to append to output files that contain an animation
if /i "!add_suffix!"=="true" (
set "ani_suffix= [ANI]"
rem Determine the length of the suffix
for /l %%i in (12,1,100) do if "!ani_suffix:~%%i,1!"=="" set "ani_suffix_length=%%i" & goto :suffix_length_determined
)
:suffix_length_determined

rem Define temporary subdirectory in the temp folder
set "temp_dir=%TEMP%\gif_webp_temp"
if not exist !temp_dir! mkdir !temp_dir!

rem Count total number of relevant files
set "count=0"
for %%f in ("!input_dir!\*.gif") do (set /a count+=1)
for %%f in ("!input_dir!\*.webp") do (set /a count+=1)
if /i "!convert_jpg_jpeg_png!"=="true" (
for %%f in ("!input_dir!\*.jpg" "!input_dir!\*.jpeg" "!input_dir!\*.png") do (set /a count+=1)
)

rem Initialize progress counter
set "current=0"

rem Initialize input_files_found
set "input_files_found=false"


rem START PROCESSING OF GIF FILES

rem Loop through all gif files in the input directory
for %%f in ("!input_dir!\*.gif") do (
set "filename=%%~nf"
set "extension=%%~xf"
set /a current+=1
set "input_files_found=true"

rem Store the input file name and path in a new variable
set "input_file=%%f"

rem Convert file to a series of png files in temp directory using ImageMagick (suppress messages)
magick "!input_file!" -coalesce "!temp_dir!\!filename!_frame_%%03d.png" 2>NUL

rem Check if there are any png files in the temp directory
dir /b "!temp_dir!\!filename!_frame_*.png" >nul 2>&1
if errorlevel 1 (
set "frames=0"
) else (
rem Count the number of png files in the temp directory to determine the number of frames
for /f %%b in ('dir /b "!temp_dir!\!filename!_frame_*.png" ^| find /c /v ""') do set "frames=%%b"
)

if "!frames!" == "0" (
rem Unable to extract frames from this file
echo !current! of !count! - GIF - !filename! - FILE [PARTIALLY] CORRUPT - CONVERSION FAILED

rem Create output filename with error indication
set "output_filename=!filename! [[[[[[ERROR]]]]]]"

if not exist "!output_dir!\!output_filename!.avif" (
rem Create empty .avif file in the output directory as a warning that the conversion has failed
type nul > "!output_dir!\!output_filename!.avif"
if /i "!keep_file_date_time!"=="true" (nircmdc clonefiletime "!input_file!" "!output_dir!\!output_filename!.avif" >nul 2>&1)
if /i "!make_output_files_read_only!"=="true" (attrib +r "!output_dir!\!output_filename!.avif")
)

) else (

rem If the number of frames is greater than one, then the file is an animation
if !frames! gtr 1 (


rem BEGINNING OF: PROCESS GIF ANIMATION

rem BEGINNING OF: DETERMINE DURATION AND FRAMERATE

rem Read the duration of the file using ExifTool (suppress warnings)
for /f "tokens=*" %%i in ('exiftool -Duration "!input_file!" 2^>nul') do set "duration=%%i"

rem Beginning of cleanup to get duration in milliseconds
rem If the duration is an empty string, set its value to zero
if "!duration!"=="" (
set "duration=0"
) else (
rem Remove "Duration                        : " from the variable
set "duration=!duration:Duration                        : =!"
rem Remove " s" from the variable
set "duration=!duration: s=!"
rem Remove the period from the variable
set "duration=!duration:.=!"
rem Check if the variable starts with a zero. If it does, remove this zero
if "!duration:~0,1!" == "0" set "duration=!duration:~1!"
rem Add "0" to the end of the variable. After this, the duration is expressed in milliseconds.
set "duration=!duration!0"
rem Check if the value of the variable is valid. If not, set its value to zero
rem Check if the variable now contains only digits. If not, set its value to zero
for /f "delims=0123456789" %%a in ("!duration!") do (set "duration=0")
)
rem Store the duration in milliseconds in a new variable
set "duration_ms=!duration!"
rem End of cleanup to get duration in milliseconds

rem Calculate the framerate from the duration and number of frames
rem Note: duration_ms is in milliseconds, which is 1000 times smaller than seconds
if !duration_ms! neq 0 (
set /a "framerate=(frames * 1000) / duration_ms"
rem Use remainder to improve rounding of framerate (if necessary)
set /a "remainder=(frames * 1000) %% duration_ms"
set /a "half_duration=duration_ms / 2"
if !remainder! geq !half_duration! (set /a framerate+=1)
)

Rem Set initial values
set "add_warning_suffix=false"
set "duration_is_unknown=false"

rem In a partially corrupted file, the read duration in milliseconds may be too low or negative
rem In a partially corrupted file, the calculated frame rate may be too low or negative
if !duration_ms! lss 8 (
set "result=problem"
) else if !framerate! lss 3 (
set "result=problem"
) else (
set "result=no_problem"
)
if "!result!"=="problem" (
set "framerate=14"  rem Default to 14 fps, if duration is less than 8 ms or framerate is less than 3 fps
set "add_warning_suffix=true"
set "duration_is_unknown=true"
set "warning_suffix= [[[WARNING - Duration may differ from original]]]"
)

rem END OF: DETERMINE DURATION AND FRAMERATE

rem Notify file being processed
if /i "!duration_is_unknown!"=="true" (
echo !current! of !count! - GIF - !filename! - !frames! ... !framerate! [frames, duration in ms, framerate] - Duration could not be determined, framerate set to default
) else (
echo !current! of !count! - GIF - !filename! - !frames! !duration_ms! !framerate! [frames, duration in ms, framerate]
)

rem If add_suffix is true and filename does not already end with ani_suffix, add it
if /i "!add_suffix!"=="true" (
if "!filename:~-!ani_suffix_length!!" neq "!ani_suffix!" (
set "output_filename=!filename!!ani_suffix!"
) else (
set "output_filename=!filename!"
)
) else (
set "output_filename=!filename!"
)

rem Add warning_suffix for exceptional cases (see above)
if /i "!add_warning_suffix!"=="true" (
set "output_filename=!output_filename!!warning_suffix!"
)

rem Check whether to always automatically skip overwriting of existing files in the output directory
set "skip_automatically=false"
if exist "!output_dir!\!output_filename!.avif" (
if /i "!always_skip_overwriting!"=="true" (
echo       Automatically skipping existing file: !output_filename!.avif
set "skip_automatically=true"
)
)

rem Decide whether to convert a series of png files to an animated avif
rem If conditions are met, do the conversion
call :decide_whether_to_convert_png_files_to_animated_avif

rem Delete the temporary png files
del "!temp_dir!\!filename!_frame_*.png"

) else (

rem END OF: PROCESS GIF ANIMATION


rem BEGINNING OF: PROCESS STATIC GIF IMAGE

rem Here, the number of frames is equal to one
rem If the number of frames is equal to one, then the file is a static image

rem Get width and height of the current static gif using ImageMagick
for /f "tokens=1,2 delims= " %%d in ('magick identify -format "%%w %%h" "!input_file!"') do (
set "width=%%d"
set "height=%%e"
)

rem Set initial values
set "reduce_image_area_size=false"
set "new_width=!width!"
set "new_height=!height!"

rem Call the subroutine to decide whether to reduce the area (width x height) of the current image, and if so, calculate new dimensions (new_width, new_height)
call :calculate_dimensions

rem Notify file being processed
if /i "!reduce_image_area_size!"=="true" (
echo !current! of !count! - GIF - !filename! - !width!x!height! - Reduced to !new_width!x!new_height!
) else (
echo !current! of !count! - GIF - !filename! - !width!x!height!
)

rem Set filename for output
set "output_filename=!filename!"

rem Add reduction_suffix if size of image area will be reduced
if /i "!reduce_image_area_size!"=="true" (
set "reduction_suffix= [REDUCED]"
set "output_filename=!filename!!reduction_suffix!"
)

rem Check whether to always automatically skip overwriting of existing files in the output directory
set "skip_automatically=false"
if exist "!output_dir!\!output_filename!.avif" (
if /i "!always_skip_overwriting!"=="true" (
echo       Automatically skipping existing file: !output_filename!.avif
set "skip_automatically=true"
)
)

rem Convert static image to avif if conditions are met
call :decide_whether_to_convert_static_image_to_avif
)
)
)

rem END OF: PROCESS STATIC GIF IMAGE


rem START PROCESSING OF WEBP FILES

rem Loop through all webp files in the input directory
for %%f in ("!input_dir!\*.webp") do (
set "filename=%%~nf"
set "extension=%%~xf"
set /a current+=1
set "input_files_found=true"

rem Store the input file name and path in a new variable
set "input_file=%%f"

rem Convert file to a series of png files in temp directory using ImageMagick (suppress messages)
magick "!input_file!" -coalesce "!temp_dir!\!filename!_frame_%%03d.png" 2>NUL

rem Check if there are any png files in the temp directory
dir /b "!temp_dir!\!filename!_frame_*.png" >nul 2>&1
if errorlevel 1 (
set "frames=0"
) else (
rem Count the number of png files in the temp directory to determine the number of frames
for /f %%b in ('dir /b "!temp_dir!\!filename!_frame_*.png" ^| find /c /v ""') do set "frames=%%b"
)

if "!frames!" == "0" (
rem Unable to extract frames from this file
echo !current! of !count! - GIF - !filename! - FILE [PARTIALLY] CORRUPT - CONVERSION FAILED

rem Create output filename with error indication
set "output_filename=!filename! [[[[[[ERROR]]]]]]"

if not exist "!output_dir!\!output_filename!.avif" (
rem Create empty .avif file in the output directory as a warning that the conversion has failed
type nul > "!output_dir!\!output_filename!.avif"
if /i "!keep_file_date_time!"=="true" (nircmdc clonefiletime "!input_file!" "!output_dir!\!output_filename!.avif" >nul 2>&1)
if /i "!make_output_files_read_only!"=="true" (attrib +r "!output_dir!\!output_filename!.avif")
)

) else (

rem If the number of frames is greater than one, then the file is an animation
if !frames! gtr 1 (


rem BEGINNING OF: PROCESS WEBP ANIMATION

rem BEGINNING OF: DETERMINE DURATION AND FRAMERATE

rem Read the duration of the file using ExifTool (suppress warnings)
for /f "tokens=*" %%i in ('exiftool -Duration "!input_file!" 2^>nul') do set "duration=%%i"

rem Beginning of cleanup to get duration in milliseconds
rem If the duration is an empty string, set its value to zero
if "!duration!"=="" (
set "duration=0"
) else (
rem Remove "Duration                        : " from the variable
set "duration=!duration:Duration                        : =!"
rem Remove " s" from the variable
set "duration=!duration: s=!"
rem Remove the period from the variable
set "duration=!duration:.=!"
rem Check if the variable starts with a zero. If it does, remove this zero
if "!duration:~0,1!" == "0" set "duration=!duration:~1!"
rem Add "0" to the end of the variable. After this, the duration is expressed in milliseconds.
set "duration=!duration!0"
rem Check if the value of the variable is valid. If not, set its value to zero
rem Check if the variable now contains only digits. If not, set its value to zero
for /f "delims=0123456789" %%a in ("!duration!") do (set "duration=0")
)
rem Store the duration in milliseconds in a new variable
set "duration_ms=!duration!"
rem End of cleanup to get duration in milliseconds

rem Calculate the framerate from the duration and number of frames
rem Note: duration_ms is in milliseconds, which is 1000 times smaller than seconds
if !duration_ms! neq 0 (
set /a "framerate=(frames * 1000) / duration_ms"
rem Use remainder to improve rounding of framerate (if necessary)
set /a "remainder=(frames * 1000) %% duration_ms"
set /a "half_duration=duration_ms / 2"
if !remainder! geq !half_duration! (set /a framerate+=1)
)

Rem Set initial values
set "add_warning_suffix=false"
set "duration_is_unknown=false"

rem In a partially corrupted file, the read duration in milliseconds may be too low or negative
rem In a partially corrupted file, the calculated frame rate may be too low or negative
if !duration_ms! lss 8 (
set "result=problem"
) else if !framerate! lss 3 (
set "result=problem"
) else (
set "result=no_problem"
)
if "!result!"=="problem" (
set "framerate=14"  rem Default to 14 fps, if duration is less than 8 ms or framerate is less than 3 fps
set "add_warning_suffix=true"
set "duration_is_unknown=true"
set "warning_suffix= [[[WARNING - Duration may differ from original]]]"
)

rem END OF: DETERMINE DURATION AND FRAMERATE

rem Notify file being processed
if /i "!duration_is_unknown!"=="true" (
echo !current! of !count! - WEBP - !filename! - !frames! ... !framerate! [frames, duration in ms, framerate] - Duration could not be determined, framerate set to default
) else (
echo !current! of !count! - WEBP - !filename! - !frames! !duration_ms! !framerate! [frames, duration in ms, framerate]
)

rem If add_suffix is true and filename does not already end with ani_suffix, add it
if /i "!add_suffix!"=="true" (
if "!filename:~-!ani_suffix_length!!" neq "!ani_suffix!" (
set "output_filename=!filename!!ani_suffix!"
) else (
set "output_filename=!filename!"
)
) else (
set "output_filename=!filename!"
)

rem Add warning_suffix for exceptional cases (see above)
if /i "!add_warning_suffix!"=="true" (
set "output_filename=!output_filename!!warning_suffix!"
)

rem Check whether to always automatically skip overwriting of existing files in the output directory
set "skip_automatically=false"
if exist "!output_dir!\!output_filename!.avif" (
if /i "!always_skip_overwriting!"=="true" (
echo       Automatically skipping existing file: !output_filename!.avif
set "skip_automatically=true"
)
)

rem Decide whether to convert a series of png files to an animated avif
rem If conditions are met, do the conversion
call :decide_whether_to_convert_png_files_to_animated_avif

rem Delete the temporary png files
del "!temp_dir!\!filename!_frame_*.png"

) else (

rem END OF: PROCESS WEBP ANIMATION


rem BEGINNING OF: PROCESS STATIC WEBP IMAGE

rem Here, the number of frames is equal to one
rem If the number of frames is equal to one, then the file is a static image

rem Get width and height of the current static webp using ImageMagick
for /f "tokens=1,2 delims= " %%d in ('magick identify -format "%%w %%h" "!input_file!"') do (
set "width=%%d"
set "height=%%e"
)

rem Set initial values
set "reduce_image_area_size=false"
set "new_width=!width!"
set "new_height=!height!"

rem Call the subroutine to decide whether to reduce the area (width x height) of the current image, and if so, calculate new dimensions (new_width, new_height)
call :calculate_dimensions

rem Notify file being processed
if /i "!reduce_image_area_size!"=="true" (
echo !current! of !count! - WEBP - !filename! - !width!x!height! - Reduced to !new_width!x!new_height!
) else (
echo !current! of !count! - WEBP - !filename! - !width!x!height!
)

rem Set filename for output
set "output_filename=!filename!"

rem Add reduction_suffix if size of image area will be reduced
if /i "!reduce_image_area_size!"=="true" (
set "reduction_suffix= [REDUCED]"
set "output_filename=!filename!!reduction_suffix!"
)

rem Check whether to always automatically skip overwriting of existing files in the output directory
set "skip_automatically=false"
if exist "!output_dir!\!output_filename!.avif" (
if /i "!always_skip_overwriting!"=="true" (
echo       Automatically skipping existing file: !output_filename!.avif
set "skip_automatically=true"
)
)

rem Convert static image to avif if conditions are met
call :decide_whether_to_convert_static_image_to_avif
)
)
)

rem END OF: PROCESS STATIC WEBP IMAGE


rem Remove the temporary subdirectory
rmdir /s /q !temp_dir!


rem BEGINNING OF: PROCESS JPG, JPEG, AND PNG IMAGE

rem Check if also to convert jpg, jpeg, and png files to avif files
if /i "!convert_jpg_jpeg_png!"=="true" (

rem Loop through all jpg, jpeg, and png files in the input directory
for %%f in ("!input_dir!\*.jpg" "!input_dir!\*.jpeg" "!input_dir!\*.png") do (
set "filename=%%~nf"
set "extension=%%~xf"
set /a current+=1
set "input_files_found=true"

rem Store the input file name and path in a new variable
set "input_file=%%f"

rem Get width and height of the current image file using ImageMagick
for /f "tokens=1,2 delims= " %%d in ('magick identify -format "%%w %%h" "!input_file!"') do (
set "width=%%d"
set "height=%%e"
)

rem Set initial values
set "reduce_image_area_size=false"
set "new_width=!width!"
set "new_height=!height!"

rem Call the subroutine to decide whether to reduce the area (width x height) of the current image, and if so, calculate new dimensions (new_width, new_height)
call :calculate_dimensions

rem Notify file being processed
if /i "!reduce_image_area_size!"=="true" (
if /i "!extension!"==".jpg" (
echo !current! of !count! - JPG - !filename! - !width!x!height! - Reduced to !new_width!x!new_height!
) else if /i "!extension!"==".jpeg" (
echo !current! of !count! - JPEG - !filename! - !width!x!height! - Reduced to !new_width!x!new_height!
) else if /i "!extension!"==".png" (
echo !current! of !count! - PNG - !filename! - !width!x!height! - Reduced to !new_width!x!new_height!
)
) else (
if /i "!extension!"==".jpg" (
echo !current! of !count! - JPG - !filename! - !width!x!height!
) else if /i "!extension!"==".jpeg" (
echo !current! of !count! - JPEG - !filename! - !width!x!height!
) else if /i "!extension!"==".png" (
echo !current! of !count! - PNG - !filename! - !width!x!height!
)
)

rem Set filename for output
set "output_filename=!filename!"

rem Add reduction_suffix if size of image area will be reduced
if /i "!reduce_image_area_size!"=="true" (
set "reduction_suffix= [REDUCED]"
set "output_filename=!filename!!reduction_suffix!"
)

rem Check whether to always automatically skip overwriting of existing files in the output directory
set "skip_automatically=false"
if exist "!output_dir!\!output_filename!.avif" (
if /i "!always_skip_overwriting!"=="true" (
echo       Automatically skipping existing file: !output_filename!.avif
set "skip_automatically=true"
)
)

rem Convert static image to avif if conditions are met
call :decide_whether_to_convert_static_image_to_avif
)

rem END OF: PROCESS JPG, JPEG, AND PNG IMAGE


rem BEGINNING OF: ADD ERROR MESSAGE TO ZERO BYTES FILES

rem Add an error message to the names of files in the output directory that are zero bytes in size (if the two conditions below are met)
rem Note: The conversion of partially corrupted files, may result in files that are zero bytes in size
for %%A in ("!output_dir!\*.*") do (
if %%~zA == 0 (
set "filename=%%~nA"
set "extension=%%~xA"

rem [1] Do not add " [[[[[[ERROR]]]]]]" to filenames that already end with " [[[[[[ERROR]]]]]]"
rem Check if the last 18 characters of the filename are " [[[[[[ERROR]]]]]]"
set "last18=!filename:~-18!"
if "!last18!" neq " [[[[[[ERROR]]]]]]" (
set "testname=!filename! [[[[[[ERROR]]]]]]!extension!"

rem [2] Do not add " [[[[[[ERROR]]]]]]" to a filename, if this results in a filename that already exists
rem Check if the new name already exists in the output directory
if not exist "!output_dir!\!testname!" (

rem Rename the file only if both conditions are met, but first remove a warning if one exists
rem Check if the filename ends with " [[[WARNING - Duration may differ from original]]]"
set "last50=!filename:~-50!"
if "!last50!"==" [[[WARNING - Duration may differ from original]]]" (
rem Remove " [[[WARNING - Duration may differ from original]]]" from the filename
set "filename=!filename:~0,-50!"
)

rem Rename the file only if both conditions are met
set "newname=!filename! [[[[[[ERROR]]]]]]!extension!"
rem Renaming "%%A" to "!newname!"
ren "%%A" "!newname!"

) else (
rem echo File "!newname!" already exists. Skipping renaming.
)
) else (
rem echo File "%%A" already contains the error message. Skipping renaming.
)
)
)

rem END OF: ADD ERROR MESSAGE TO ZERO BYTES FILES


if "!input_files_found!"=="false" (
echo.
echo No relevant image/animation files found in the input directory. Please set the input directory with your image/animation files in this script [do this after "BEGINNING OF: USER SETTINGS" in this script], and/or place relevant image/animation files in the input directory.
echo.
)


goto :end



rem BEGINNING OF: Subroutine to decide whether to convert a series of png files to an animated avif
:decide_whether_to_convert_png_files_to_animated_avif
rem Convert the series of png files to an animated avif using the calculated framerate
rem Only write file if it doesn't exist or if permission to write is given and existing file is not read-only
if /i "!skip_automatically!"=="false" (
rem ----------------------------------------
rem Check if file exists in output directory
if exist "!output_dir!\!output_filename!.avif" (
set "confirm=N"   rem Initialize confirm
<nul set /p="_____ File "!output_filename!.avif" already exists. Overwrite? [y/N] "
set /p confirm=
if /i "!confirm!"=="" set "confirm=N"    rem Pressing Enter is here equivalent to entering "N".
if /i "!confirm!"=="y" (
rem ----------------------------------------
rem Check if file is read-only
call :is_readonly "!output_dir!\!output_filename!.avif"
if defined readonly (
echo       Permission to overwrite is denied, because existing file is read-only
echo       Skipping file: !output_filename!.avif
rem ----------------------------------------
) else (
echo       Overwriting file: !output_filename!.avif
rem Convert a series of png files to an animated avif using FFmpeg
call :convert_png_files_to_animated_avif
)
rem ----------------------------------------
) else (
echo       Skipping file: !output_filename!.avif
)
rem ----------------------------------------
) else (
rem Convert a series of png files to an animated avif using FFmpeg
call :convert_png_files_to_animated_avif
)
)
exit /b
rem END OF: Subroutine to decide whether to convert a series of png files to an animated avif


rem BEGINNING OF: Subroutine to convert a series of png files to an animated avif using FFmpeg
:convert_png_files_to_animated_avif
rem Convert series of png files to avif animation using FFmpeg
ffmpeg -y -framerate !framerate! -i "!temp_dir!\!filename!_frame_%%03d.png" -c:v libaom-av1 -cpu-used 8 -pix_fmt yuv420p -loglevel error "!output_dir!\!output_filename!.avif"
rem ----------------------------------------
if /i "!keep_file_date_time!"=="true" (nircmdc clonefiletime "!input_file!" "!output_dir!\!output_filename!.avif" >nul 2>&1)
if /i "!make_output_files_read_only!"=="true" (attrib +r "!output_dir!\!output_filename!.avif")
exit /b
rem END OF: Subroutine to convert a series of png files to an animated avif using FFmpeg


rem BEGINNING OF: Subroutine to decide whether to convert static image to avif
:decide_whether_to_convert_static_image_to_avif
rem Convert static image to avif if conditions are met
rem Only write file if it doesn't exist or if permission to write is given and existing file is not read-only
if /i "!skip_automatically!"=="false" (
rem ----------------------------------------
rem Check if file exists in output directory
if exist "!output_dir!\!output_filename!.avif" (
set "confirm=N"   rem Initialize confirm
<nul set /p="_____ File "!output_filename!.avif" already exists. Overwrite? [y/N] "
set /p confirm=
if /i "!confirm!"=="" set "confirm=N"    rem Pressing Enter is here equivalent to entering "N".
if /i "!confirm!"=="y" (
rem ----------------------------------------
rem Check if file is read-only
call :is_readonly "!output_dir!\!output_filename!.avif"
if defined readonly (
echo       Permission to overwrite is denied, because existing file is read-only
echo       Skipping file: !output_filename!.avif
rem ----------------------------------------
) else (
echo       Overwriting file: !output_filename!.avif
rem Convert a static image to avif using ImageMagick
call :convert_static_image_to_avif
)
rem ----------------------------------------
) else (
echo       Skipping file: !output_filename!.avif
)
rem ----------------------------------------
) else (
rem Convert a static image to avif using ImageMagick
call :convert_static_image_to_avif
)
)
)
)
exit /b
rem END OF: Subroutine to decide whether to convert static image to avif


rem BEGINNING OF: Subroutine to convert static image to avif using ImageMagick
:convert_static_image_to_avif
if /i "!reduce_image_area_size!"=="true" (
rem Convert static image to avif and resize using ImageMagick
magick "!input_file!" -resize !new_width!x!new_height! -define heic:speed=5 "!output_dir!\!output_filename!.avif"
rem ----------------------------------------
) else (
rem Convert static image to avif using ImageMagick
magick "!input_file!" -define heic:speed=5 "!output_dir!\!output_filename!.avif"
rem ----------------------------------------
)
if /i "!keep_file_date_time!"=="true" (nircmdc clonefiletime "!input_file!" "!output_dir!\!output_filename!.avif" >nul 2>&1)
if /i "!make_output_files_read_only!"=="true" (attrib +r "!output_dir!\!output_filename!.avif")
exit /b
rem END OF: Subroutine to convert static image to avif using ImageMagick


rem BEGINNING OF: Subroutine to check if a file is read-only
:is_readonly
set "readonly="
rem echo Checking file: "%~1"
for /f "tokens=*" %%A in ('attrib "%~1"') do (
set "attrib_output=%%A"
)
set "attrib_output=%attrib_output:~0,13%"
rem echo Attrib output: "%attrib_output%"
if "%attrib_output%"=="%attrib_output:R=%" (
rem echo No "R" found in attrib output.
) else (
set "readonly=true"
)
exit /b
rem END OF: Subroutine to check if a file is read-only


rem BEGINNING OF: Subroutine to decide whether to reduce the area (width x height) of the current image, and if so, calculate new dimensions (new_width, new_height)
:calculate_dimensions

rem BEGINNING OF: DECIDE WHETHER TO REDUCE AREA OF IMAGE (IF SIGNIFICANT DIFFERENCE)
rem Check whether to reduce the area (width x height) of large images during conversion to avif

rem Calculate the area of the image
set /a area=!width!*!height!

rem Compare area to max_area
if !area! gtr !max_area! (
set "area_greater_than_max_area=true"
) else (
set "area_greater_than_max_area=false"
)

rem Check whether to reduce the area (width x height) of the image
rem Will only reduce area of image, if relative difference with max_area is significant
set "reduce_image_area_size_if_difference_is_significant=false" rem Initial value
if /i "!reduce_size_of_large_static_images!"=="true" (
if /i "!area_greater_than_max_area!"=="true" (
set "reduce_image_area_size_if_difference_is_significant=true"
)
)

rem END OF: DECIDE WHETHER TO REDUCE AREA OF IMAGE (IF SIGNIFICANT DIFFERENCE)

rem BEGINNING OF: CALCULATE SCALE FACTOR TIMES THOUSAND

if /i "!reduce_image_area_size_if_difference_is_significant!"=="true" (
rem The intention is to calculate this: scale_factor_times_thousand=1000*sqrt(!max_area!/!area!)
rem However, a Windows batch script cannot calculate a square root directly, so it cannot be calculated in this way
rem Therefore, the square root will calculated by an iterative approximation method
rem The multiplication by 1000 and extra calculation steps, are due to the limited computational capabilities of a Windows batch script

rem First preparation step to calculate square root
set /a thousand_times_division=1000*!max_area!/!area!

rem Second preparation step to calculate square root
set /a million_times_division=1000*!thousand_times_division!

rem Note: The scale_factor_times_thousand to be calculated, is equal to the square root of million_times_division

rem This is the number for which to calculate the square root
set /a number=million_times_division

rem Initialize variables for iterative method
set /a guess=number / 2
set /a epsilon=1
set /a diff=number

rem Calculate the square root using an iterative method
call :iterate

rem Store the iteratively calculated square root in scale_factor_times_thousand
set /a scale_factor_times_thousand=guess

rem END OF: CALCULATE SCALE FACTOR TIMES THOUSAND

rem Very small relative differences between area and max_area will be ignored
rem Only reduce image, if value of scale_factor_times_thousand is less than 985
rem Note: A value of scale_factor_times_thousand of 985, equals 98.5% of max_area
if !scale_factor_times_thousand! lss 985 (

set "reduce_image_area_size=true"

rem BEGINNING OF: CALCULATE NEW WIDTH AND NEW HEIGHT

rem Note: Later the area of the image will be reduced to become smaller than the maximum area
rem Use scale factor (x 1000) to calculate new_width (x 1000) and new_height (x 1000)
set /a new_width_times_thousand=!width!*!scale_factor_times_thousand!
set /a new_height_times_thousand=!height!*!scale_factor_times_thousand!

rem Calculate new_width
set /a new_width=!new_width_times_thousand!/1000
rem Use remainder to improve rounding of new_width (if necessary)
set /a remainder=!new_width_times_thousand! %% 1000
set /a half_divisor=1000 / 2
if !remainder! geq !half_divisor! (set /a new_width+=1)

rem Calculate new_height
set /a new_height=!new_height_times_thousand!/1000
rem Use remainder to improve rounding of new_height (if necessary)
set /a remainder=!new_height_times_thousand! %% 1000
set /a half_divisor=1000 / 2
if !remainder! geq !half_divisor! (set /a new_height+=1)
) 
)

rem END OF: CALCULATE NEW WIDTH AND NEW HEIGHT
exit /b
rem END OF: Subroutine to decide whether to reduce the area (width x height) of the current image, and if so, calculate dimensions (new_width, new_height)


rem BEGINNING OF: Subroutine to calculate the square root of a number using an iterative method 
rem This code has been placed outside of any loop to prevent unwanted changes to the value of variables in a loop.
:iterate
set /a guess_plus_number_devided_by_guess = guess + number / guess
set /a new_guess=guess_plus_number_devided_by_guess / 2
set /a diff=new_guess - guess
if !diff! lss 0 set /a diff=-!diff!
set /a guess=new_guess
if !diff! gtr !epsilon! goto iterate
exit /b
rem END OF: Subroutine to calculate the square root of a number using an iterative method


:end

endlocal
echo Conversion complete
pause



