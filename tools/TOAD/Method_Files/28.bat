rem PIE 9.0
:DeclareNewVariables
set DirectoriesToProcess=
set FileCount=0
set Filename=
set FilenameWithAddress=
set temp=0
set temp2=0
set temp3=0
set TotalFileCount=0

::-----------------------------------------------------------------------------------------------------------------------------

:DeclareOldVariables
:: This batch file can access the variables set by TOAD itself. So please don't create any new variables that start "TOAD_" as this could cause a clash.
:: These variables already exist, so this section just serves as a reminder of what they are.
set TOAD_ABI=%TOAD_ABI%
:: TOAD_ABI is the type of processor your device uses (arm, arm64, ETC).
set TOAD_Address=%TOAD_Address%
:: This is the address of the single file that needs to be deodexed, if that's what we're doing.
set TOAD_DeodexErrors=%TOAD_DeodexErrors%
:: This variable tracks the number of files that don't deodex.
set TOAD_DeodexSuccesses=%TOAD_DeodexSuccesses%
:: This variable tracks the number of files that do deodex.
set TOAD_Extension=%TOAD_Extension%
:: This is the extension of the single file that needs to be deodexed, if that's what we're doing.
set TOAD_Filename=%TOAD_Filename%
:: This is the filename of the single file that needs to be deodexed, if that's what we're doing.
set TOAD_IncludeFramework=%TOAD_IncludeFramework%
:: TOAD_IncludeFramework says whether to include the 'framework' folder in the deodexing process.
set TOAD_SingleFile=%TOAD_SingleFile%
:: TOAD_SingleFile says whether to deodex a single file or the whole 'Your_Files' folder.
set TOAD_StartDirectory=%TOAD_StartDirectory%
:: This is the address for the folder that TOAD.exe is in.

::-----------------------------------------------------------------------------------------------------------------------------

if %TOAD_SingleFile%==yes (goto ProcessSingleFile)
call Tool_Files\Display_Title 50 3
echo. Please wait...
:: This shows a blank screen with the title. The first number is the width of the window. The second number is the height (not including the title itself).

::-----------------------------------------------------------------------------------------------------------------------------

:CountVDEXFiles
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
		if exist Your_Files\framework\%TOAD_ABI%\boot-*.vdex (
	        for /f %%b in ('dir /b/on Your_Files\framework\%TOAD_ABI%\boot-*.vdex') do (
        	    set Filename=%%~nb
        		set Filename=!Filename:~5!
		        if exist Your_Files\framework\!Filename!.jar (
    			    set /a TotalFileCount+=1
			    )
			)
		)
		if exist Your_Files\framework\boot-*.vdex (
	        for /f %%b in ('dir /b/on Your_Files\framework\boot-*.vdex') do (
        	    set Filename=%%~nb
        		set Filename=!Filename:~5!
		        if exist Your_Files\framework\!Filename!.jar (
    			    set /a TotalFileCount+=1
			    )
			)
		)
    	if exist Your_Files\%%a\oat\%TOAD_ABI%\*.vdex (
            for /f %%b in ('dir /b/on Your_Files\%%a\oat\%TOAD_ABI%\*.vdex') do (
	            if exist Your_Files\%%a\%%~nb.jar (
                    set /a TotalFileCount+=1
			    )
		    )
	    )
	)
	if exist Your_Files\%%a\*.* (
        for /f %%b in ('dir /ad/b/on Your_Files\%%a') do (
	        if exist Your_Files\%%a\%%b\oat\%TOAD_ABI%\%%b.vdex (
                set /a TotalFileCount+=1
			)
		)
	)
	if %%a==vendor\framework (
		if exist Your_Files\%%a\oat\%TOAD_ABI%\*.vdex (
        	for /f %%b in ('dir /b/on Your_Files\%%a\oat\%TOAD_ABI%\*.vdex') do (
		        if exist Your_Files\%%a\%%~nb.jar (
                	set /a TotalFileCount+=1
				)
			)
		)
	)
)
:: These lines will increment TotalFileCount for every APK or JAR we might be able to deodex

::-----------------------------------------------------------------------------------------------------------------------------

:ProcessVDEXFiles
copy Tool_Files\updater-scriptBLANK Tool_Files\META-INF\com\google\android\updater-script >nul
:: The above line creates a new updater-script which we'll be updating as we go along
:ProcessVDEXFiles_APK
for %%a in (%DirectoriesToProcess%) do (
	if exist Your_Files\%%a\*.* (
    	for /f %%b in ('dir /ad/b/on Your_Files\%%a') do (
		    if exist Your_Files\%%a\%%b\oat\%TOAD_ABI%\%%b.vdex (
			    set temp2=!TOAD_DeodexErrors!
				call Tool_Files\Display_Title 100 11
				set /a FileCount+=1
				title TOAD [!FileCount!/%TotalFileCount%]
				echo. I'm now trying to process file !FileCount! of %TotalFileCount%:
		        echo.
		        echo.  "%%a\%%b.apk"
		        echo.
		        echo. This won't take long. You can ignore what I say below this..
				if exist Tool_Files\*.dex (
		    		del Tool_Files\*.dex /q >nul
				)
        		if exist Tool_Files\*.cdex (
		    		del Tool_Files\*.cdex /q >nul
				)
        		if exist Tool_Files\*.cdex.new (
		    		del Tool_Files\*.cdex.new /q >nul
				)
        		echo.>>log.txt
        		echo.----------->>log.txt
        		echo.>>log.txt
        		echo.Processing file !FileCount! of %TotalFileCount% - "Your_Files\%%a\%%b\oat\%TOAD_ABI%\%%b.vdex">>log.txt
				if not exist Tool_Files\system\%%a\%%b (
				    mkdir Tool_Files\system\%%a\%%b >nul
				)
				copy Your_Files\%%a\%%b\%%b.apk Tool_Files\system\%%a\%%b\ >nul
        		Tool_Files\vdexextractor.exe -i Your_Files/%%a/%%b/oat/%TOAD_ABI%/%%b.vdex -o Tool_Files -f >>log.txt 2>&1
				:: This is the line that will convert our VDEX file into one or more CDEX files
        		if not exist Tool_Files\*.cdex (
            		set /a TOAD_DeodexErrors+=1
				) else (
    				set temp=!TOAD_DeodexErrors!
        		    for /f %%c in ('dir /b/on Tool_Files\%%b_classes*.cdex') do (
        	    		Tool_Files\bg33.exe locate 16 1
	    			    Tool_Files\flinux Tool_Files\compact_dex_converter Tool_Files\%%c
					    if not exist Tool_Files\%%c.new (
            				set /a TOAD_DeodexErrors+=1
				        )
				    )
					:: The above lines convert the CDEX files into CDEX.NEW files. These are the deodexed files we need.
            	    if !temp!==!TOAD_DeodexErrors! (
                        rename Tool_Files\%%b_classes.cdex.new classes.dex
				        if exist Tool_Files\%%b_classes*.cdex.new (
        				    set temp=2
				            for /f %%c in ('dir /b/on Tool_Files\%%b_classes*.cdex.new') do (
        					    if exist %%c (
								    rename %%c classes!temp!.dex
								)
						        set /a temp+=1
					        )
				        )
				        if exist Tool_Files\*.tmp (
        		    		del Tool_Files\*.tmp /q >nul
				        )
		                if exist vdexExtractor.exe.stackdump (
        		    		del vdexExtractor.exe.stackdump /q >nul
				        )
				        cd Tool_Files
        		        7za u -tzip "system\%%a\%%b\%%b.apk" classes*.dex>>"%TOAD_StartDirectory%\log.txt"
						7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
        		        cd ..
					    echo.ui_print(" Deleting VDEX/ODEX files for '%%a/%%b/'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                        echo.delete_recursive("/system/%%a/%%b/oat/"^);>>Tool_Files\META-INF\com\google\android\updater-script
                        echo.ui_print(" Adding Deodexed '%%b.apk'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                        echo.package_extract_file("system/%%a/%%b/%%b.apk","/system/%%a/%%b"^);>>Tool_Files\META-INF\com\google\android\updater-script
                        echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                        echo.set_perm_recursive(0, 0, 0755, 0644, "/system/%%a/%%b"^);>>Tool_Files\META-INF\com\google\android\updater-script
				        if exist Tool_Files\*.dex (
        		    		del Tool_Files\*.dex /q >nul
	    			    )
				        if exist Tool_Files\*.cdex (
        		    		del Tool_Files\*.cdex /q >nul
	    			    )
		    		    if exist Tool_Files\*.cdex.new (
    		    		    del Tool_Files\*.cdex.new /q >nul
				        )
				        set /a TOAD_DeodexSuccesses+=1
					)
				)
				if !temp2! neq !TOAD_DeodexErrors! (
                	echo.>>log.txt
	                echo.>>log.txt
	                echo.ERROR!!!! EXTRACTION FAILED!!!!>>log.txt
				)
				rmdir Tool_Files\system /s/q >nul
			)
		)
	)
)
:: All the odexed APK files in "app", "priv-app", "framework", "vendor\app", "vendor\priv-app" and "vendor\framework" should now be deodexed inside the ZIP file.
:: Any APK file that didn't deodex has been left untouched.
:ProcessVDEXFiles_JAR
if %TOAD_IncludeFramework%==yes (
    set DirectoriesToProcess=framework vendor\framework
) else (
    set DirectoriesToProcess=vendor\framework
)
for %%a in (%DirectoriesToProcess%) do (
	if exist Your_Files\%%a\*.* (
    	for /f %%b in ('dir /b/on Your_Files\%%a\oat\%TOAD_ABI%\*.vdex') do (
		    if exist Your_Files\%%a\%%~nb.jar (
			    set temp2=!TOAD_DeodexErrors!
				call Tool_Files\Display_Title 100 11
				set /a FileCount+=1
				title TOAD [!FileCount!/%TotalFileCount%]
				echo. I'm now trying to process file !FileCount! of %TotalFileCount%:
		        echo.
		        echo.  "%%a\%%~nb.jar"
		        echo.
		        echo. This won't take long. You can ignore what I say below this..
				if exist Tool_Files\*.dex (
		    		del Tool_Files\*.dex /q >nul
				)
        		if exist Tool_Files\*.cdex (
		    		del Tool_Files\*.cdex /q >nul
				)
        		if exist Tool_Files\*.cdex.new (
		    		del Tool_Files\*.cdex.new /q >nul
				)
        		echo.>>log.txt
        		echo.----------->>log.txt
        		echo.>>log.txt
        		echo.Processing file !FileCount! of %TotalFileCount% - "Your_Files\%%a\oat\%TOAD_ABI%\%%~nb.vdex">>log.txt
				if not exist Tool_Files\system\%%a\ (
				    mkdir Tool_Files\system\%%a\ >nul
				)
				copy Your_Files\%%a\%%~nb.jar Tool_Files\system\%%a\ >nul
        		Tool_Files\vdexextractor.exe -i Your_Files/%%a/oat/%TOAD_ABI%/%%~nb.vdex -o Tool_Files -f >>log.txt 2>&1
				:: This is the line that will convert our VDEX file into one or more CDEX files
        		if not exist Tool_Files\*.cdex (
            		set /a TOAD_DeodexErrors+=1
				) else (
    				set temp=!TOAD_DeodexErrors!
        		    for /f %%c in ('dir /b/on Tool_Files\%%~nb_classes*.cdex') do (
        	    		::Tool_Files\bg33.exe locate 16 1
	    			    Tool_Files\flinux Tool_Files\compact_dex_converter Tool_Files\%%c
					    if not exist Tool_Files\%%c.new (
            				set /a TOAD_DeodexErrors+=1
				        )
				    )
					:: The above lines convert the CDEX files into CDEX.NEW files. These are the deodexed files we need.
            	    if !temp!==!TOAD_DeodexErrors! (
                        rename Tool_Files\%%~nb_classes.cdex.new classes.dex
				        if exist Tool_Files\%%~nb_classes*.cdex.new (
        				    set temp=2
				            for /f %%c in ('dir /b/on Tool_Files\%%~nb_classes*.cdex.new') do (
        					    if exist Tool_Files\%%c (
								    rename Tool_Files\%%c classes!temp!.dex
								)
						        set /a temp+=1
					        )
				        )
				        if exist Tool_Files\*.tmp (
        		    		del Tool_Files\*.tmp /q >nul
				        )
		                if exist vdexExtractor.exe.stackdump (
        		    		del vdexExtractor.exe.stackdump /q >nul
				        )
				        cd Tool_Files
        		        7za u -tzip "system\%%a\%%~nb.jar" classes*.dex>>"%TOAD_StartDirectory%\log.txt"
						7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
        		        cd ..
					    echo.ui_print(" Deleting VDEX/ODEX files for '%%~nb.jar'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
						if exist Your_Files\%%a\oat\%TOAD_ABI%\%%~nb.odex (
						    echo.delete("/system/%%a/oat/%TOAD_ABI%/%%~nb.odex"^);>>Tool_Files\META-INF\com\google\android\updater-script
						)
						if exist Your_Files\%%a\oat\%TOAD_ABI%\%%~nb.vdex (
						    echo.delete("/system/%%a/oat/%TOAD_ABI%/%%~nb.vdex"^);>>Tool_Files\META-INF\com\google\android\updater-script
						)
                        echo.ui_print(" Adding Deodexed '%%~nb.jar'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                        echo.package_extract_file("system/%%a/%%~nb.jar","/system/%%a/"^);>>Tool_Files\META-INF\com\google\android\updater-script
                        echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
                        echo.set_perm_recursive(0, 0, 0755, 0644, "/system/%%a/"^);>>Tool_Files\META-INF\com\google\android\updater-script
				        if exist Tool_Files\*.dex (
        		    		del Tool_Files\*.dex /q >nul
	    			    )
				        if exist Tool_Files\*.cdex (
        		    		del Tool_Files\*.cdex /q >nul
	    			    )
		    		    if exist Tool_Files\*.cdex.new (
    		    		    del Tool_Files\*.cdex.new /q >nul
				        )
				        set /a TOAD_DeodexSuccesses+=1
					)
				)
				if !temp2! neq !TOAD_DeodexErrors! (
                	echo.>>log.txt
	                echo.>>log.txt
	                echo.ERROR!!!! EXTRACTION FAILED!!!!>>log.txt
				)
				rmdir Tool_Files\system /s/q >nul
			)
		)
	)
)
:: All the odexed JAR files in "framework" and "vendor\framework" should now be deodexed inside the ZIP file.
:: Any JAR file that didn't deodex has been left untouched.
:ProcessVDEXFiles_BOOT_Files
if %TOAD_IncludeFramework%==yes (
    set temp2=!TOAD_DeodexErrors!
	:ProcessVDEXFiles_BOOT_Files_BOOTdotOAT
	if exist Your_Files\framework\%TOAD_ABI%\boot.oat (
		for /f %%a in ('java -Xmx1024m -jar Tool_Files\baksmali.jar list dex Your_Files\framework\%TOAD_ABI%\boot.oat') do (
			:: The above line lists all the files that have their DEX files inside "boot.oat". We can't process them with baksmali.jar yet though.
			set Filename=%%~nxa
			if exist Your_Files\framework\!Filename! (
				call Tool_Files\Display_Title 100 11
				set /a FileCount+=1
				title TOAD [!FileCount!/%TotalFileCount%]
				echo. I'm now trying to process file !FileCount! of %TotalFileCount%:
				echo.
				echo.  "framework\!Filename!"
				echo.
				echo. This won't take long. You can ignore what I say below this..
				if exist Tool_Files\*.dex (
					del Tool_Files\*.dex /q >nul
				)
				if exist Tool_Files\*.cdex (
					del Tool_Files\*.cdex /q >nul
				)
				if exist Tool_Files\*.cdex.new (
					del Tool_Files\*.cdex.new /q >nul
				)
				echo.>>log.txt
				echo.----------->>log.txt
				echo.>>log.txt
				echo.Processing file !FileCount! of %TotalFileCount% - "Your_Files\framework\%TOAD_ABI%\boot.oat\%%a">>log.txt
				if not exist Tool_Files\system\framework\ (
					mkdir Tool_Files\system\framework\ >nul
				)
				copy Your_Files\framework\!Filename! Tool_Files\system\framework\ >nul
				Tool_Files\vdexextractor.exe -i Your_Files/framework/%TOAD_ABI%/boot.vdex -o Tool_Files -f >>log.txt 2>&1
				:: This is the line that will convert our VDEX file into one or more CDEX files
				if not exist Tool_Files\*.cdex (
					set /a TOAD_DeodexErrors+=1
				) else (
					set temp=!TOAD_DeodexErrors!
					for /f %%b in ('dir /b/on Tool_Files\*.cdex') do (
							Tool_Files\bg33.exe locate 16 1
							Tool_Files\flinux Tool_Files\compact_dex_converter Tool_Files\%%b
							if not exist Tool_Files\%%b.new (
								set /a TOAD_DeodexErrors+=1
							)
						)
						:: The above lines convert the CDEX files into CDEX.NEW files. These are the deodexed files we need.
						if !temp! neq !TOAD_DeodexErrors! (
							set /a TOAD_DeodexErrors+=1
						) else (
							rename Tool_Files\*_classes.cdex.new classes.dex
							if exist Tool_Files\*.cdex.new (
								set temp=2
								for /f %%c in ('dir /b/on Tool_Files\*.cdex.new') do (
									if exist %%c (rename %%c classes!temp!.dex)
									set /a temp+=1
								)
							)
							if exist Tool_Files\*.tmp (
								del Tool_Files\*.tmp /q >nul
							)
							if exist vdexExtractor.exe.stackdump (
								del vdexExtractor.exe.stackdump /q >nul
							)
							cd Tool_Files
							7za u -tzip "system\framework\!Filename!" classes*.dex>>"%TOAD_StartDirectory%\log.txt"
							7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
							cd ..
							echo.ui_print(" Adding Deodexed '!Filename!'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
							echo.package_extract_file("system/framework/!Filename!","/system/framework/"^);>>Tool_Files\META-INF\com\google\android\updater-script
							echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
							echo.set_perm_recursive(0, 0, 0755, 0644, "/system/framework/"^);>>Tool_Files\META-INF\com\google\android\updater-script
							if exist Tool_Files\*.dex (
								del Tool_Files\*.dex /q >nul
							)
							if exist Tool_Files\*.cdex (
								del Tool_Files\*.cdex /q >nul
							)
							if exist Tool_Files\*.cdex.new (
								del Tool_Files\*.cdex.new /q >nul
							)
							set /a TOAD_DeodexSuccesses+=1
						)
					)
					if !temp2! neq !TOAD_DeodexErrors! (
						echo.>>log.txt
						echo.>>log.txt
						echo.ERROR!!!! EXTRACTION FAILED!!!!>>log.txt
					) else (
						echo.ui_print(" Deleting VDEX/ODEX/etc files for 'boot.oat'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
						for /f %%d in ('dir /b/on Your_Files\framework\%TOAD_ABI%\boot.*') do (
							echo.delete("/system/framework/%TOAD_ABI%/%%d"^);>>Tool_Files\META-INF\com\google\android\updater-script
						)
					)
					rmdir Tool_Files\system /s/q >nul
				)
			)
		)
	)
	if exist Your_Files\framework\boot.oat (
		for /f %%a in ('java -Xmx1024m -jar Tool_Files\baksmali.jar list dex Your_Files\framework\boot.oat') do (
			:: The above line lists all the files that have their DEX files inside "boot.oat". We can't process them with baksmali.jar yet though.
			set Filename=%%~nxa
			if exist Your_Files\framework\!Filename! (
				call Tool_Files\Display_Title 100 11
				set /a FileCount+=1
				title TOAD [!FileCount!/%TotalFileCount%]
				echo. I'm now trying to process file !FileCount! of %TotalFileCount%:
				echo.
				echo.  "framework\!Filename!"
				echo.
				echo. This won't take long. You can ignore what I say below this..
				if exist Tool_Files\*.dex (
					del Tool_Files\*.dex /q >nul
				)
				if exist Tool_Files\*.cdex (
					del Tool_Files\*.cdex /q >nul
				)
				if exist Tool_Files\*.cdex.new (
					del Tool_Files\*.cdex.new /q >nul
				)
				echo.>>log.txt
				echo.----------->>log.txt
				echo.>>log.txt
				echo.Processing file !FileCount! of %TotalFileCount% - "Your_Files\framework\boot.oat\%%a">>log.txt
				if not exist Tool_Files\system\framework\ (
					mkdir Tool_Files\system\framework\ >nul
				)
				copy Your_Files\framework\!Filename! Tool_Files\system\framework\ >nul
				Tool_Files\vdexextractor.exe -i Your_Files/framework/boot.vdex -o Tool_Files -f >>log.txt 2>&1
				:: This is the line that will convert our VDEX file into one or more CDEX files
				if not exist Tool_Files\*.cdex (
					set /a TOAD_DeodexErrors+=1
				) else (
					set temp=!TOAD_DeodexErrors!
					for /f %%b in ('dir /b/on Tool_Files\*.cdex') do (
							Tool_Files\bg33.exe locate 16 1
							Tool_Files\flinux Tool_Files\compact_dex_converter Tool_Files\%%b
							if not exist Tool_Files\%%b.new (
								set /a TOAD_DeodexErrors+=1
							)
						)
						:: The above lines convert the CDEX files into CDEX.NEW files. These are the deodexed files we need.
						if !temp! neq !TOAD_DeodexErrors! (
							set /a TOAD_DeodexErrors+=1
						) else (
							rename Tool_Files\*_classes.cdex.new classes.dex
							if exist Tool_Files\*.cdex.new (
								set temp=2
								for /f %%c in ('dir /b/on Tool_Files\*.cdex.new') do (
									if exist %%c (rename %%c classes!temp!.dex)
									set /a temp+=1
								)
							)
							if exist Tool_Files\*.tmp (
								del Tool_Files\*.tmp /q >nul
							)
							if exist vdexExtractor.exe.stackdump (
								del vdexExtractor.exe.stackdump /q >nul
							)
							cd Tool_Files
							7za u -tzip "system\framework\!Filename!" classes*.dex>>"%TOAD_StartDirectory%\log.txt"
							7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
							cd ..
							echo.ui_print(" Adding Deodexed '!Filename!'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
							echo.package_extract_file("system/framework/!Filename!","/system/framework/"^);>>Tool_Files\META-INF\com\google\android\updater-script
							echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
							echo.set_perm_recursive(0, 0, 0755, 0644, "/system/framework/"^);>>Tool_Files\META-INF\com\google\android\updater-script
							if exist Tool_Files\*.dex (
								del Tool_Files\*.dex /q >nul
							)
							if exist Tool_Files\*.cdex (
								del Tool_Files\*.cdex /q >nul
							)
							if exist Tool_Files\*.cdex.new (
								del Tool_Files\*.cdex.new /q >nul
							)
							set /a TOAD_DeodexSuccesses+=1
						)
					)
					if !temp2! neq !TOAD_DeodexErrors! (
						echo.>>log.txt
						echo.>>log.txt
						echo.ERROR!!!! EXTRACTION FAILED!!!!>>log.txt
					) else (
						echo.ui_print(" Deleting VDEX/ODEX/etc files for 'boot.oat'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
						for /f %%d in ('dir /b/on Your_Files\framework\boot.*') do (
							echo.delete("/system/framework/%%d"^);>>Tool_Files\META-INF\com\google\android\updater-script
						)
					)
					rmdir Tool_Files\system /s/q >nul
				)
			)
		)
	)
)
if %TOAD_IncludeFramework%==yes (
	:ProcessVDEXFiles_BOOT_Files_BOOT-dotVDEX
	if exist Your_Files\framework\%TOAD_ABI%\boot-*.vdex (
		for /f %%a in ('dir /b/on Your_Files\framework\%TOAD_ABI%\boot-*.vdex') do (
			set Filename=%%~na
			set Filename=!Filename:~5!
			if exist Your_Files\framework\!Filename!.jar (
				set temp2=!TOAD_DeodexErrors!
				call Tool_Files\Display_Title 100 11
				set /a FileCount+=1
				title TOAD [!FileCount!/%TotalFileCount%]
				echo. I'm now trying to process file !FileCount! of %TotalFileCount%:
				echo.
				echo.  "framework\!Filename!.jar"
				echo.
				echo. This won't take long. You can ignore what I say below this..
				if exist Tool_Files\*.dex (
					del Tool_Files\*.dex /q >nul
				)
				if exist Tool_Files\*.cdex (
					del Tool_Files\*.cdex /q >nul
				)
				if exist Tool_Files\*.cdex.new (
					del Tool_Files\*.cdex.new /q >nul
				)
				echo.>>log.txt
				echo.----------->>log.txt
				echo.>>log.txt
				echo.Processing file !FileCount! of %TotalFileCount% - "Your_Files\framework\%TOAD_ABI%\%%a">>log.txt
				if not exist Tool_Files\system\framework\ (
					mkdir Tool_Files\system\framework\ >nul
				)
				copy Your_Files\framework\!Filename!.jar Tool_Files\system\framework\ >nul
				Tool_Files\vdexextractor.exe -i Your_Files/framework/%TOAD_ABI%/%%a -o Tool_Files -f >>log.txt 2>&1
				:: This is the line that will convert our VDEX file into one or more CDEX files
				if not exist Tool_Files\*.cdex (
					set /a TOAD_DeodexErrors+=1
				) else (
					set temp=!TOAD_DeodexErrors!
					for /f %%b in ('dir /b/on Tool_Files\%%~na_classes*.cdex') do (
						Tool_Files\bg33.exe locate 16 1
						Tool_Files\flinux Tool_Files\compact_dex_converter Tool_Files\%%b
						if not exist Tool_Files\%%b.new (
							set /a TOAD_DeodexErrors+=1
						)
					)
					:: The above lines convert the CDEX files into CDEX.NEW files. These are the deodexed files we need.
					if !temp! neq !TOAD_DeodexErrors! (
						   set /a TOAD_DeodexErrors+=1
					) else (
						rename Tool_Files\%%~na_classes.cdex.new classes.dex
						if exist Tool_Files\%%~na_classes*.cdex.new (
							set temp=2
							for /f %%b in ('dir /b/on Tool_Files\%%~na_classes*.cdex.new') do (
								if exist %%b (rename %%b classes!temp!.dex)
								set /a temp+=1
							)
						)
						if exist Tool_Files\*.tmp (
							del Tool_Files\*.tmp /q >nul
						)
						if exist vdexExtractor.exe.stackdump (
							del vdexExtractor.exe.stackdump /q >nul
						)
						cd Tool_Files
						7za u -tzip "system\framework\!Filename!.jar" classes*.dex>>"%TOAD_StartDirectory%\log.txt"
						7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
						cd ..
						echo.ui_print(" Deleting VDEX/ODEX files for '!Filename!.jar'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
						for /f %%b in ('dir /b/on Your_Files\framework\%TOAD_ABI%\boot-!Filename!.*') do (
							echo.delete("/system/framework/%TOAD_ABI%/%%b"^);>>Tool_Files\META-INF\com\google\android\updater-script
						)
						echo.ui_print(" Adding Deodexed '!Filename!.jar'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
						echo.package_extract_file("system/framework/!Filename!.jar","/system/framework/"^);>>Tool_Files\META-INF\com\google\android\updater-script
						echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
						echo.set_perm_recursive(0, 0, 0755, 0644, "/system/framework/"^);>>Tool_Files\META-INF\com\google\android\updater-script
						if exist Tool_Files\*.dex (
							del Tool_Files\*.dex /q >nul
						)
						if exist Tool_Files\*.cdex (
							del Tool_Files\*.cdex /q >nul
						)
						if exist Tool_Files\*.cdex.new (
							del Tool_Files\*.cdex.new /q >nul
						)
						set /a TOAD_DeodexSuccesses+=1
					)
				)
				if !temp2! neq !TOAD_DeodexErrors! (
					echo.>>log.txt
					echo.>>log.txt
					echo.ERROR!!!! EXTRACTION FAILED!!!!>>log.txt
				)
				rmdir Tool_Files\system /s/q >nul
			)
		)
	)
	if exist Your_Files\frameworkboot-*.vdex (
		for /f %%a in ('dir /b/on Your_Files\framework\boot-*.vdex') do (
			set Filename=%%~na
			set Filename=!Filename:~5!
			if exist Your_Files\framework\!Filename!.jar (
				set temp2=!TOAD_DeodexErrors!
				call Tool_Files\Display_Title 100 11
				set /a FileCount+=1
				title TOAD [!FileCount!/%TotalFileCount%]
				echo. I'm now trying to process file !FileCount! of %TotalFileCount%:
				echo.
				echo.  "framework\!Filename!.jar"
				echo.
				echo. This won't take long. You can ignore what I say below this..
				if exist Tool_Files\*.dex (
					del Tool_Files\*.dex /q >nul
				)
				if exist Tool_Files\*.cdex (
					del Tool_Files\*.cdex /q >nul
				)
				if exist Tool_Files\*.cdex.new (
					del Tool_Files\*.cdex.new /q >nul
				)
				echo.>>log.txt
				echo.----------->>log.txt
				echo.>>log.txt
				echo.Processing file !FileCount! of %TotalFileCount% - "Your_Files\framework\%%a">>log.txt
				if not exist Tool_Files\system\framework\ (
					mkdir Tool_Files\system\framework\ >nul
				)
				copy Your_Files\framework\!Filename!.jar Tool_Files\system\framework\ >nul
				Tool_Files\vdexextractor.exe -i Your_Files/framework/%%a -o Tool_Files -f >>log.txt 2>&1
				:: This is the line that will convert our VDEX file into one or more CDEX files
				if not exist Tool_Files\*.cdex (
					set /a TOAD_DeodexErrors+=1
				) else (
					set temp=!TOAD_DeodexErrors!
					for /f %%b in ('dir /b/on Tool_Files\%%~na_classes*.cdex') do (
						Tool_Files\bg33.exe locate 16 1
						Tool_Files\flinux Tool_Files\compact_dex_converter Tool_Files\%%b
						if not exist Tool_Files\%%b.new (
							set /a TOAD_DeodexErrors+=1
						)
					)
					:: The above lines convert the CDEX files into CDEX.NEW files. These are the deodexed files we need.
					if !temp! neq !TOAD_DeodexErrors! (
						   set /a TOAD_DeodexErrors+=1
					) else (
						rename Tool_Files\%%~na_classes.cdex.new classes.dex
						if exist Tool_Files\%%~na_classes*.cdex.new (
							set temp=2
							for /f %%b in ('dir /b/on Tool_Files\%%~na_classes*.cdex.new') do (
								if exist %%b (rename %%b classes!temp!.dex)
								set /a temp+=1
							)
						)
						if exist Tool_Files\*.tmp (
							del Tool_Files\*.tmp /q >nul
						)
						if exist vdexExtractor.exe.stackdump (
							del vdexExtractor.exe.stackdump /q >nul
						)
						cd Tool_Files
						7za u -tzip "system\framework\!Filename!.jar" classes*.dex>>"%TOAD_StartDirectory%\log.txt"
						7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
						cd ..
						echo.ui_print(" Deleting VDEX/ODEX files for '!Filename!.jar'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
						for /f %%b in ('dir /b/on Your_Files\framework\boot-!Filename!.*') do (
							echo.delete("/system/framework/%%b"^);>>Tool_Files\META-INF\com\google\android\updater-script
						)
						echo.ui_print(" Adding Deodexed '!Filename!.jar'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
						echo.package_extract_file("system/framework/!Filename!.jar","/system/framework/"^);>>Tool_Files\META-INF\com\google\android\updater-script
						echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
						echo.set_perm_recursive(0, 0, 0755, 0644, "/system/framework/"^);>>Tool_Files\META-INF\com\google\android\updater-script
						if exist Tool_Files\*.dex (
							del Tool_Files\*.dex /q >nul
						)
						if exist Tool_Files\*.cdex (
							del Tool_Files\*.cdex /q >nul
						)
						if exist Tool_Files\*.cdex.new (
							del Tool_Files\*.cdex.new /q >nul
						)
						set /a TOAD_DeodexSuccesses+=1
					)
				)
				if !temp2! neq !TOAD_DeodexErrors! (
					echo.>>log.txt
					echo.>>log.txt
					echo.ERROR!!!! EXTRACTION FAILED!!!!>>log.txt
				)
				rmdir Tool_Files\system /s/q >nul
			)
		)
	)
	if !temp2!==!TOAD_DeodexErrors! (
        echo.ui_print(" Deleting 'framework/%TOAD_ABI%/' folder.."^);>>Tool_Files\META-INF\com\google\android\updater-script	
		echo.delete_recursive("/framework/%TOAD_ABI%/"^);>>Tool_Files\META-INF\com\google\android\updater-script
	)
)
:: All the odexed JAR files inside "framework\%TOAD_ABI%\boot.oat" and
:: all the odexed 'boot-*' JAR files in "framework" should now be deodexed inside the ZIP file.
:: Any JAR file that didn't deodex has been left untouched.
:: If all the files could be deodexed, the ZIP file will delete the "%TOAD_ABI%" folder.
echo.run_program("/sbin/busybox", "umount", "/system"^);>>Tool_Files\META-INF\com\google\android\updater-script
echo.ui_print(" "^);>>Tool_Files\META-INF\com\google\android\updater-script
echo.ui_print(" Flashing Complete"^);>>Tool_Files\META-INF\com\google\android\updater-script
echo.ui_print(" "^);>>Tool_Files\META-INF\com\google\android\updater-script
goto ProcessVDEXFILES_END

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
if exist Tool_Files\*.cdex (
    del Tool_Files\*.cdex /q >nul
)
if exist Tool_Files\*.cdex.new (
    del Tool_Files\*.cdex.new /q >nul
)
echo.>>log.txt
echo.----------->>log.txt
echo.>>log.txt
copy Tool_Files\updater-scriptBLANK Tool_Files\META-INF\com\google\android\updater-script >nul
:: The above line creates a new updater-script which we'll be updating as we go along
if %TOAD_Extension% == apk (
    :ProcessSingleFile_APK
    call Tool_Files\Display_Title 100 11
    set /a FileCount+=1
    title TOAD [%TOAD_Address%\%TOAD_Filename%.%TOAD_Extension%]
    echo. I'm now trying to process file:
    echo.
    echo.  "%TOAD_Address%\%TOAD_Filename%.%TOAD_Extension%"
    echo.
    echo. This won't take long. You can ignore what I say below this..
    echo.Processing file  - "Your_Files\%TOAD_Address%\%TOAD_Filename%\oat\%TOAD_ABI%\%TOAD_Filename%.vdex">>log.txt
    mkdir Tool_Files\system\%TOAD_Address%\%TOAD_Filename% >nul
    copy Your_Files\%TOAD_Address%\%TOAD_Filename%\%TOAD_Filename%.apk Tool_Files\system\%TOAD_Address%\%TOAD_Filename%\ >nul
    if %TOAD_Address:~0,6%==vendor (
        for /f "tokens=1-4 delims=\ " %%a in ("%TOAD_Address%") do (
		    set TOAD_Address=%%a/%%b
		)
	)	    
    Tool_Files\vdexextractor.exe -i Your_Files/!TOAD_Address!/%TOAD_Filename%/oat/%TOAD_ABI%/%TOAD_Filename%.vdex -o Tool_Files -f >>log.txt 2>&1
    :: This is the line that will try to extract the code from the VDEX file and create one or more DEX files. Vdexextractor.exe is a Linux program and uses "/" for the folders, NOT "\".
    if %TOAD_Address:~0,6%==vendor (
        for /f "tokens=1-4 delims=/ " %%a in ("!TOAD_Address!") do (
		    set TOAD_Address=%%a\%%b
		)
    ) 
    if exist Tool_Files\*.tmp (
	    del Tool_Files\*.tmp /q >nul
	)
    if exist vdexExtractor.exe.stackdump (
	    del vdexExtractor.exe.stackdump /q >nul
	)
	if not exist Tool_Files\*.cdex (
	    set /a TOAD_DeodexErrors+=1
	) else (
	    set temp=!TOAD_DeodexErrors!
	    for /f %%a in ('dir /b/on Tool_Files\%TOAD_Filename%_classes*.cdex') do (
    		Tool_Files\bg33.exe locate 16 1
		    Tool_Files\flinux Tool_Files\compact_dex_converter Tool_Files\%%a
		    if not exist Tool_Files\%%a.new (
   				set /a TOAD_DeodexErrors+=1
	        )
	    )
   	    if !temp!==!TOAD_DeodexErrors! (
            rename Tool_Files\%TOAD_Filename%_classes.cdex.new classes.dex
	        if exist Tool_Files\%TOAD_Filename%_classes*.cdex.new (
			    set temp=2
	            for /f %%a in ('dir /b/on Tool_Files\%TOAD_Filename%_classes*.cdex.new') do (
				    if exist %%a (
					    rename %%a classes!temp!.dex
					)
					set /a temp+=1
				)
	        )
	        if exist Tool_Files\*.tmp (
	    		del Tool_Files\*.tmp /q >nul
	        )
            if exist vdexExtractor.exe.stackdump (
	    		del vdexExtractor.exe.stackdump /q >nul
	        )
	        cd Tool_Files
	        7za u -tzip "system\!TOAD_Address!\%TOAD_Filename%\%TOAD_Filename%.apk" classes*.dex>>"%TOAD_StartDirectory%\log.txt"
    		7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
	        cd ..
            if %TOAD_Address:~0,6%==vendor (
                for /f "tokens=1-4 delims=\ " %%a in ("!TOAD_Address!") do (
		            set TOAD_Address=%%a/%%b
		        )
	        )	    
		    echo.ui_print(" Deleting VDEX/ODEX files for '!TOAD_Address!/%TOAD_Filename%/'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
            echo.delete_recursive("/system/!TOAD_Address!/%TOAD_Filename%/oat/"^);>>Tool_Files\META-INF\com\google\android\updater-script
            echo.ui_print(" Adding Deodexed '%TOAD_Filename%.apk'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
            echo.package_extract_file("system/!TOAD_Address!/%TOAD_Filename%/%TOAD_Filename%.apk","/system/!TOAD_Address!/%TOAD_Filename%"^);>>Tool_Files\META-INF\com\google\android\updater-script
            echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
            echo.set_perm_recursive(0, 0, 0755, 0644, "/system/!TOAD_Address!/%TOAD_Filename%"^);>>Tool_Files\META-INF\com\google\android\updater-script
            if %TOAD_Address:~0,6%==vendor (
                for /f "tokens=1-4 delims=/ " %%a in ("!TOAD_Address!") do (
                    set TOAD_Address=%%a\%%b
                )
            ) 
	        if exist Tool_Files\*.dex (
	    		del Tool_Files\*.dex /q >nul
		    )
	        if exist Tool_Files\*.cdex (
	    		del Tool_Files\*.cdex /q >nul
		    )
   		    if exist Tool_Files\*.cdex.new (
    		    del Tool_Files\*.cdex.new /q >nul
	        )
	        set /a TOAD_DeodexSuccesses+=1
			echo.run_program("/sbin/busybox", "umount", "/system"^);>>Tool_Files\META-INF\com\google\android\updater-script
            echo.ui_print(" "^);>>Tool_Files\META-INF\com\google\android\updater-script
            echo.ui_print(" Flashing Complete"^);>>Tool_Files\META-INF\com\google\android\updater-script
            echo.ui_print(" "^);>>Tool_Files\META-INF\com\google\android\updater-script
		)
	)
	if !temp2! neq !TOAD_DeodexErrors! (
       	echo.>>log.txt
        echo.>>log.txt
        echo.ERROR!!!! EXTRACTION FAILED!!!!>>log.txt
	)
    rmdir Tool_Files\system /s/q >nul
)
if %TOAD_Extension% == jar (
    :ProcessSingleFile_JAR
    call Tool_Files\Display_Title 100 11
    set /a FileCount+=1
    title TOAD [%TOAD_Address%\%TOAD_Filename%.%TOAD_Extension%]
    echo. I'm now trying to process file:
    echo.
    echo.  "%TOAD_Address%\%TOAD_Filename%.%TOAD_Extension%"
    echo.
    echo. This won't take long. You can ignore what I say below this..
    echo.Processing file  - "Your_Files\%TOAD_Address%\oat\%TOAD_ABI%\%TOAD_Filename%.vdex">>log.txt
    mkdir Tool_Files\system\%TOAD_Address%\ >nul
    copy Your_Files\%TOAD_Address%\%TOAD_Filename%.jar Tool_Files\system\%TOAD_Address%\ >nul
    if %TOAD_Address:~0,6%==vendor (
        for /f "tokens=1-4 delims=\ " %%a in ("%TOAD_Address%") do (
		    set TOAD_Address=%%a/%%b
		)
	)	    
    Tool_Files\vdexextractor.exe -i Your_Files/!TOAD_Address!/oat/%TOAD_ABI%/%TOAD_Filename%.vdex -o Tool_Files -f >>log.txt 2>&1
    :: This is the line that will try to extract the code from the VDEX file and create one or more DEX files. Vdexextractor.exe is a Linux program and uses "/" for the folders, NOT "\".
    if %TOAD_Address:~0,6%==vendor (
        for /f "tokens=1-4 delims=/ " %%a in ("!TOAD_Address!") do (
		    set TOAD_Address=%%a\%%b
		)
    ) 
    if exist Tool_Files\*.tmp (
	    del Tool_Files\*.tmp /q >nul
	)
    if exist vdexExtractor.exe.stackdump (
	    del vdexExtractor.exe.stackdump /q >nul
	)
	if not exist Tool_Files\*.cdex (
	    set /a TOAD_DeodexErrors+=1
	) else (
	    set temp=!TOAD_DeodexErrors!
	    for /f %%a in ('dir /b/on Tool_Files\%TOAD_Filename%_classes*.cdex') do (
    		Tool_Files\bg33.exe locate 16 1
		    Tool_Files\flinux Tool_Files\compact_dex_converter Tool_Files\%%a
		    if not exist Tool_Files\%%a.new (
   				set /a TOAD_DeodexErrors+=1
	        )
	    )
   	    if !temp!==!TOAD_DeodexErrors! (
            rename Tool_Files\%TOAD_Filename%_classes.cdex.new classes.dex
	        if exist Tool_Files\%TOAD_Filename%_classes*.cdex.new (
			    set temp=2
	            for /f %%a in ('dir /b/on Tool_Files\%TOAD_Filename%_classes*.cdex.new') do (
				    if exist %%a (
					    rename %%a classes!temp!.dex
					)
					set /a temp+=1
				)
	        )
	        if exist Tool_Files\*.tmp (
	    		del Tool_Files\*.tmp /q >nul
	        )
            if exist vdexExtractor.exe.stackdump (
	    		del vdexExtractor.exe.stackdump /q >nul
	        )
	        cd Tool_Files
	        7za u -tzip "system\!TOAD_Address!\%TOAD_Filename%.jar" classes*.dex>>"%TOAD_StartDirectory%\log.txt"
    		7za a -y -mx0 "%TOAD_StartDirectory%\TOAD_deodex_%TOAD_day%%TOAD_month%%TOAD_year%-%TOAD_hour%%TOAD_min%.zip" system >>"%TOAD_StartDirectory%\LOG.txt" 2>&1
	        cd ..
            if %TOAD_Address:~0,6%==vendor (
                for /f "tokens=1-4 delims=\ " %%a in ("!TOAD_Address!") do (
		            set TOAD_Address=%%a/%%b
		        )
	        )	    
		    echo.ui_print(" Deleting VDEX/ODEX files for '!TOAD_Address!/%TOAD_Filename%.jar/'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
			if exist Your_Files\!TOAD_Address!\oat\%TOAD_ABI%\%TOAD_Filename%.odex (
			    echo.delete("/system/!TOAD_Address!/oat/%TOAD_ABI%/%TOAD_Filename%.odex"^);>>Tool_Files\META-INF\com\google\android\updater-script
			)
			if exist Your_Files\!TOAD_Address!\oat\%TOAD_ABI%\%TOAD_Filename%.vdex (
			    echo.delete("/system/!TOAD_Address!/oat/%TOAD_ABI%/%TOAD_Filename%.vdex"^);>>Tool_Files\META-INF\com\google\android\updater-script
			)
            echo.ui_print(" Adding Deodexed '%TOAD_Filename%.jar'.."^);>>Tool_Files\META-INF\com\google\android\updater-script
            echo.package_extract_file("system/!TOAD_Address!/%TOAD_Filename%.jar","/system/!TOAD_Address!"^);>>Tool_Files\META-INF\com\google\android\updater-script
            echo.ui_print(" Setting Permissions.."^);>>Tool_Files\META-INF\com\google\android\updater-script
            echo.set_perm_recursive(0, 0, 0755, 0644, "/system/!TOAD_Address!"^);>>Tool_Files\META-INF\com\google\android\updater-script
            if %TOAD_Address:~0,6%==vendor (
                for /f "tokens=1-4 delims=/ " %%a in ("!TOAD_Address!") do (
                    set TOAD_Address=%%a\%%b
                )
            ) 
	        if exist Tool_Files\*.dex (
	    		del Tool_Files\*.dex /q >nul
		    )
	        if exist Tool_Files\*.cdex (
	    		del Tool_Files\*.cdex /q >nul
		    )
   		    if exist Tool_Files\*.cdex.new (
    		    del Tool_Files\*.cdex.new /q >nul
	        )
	        set /a TOAD_DeodexSuccesses+=1
			echo.run_program("/sbin/busybox", "umount", "/system"^);>>Tool_Files\META-INF\com\google\android\updater-script
            echo.ui_print(" "^);>>Tool_Files\META-INF\com\google\android\updater-script
            echo.ui_print(" Flashing Complete"^);>>Tool_Files\META-INF\com\google\android\updater-script
            echo.ui_print(" "^);>>Tool_Files\META-INF\com\google\android\updater-script
		)
	)
	if !temp2! neq !TOAD_DeodexErrors! (
       	echo.>>log.txt
        echo.>>log.txt
        echo.ERROR!!!! EXTRACTION FAILED!!!!>>log.txt
	)
    rmdir Tool_Files\system /s/q >nul
)

::-----------------------------------------------------------------------------------------------------------------------------

:ProcessVDEXFILES_END
:: We should now have a collection of fully deodexed APK and JAR files inside a flashable ZIP.
:: Or we should have a single deodexed file in the root folder, if the user selected that option.
exit /b
