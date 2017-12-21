## hyperv_backup_clusters.ps1
## Version 0.3
## Basically, it exports all VMs that have notes reading Auto-Backuped-Up then it compresses the exports, then moves the arvhive to a Samba share and cleans up the local backups.

$tempBackupLocation = "C:\ClusterStorage\Volume1\scripts\auto_hyperv_backups"
$mahCluster = "hypervcluster"


## Thanks to Karl Glennon for the following 7-Zip function
## https://stackoverflow.com/questions/1153126/how-to-create-a-zip-archive-with-powershell
function create-7zip([String] $aDirectory, [String] $aZipfile){    
    [string]$pathToZipExe = "$($Env:ProgramFiles)\7-Zip\7z.exe";    
    [Array]$arguments = "a", "-tzip", "$aZipfile", "$aDirectory";    & $pathToZipExe $arguments;
}

$todayDate = $((get-date).tostring('yyy-MM-dd_HH-mm'))
$hostname = Invoke-Command {hostname.exe}


## Thanks to Trevor Sullinvan for the following for loop
## https://stackoverflow.com/questions/21409249/powershell-how-to-return-all-the-vms-in-a-hyper-v-cluster
$clusterNodez = get-clusternode -cluster $mahCluster
foreach($item in $clusterNodez) {
    get-vm -ComputerName $item.Name | where-object { $_.Notes -like "*Auto-Backed-Up*" } | Export-VM -Path "$tempBackupLocation\$todayDate\"
}
create-7zip "$tempBackupLocation\$todayDate\" "$tempBackupLocation\$todayDate.zip"
move-item "$tempBackupLocation\$todayDate.zip" -destination "\\houqnap01\IT\Backups\VMs\sbs_hyperv\auto_hyperv_backups\$hostname\" -Force
remove-item -recurse "$tempBackupLocation\$todayDate"
