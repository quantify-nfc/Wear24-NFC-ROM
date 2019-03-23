rem NOUGAT 7.1
:DeclareNewVariables
set FileCount=0
set Filename=
set temp=0
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
set TOAD_StartDirectory=%TOAD_StartDirectory%
rem This is the address for the folder that TOAD.exe is in.

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
        for /f %%b in ('java -Xmx1024m -jar Tool_Files\baksmali.jar list dex Your_Files\framework\%TOAD_ABI%\boot.oat') do (
            set /a TotalFileCount+=1
		)
		if exist Your_Files\framework\%TOAD_ABI%\boot-*.oat (
	        for /f %%b in ('dir /b/on Your_Files\framework\%TOAD_ABI%\boot-*.oat') do (
        	    set Filename=%%~nb
        		set Filename=!Filename:~5!
		        if exist Your_Files\framework\!Filename!.jar (
    			    set /a TotalFileCount+=1
			    )
			)
		)
    	if exist Your_Files\%%a\oat\%TOAD_ABI%\*.odex (
            for /f %%b in ('dir /b/on Your_Files\%%a\oat\%TOAD_ABI%\*.odex') do (
	            if exist Your_Files\%%a\%%~nb.jar (
                    set /a TotalFileCount+=1
			    )
		    )
	    )
	)
	if exist Your_Files\%%a\*.* (
        for /f %%b in ('dir /ad/b/on Your_Files\%%a') do (
	        if exist Your_Files\%%a\%%b\oat\%TOAD_ABI%\%%b.odex (
                set /a TotalFileCount+=1
			)
		)
	)
	if %%a==vendor\framework (
		if exist Your_Files\%%a\oat\%TOAD_ABI%\*.odex (
        	for /f %%b in ('dir /b/on Your_Files\%%a\oat\%TOAD_ABI%\*.odex') do (
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
    	for /f %%b in ('dir /ad/b/on Your_Files\%%a') do (
		    if exist Your_Files\%%a\%%b\oat\%TOAD_ABI%\%%b.odex (
			    set temp=!TOAD_DeodexErrors!
				set temp2=0
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
        		if exist Tool_Files\out\*.* (
		    		rmdir Tool_Files\out\ /s/q >nul
				)
        		echo.>>log.txt
        		echo.----------->>log.txt
        		echo.>>log.txt
        		echo.Processing file !FileCount! of %TotalFileCount% - "Your_Files\%%a\%%b\oat\%TOAD_ABI%\%%b.odex">>log.txt
				if not exist Tool_Files\system\%%a\%%b (
				    mkdir Tool_Files\system\%%a\%%b >nul
				)
				copy Your_Files\%%a\%%b\%%b.apk Tool_Files\system\%%a\%%b\ >nul
				for /f %%c in ('java -Xmx1024m -jar Tool_Files\baksmali.jar list dex Your_Files\%%a\%%b\oat\%TOAD_ABI%\%%b.odex') DO (
                    if !temp!==!TOAD_DeodexErrors! (
					    rem The above line stops TOAD from processing an APK that's already failed
						echo.Processing "%%c">>log.txt
						java -Xmx1024m -jar Tool_Files\baksmali.jar deodex -c boot.oat -d Your_Files\framework\%TOAD_ABI% Your_Files\%%a\%%b\oat\%TOAD_ABI%\%%b.odex%%c -o Tool_Files\out >>log.txt 2>&1
						if %errorlevel%==0 (
						    rem %errorlevel% will be 0 if baksmali.jar was able to convert the ODEX file into SMALI files
						    set /a temp2+=1
							if !temp2!==1 (
							    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 25 Tool_Files\out -o Tool_Files\classes.dex >>log.txt 2>&1
								if %errorlevel%==1 (
								    rem %errorlevel% will be 1 if smali.jar wasn't able to convert the SMALI files to a DEX file
									set /a TOAD_DeodexErrors+=1
									echo.>>log.txt
									echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
								)
							) else (
							    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 25 Tool_Files\out -o Tool_Files\classes!temp2!.dex >>log.txt 2>&1
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
                    7za u -tzip %TOAD_StartDirectory%\Tool_Files\system\%%a\%%b\%%b.apk classes*.dex>>%TOAD_StartDirectory%\log.txt
                    7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
                    cd ..
                    echo.ui_print(" Deleting ODEX files for '%%a/%%b/'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.delete_recursive("/system/%%a/%%b/oat/"^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.ui_print(" Adding Deodexed '%%b.apk'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.package_extract_file("system/%%a/%%b/%%b.apk","/system/%%a/%%b"^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.set_perm_recursive(0, 0, 0755, 0644, "/system/%%a/%%b"^);>>Tool_Files\META-INF\com\google\android\updater-script
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
if %TOAD_IncludeFramework%==yes (
    set DirectoriesToProcess=framework vendor\framework
) else (
    set DirectoriesToProcess=vendor\framework
)
for %%a in (%DirectoriesToProcess%) do (
	if exist Your_Files\%%a\*.* (
    	for /f %%b in ('dir /b/on Your_Files\%%a\*.jar') do (
		    if exist Your_Files\%%a\oat\%TOAD_ABI%\%%~nb.odex (
			    set temp=!TOAD_DeodexErrors!
				set temp2=0
				call Tool_Files\Display_Title 100 6
				set /a FileCount+=1
				title TOAD [!FileCount!/%TotalFileCount%]
				echo. I'm now trying to process file !FileCount! of %TotalFileCount%:
		        echo.
		        echo.  "%%a\%%b"
		        echo.
		        echo. Please wait, this may take a while.
				if exist Tool_Files\*.dex (
		    		del Tool_Files\*.dex /q >nul
				)
        		if exist Tool_Files\out\*.* (
		    		rmdir Tool_Files\out\ /s/q >nul
				)
        		echo.>>log.txt
        		echo.----------->>log.txt
        		echo.>>log.txt
        		echo.Processing file !FileCount! of %TotalFileCount% - "Your_Files\%%a\oat\%TOAD_ABI%\%%~nb.odex">>log.txt
				if not exist Tool_Files\system\%%a\ (
				    mkdir Tool_Files\system\%%a\ >nul
				)
				copy Your_Files\%%a\%%b Tool_Files\system\%%a\ >nul
				for /f %%c in ('java -Xmx1024m -jar Tool_Files\baksmali.jar list dex Your_Files\%%a\oat\%TOAD_ABI%\%%~nb.odex') DO (
                    if !temp!==!TOAD_DeodexErrors! (
					    rem The above line stops TOAD from processing a JAR that's already failed
						echo.Processing "%%c">>log.txt
						java -Xmx1024m -jar Tool_Files\baksmali.jar deodex -c boot.oat -d Your_Files\framework\%TOAD_ABI% Your_Files\%%a\oat\%TOAD_ABI%\%%~nb.odex%%c -o Tool_Files\out >>log.txt 2>&1
						if %errorlevel%==0 (
						    rem %errorlevel% will be 0 if baksmali.jar was able to convert the ODEX file into SMALI files
						    set /a temp2+=1
							if !temp2!==1 (
							    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 25 Tool_Files\out -o Tool_Files\classes.dex >>log.txt 2>&1
								if %errorlevel%==1 (
								    rem %errorlevel% will be 1 if smali.jar wasn't able to convert the SMALI files to a DEX file
									set /a TOAD_DeodexErrors+=1
									echo.>>log.txt
									echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
								)
							) else (
							    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 25 Tool_Files\out -o Tool_Files\classes!temp2!.dex >>log.txt 2>&1
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
                    echo.ui_print(" Deleting ODEX files for '%%a/%%b'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.delete("/system/%%a/oat/%TOAD_ABI%/%%~nb.odex"^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.ui_print(" Adding Deodexed '%%b'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.package_extract_file("system/%%a/%%b","/system/%%a/"^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.set_perm_recursive(0, 0, 0755, 0644, "/system/%%a/"^);>>Tool_Files\META-INF\com\google\android\updater-script
        		    del Tool_Files\*.dex /q >nul
       				set /a TOAD_DeodexSuccesses+=1
				)
   				rmdir Tool_Files\system /s/q >nul
			)
		)
	)
)
rem All the odexed JAR files in "framework" and "vendor\framework" should now be deodexed inside the ZIP file.
rem Any JAR file that didn't deodex has been left untouched.
:ProcessODEXFiles_Boot
if %TOAD_IncludeFramework%==yes (
    set temp3=!TOAD_DeodexErrors!
    :ProcessODEXFiles_BootOAT
    if exist Your_Files\framework\%TOAD_ABI%\boot.oat (
	    set temp=!TOAD_DeodexErrors!
	    for /f %%a in ('java -Xmx1024m -jar Tool_Files\baksmali.jar list dex Your_Files\framework\%TOAD_ABI%\boot.oat') do (
		    rem This will loop through all the JAR files whose DEX files are inside "boot.oat", deodexing each one.
			if !temp!==!TOAD_DeodexErrors! (
			    rem This check will stop us from continuing to process "boot.oat" if we've already failed part of it.
				set Filename=%%~na
    			if exist Your_Files\framework\!Filename!.jar (
				    set temp2=0
				    call Tool_Files\Display_Title 100 6
				    set /a FileCount+=1
				    title TOAD [!FileCount!/%TotalFileCount%]
				    echo. I'm now trying to process file !FileCount! of %TotalFileCount%:
		            echo.
		            echo.  "framework\!Filename!.jar"
		            echo.
		            echo. Please wait, this may take a while.
				    if exist Tool_Files\*.dex (
    		    		del Tool_Files\*.dex /q >nul
				    )
        		    if exist Tool_Files\out\*.* (
    		    		rmdir Tool_Files\out\ /s/q >nul
				    )
        		    echo.>>log.txt
        		    echo.----------->>log.txt
        		    echo.>>log.txt
        		    echo.Processing file !FileCount! of %TotalFileCount% - "Your_Files\framework\%TOAD_ABI%\boot.oat%%a">>log.txt
				    if not exist Tool_Files\system\framework\ (
    				    mkdir Tool_Files\system\framework\ >nul
				    )
				    copy Your_Files\framework\!Filename!.jar Tool_Files\system\framework\ >nul
					java -Xmx1024m -jar Tool_Files\baksmali.jar deodex -c boot.oat -d Your_Files\framework\%TOAD_ABI% Your_Files\framework\%TOAD_ABI%\boot.oat%%a -o Tool_Files\out >>log.txt 2>&1
					if %errorlevel%==0 (
					    rem %errorlevel% will be 0 if baksmali.jar was able to convert the ODEX file into SMALI files
					    set /a temp2+=1
						if !temp2!==1 (
						    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 25 Tool_Files\out -o Tool_Files\classes.dex >>log.txt 2>&1
							if %errorlevel%==1 (
							    rem %errorlevel% will be 1 if smali.jar wasn't able to convert the SMALI files to a DEX file
								set /a TOAD_DeodexErrors+=1
								echo.>>log.txt
								echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
							)
						) else (
						    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 25 Tool_Files\out -o Tool_Files\classes!temp2!.dex >>log.txt 2>&1
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
                7za u -tzip system\framework\!Filename!.jar classes*.dex>>%TOAD_StartDirectory%\log.txt
                7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
    			cd ..
                echo.ui_print(" Adding Deodexed '!Filename!.jar'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                echo.package_extract_file("system/framework/!Filename!.jar","/system/framework/"^);>>Tool_Files\META-INF\com\google\android\updater-script
      		    del Tool_Files\*.dex /q >nul
    			set /a TOAD_DeodexSuccesses+=1
			)
   			rmdir Tool_Files\system /s/q >nul
		)
        if !temp!==!TOAD_DeodexErrors! (
            echo.ui_print(" Deleting ODEX files for 'framework/oat/%TOAD_ABI%/boot.oat'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
		    for /f %%b in ('dir /b/on Your_Files\framework\%TOAD_ABI%\boot.*') do (
			    echo.delete("/system/framework/%TOAD_ABI%/%%b"^);>>Tool_Files\META-INF\com\google\android\updater-script
			)
            echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
            echo.set_perm_recursive(0, 0, 0755, 0644, "/system/framework/"^);>>Tool_Files\META-INF\com\google\android\updater-script
		)
	)
    :ProcessODEXFiles_BootJAR
	if exist Your_Files\framework\%TOAD_ABI%\boot-*.oat (
	    set temp=!TOAD_DeodexErrors!
	    for /f %%a in ('dir /b/on Your_Files\framework\%TOAD_ABI%\boot-*.oat') do (
    	    for /f %%b in ('java -Xmx1024m -jar Tool_Files\baksmali.jar list dex Your_Files\framework\%TOAD_ABI%\%%a') do (
    		    rem This will loop through all the JAR files whose DEX files are inside "boot-*.oat", deodexing each one.
    			if !temp!==!TOAD_DeodexErrors! (
					call :ProcessODEXFiles_Boot_SetFilename %%b
    			    if exist Your_Files\framework\!Filename!.jar (
				        call Tool_Files\Display_Title 100 6
				        set /a FileCount+=1
				        title TOAD [!FileCount!/%TotalFileCount%]
				        echo. I'm now trying to process file !FileCount! of %TotalFileCount%:
		                echo.
		                echo.  "framework\!Filename!.jar"
		                echo.
		                echo. Please wait, this may take a while.
				        if exist Tool_Files\*.dex (
        		    		del Tool_Files\*.dex /q >nul
				        )
        		        if exist Tool_Files\out\*.* (
        		    		rmdir Tool_Files\out\ /s/q >nul
				        )
        		        echo.>>log.txt
        		        echo.----------->>log.txt
        		        echo.>>log.txt
        		        echo.Processing file !FileCount! of %TotalFileCount% - "Your_Files\framework\oat\%TOAD_ABI%\%%a">>log.txt
				        if not exist Tool_Files\system\framework\ (
        				    mkdir Tool_Files\system\framework\ >nul
				        )
						if not exist Tool_Files\system\framework\!Filename!.jar (
    				        copy Your_Files\framework\!Filename!.jar Tool_Files\system\framework\ >nul
						)
					    java -Xmx1024m -jar Tool_Files\baksmali.jar deodex -c boot.oat -d Your_Files\framework\%TOAD_ABI% Your_Files\framework\%TOAD_ABI%\%%a%%b -o Tool_Files\out >>log.txt 2>&1
					    if %errorlevel%==0 (
    					    rem %errorlevel% will be 0 if baksmali.jar was able to convert the ODEX file into SMALI files
					        set /a temp2+=1
						    if !temp2!==1 (
    						    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 25 Tool_Files\out -o Tool_Files\classes.dex >>log.txt 2>&1
							    if %errorlevel%==1 (
    							    rem %errorlevel% will be 1 if smali.jar wasn't able to convert the SMALI files to a DEX file
								    set /a TOAD_DeodexErrors+=1
								    echo.>>log.txt
								    echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
							    )
						    ) else (
    						    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 25 Tool_Files\out -o Tool_Files\classes!temp2!.dex >>log.txt 2>&1
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
                    7za u -tzip %TOAD_StartDirectory%\Tool_Files\system\framework\!Filename!.jar classes*.dex>>"%TOAD_StartDirectory%\log.txt" 2>&1
    			    cd ..
                    echo.ui_print(" Deleting ODEX files for 'framework/%TOAD_ABI%/%%a'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
				    for /f %%c in ('dir /b/on Your_Files\framework\%TOAD_ABI%\%%~na.*') do (
    				    echo.delete("/system/framework/%TOAD_ABI%/%%c"^);>>Tool_Files\META-INF\com\google\android\updater-script
				    )
                    echo.ui_print(" Adding Deodexed '!Filename!.jar'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.package_extract_file("system/framework/!Filename!.jar","/system/framework/"^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                    echo.set_perm_recursive(0, 0, 0755, 0644, "/system/framework/"^);>>Tool_Files\META-INF\com\google\android\updater-script
      		        del Tool_Files\*.dex /q >nul
    			    set /a TOAD_DeodexSuccesses+=1
			    ) else (
				    del Tool_Files\system\framework\!Filename!.jar /q >nul
				)
		    )
		)
	)
	if !temp3!==!TOAD_DeodexErrors! (
        echo.ui_print(" Deleting 'framework/%TOAD_ABI%/' folder.."^);>>Tool_Files\META-INF\com\google\android\updater-script	
		echo.delete_recursive("/framework/%TOAD_ABI%/"^);>>Tool_Files\META-INF\com\google\android\updater-script
	)
	cd Tool_Files
    7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
	cd ..
    rmdir Tool_Files\system /s/q >nul
)
goto ProcessODEXFILES_END

:ProcessODEXFiles_Boot_SetFilename
set Filename=%1
if %Filename:~0,39%==/system/framework/framework.jar:classes (
	set temp2=%Filename:~39,-4%
	set /a temp2-=1
    set Filename=framework
	rem If "boot.oat" contains files for "classes2.dex", or above, in "framework.jar", this section will set the variables as needed.
) else (
    set Filename=%Filename:~18,-4%
	set temp2=0
)
goto :eof

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
    echo.Processing file  - "Your_Files\%TOAD_Address%\%TOAD_Filename%\oat\%TOAD_ABI%\%TOAD_Filename%.odex">>log.txt
    mkdir Tool_Files\system\%TOAD_Address%\%TOAD_Filename% >nul
    copy Your_Files\%TOAD_Address%\%TOAD_Filename%\%TOAD_Filename%.apk Tool_Files\system\%TOAD_Address%\%TOAD_Filename%\ >nul
    for /f %%a in ('java -Xmx1024m -jar Tool_Files\baksmali.jar list dex Your_Files\%TOAD_Address%\%TOAD_Filename%\oat\%TOAD_ABI%\%TOAD_Filename%.odex') DO (
        if !temp!==!TOAD_DeodexErrors! (
		    rem The above line stops TOAD from processing an APK that's already failed
			echo.Processing "%%a">>log.txt
			java -Xmx1024m -jar Tool_Files\baksmali.jar deodex -c boot.oat -d Your_Files\framework\%TOAD_ABI% Your_Files\%TOAD_Address%\%TOAD_Filename%\oat\%TOAD_ABI%\%TOAD_Filename%.odex%%a -o Tool_Files\out >>log.txt 2>&1
			if %errorlevel%==0 (
			    rem %errorlevel% will be 0 if baksmali.jar was able to convert the ODEX file into SMALI files
			    set /a temp2+=1
				if !temp2!==1 (
				    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 25 Tool_Files\out -o Tool_Files\classes.dex >>log.txt 2>&1
					if %errorlevel%==1 (
					    rem %errorlevel% will be 1 if smali.jar wasn't able to convert the SMALI files to a DEX file
						set /a TOAD_DeodexErrors+=1
						echo.>>log.txt
						echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
					)
				) else (
				    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 25 Tool_Files\out -o Tool_Files\classes!temp2!.dex >>log.txt 2>&1
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
        7za u -tzip %TOAD_StartDirectory%\Tool_Files\system\%TOAD_Address%\%TOAD_Filename%\%TOAD_Filename%.apk classes*.dex>>%TOAD_StartDirectory%\log.txt
        7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
        cd ..
        echo.ui_print(" Deleting ODEX files for '%TOAD_Address%/%TOAD_Filename%/'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.delete_recursive("/system/%TOAD_Address%/%TOAD_Filename%/oat/"^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.ui_print(" Adding Deodexed '%TOAD_FILENAME%.apk'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.package_extract_file("system/%TOAD_Address%/%TOAD_Filename%/%TOAD_Filename%.apk","/system/%TOAD_Address%/%TOAD_Filename%"^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.set_perm_recursive(0, 0, 0755, 0644, "/system/%TOAD_Address%/%TOAD_Filename%"^);>>Tool_Files\META-INF\com\google\android\updater-script
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
    echo.Processing file  - "Your_Files\%TOAD_Address%\oat\%TOAD_ABI%\%TOAD_Filename%.odex">>log.txt
    mkdir Tool_Files\system\%TOAD_Address% >nul
    copy Your_Files\%TOAD_Address%\%TOAD_Filename%.jar Tool_Files\system\%TOAD_Address%\ >nul
    for /f %%a in ('java -Xmx1024m -jar Tool_Files\baksmali.jar list dex Your_Files\%TOAD_Address%\oat\%TOAD_ABI%\%TOAD_Filename%.odex') DO (
        if !temp!==!TOAD_DeodexErrors! (
		    rem The above line stops TOAD from processing an APK that's already failed
			echo.Processing "%%a">>log.txt
			java -Xmx1024m -jar Tool_Files\baksmali.jar deodex -c boot.oat -d Your_Files\framework\%TOAD_ABI% Your_Files\%TOAD_Address%\oat\%TOAD_ABI%\%TOAD_Filename%.odex%%a -o Tool_Files\out >>log.txt 2>&1
			if %errorlevel%==0 (
			    rem %errorlevel% will be 0 if baksmali.jar was able to convert the ODEX file into SMALI files
			    set /a temp2+=1
				if !temp2!==1 (
				    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 25 Tool_Files\out -o Tool_Files\classes.dex >>log.txt 2>&1
					if %errorlevel%==1 (
					    rem %errorlevel% will be 1 if smali.jar wasn't able to convert the SMALI files to a DEX file
						set /a TOAD_DeodexErrors+=1
						echo.>>log.txt
						echo.ERROR^!^!^!^! DEODEXING FAILED^!^!^!^!>>log.txt
					)
				) else (
				    java -Xmx1024m -jar Tool_Files\smali.jar assemble -a 25 Tool_Files\out -o Tool_Files\classes!temp2!.dex >>log.txt 2>&1
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
        for /f %%a in ('dir /b/on Your_Files\framework\oat\%TOAD_ABI%\%TOAD_Filename%.*') do (
            echo.delete("/system/framework/oat/%TOAD_ABI%/%a"^);>>Tool_Files\META-INF\com\google\android\updater-script
	    )
        echo.ui_print(" Adding Deodexed '%TOAD_FILENAME%.jar'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.package_extract_file("system/%TOAD_Address%/%TOAD_Filename%.jar","/system/%TOAD_Address%"^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
        echo.set_perm_recursive(0, 0, 0755, 0644, "/system/%TOAD_Address%"^);>>Tool_Files\META-INF\com\google\android\updater-script
	    del Tool_Files\*.dex /q >nul
        set /a TOAD_DeodexSuccesses+=1
	)
	rmdir Tool_Files\system /s/q >nul
)

::-----------------------------------------------------------------------------------------------------------------------------

:ProcessODEXFILES_END
:: We should now have a collection of fully deodexed APK and JAR files, ready to make into a ZIP. TOAD will create that ZIP and tell the user.
exit /b
