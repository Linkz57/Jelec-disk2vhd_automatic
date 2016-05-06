#!/bin/bash

## disk2vhd_cleanup.sh
## version 1.0


## remove the old log, since it was probably already emailed out.
## the leading slash makes sure no goofy aliases of rm are being used. 
\rm /mnt/disk2vhd/clean.log

function clean {
	cd /mnt/disk2vhd/$1
	## section header for email
	echo $1 >> /mnt/disk2vhd/clean.log
	echo "________" >> /mnt/disk2vhd/clean.log
	## here is where the actual work happens. 
	## ls sorts by age and throws a trailing slash for folders
	## grep removes anything with a trailing slash aka folders
	## tail is then given a list of non-folders sorted by age of last modification, and then ignores the 5 at the top (newest)
	## the output of tail (all except 5 newest) is saved in a text file
	ls -tp | grep -v '/$' | tail -n +6 >> /mnt/disk2vhd/clean.log
	## now do the same thing, except delete those items, instead of saving their names in a text file.
	## thanks to mklement0 for these two lines that do the actual work in this script.
	## https://stackoverflow.com/questions/25785/delete-all-but-the-most-recent-x-files-in-bash
	ls -tp | grep -v '/$' | tail -n +6 | xargs -d '\n' rm --
	## make some room at the end of a section, to make the text file more human-friendly
	echo "" >> /mnt/disk2vhd/clean.log
	echo "" >> /mnt/disk2vhd/clean.log
	echo "" >> /mnt/disk2vhd/clean.log
}

## I've set up my folders to each hold one server's collection of VHDs. 
## I've got 5 servers, one for each folder, and am constantly saving VHDs from those servers into these folders.
## now that the function has been defined, run it using these arguments as folder names to clean.
clean server1
clean machine2
clean folder3
clean directory4
clean vhdrepo5

## now use that text file I was creating during each running of the function as the body of an email.
cat /mnt/disk2vhd/clean.log | mail -s "I have deleted these old VHD files" me@jelec.com
## on Debian, I set up the mailer with 
##   apt install exim4-daemon-light mailutils && dpkg-reconfigure exim4-config
## now I can pipe things to "mail" and it works great.


## I like that modification age is measured instead of creation age
## an old VHD file that is currently being virtualized is being written to, meaning recently modification
## this should help prevent VMs from having their VHDs deleted out from under them.
