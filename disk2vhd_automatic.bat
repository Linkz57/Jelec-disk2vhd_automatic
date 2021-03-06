@echo off
REM disk2vhd_automatic.bat
REM version 3.5.3
REM written by Tyler Francis for Jelec USA on 2015-09-08
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
cd c:\disk2vhd_automatic
set actualerror="This is a blank error. You should never see this, but obviously you are--right now. This means that the script has broken is new and exciting ways, and it's anyone's guess as to whether the backup was successful and is bootable."
set actualErrorLevel=Potentially Catastrophic

REM Trying to make the errors more legible, so I'm going to take jeb's suggestion for making multi-line variables. Hopefully this doesn't break anything
REM https://stackoverflow.com/questions/3294599/do-batch-files-support-multiline-variables
setlocal enableDelayedExpansion
set NL=^


REM parse and edit the current date and time, to make it filename-friendly by replacing spaces with zeros.
REM thanks to Alex K. for the following two lines, and everywhere else you see %date%, %hr%, or %time%. https://stackoverflow.com/questions/7727114/batch-command-date-and-time-in-file-name
set hr=%time:~0,2%
if "%hr:~0,1%" equ " " set hr=0%hr:~1,1%


REM find the name of the computer and save it in a variable
REM thanks to Dave Webb for the following line. https://stackoverflow.com/questions/998366/how-to-store-the-hostname-in-a-variable-in-a-bat-file
FOR /F "usebackq" %%i IN (`hostname`) DO SET host=%%i


REM This is the folder where everything will be saved to, from logs to the actual VHD files
set saveDir="\\OMITTED\disk2vhd"


REM this mkdir will make sure the destination exists. If this directory already exists, (which it always should, except for the first time) then it'll print "A subdirectory or file \\hyperv-server\vhd\disk2vhd\foo already exists." and just go on to the next line.
mkdir "%saveDir%\%host%"

REM log backup attempt and create something to test against before actual backup
echo Backup's log >> "%saveDir%\%host%\backup.log"
REM echo "<br />" >> "%saveDir%\%host%\backup.log"
echo Stardate %date:~-4,4%/%date:~-10,2%/%date:~-7,2% >> "%saveDir%\%host%\backup.log"
REM echo "<br />" >> "%saveDir%\%host%\backup.log"
echo Startime %hr%:%time:~3,2%:%time:~6,2% >> "%saveDir%\%host%\backup.log"
REM echo "<br />" >> "%saveDir%\%host%\backup.log"
echo It begins >> "%saveDir%\%host%\backup.log"
REM echo "<br />" >> "%saveDir%\%host%\backup.log"
REM echo "<br />" >> "%saveDir%\%host%\backup.log"
echo. >> "%saveDir%\%host%\backup.log"

REM test backup destination to make sure it exists. If failed, email the authorities and make a local note of failure.
if exist "%saveDir%\%host%\backup.log" (
	set accessibility=true
) else (
	set accessibility=false
	set actualerror=The intended destination was %saveDir%\%host% !NL!But I could not find it.
	REM I spoke into the void and said Hello hello hello... Can anybody navigate there? Just reply if you can ACK me. Is there anynas home?<br />But there is no ping I am receiving. A distant share out on the network. It's only coming through in dropped packets. My SYNs send, but it can't ACK what I'm saying."
	set actualErrorLevel=ERROR
	goto fail
)

REM test backup destination for available free space. Unfortunately, this only works if the destination is a Windows machine using a single volume for VHD storage.
wmic /node:"OMITTED" LogicalDisk Where DeviceID="R:" Get FreeSpace | find /V "FreeSpace" > temp.txt
set /P availableSpace=<temp.txt
del temp.txt
REM Since this language is stupid, I can't math large numbers. Instead I'm going to chop the last 6 digits off (plus the two line ending characters I think) and math this grossly rounded number instead.
REM I want to make sure I have at least 55.6 GiB free, which should return true or fail from 32-bit integer stupidity If I have enough available.
set chopSpace=%availableSpace:~0,-8%
if %chopSpace% LSS 59701 (
	set actualerror=Not enough free space. !NL! !NL!There's probably not enough space to store a new VHD, so I didn't try. I might be able to fit one more VHD in there, but come on. You have less than 56 GigaBytes of free space; you can't expect me to work in these conditions. !NL!You literally have %availableSpace%Bytes available. !NL!Not a lot.
	set actualErrorLevel=ERROR
	goto fail
)


del dpart_start.txt
echo sel disk 0 > dpart_start.txt
set provisioncheck=false
set rundiskpart=true

REM apparently different machines have different disk layouts--who knew? Here's where I do a little forking to accommodate different machines.
REM I dislike hard-coding, but its not like this script will see much wide-spread use.
REM since I can't use something like 'if host==1 || host==2', I'll just repeat these 4 lines for each server explicitly.
REM It seems wasteful, but the Internet's suggestion of clever variable manipulation is slightly less stable and a lot more complicated.
REM Instead, I'll just bloat up my line count, and wish I was scripting for a better shell like Bash or even PowerShell.
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
	REM set mahpart=1
	set provisioncheck=true
	set rundiskpart=false
)
if %host%==OMITTED (
	REM set mahpart=1
	set provisioncheck=true
	set rundiskpart=false
)
if %host%==OMITTED (
	set mahpart=2
	set provisioncheck=true
)
if %host%==OMITTED (
	REM set mahpart=1
	set provisioncheck=true
	set rundiskpart=false
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

REM if none of those previous checks pass, that means this is running on an unknown machine. If I don't know exactly where that System Reserved/Recovery partition is, I won't be able to include it in the backup, and we'll have a useless, unbootable VHD. I'd rather have no VHD than a useless one, so let's fail instead.
if %provisioncheck%==false (
	set actualerror=I am running this backup script on an unknown machine. !NL! !NL!The C:\ drive might always be the C:\ drive, but the actual position of the partitions seem to be a grab-bag of options. I have attempted to assign a temporary letter to the System Reserved partition, using a hard-coded provision with each of our servers in mind, but I do not have such a provision on this machine, the one you refer to as %host%. !NL!Instead of making a non-bootable backup of just C, I have decided not to waste the storage, cycles, and watts.
	set actualErrorLevel=ERROR
	goto fail
)

REM assign that mysterious first partition (usually System Reserved, sometimes Recovery as well) a drive letter, so I can target it with disk2vhd, without having to copy EVERY partition.
REM thanks to bwalraven for this diskpart hack-around. It's not perfect, but it ought to do the trick. 
REM http://forum.sysinternals.com/how-to-select-a-sys-partition-from-commandline_topic20947.html
echo sel part %mahpart% >> dpart_start.txt
echo assign letter=b noerr >> dpart_start.txt
if %rundiskpart%==true (
	diskpart /s dpart_start.txt
)

set humanStartDate=%date:~-4,4%/%date:~-10,2%/%date:~-7,2%
set humanStartTime=%hr%:%time:~3,2%:%time:~6,2%
set humanStartDay=%date:~-7,2%
REM thanks to Aacini for time calculation code: https://stackoverflow.com/questions/9922498/calculate-time-difference-in-windows-batch-file
REM Get start time, as measured in centiseconds:
for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
   set /A "start=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)

disk2vhd.exe -accepteula b: c: "%saveDir%\%host%\%host%_BC_%date:~-4,4%-%date:~-10,2%-%date:~-7,2%_%hr%-%time:~3,2%-%time:~6,2%"

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
timeout /t 3
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
	echo It finished on %date:~-4,4%/%date:~-10,2%/%date:~-7,2% at %hr%:%time:~3,2%:%time:~6,2% >> "%saveDir%\%host%\backup.log"
	echo. >> "%saveDir%\%host%\backup.log"
	echo The whole System Reserved and C:\ backup took %hh% hours, %mm% minutes, and %ss% seconds to complete >> "%saveDir%\%host%\backup.log"
	echo. >> "%saveDir%\%host%\backup.log"
	echo. >> "%saveDir%\%host%\backup.log"
	echo. >> "%saveDir%\%host%\backup.log"
) else (
	echo apparently I can't write what you're now reading. This is an illogical scenario. >> "%saveDir%\%host%\backup.log"
)

REM notify the authorities if the backup took less than 3 minutes.
if %elapsed% LSS 18000 (
	if %humanStartDay%==%date:~-7,2% (
		set actualerror=This backup was too fast. !NL! !NL! %host% either has less than a gig of used space, super fast disks, or something has gone wrong. !NL! !NL!Now I may be a simple script, designed to do exactly what I'm told without thinking too much about it, but this backup seemed WAY too fast. !NL!I would recommend you try to boot from the VHD I just tried to make, just to make sure it works the way you want it to. No one wants a backup that fails silently, so this is me trying to make some noise. !NL!If I'm wrong, and you're imaging SSDs because you don't care about their lifespan, then go ahead and edit this error threshold so I only pipe up when you want me to. You should be able to find it on line 215 of c:\disk2vhd_automatic.bat last time I checked. Things change, so ask around if you don't see it. Also, by C:\ I mean the local disk of %host%
		set actualErrorLevel=Warning
		goto fail
	) else (
		set actualerror=The backup ran over night. !NL! !NL!No problem here, just wanted you to know that %host% started backing up before midnight, and finished sometime after midnight. !NL!Or the backup process took a month to complete, but that's much less likely.
		set actualErrorLevel=Info
		REM I'm only failing here temporarily, to receive these emails. This is the last line that does anything anyway, so I don't feel I'm missing out on the rest of the script. 
		REM I'll comment this goto out later, and just assign these variables without ever using them, just to catch an odd failure if it happens around this area.
		REM goto fail
	)
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
echo Backup's log > email.txt
echo Date Now:     %date:~-4,4%/%date:~-10,2%/%date:~-7,2% >> email.txt
echo Time Now:     %hr%:%time:~3,2%:%time:~6,2% >> email.txt
echo. >> email.txt
echo Start Date:   %humanStartDate% >> email.txt
echo Start Time:   %humanStartTime% >> email.txt
echo. >> email.txt
echo. >> email.txt
echo Error Information:
echo. >> email.txt
echo !actualerror! >> email.txt
echo. >> email.txt
REM echo When I was a subroutuine, I had a error. my STDOUT looked like two balloons. Now I've got that feeling once again. I can explain, you'd probably understand. This is now how I am >> email.txt
REM echo IIIIIIiiiiii... have become, uncomfortably erroneous. >> email.txt
echo. >> email.txt
type email.txt >> backup.log
echo. >> backup.log
echo. >> backup.log
echo. >> backup.log
echo. >> backup.log
echo. >> backup.log
type email.txt | blat -to tyler.francis@jelec.com -server 10.0.0.0 -f disk2vhd_automatic@jelec.com -subject "%actualErrorLevel%: %host% set us up the backup"
echo.
echo.
echo.
echo.
echo whelp, this failed.
timeout /t 120
exit
