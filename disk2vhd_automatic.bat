REM disk2vhd_automatic.bat
REM version 0.6
REM written by Tyler Francis for JelecUSA on 2015-09-08
REM this script is designed to aid a phase in automating a cheap backup system that will perform live, full-metal backups that are then able to be quickly virtualized at a moment's notice.

REM this script must be run as an Administrator, so it can spawn disk2vhd.exe with the permissions it needs to have.



REM parse and edit the current date and time, to make it filename-friendly by replacing spaces with zeros.
REM thanks to Alex K. for the following two lines. https://stackoverflow.com/questions/7727114/batch-command-date-and-time-in-file-name
set hr=%time:~0,2%
if "%hr:~0,1%" equ " " set hr=0%hr:~1,1%


REM find the name of the computer and save it in a variable
REM thanks to Dave Webb for the following line. https://stackoverflow.com/questions/998366/how-to-store-the-hostname-in-a-variable-in-a-bat-file
FOR /F "usebackq" %%i IN (`hostname`) DO SET host=%%i


REM this mkdir will make sure the destination exists. If this directory already exists, (which it always should, except for the first time) then it'll print "A subdirectory or file \\test-hyperv-201\c vhd repo\foo already exists." and just go on to the next line.
mkdir "\\test-hyperv-201\c vhd repo\%host%"

REM log backup attempt and create something to test against before actual backup
echo Backup's log >> "\\test-hyperv-201\c vhd repo\%host%\backup.log"
echo Stardate %date:~-4,4%/%date:~-10,2%/%date:~-7,2% >> "\\test-hyperv-201\c vhd repo\%host%\backup.log"
echo Startime %hr%:%time:~3,2%:%time:~6,2% >> "\\test-hyperv-201\c vhd repo\%host%\backup.log"
echo It begins >> "\\test-hyperv-201\c vhd repo\%host%\backup.log"
echo. >> "\\test-hyperv-201\c vhd repo\%host%\backup.log"

REM test backup destination for a successful write. If failed, email the authorities and make a local note of failure.
if exist "\\test-hyperv-201\c vhd repo\%host%\backup.log" (
	set accessibility=true
) else (
set accessibility=false
	blat OMITTED -subject "Lo! %host% has become error, destroyer of backup schedules." -html -body "<p>The intended destination was \\test-hyperv-201\c vhd repo\%host%</p><br /><p>But as you've probably already guessed: there is no ping I am recieving. A distant share out on the network. It's only coming through in dropped packets. My SYNs send, but it can't ACK what I'm saying. <br /><br />When I was a subroutuine, I had a error; my STDOUT looked like two baloons. Now I've got that feeling once again. I can explain, you'd probably understand. This is now how I am: <br /> IIIIIIiiiiii... have become, uncomfortably erroneous.</p>"
	echo "Backup's log >> backup.log
	echo Stardate %date:~-4,4%/%date:~-10,2%/%date:~-7,2% >> backup.log
	echo Startime %hr%:%time:~3,2%:%time:~6,2% >> backup.log
	echo I failed to find my destination. The network has left me, hasn't it? Woe is me, an island of a server! Hello hello hello... Can anybody navigate there? Just reply if you can ack me. Is there anynas home? >> backup.log
	echo. >> backup.log
	echo. >> backup.log
	echo. >> backup.log
)


REM thanks to Aacini for time calculation code: https://stackoverflow.com/questions/9922498/calculate-time-difference-in-windows-batch-file
REM Get start time:
for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
   set /A "start=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)

disk2vhd.exe c: "\\test-hyperv-201\c vhd repo\%host%\%host%_C_%date:~-4,4%-%date:~-10,2%-%date:~-7,2%_%hr%-%time:~3,2%-%time:~6,2%"

REM Get end time:
for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
   set /A "end=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)

REM Get elapsed time:
set /A elapsed=end-start

REM Show elapsed time:
set /A hh=elapsed/(60*60*100), rest=elapsed%%(60*60*100), mm=rest/(60*100), rest%%=60*100, ss=rest/100, cc=rest%%100
if %mm% lss 10 set mm=0%mm%
if %ss% lss 10 set ss=0%ss%
if %cc% lss 10 set cc=0%cc%
echo %hh%:%mm%:%ss%,%cc%

if %accessibility%==true (
	echo It finished on %date:~-4,4%/%date:~-10,2%/%date:~-7,2% at %hr%:%time:~3,2%:%time:~6,2% >> "\\test-hyperv-201\c vhd repo\%host%\backup.log"
	echo The whole C:\ backup took %hh% hours, %mm% minutes, and %ss% seconds to complete >> "\\test-hyperv-201\c vhd repo\%host%\backup.log"
	echo. >> "\\test-hyperv-201\c vhd repo\%host%\backup.log"
	echo. >> "\\test-hyperv-201\c vhd repo\%host%\backup.log"
	echo. >> "\\test-hyperv-201\c vhd repo\%host%\backup.log"
) else (
	echo apparently I can't write what you're now reading >> "\\test-hyperv-201\c vhd repo\%host%\backup.log"
)
