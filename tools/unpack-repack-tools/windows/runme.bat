@ECHO off
title Android 7.x.x System Tools
setlocal enabledelayedexpansion 
if (%1)==(0) goto skipme
if (%1) neq () goto skipme  
echo  ============================================================================== >> log.log
echo  ==                        Android 7.x.x System Tools                        == >> log.log
echo  ==                             by Karan Sangaj                              == >> log.log
echo  ============================================================================== >> log.log
echo                          %date% -- %time%^ >> log.log                     >> log.log
Setup 0 2 >> log.log 
:error
:skipme
cd "%~dp0" 
if errorlevel 1 goto erradb
cls
:RESTART
cd "%~dp0"
set menunr=GARBAGE
cls    
echo  ==============================================================================
echo  ==                      Android 7.x.x System Tools                          ==
echo  ==                            by Karan Sangaj                               ==
echo  ==============================================================================
ECHO.  
ECHO  01 Main menu               
ECHO  02 Setup Directories                        
ECHO  00 Quit  
ECHO.
ECHO.       
SET /P menunr=Please make your decision: 
IF %menunr%==01 (goto MENU )
IF %menunr%==02 (goto SETDIR) 
IF %menunr%==00 (goto QUIT) 
 
 
  
:SETDIR 
mkdir output_converted_dat_to_ext4
mkdir output_converted_folder_to_ext4
mkdir place_dat_transfer_list_file_context_here   
mkdir extract_system_img_here 
cd extract_system_img_here
mkdir system
cd "%~dp0"  
PAUSE
GOTO RESTART
:MENU
set menunr=GARBAGE2
:home
cls
echo  ==============================================================================
echo  ==                                                                          ==
echo  ==                      Android 7.x.x System Tools                          ==
echo  ==                            by Karan Sangaj                               ==
echo  ==                                                                          ==
echo  ==============================================================================
echo.                                %date% 
echo  ==============================================================================
echo  IMG size: %temp_size%                             
echo  ==============================================================================
echo. 
echo  01 Enter size in bytes  
echo  02 Convert "system.new.dat" to "system.img".
echo  03 Unpack system.img 
echo  04 Repack "system" folder to "systemraw.img".
echo  05 Convert "systemraw.img" to "systemsparse.img".
echo  06 Convert "systemsparse.img" to "system.new.dat".  
echo  07 Clean All
ECHO  08 Return to Menu 
echo  00 Exit
echo.
set /p web=Type option:
if "%web%"=="01" goto size
if "%web%"=="02" goto dat2img
if "%web%"=="03" goto ext2dir 
if "%web%"=="04" goto dir2img
if "%web%"=="05" goto img2simg
if "%web%"=="06" goto simg2dat 
if "%web%"=="07" goto clean 
if "%web%"=="08" goto RESTART 
if "%web%"=="00" goto exit
goto home

:size
cls 
echo. 
del temp_size.txt
set /p temp_size=Enter size in bytes:  
echo %temp_size%>>temp_size.txt 
echo.  
cd "%~dp0"
pause
goto home 
 
:dat2img 
echo.
CLS
echo Extracting DAT file
echo.
tools\sdat2img.py place_dat_transfer_list_file_context_here\system.transfer.list place_dat_transfer_list_file_context_here\system.new.dat output_converted_dat_to_ext4\system.img
echo. 
echo Successfully Extracted!
cd "%~dp0"
pause
goto home

:ext2dir
CLS
tools\Ext4Extractor output_converted_dat_to_ext4\system.img extract_system_img_here\system -i
del extract_system_img_here\system\.journal
cd "%~dp0"
pause
goto home

:dir2img
CLS
tools\make_ext4fs -T 0 -S place_dat_transfer_list_file_context_here\file_contexts -l %temp_size% -a system output_converted_folder_to_ext4\my_new_system.img EXTRACT_system_img_here\system\
del temp_size.txt
cd "%~dp0"
pause
goto home

:img2simg
CLS
tools\img2simg output_converted_folder_to_ext4\my_new_system.img output_converted_folder_to_ext4\system.img
cd "%~dp0"
pause
goto home

:simg2dat
CLS
tools\img2sdat.py output_converted_folder_to_ext4\system.img
cd "%~dp0"
pause
goto home
 
:clean
CLS
echo.
echo Removing old files...
echo.
del log.log 
del temp_size.txt

rmdir /Q /S output_converted_dat_to_ext4
rmdir /Q /S output_converted_ext4_to_dat
rmdir /Q /S output_converted_folder_to_ext4 

rmdir /Q /S place_dat_transfer_list_file_context_here
rmdir /Q /S extract_system_img_here  
echo.
echo Done!...
echo.
cd "%~dp0"
pause
goto home