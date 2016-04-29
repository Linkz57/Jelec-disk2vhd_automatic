# disk2vhd_automatic.bat
this script is designed to aid a phase in automating a cheap backup system that will perform live, full-metal backups that are then able to be quickly virtualized at a moment's notice. This script is scheduled to run locally by each of the servers we want to be backed up.


# disk2vhd_cleanup.sh
This script is designed to cleanup the constant influx of VHD files created by disk2vhd_automatic.bat. It does this by deleting all but the 5 newest files for each server. This script is scheduled to run on a single server, and clean up each VHD repository created by each server running the disk2vhd_automatic.bat script.
