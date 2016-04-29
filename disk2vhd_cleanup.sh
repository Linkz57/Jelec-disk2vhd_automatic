## disk2vhd_cleanup.sh
## vserion 0.1

## 1
ls -tp /mnt/disk2vhd/1 | grep -v '/$' | tail -n +6 | mail -s "I think we should delete these old VHD files for 1" tyler.francis@jelec.com

## 2
ls -tp /mnt/disk2vhd/2 | grep -v '/$' | tail -n +6 | mail -s "I think we should delete these old VHD files for 2" tyler.francis@jelec.com

## 3
ls -tp /mnt/disk2vhd/3 | grep -v '/$' | tail -n +6 | mail -s "I think we should delete these old VHD files for 3" tyler.francis@jelec.com

## 4
ls -tp /mnt/disk2vhd/4 | grep -v '/$' | tail -n +6 | mail -s "I think we should delete these old VHD files for 4" tyler.francis@jelec.com

## 5
ls -tp /mnt/disk2vhd/5 | grep -v '/$' | tail -n +6 | mail -s "I think we should delete these old VHD files for 5" tyler.francis@jelec.com
