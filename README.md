This is a ready-to-go Windows batch script to convert GIF animations and WEBP animations to AVIF. To convert an animation to AVIF, this script uses a lossless intermediate format consisting of a series of temporary PNG files.

This Windows batch script can do the following:
- Convert animated GIF to animated AVIF
- Convert animated WEBP to animated AVIF
- Convert static GIF/WEBP image to static AVIF image.
- Optional: Convert static PNG/JPG/JPEG image to static AVIF image.
- Optional: For an animation: Add a suffix to output filename which indicates it is an animation.
- Optional: Automatically skip overwriting of existing files in the output directory.
- Optional: Preserve the file date and time of the input file in the output file.
- Optional: Make the output files read-only.
- Optional: Delete all existing files from the output directory when this script starts.
- Optional: Reduce the size (width x height) of a static image during conversion, if it is bigger than a specified maximum.
- See the beginning of the script (after "BEGINNING OF: USER SETTINGS") for these options.

Limitations of this script:
- Animations with unequal frame durations are not fully supported. After conversion, each frame will have the same duration and the total duration will be the same as in the original animation. 
- For animations, all metadata will be lost during the conversion process.

To use this script: 
- Download the file "Convert-animations-and-images-to-AVIF.bat". 
- Open this file in Notepad, locate the text after "BEGINNING OF: USER SETTINGS", and specify the input directory containing the image/animation files to be converted.
- In addition, change settings there if needed.
- Save the .bat file.
- Double-click the .bat file to run the script.

The output directory of this script is a subdirectory of its input directory. The output directory will be created if it does not exist. The name of the output directory is "Output to AVIF".

This script requires certain files to be present on the computer. The following programs should be available and their location should be added to PATH in the system environment variables of Windows:
- FFmpeg (only this file is required: ffmpeg.exe) — https://phoenixnap.com/kb/ffmpeg-windows
- ImageMagick (only this file is required: magick.exe) — https://imagemagick.org/script/download.php
- ExifTool (only this file is required: exiftool.exe) — https://oliverbetz.de/pages/Artikel/ExifTool-for-Windows
- NirCmd (only this file is required: nircmdc.exe) — Only needed for the option to preserve the file date and time. For this, download "NirCmd" from https://www.nirsoft.net/utils/nircmd.html and put "nircmdc.exe" in "C:\Windows".

Animated AVIF can be viewed in the Imagine freeware image & animation viewer for Windows — https://www.nyam.pe.kr/dev/imagine/
