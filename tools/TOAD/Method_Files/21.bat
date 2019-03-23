rem LOLLIPOP 5.0
:DeclareNewVariables
set FileCount=0
set Filename=
set StartDirectory=%cd%
set temp=
set temp2=
set TotalFileCount=0

::-----------------------------------------------------------------------------------------------------------------------------

:DeclareOldVariables
rem This batch file can access the variables set by TOAD itself. So please don't create any new variables that start "TOAD_" as this could cause a clash.
rem These variables already exist, so this section just serves as a reminder of what they are.
set TOAD_ABI=%TOAD_ABI%
rem TOAD_ABI is the type of processor your device uses (arm, arm64, ETC).
set TOAD_Address=%TOAD_Address%
rem This is the address of the single file that needs to be deodexed, if that's what we're doing.
set TOAD_DeodexErrors=%TOAD_DeodexErrors%
rem This variable tracks the number of files that don't deodex.
set TOAD_DeodexSuccesses=%TOAD_DeodexSuccesses%
rem This variable tracks the number of files that do deodex.
set TOAD_Extension=%TOAD_Extension%
rem This is the extension of the single file that needs to be deodexed, if that's what we're doing.
set TOAD_Filename=%TOAD_Filename%
rem This is the filename of the single file that needs to be deodexed, if that's what we're doing.
set TOAD_IncludeFramework=%TOAD_IncludeFramework%
rem TOAD_IncludeFramework says whether to include the 'framework' folder in the deodexing process.
set TOAD_SingleFile=%TOAD_SingleFile%
rem TOAD_SingleFile says whether to deodex a single file or the whole 'Your_Files' folder.

::-----------------------------------------------------------------------------------------------------------------------------

if %TOAD_SingleFile%==yes (goto ProcessSingleFile)
call Tool_Files\Display_Title 50 3
echo. Please wait...
rem This shows a blank screen with the title. The first number is the width of the window. The second number is the height (not including the title itself).

::-----------------------------------------------------------------------------------------------------------------------------

:CountODEXFiles
if %TOAD_IncludeFramework%==yes (
    set DirectoriesToProcess=app priv-app framework vendor\app vendor\priv-app vendor\framework
) else (
    set DirectoriesToProcess=app priv-app vendor\app vendor\priv-app vendor\framework
)
for %%a in (%DirectoriesToProcess%) do (
    if %%a==framework (
        set /a TotalFileCount+=1
		rem In Lollipop all the files within "boot.oat" can be processed with a single command. So this just increments 'TotalFileCount'.
    	if exist Your_Files\%%a\%TOAD_ABI%\*.odex (
            for /f %%b in ('dir /b/on Your_Files\%%a\%TOAD_ABI%\*.odex') do (
	            if exist Your_Files\%%a\%%~nb.jar (
                    set /a TotalFileCount+=1
			    )
		    )
	    )
	)
	if exist Your_Files\%%a\*.* (
        for /f %%b in ('dir /ad/b/on Your_Files\%%a') do (
	        if exist Your_Files\%%a\%%b\%TOAD_ABI%\%%b.odex (
                set /a TotalFileCount+=1
			)
		)
	)
	if %%a==vendor\framework (
		if exist Your_Files\%%a\oat\%TOAD_ABI%\*.odex (
        	for /f %%b in ('dir /b/on Your_Files\%%a\%TOAD_ABI%\*.odex') do (
		        if exist Your_Files\%%a\%%~nb.jar (
                	set /a TotalFileCount+=1
				)
			)
		)
	)
)
rem These lines will increment TotalFileCount for every APK or JAR we might be able to deodex

::-----------------------------------------------------------------------------------------------------------------------------

:ProcessODEXFiles
copy Tool_Files\updater-scriptBLANK Tool_Files\META-INF\com\google\android\updater-script >nul
java -Xmx1024m -jar Tool_Files\oat2dex.jar boot Your_Files\framework\%TOAD_ABI%\boat.oat>>log.txt
rem The above line creates a new updater-script which we'll be updating as we go along
:ProcessODEXFiles_APK
for %%a in (%DirectoriesToProcess%) do (
	if exist Your_Files\%%a\*.* (
    	for /f %%b in ('dir /ad/b/on Your_Files\%%a') do (
		    if exist Your_Files\%%a\%%b\%TOAD_ABI%\%%b.odex (
				call Tool_Files\Display_Title 100 6
				set /a FileCount+=1
				title TOAD [!FileCount!/%TotalFileCount%]
				echo. I'm now trying to process file !FileCount! of %TotalFileCount%:
		        echo.
		        echo.  "%%a\%%b.apk"
		        echo.
		        echo. Please wait, this may take a while.
				if exist Tool_Files\*.dex (
		    		del Tool_Files\*.dex /q >nul
				)
        		echo.>>log.txt
        		echo.----------->>log.txt
        		echo.>>log.txt
        		echo.Processing file !FileCount! of %TotalFileCount% - "Your_Files\%%a\%%b\%TOAD_ABI%\%%b.odex">>log.txt
				if not exist Tool_Files\system\%%a\%%b (
				    mkdir Tool_Files\system\%%a\%%b >nul
				)
				copy Your_Files\%%a\%%b\%%b.apk Tool_Files\system\%%a\%%b\ >nul
				java -Xmx1024m -jar Tool_Files\oat2dex.jar -o Tool_Files Your_Files\%%a\%%b\%TOAD_ABI%\%%b.odex Your_Files\framework>>log.txt
				if exist Tool_Files\%%b.dex (
				    set /a TOAD_DeodexSuccesses+=1
					rename Tool_Files\%%b.dex classes.dex >nul
					set temp=2
					if exist Tool_Files\%%b-classes*.dex (
					    for /f %%c in ('dir /b/on Tool_Files\%%b-classes*.dex') do (
						    rename Tool_Files\%%c classes!temp!.dex
							set /a temp+=1
						)
					)
                    cd Tool_Files
                    7za u -tzip %TOAD_StartDirectory%\Tool_Files\system\%%a\%%b\%%b.apk classes*.dex>>%TOAD_StartDirectory%\log.txt
                    7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
                    cd ..
                    echo.ui_print(" Deleting ODEX files for '%%a/%%b/'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.delete_recursive("/system/%%a/%%b/%TOAD_ABI%/"^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.ui_print(" Adding Deodexed '%%b.apk'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.package_extract_file("system/%%a/%%b/%%b.apk","/system/%%a/%%b"^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.set_perm_recursive(0, 0, 0755, 0644, "/system/%%a/%%b"^);>>Tool_Files\META-INF\com\google\android\updater-script
        		    del Tool_Files\*.dex /q >nul
				) else (
				    set /a TOAD_DeodexErrors+=1
					echo.>>log.txt
					echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
				)				    
   				rmdir Tool_Files\system /s/q >nul
			)
		)
	)
)
rem All the odexed APK files in "app", "priv-app", "framework", "vendor\app", "vendor\priv-app" and "vendor\framework" should now be deodexed inside the ZIP file.
rem Any APK file that didn't deodex has been left untouched.
:ProcessODEXFiles_Boot
rem "oat2dex.jar" should be able to process every JAR in the "framework" folder in one go, so this should be all we need.
if %TOAD_IncludeFramework%==yes (
    for %%a in (boot-jar-original boot-jar-with-dex boot-raw framework-jar-original framework-jar-with-dex framework-odex) do (
	    if exist Tool_Files\%%a\*.* (
		    rmdir Tool_Files\%%a /s/q >nul
		)
	)
	if not exist Tool_Files\system\framework (
	    mkdir Tool_Files\system\framework >nul
	)
    echo.>>log.txt
    echo.----------->>log.txt
    echo.>>log.txt
    echo.Processing all files in "Your_Files\framework">>log.txt
    call Tool_Files\Display_Title 100 4
    title TOAD [framework]
    echo. I'm now trying to process your "framework" folder.
    echo.
    echo. Please wait..
    java -Xmx1024m -jar Tool_Files\oat2dex.jar -a 22 -o Tool_Files devfw Your_Files\framework >>log.txt
    if %errorlevel%==0 (
        set /a TOAD_DeodexSuccesses+=1
		for %%a in (boot-jar-with-dex framework-jar-with-dex) do (
		    if exist Tool_Files\%%a\*.* (
    		    for /f %%b in ('dir /b/on Tool_Files\%%a\*.*') do (
                    echo.ui_print(" Deleting ODEX files for 'framework/%%b/'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.delete("/system/framework/%TOAD_ABI%/%%~nb.odex"^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.ui_print(" Adding Deodexed '%%b'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.package_extract_file("system/framework/%%b","/system/framework/"^);>>Tool_Files\META-INF\com\google\android\updater-script
                    move /y Tool_Files\%%a\%%b Tool_Files\system\framework >nul
			    )
                echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                echo.set_perm_recursive(0, 0, 0755, 0644, "/system/framework/"^);>>Tool_Files\META-INF\com\google\android\updater-script
			)
		)
        cd Tool_Files
        7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
        cd ..
	) else (
        set /a TOAD_DeodexErrors+=1
        echo.>>log.txt
        echo.ERROR!!!! DEODEXING FAILED!!!!>>log.txt
    )
    for %%a in (boot-jar-original boot-jar-with-dex boot-raw framework-jar-original framework-jar-with-dex framework-odex) do (
	    if exist Tool_Files\%%a\*.* (
		    rmdir Tool_Files\%%a /s/q >nul
		)
	)
)
goto ProcessODEXFILES_END

::-----------------------------------------------------------------------------------------------------------------------------

:ProcessSingleFile
copy Tool_Files\updater-scriptBLANK Tool_Files\META-INF\com\google\android\updater-script >nul
rem The above line creates a new updater-script which we'll be updating as we go along
java -Xmx1024m -jar Tool_Files\oat2dex.jar boot Your_Files\framework\%TOAD_ABI%\boat.oat>>log.txt
if %TOAD_Extension%==apk (
    :ProcessSingleFile_APK
    call Tool_Files\Display_Title 100 6
    title TOAD [%TOAD_Address%\%TOAD_Filename%.%TOAD_Extension%]
    echo. I'm now trying to process file:
    echo.
    echo.  "%TOAD_Address%\%TOAD_Filename%.%TOAD_Extension%"
    echo.
    echo. Please wait..
    if exist Tool_Files\*.dex (
	    del Tool_Files\*.dex /q >nul
	)
    if not exist Tool_Files\system\%TOAD_Address%\%TOAD_Filename% (
         mkdir Tool_Files\system\%TOAD_Address%\%TOAD_Filename% >nul
    )
    echo.>>log.txt
    echo.----------->>log.txt
    echo.>>log.txt
    echo.Processing file  - "Your_Files\%TOAD_Address%\%TOAD_Filename%\%TOAD_ABI%\%TOAD_Filename%.odex">>log.txt
	copy Your_Files\%TOAD_Address%\%TOAD_Filename%\%TOAD_Filename%.apk Tool_Files\system\%TOAD_Address%\%TOAD_Filename%\ >nul
    java -Xmx1024m -jar Tool_Files\oat2dex.jar -o Tool_Files Your_Files\%TOAD_Address%\%TOAD_Filename%\%TOAD_ABI%\%TOAD_Filename%.odex Your_Files\framework>>log.txt
	if exist Tool_Files\%TOAD_Filename%.dex (
	    set /a TOAD_DeodexSuccesses+=1
		rename Tool_Files\%TOAD_Filename%.dex classes.dex >nul
		set temp=2
		if exist Tool_Files\%TOAD_Filename%-classes*.dex (
		    for /f %%a in ('dir /b/on Tool_Files\%TOAD_Filename%-classes*.dex') do (
			    rename Tool_Files\%%a classes!temp!.dex
				set /a temp+=1
			)
		)
        cd Tool_Files
        7za u -tzip %TOAD_StartDirectory%\Tool_Files\system\%TOAD_Address%\%TOAD_Filename%\%TOAD_Filename%.apk classes*.dex>>%TOAD_StartDirectory%\log.txt
        7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
        cd ..
        echo.ui_print(" Deleting ODEX files for '%TOAD_Address%/%TOAD_Filename%.apk'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.delete_recursive("/system/%TOAD_Address%/%TOAD_Filename%/%TOAD_ABI%/"^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.ui_print(" Adding Deodexed '%TOAD_Filename%.apk'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.package_extract_file("system/%TOAD_Address%/%TOAD_Filename%/%TOAD_Filename%.apk","/system/%TOAD_Address%/%TOAD_Filename%"^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.set_perm_recursive(0, 0, 0755, 0644, "/system/%TOAD_Address%/%TOAD_Filename%"^);>>Tool_Files\META-INF\com\google\android\updater-script
	    del Tool_Files\*.dex /q >nul
	) else (
	    set /a TOAD_DeodexErrors+=1
		echo.>>log.txt
		echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
	)				    
	rmdir Tool_Files\system /s/q >nul
)
if %TOAD_Extension%==jar (
    :ProcessSingleFile_JAR
    call Tool_Files\Display_Title 100 6
    title TOAD [%TOAD_Address%\%TOAD_Filename%.%TOAD_Extension%]
    echo. I'm now trying to process file:
    echo.
    echo.  "%TOAD_Address%\%TOAD_Filename%.%TOAD_Extension%"
    echo.
    echo. Please wait..
    if exist Tool_Files\*.dex (
	    del Tool_Files\*.dex /q >nul
	)
    if not exist Tool_Files\system\%TOAD_Address%\ (
         mkdir Tool_Files\system\%TOAD_Address%\ >nul
    )
    echo.>>log.txt
    echo.----------->>log.txt
    echo.>>log.txt
    echo.Processing file  - "Your_Files\%TOAD_Address%\%TOAD_ABI%\%TOAD_Filename%.odex">>log.txt
	copy Your_Files\%TOAD_Address%\%TOAD_Filename%.jar Tool_Files\system\%TOAD_Address%\ >nul
    java -Xmx1024m -jar Tool_Files\oat2dex.jar -o Tool_Files Your_Files\%TOAD_Address%\%TOAD_ABI%\%TOAD_Filename%.odex Your_Files\framework>>log.txt
	if exist Tool_Files\%TOAD_Filename%.dex (
	    set /a TOAD_DeodexSuccesses+=1
		rename Tool_Files\%TOAD_Filename%.dex classes.dex >nul
		set temp=2
		if exist Tool_Files\%TOAD_Filename%-classes*.dex (
		    for /f %%a in ('dir /b/on Tool_Files\%TOAD_Filename%-classes*.dex') do (
			    rename Tool_Files\%%a classes!temp!.dex
				set /a temp+=1
			)
		)
        cd Tool_Files
        7za u -tzip %TOAD_StartDirectory%\Tool_Files\system\%TOAD_Address%\%TOAD_Filename%.jar classes*.dex>>%TOAD_StartDirectory%\log.txt
        7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
        cd ..
        echo.ui_print(" Deleting ODEX files for '%TOAD_Address%/%TOAD_Filename%.jar'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.delete_recursive("/system/%TOAD_Address%/%TOAD_ABI%/%TOAD_Filename%.odex"^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.ui_print(" Adding Deodexed '%TOAD_Filename%.jar'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.package_extract_file("system/%TOAD_Address%/%TOAD_Filename%.jar","/system/%TOAD_Address%/"^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.set_perm_recursive(0, 0, 0755, 0644, "/system/%TOAD_Address%/"^);>>Tool_Files\META-INF\com\google\android\updater-script
	    del Tool_Files\*.dex /q >nul
	) else (
	    set /a TOAD_DeodexErrors+=1
		echo.>>log.txt
		echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
	)				    
	rmdir Tool_Files\system /s/q >nul
)

::-----------------------------------------------------------------------------------------------------------------------------

:ProcessODEXFILES_END
if exist Your_Files\framework\odex (
    rmdir Your_Files\framework\odex /s/q >nul
)
if exist Your_Files\framework\dex (
    rmdir Your_Files\framework\dex /s/q >nul
)
rem We should now have a collection of fully deodexed APK and JAR files inside a ZIP file. Or a single APK and JAR in a ZIP, if that's what has been selected.
exit /b
