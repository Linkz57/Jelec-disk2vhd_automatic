## hyperv_backup.ps1
## Version 1.4
## Basically, it exports all VMs that have notes reading Auto-Backuped-Up then it compresses the exports, then moves the archive to a Samba share and cleans up the local backups.


## Thanks to Karl Glennon for the following 7-Zip function
## https://stackoverflow.com/questions/1153126/how-to-create-a-zip-archive-with-powershell
function create-7zip([String] $aDirectory, [String] $aZipfile){    
    [string]$pathToZipExe = "$($Env:ProgramFiles)\7-Zip\7z.exe";    
    [Array]$arguments = "a", "-tzip", "$aZipfile", "$aDirectory";    & $pathToZipExe $arguments;
}

$todayDate = $((get-date).tostring('yyy-MM-dd_HH-mm'))
$hostname = Invoke-Command {hostname.exe}

get-vm | where-object { $_.Notes -like "*Auto-Backuped-Up*" } | Export-VM -Path F:\auto_hyperv_backups\$todayDate\
create-7zip "F:\auto_hyperv_backups\$todayDate\" "F:\auto_hyperv_backups\$todayDate.zip"
new-item -ItemType directory -Force -Path "\\houqnap01\IT\Backups\VMs\auto_hyperv_backups\$hostname\"
move-item "F:\auto_hyperv_backups\$todayDate.zip" -destination "\\houqnap01\IT\Backups\VMs\auto_hyperv_backups\$hostname\" -Force
remove-item -recurse "F:\auto_hyperv_backups\$todayDate"
