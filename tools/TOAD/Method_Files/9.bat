rem GINGERBREAD 2.3 - 2.3.2
:DeclareNewVariables
set FileCount=0
set Filename=
set StartDirectory=%cd%
set temp=
set temp2=0
set temp3=0
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

if %TOAD_SingleFile%==yes (
    goto ProcessSingleFile
)
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
    	if exist Your_Files\%%a\*.odex (
            for /f %%b in ('dir /b/on Your_Files\%%a\*.odex') do (
	            if exist Your_Files\%%a\%%~nb.jar (
                    set /a TotalFileCount+=1
			    )
		    )
	    )
	)
	if exist Your_Files\%%a\*.* (
        for /f %%b in ('dir /b/on Your_Files\%%a\*.odex') do (
	        if exist Your_Files\%%a\%%~nb.apk (
                set /a TotalFileCount+=1
			)
		)
	)
	if %%a==vendor\framework (
		if exist Your_Files\%%a\*.odex (
        	for /f %%b in ('dir /b/on Your_Files\%%a\*.odex') do (
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
rem The above line creates a new updater-script which we'll be updating as we go along
:ProcessODEXFiles_APK
for %%a in (%DirectoriesToProcess%) do (
	if exist Your_Files\%%a\*.* (
    	for /f %%b in ('dir /b/on Your_Files\%%a\*.apk') do (
		    if exist Your_Files\%%a\%%~nb.odex (
				call Tool_Files\Display_Title 100 6
				set /a FileCount+=1
				title TOAD [!FileCount!/%TotalFileCount%]
				echo. I'm now trying to process file !FileCount! of %TotalFileCount%:
		        echo.
		        echo.  "%%a\%%~nb.apk"
		        echo.
		        echo. Please wait, this may take a while.
				if exist Tool_Files\*.dex (
		    		del Tool_Files\*.dex /q >nul
				)
        		echo.>>log.txt
        		echo.----------->>log.txt
        		echo.>>log.txt
        		echo.Processing file !FileCount! of %TotalFileCount% - "Your_Files\%%a\%%~nb.odex">>log.txt
				if not exist Tool_Files\system\%%a (
				    mkdir Tool_Files\system\%%a >nul
				)
				copy Your_Files\%%a\%%~nb.apk Tool_Files\system\%%a\ >nul
				for /f %%c in ('java -Xmx1024m -jar Tool_Files\baksmali.jar list dex Your_Files\%%a\%%~nb.odex') DO (
                    if !temp!==!TOAD_DeodexErrors! (
					    rem The above line stops TOAD from processing an APK that's already failed
						echo.Processing "%%c">>log.txt
						java -Xmx1024m -jar Tool_Files\baksmali.jar deodex -c boot.oat -d Your_Files\framework\%TOAD_ABI% Your_Files\%%a\%%~nb.odex%%c -o Tool_Files\out >>log.txt 2>&1
						if %errorlevel%==0 (
						    rem %errorlevel% will be 0 if baksmali.jar was able to convert the ODEX file into SMALI files
						    set /a temp2+=1
							if !temp2!==1 (
							    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 9 Tool_Files\out -o Tool_Files\classes.dex >>log.txt 2>&1
								if %errorlevel%==1 (
								    rem %errorlevel% will be 1 if smali.jar wasn't able to convert the SMALI files to a DEX file
									set /a TOAD_DeodexErrors+=1
									echo.>>log.txt
									echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
								)
							) else (
							    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 9 Tool_Files\out -o Tool_Files\classes!temp2!.dex >>log.txt 2>&1
								if %errorlevel%==1 (
								    rem %errorlevel% will be 1 if smali.jar wasn't able to convert the SMALI files to a DEX file
									set /a TOAD_DeodexErrors+=1
									echo.>>log.txt
									echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
								)
							)
						) else (
						    set /a TOAD_DeodexErrors+=1
							echo.>>log.txt
							echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
						)
		        		if exist Tool_Files\out\*.* (
            	    		rmdir Tool_Files\out\ /s/q >nul
			        	)
					)
				)
                if !temp!==!TOAD_DeodexErrors! (
                    cd Tool_Files
                    7za u -tzip %TOAD_StartDirectory%\Tool_Files\system\%%a\%%~nb.apk classes*.dex>>%TOAD_StartDirectory%\log.txt
                    7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
                    cd ..
                    echo.ui_print(" Deleting ODEX files for '%%a/%%~nb.apk/'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.delete("/system/%%a/%%~nb.odex"^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.ui_print(" Adding Deodexed '%%~nb.apk'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.package_extract_file("system/%%a/%%~nb.apk","/system/%%a"^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.set_perm_recursive(0, 0, 0755, 0644, "/system/%%a"^);>>Tool_Files\META-INF\com\google\android\updater-script
        		    del Tool_Files\*.dex /q >nul
       				set /a TOAD_DeodexSuccesses+=1
				)
   				rmdir Tool_Files\system /s/q >nul
			)
		)
	)
)
rem All the odexed APK files in "app", "priv-app", "framework", "vendor\app", "vendor\priv-app" and "vendor\framework" should now be deodexed inside the ZIP file.
rem Any APK file that didn't deodex has been left untouched.
:ProcessODEXFiles_JAR
for %%a in (%DirectoriesToProcess%) do (
	if exist Your_Files\%%a\*.* (
    	for /f %%b in ('dir /b/on Your_Files\%%a\*.jar') do (
		    if exist Your_Files\%%a\%%~nb.odex (
				call Tool_Files\Display_Title 100 6
				set /a FileCount+=1
				title TOAD [!FileCount!/%TotalFileCount%]
				echo. I'm now trying to process file !FileCount! of %TotalFileCount%:
		        echo.
		        echo.  "%%a\%%~nb.jar"
		        echo.
		        echo. Please wait, this may take a while.
				if exist Tool_Files\*.dex (
		    		del Tool_Files\*.dex /q >nul
				)
        		echo.>>log.txt
        		echo.----------->>log.txt
        		echo.>>log.txt
        		echo.Processing file !FileCount! of %TotalFileCount% - "Your_Files\%%a\%%~nb.odex">>log.txt
				if not exist Tool_Files\system\%%a (
				    mkdir Tool_Files\system\%%a >nul
				)
				copy Your_Files\%%a\%%~nb.jar Tool_Files\system\%%a\ >nul
				for /f %%c in ('java -Xmx1024m -jar Tool_Files\baksmali.jar list dex Your_Files\%%a\%%~nb.odex') DO (
                    if !temp!==!TOAD_DeodexErrors! (
					    rem The above line stops TOAD from processing an JAR that's already failed
						echo.Processing "%%c">>log.txt
						java -Xmx1024m -jar Tool_Files\baksmali.jar deodex -c boot.oat -d Your_Files\framework\%TOAD_ABI% Your_Files\%%a\%%~nb.odex%%c -o Tool_Files\out >>log.txt 2>&1
						if %errorlevel%==0 (
						    rem %errorlevel% will be 0 if baksmali.jar was able to convert the ODEX file into SMALI files
						    set /a temp2+=1
							if !temp2!==1 (
							    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 9 Tool_Files\out -o Tool_Files\classes.dex >>log.txt 2>&1
								if %errorlevel%==1 (
								    rem %errorlevel% will be 1 if smali.jar wasn't able to convert the SMALI files to a DEX file
									set /a TOAD_DeodexErrors+=1
									echo.>>log.txt
									echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
								)
							) else (
							    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 9 Tool_Files\out -o Tool_Files\classes!temp2!.dex >>log.txt 2>&1
								if %errorlevel%==1 (
								    rem %errorlevel% will be 1 if smali.jar wasn't able to convert the SMALI files to a DEX file
									set /a TOAD_DeodexErrors+=1
									echo.>>log.txt
									echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
								)
							)
						) else (
						    set /a TOAD_DeodexErrors+=1
							echo.>>log.txt
							echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
						)
		        		if exist Tool_Files\out\*.* (
            	    		rmdir Tool_Files\out\ /s/q >nul
			        	)
					)
				)
                if !temp!==!TOAD_DeodexErrors! (
                    cd Tool_Files
                    7za u -tzip %TOAD_StartDirectory%\Tool_Files\system\%%a\%%~nb.jar classes*.dex>>%TOAD_StartDirectory%\log.txt
                    7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
                    cd ..
                    echo.ui_print(" Deleting ODEX files for '%%a/%%~nb.jar/'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.delete("/system/%%a/%%~nb.odex"^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.ui_print(" Adding Deodexed '%%~nb.jar'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.package_extract_file("system/%%a/%%~nb.jar","/system/%%a"^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.set_perm_recursive(0, 0, 0755, 0644, "/system/%%a"^);>>Tool_Files\META-INF\com\google\android\updater-script
        		    del Tool_Files\*.dex /q >nul
       				set /a TOAD_DeodexSuccesses+=1
				)
   				rmdir Tool_Files\system /s/q >nul
			)
		)
	)
)
rem All the odexed JAR files in "app", "priv-app", "framework", "vendor\app", "vendor\priv-app" and "vendor\framework" should now be deodexed inside the ZIP file.
rem Any JAR file that didn't deodex has been left untouched.
goto ProcessODEXFILES_END

::-----------------------------------------------------------------------------------------------------------------------------

:ProcessSingleFile
if exist Tool_Files\META-INF\com\google\android\ (
    rmdir Tool_Files\META-INF\com\google\android\ /s/q >nul
)
mkdir Tool_Files\META-INF\com\google\android\ >nul
if exist Tool_Files\system\*.* (
    rmdir Tool_Files\system\ /s/q >nul
)
if exist Tool_Files\out\*.* (
    rmdir Tool_Files\out /s/q >nul
)
if exist Tool_Files\*.dex (
    del Tool_Files\*.dex /q >nul
)
echo.>>log.txt
echo.----------->>log.txt
echo.>>log.txt
copy Tool_Files\updater-scriptBLANK Tool_Files\META-INF\com\google\android\updater-script >nul
rem The above line creates a new updater-script which we'll be updating as we go along
set temp=%TOAD_DeodexErrors%
if %TOAD_Extension% == apk (
    :ProcessSingleFile_APK
    call Tool_Files\Display_Title 100 6
    set /a FileCount+=1
    title TOAD [%TOAD_Address%\%TOAD_Filename%.%TOAD_Extension%]
    echo. I'm now trying to process file:
    echo.
    echo.  "%TOAD_Address%\%TOAD_Filename%.%TOAD_Extension%"
    echo.
    echo. Please wait, this may take a while.
    echo.Processing file  - "Your_Files\%TOAD_Address%\%TOAD_Filename%.odex">>log.txt
    mkdir Tool_Files\system\%TOAD_Address%\ >nul
    copy Your_Files\%TOAD_Address%\%TOAD_Filename%.apk Tool_Files\system\%TOAD_Address%\ >nul
    for /f %%a in ('java -Xmx1024m -jar Tool_Files\baksmali.jar list dex Your_Files\%TOAD_Address%\%TOAD_Filename%.odex') DO (
        if !temp!==!TOAD_DeodexErrors! (
		    rem The above line stops TOAD from processing an APK that's already failed
			echo.Processing "%%a">>log.txt
			java -Xmx1024m -jar Tool_Files\baksmali.jar deodex -c boot.oat -d Your_Files\framework\%TOAD_ABI% Your_Files\%TOAD_Address%\%TOAD_Filename%.odex%%a -o Tool_Files\out >>log.txt 2>&1
			if %errorlevel%==0 (
			    rem %errorlevel% will be 0 if baksmali.jar was able to convert the ODEX file into SMALI files
			    set /a temp2+=1
				if !temp2!==1 (
				    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 9 Tool_Files\out -o Tool_Files\classes.dex >>log.txt 2>&1
					if %errorlevel%==1 (
					    rem %errorlevel% will be 1 if smali.jar wasn't able to convert the SMALI files to a DEX file
						set /a TOAD_DeodexErrors+=1
						echo.>>log.txt
						echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
					)
				) else (
				    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 9 Tool_Files\out -o Tool_Files\classes!temp2!.dex >>log.txt 2>&1
					if %errorlevel%==1 (
					    rem %errorlevel% will be 1 if smali.jar wasn't able to convert the SMALI files to a DEX file
						set /a TOAD_DeodexErrors+=1
						echo.>>log.txt
						echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
					)
				)
			) else (
			    set /a TOAD_DeodexErrors+=1
				echo.>>log.txt
				echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
			)
       		if exist Tool_Files\out\*.* (
   	    		rmdir Tool_Files\out\ /s/q >nul
        	)
		)
	)
    if !temp!==!TOAD_DeodexErrors! (
        cd Tool_Files
        7za u -tzip %TOAD_StartDirectory%\Tool_Files\system\%TOAD_Address%\%TOAD_Filename%.apk classes*.dex>>%TOAD_StartDirectory%\log.txt
        7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
        cd ..
        echo.ui_print(" Deleting ODEX files for '%TOAD_Address%/%TOAD_Filename%.apk'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.delete("/system/%TOAD_Address%/%TOAD_Filename%.odex"^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.ui_print(" Adding Deodexed '%TOAD_FILENAME%.apk'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.package_extract_file("system/%TOAD_Address%/%TOAD_Filename%.apk","/system/%TOAD_Address%"^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.set_perm_recursive(0, 0, 0755, 0644, "/system/%TOAD_Address%/%TOAD_Filename%.apk"^);>>Tool_Files\META-INF\com\google\android\updater-script
	    del Tool_Files\*.dex /q >nul
        set /a TOAD_DeodexSuccesses+=1
	)
	rmdir Tool_Files\system /s/q >nul
)
if %TOAD_Extension% == jar (
    :ProcessSingleFile_JAR
    call Tool_Files\Display_Title 100 6
    set /a FileCount+=1
    title TOAD [%TOAD_Address%\%TOAD_Filename%.%TOAD_Extension%]
    echo. I'm now trying to process file:
    echo.
    echo.  "%TOAD_Address%\%TOAD_Filename%.%TOAD_Extension%"
    echo.
    echo. Please wait, this may take a while.
    echo.Processing file  - "Your_Files\%TOAD_Address%\%TOAD_Filename%.odex">>log.txt
    mkdir Tool_Files\system\%TOAD_Address%\ >nul
    copy Your_Files\%TOAD_Address%\%TOAD_Filename%.jar Tool_Files\system\%TOAD_Address%\ >nul
    for /f %%a in ('java -Xmx1024m -jar Tool_Files\baksmali.jar list dex Your_Files\%TOAD_Address%\%TOAD_Filename%.odex') DO (
        if !temp!==!TOAD_DeodexErrors! (
		    rem The above line stops TOAD from processing an JAR that's already failed
			echo.Processing "%%a">>log.txt
			java -Xmx1024m -jar Tool_Files\baksmali.jar deodex -c boot.oat -d Your_Files\framework\%TOAD_ABI% Your_Files\%TOAD_Address%\%TOAD_Filename%.odex%%a -o Tool_Files\out >>log.txt 2>&1
			if %errorlevel%==0 (
			    rem %errorlevel% will be 0 if baksmali.jar was able to convert the ODEX file into SMALI files
			    set /a temp2+=1
				if !temp2!==1 (
				    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 9 Tool_Files\out -o Tool_Files\classes.dex >>log.txt 2>&1
					if %errorlevel%==1 (
					    rem %errorlevel% will be 1 if smali.jar wasn't able to convert the SMALI files to a DEX file
						set /a TOAD_DeodexErrors+=1
						echo.>>log.txt
						echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
					)
				) else (
				    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 9 Tool_Files\out -o Tool_Files\classes!temp2!.dex >>log.txt 2>&1
					if %errorlevel%==1 (
					    rem %errorlevel% will be 1 if smali.jar wasn't able to convert the SMALI files to a DEX file
						set /a TOAD_DeodexErrors+=1
						echo.>>log.txt
						echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
					)
				)
			) else (
			    set /a TOAD_DeodexErrors+=1
				echo.>>log.txt
				echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
			)
       		if exist Tool_Files\out\*.* (
   	    		rmdir Tool_Files\out\ /s/q >nul
        	)
		)
	)
    if !temp!==!TOAD_DeodexErrors! (
        cd Tool_Files
        7za u -tzip %TOAD_StartDirectory%\Tool_Files\system\%TOAD_Address%\%TOAD_Filename%.jar classes*.dex>>%TOAD_StartDirectory%\log.txt
        7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
        cd ..
        echo.ui_print(" Deleting ODEX files for '%TOAD_Address%/%TOAD_Filename%.jar'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.delete("/system/%TOAD_Address%/%TOAD_Filename%.odex"^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.ui_print(" Adding Deodexed '%TOAD_FILENAME%.jar'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.package_extract_file("system/%TOAD_Address%/%TOAD_Filename%.jar","/system/%TOAD_Address%"^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.set_perm_recursive(0, 0, 0755, 0644, "/system/%TOAD_Address%/%TOAD_Filename%.jar"^);>>Tool_Files\META-INF\com\google\android\updater-script
	    del Tool_Files\*.dex /q >nul
        set /a TOAD_DeodexSuccesses+=1
	)
	rmdir Tool_Files\system /s/q >nul
)

::-----------------------------------------------------------------------------------------------------------------------------

:ProcessODEXFILES_END
rem We should now have a collection of fully deodexed APK and JAR files, ready to make into a ZIP. TOAD will create that ZIP and tell the user.
exit /b
