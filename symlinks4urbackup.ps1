# symlinks4urbackup.ps1
# Written by Tyler Francis on 2016-08-05
# The idea is to create a Windows symlink in each directory created by urBackup 2.0.31
# so that the new directory structure works with Hyper-V 2012r2




# First: we need to figure out what the parent VHD file should be.
# Because urBackup writes VHDs that only look for its parent,
# and because symlinks are super tiny, 
# we'll just make a symlink for every possible parent,
# and let each incremental VHD pick what it wants from among the symlinks.

# In the 3 months I've been using urBackup
# I've never had an incremental image larger than 125 GiB
# I've also never had a full image smaller than 440 GiB
# This gives me a wide margin of error to work in. 
# To err on the safe side, 
# I'll tell PowerShell to ignore any files smaller than 200 GiB.
$ignoreSmall = 214748364800


# Now, where do we look for these VHD files?
$vhdPath = "R:"


# Are we dealing with VHD files?
# or VHDX or zvhd or what?
$extension = "vhd"


# Now, let's look for the parent VHDs.
Get-ChildItem $vhdPath -recurse -include *.$extension |  # look in the path specified above for anything with the extension specified above.
where-object {$_.length -gt $ignoreSmall} | # Filter that list to exclude anything smaller than the size specified above.
ft fullname | # format the now smaller list to only show the full path of the found files.
Out-String -Stream | # format those paths in a way Select-String can understand.
Select-String -Pattern "$extension" -outvariable possibleParentsPath # Remove the header from the FT command, and reduce the list to just filenames and nothing else. Then save the result in a variable for use later.

# Clean up the empty lines from the variable we just created
$possibleParentsPath = $possibleParentsPath -creplace '(?m)^\s*\r?\n',''


# While we're at it, let's also just capture the name of the possible parents,
# without the rest of the path info.
Get-ChildItem $vhdPath -recurse -include *.$extension | 
where-object {$_.length -gt $ignoreSmall} | 
ft name |
Out-String -Stream | 
Select-String -Pattern "$extension" -outvariable possibleParentsName

# Clean up the empty lines from the variable we just created
$possibleParentsName = $possibleParentsName -creplace '(?m)^\s*\r?\n',''

$vhdPathBeginning = $vhdPath.SubString(0,2)
# That's only half of the information we need, though.
# Where are the folders of the incremental VHDs?
# We need to know this to fill those folders with symlinks to their possible parents.
Get-ChildItem $vhdPath | # list everything in the path specified above
?{ $_.PSIsContainer } | # of that list, show only folders (AKA Containers) 
Select-Object FullName | # Show the full path of each of those folders.
Out-String -Stream | 
Select-String -Pattern "$extension" |
ForEach-Object -Process {
	$symlinkDestination = $_ | Out-String -Stream | Select-String -Pattern "$vhdPathBeginning"
	# Clean up the empty lines from the variable we just created
	$symlinkDestination -replace '(?m)^\s*\r?\n',''
	$symlinkDestination -replace '[^\p{L}\p{Nd}/_/:/\-/\\]', '' # this works, but doesn't solve any problems. I thought there might be an invisible character like a line ending at the end, but now I don't think there is...
	
	$possibleParentsPath | ForEach-Object -Process {
		# echo $symlinkDestination
		# echo $possibleParentsName
		# echo $symlinkDestination\$possibleParentsName
		# echo $_
		# echo ""
		# echo ""
		cd $symlinkDestination
# 		cmd /c mklink $possibleParentsName $_
	}
}

