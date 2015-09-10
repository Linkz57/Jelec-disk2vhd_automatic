@echo off
REM disk2vhd_automatic.bat
REM version 2.6
REM written by Tyler Francis for JelecUSA on 2015-09-08
REM this script is designed to aid a phase in automating a cheap backup system that will perform live, full-metal backups that are then able to be quickly virtualized at a moment's notice.
echo.
echo.
echo.
echo.
echo.
echo " " " " " " " " " " " " " " " " " " " " " " " " " " " "
echo "     __    __                 _               _      "
echo "    / / /\ \ \__ _ _ __ _ __ (_)_ __   __ _  / \     "
echo "    \ \/  \/ / _` | '__| '_ \| | '_ \ / _` |/  /     "
echo "     \  /\  / (_| | |  | | | | | | | | (_| /\_/      "
echo "      \/  \/ \__,_|_|  |_| |_|_|_| |_|\__, \/        "
echo "    ----------------------------------|___/------    "
echo "   | This script must be run as an Administrator |   "
echo "   |  so it can spawn disk2vhd.exe and diskpart  |   "
echo "   |   with the permissions they need to have.   |   "
echo "    ---------------------------------------------    "
echo "                                                     "
echo " " " " " " " " " " " " " " " " " " " " " " " " " " " "
echo.
echo.
echo.
echo.
echo.


timeout /t 20
@echo on
c:
cd %userprofile%\Desktop
set actualerror="This is a blank error. You should never see this, but obviously you are--right now. This means that the script has broken is new and exciting ways, and it's anyone's guess as to whether the backup was sucessful and is bootable.


REM parse and edit the current date and time, to make it filename-friendly by replacing spaces with zeros.
REM thanks to Alex K. for the following two lines, and everywhere else you see %date%, %hr%, or %time%. https://stackoverflow.com/questions/7727114/batch-command-date-and-time-in-file-name
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
	set actualerror="<p>The intended destination was \\test-hyperv-201\c vhd repo\%host% <br />But I could not find it.</p> I spoke into the void and said Hello hello hello... Can anybody navigate there? Just reply if you can ACK me. Is there anynas home? <br />But there is no ping I am recieving. A distant share out on the network. It's only coming through in dropped packets. My SYNs send, but it can't ACK what I'm saying."
	goto fail
)


del dpart_start.txt
echo sel disk 0 > dpart_start.txt
set provisioncheck=false
REM apparently different machines have different disk layouts--who knew? Here's where I do a little forking to accommodate different machines. 
REM I dislike hard-coding, but its not like this script will see much wide-spread use.
REM since I can't use something like 'if host==1 || host==2', I'll just repeat these 4 lines for each server explicitly. It seems wasteful, but the Internet's suggestion of clever variable manipulation is slightly less stable and a lot more complicated. Instead, I'll just bloat up my line count, and wish I was scripting for a better shell like Bash or even PowerShell.
if %host%==OMITTED (
	set mahpart=2
	set provisioncheck=true
)
if %host%==OMITTED (
	set mahpart=1
	set provisioncheck=true
)
if %host%==OMITTED (
	set mahpart=2
	set provisioncheck=true
)
if %host%==OMITTED (
	set mahpart=1
	set provisioncheck=true
)
if %host%==OMITTED (
	set mahpart=1
	set provisioncheck=true
)
if %host%==OMITTED (
	set mahpart=2
	set provisioncheck=true
)
if %host%==OMITTED (
	set mahpart=1
	set provisioncheck=true
)
if %host%==OMITTED (
	set mahpart=2
	set provisioncheck=true
)

REM if none of those previous checks pass, that means this is running on an unknown machine. If I don't know exactly where that System Reserved/Recovery partition is, I won't be able to include it in the backup, and we'll have a useless, unbootable VHD. I'd rather have no VHD than a useless one, so let's fail instead.
if %provisioncheck%==false (
	set actualerror="I am running this backup script on an unknown machine. The C:\ drive might always be the C:\ drive, but the actual position of the partitions seem to be a grab-bag of options. I have attempted to assign a temporary letter to the System Reserved partition, with a hard-coded provision for each of our servers, but I do not have such a provision for this machine, the one you call %host%.<br />Instead of making a non-bootable backup of just C, I have decided not to waste the storage, cycles, and watts.<br /><br />Because there is no provision I am recieving. A distant partition out on the disk. I'm only coming through in assumptions. Your fingers type, but I can't understand what you're saying."
	goto fail
)

REM assign that mysterious first partition (usually System Reserved, sometimes Recovery as well) a drive letter, so I can target it with disk2vhd, without having to copy EVERY partition.
REM thanks to bwalraven for this diskpart hack-around. It's not perfect, but it ought to do the trick. http://forum.sysinternals.com/how-to-select-a-sys-partition-from-commandline_topic20947.html
echo sel part %mahpart% >> dpart_start.txt
echo assign letter=b noerr >> dpart_start.txt
diskpart /s dpart_start.txt

REM thanks to Aacini for time calculation code: https://stackoverflow.com/questions/9922498/calculate-time-difference-in-windows-batch-file
REM Get start time:
for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
   set /A "start=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)

disk2vhd.exe -accepteula b: c: "\\test-hyperv-201\c vhd repo\%host%\%host%_BC_%date:~-4,4%-%date:~-10,2%-%date:~-7,2%_%hr%-%time:~3,2%-%time:~6,2%"

REM Get end time:
for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
   set /A "end=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)

REM un-assign that first partition, lest it lose its mystique. 
del dpart_end.txt
echo sel disk 0 > dpart_end.txt
echo sel part %mahpart% >> dpart_end.txt
echo remove letter=b noerr >> dpart_end.txt
diskpart /s dpart_end.txt
timeout /3
del dpart_start.txt
del dpart_end.txt

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
	echo The whole System Reserved and C:\ backup took %hh% hours, %mm% minutes, and %ss% seconds to complete >> "\\test-hyperv-201\c vhd repo\%host%\backup.log"
	echo. >> "\\test-hyperv-201\c vhd repo\%host%\backup.log"
	echo. >> "\\test-hyperv-201\c vhd repo\%host%\backup.log"
	echo. >> "\\test-hyperv-201\c vhd repo\%host%\backup.log"
) else (
	echo apparently I can't write what you're now reading >> "\\test-hyperv-201\c vhd repo\%host%\backup.log"
)

@echo off
echo.
echo.
echo.
echo.
echo.
echo " " " " " " " " " " " " " " " " " " " " " "
echo "    ____    ____  ___   ____    ____     "
echo "    \   \  /   / /   \  \   \  /   /     "
echo "     \   \/   / /  ^  \  \   \/   /      "
echo "      \_    _/ /  /_\  \  \_    _/       "
echo "        |  |  /  _____  \   |  |         "
echo "        |__| /__/     \__\  |__|         "
echo "                                         "
echo "    You have reached the logical end     "
echo "    of a successful script execution.    "
echo "                                         "
echo " " " " " " " " " " " " " " " " " " " " " "
echo.
echo.
echo.
echo.
echo.


timeout /t 10
@echo on
exit


:fail
blat OMITTED -subject "Lo! %host% has become error, destroyer of backup schedules." -html -body "%actualerror% <br /><br />When I was a subroutuine, I had a error; my STDOUT looked like two baloons. Now I've got that feeling once again. I can explain, you'd probably understand. This is now how I am: <br /> IIIIIIiiiiii... have become, uncomfortably erroneous.</p>"
echo "Backup's log >> backup.log
echo Stardate %date:~-4,4%/%date:~-10,2%/%date:~-7,2% >> backup.log
echo Startime %hr%:%time:~3,2%:%time:~6,2% >> backup.log
echo I have failed. Woe is me, a wretch of a script! %actualerror% >> backup.log
echo When I was a subroutuine, I had a error; my STDOUT looked like two baloons. Now I've got that feeling once again. I can explain, you'd probably understand. This is now how I am: >> backup.log
echo IIIIIIiiiiii... have become, uncomfortably erroneous. >> backup.log
echo. >> backup.log
echo. >> backup.log
echo. >> backup.log
echo.
echo.
echo.
echo.
echo whelp, this failed.
timeout /t 120
exit
