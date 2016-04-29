#!/bin/bash

## disk2vhd_cleanup.sh
## version 0.5

\rm /mnt/disk2vhd/clean.log

function clean {
	cd /mnt/disk2vhd/$1
	echo $1 >> /mnt/disk2vhd/clean.log
	echo "________" >> /mnt/disk2vhd/clean.log
	ls -tp | grep -v '/$' | tail -n +6 >> /mnt/disk2vhd/clean.log
	echo "" >> /mnt/disk2vhd/clean.log
	echo "" >> /mnt/disk2vhd/clean.log
	echo "" >> /mnt/disk2vhd/clean.log
}

clean 1
clean 2
clean 3
clean 4
clean 5

cat /mnt/disk2vhd/clean.log | mail -s "I want to delete these old VHD files" tyler.francis@jelec.com
