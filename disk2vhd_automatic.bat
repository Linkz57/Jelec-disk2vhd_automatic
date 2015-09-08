REM disk2vhd_automatic.bat
REM version 0.1
REM written by Tyler Francis for JelecUSA on 2015-09-08
REM this script is designed to aid a phase in automating a cheap backup system that will perform live, full-metal backups that are then able to be quickly virtualized at a moment's notice.

REM this script must be run as an Administrator, so it can spawn disk2vhd.exe with the permissions it needs to have.



REM parse and edit the date, to make it filename-friendly
REM Thanks to Alex K. for the following two lines. https://stackoverflow.com/users/246342/alex-k
set hr=%time:~0,2%
if "%hr:~0,1%" equ " " set hr=0%hr:~1,1%


REM find the name of the computer and save it in a variable
REM Thanks to Dave Webb for the following two lines. https://stackoverflow.com/users/3171/dave-webb
FOR /F "usebackq" %%i IN (`hostname`) DO SET host=%%i
ECHO %host%


REM this mkdir will make sure the destination exists (not that it is reachable and writable). In a future version I will test for "The network path was not found." and send an email, or something like that. Anyway, if this directory already exists, (which it always should, except for the first time) then it'll print "A subdirectory or file \\test-hyperv-201\c vhd repo\foo already exists." and just go on to the next line.
mkdir "\\test-hyperv-201\c vhd repo\%host%"
disk2vhd.exe c: "\\test-hyperv-201\c vhd repo\%host%\%host%_C_%date:~-4,4%-%date:~-10,2%-%date:~-7,2%_%hr%-%time:~3,2%-%time:~6,2%"
