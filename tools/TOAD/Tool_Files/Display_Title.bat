set Display_Title_temp=%2
set /a Display_Title_temp+=%TOAD_TitleLines%
mode con:cols=%1 lines=%Display_Title_temp%
echo.
echo.   oO^)-.     The
echo.  /__  _\    Open-Source  
echo.  \  \^(  ^|   Android    
echo.   \__^|\ ^{   Deodexer                                           
echo.   '  '--'  
echo.
echo.
echo.
exit /b