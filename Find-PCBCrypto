function Find-PCBCrypto {
<#
.SYNOPSIS
Find files with hallmark signs of CryptoLocker
.DESCRIPTION
Find-PBRCrypto is an aid in hunting down files encrypted with CryptoLocker or other similar encryption malware.  It relies on Get-FileTimeStamp, written by Boe Prox.
Get-FileTimeStamp.ps1 is available at http://gallery.technet.microsoft.com/scriptcenter/Get-MFT-Timestamp-of-a-file-9227f399
 
It is NOT a full fledged scanner and cannot determine if a file is actually encrypted; it instead works on known "fingerprint" changes to files common with CryptoLocker.
 
It is the user's responsibility to exercise judgement and know how to use this tool to aid in discovering the scope of damage.
 
Find-PCBCrypto is written by and copyright of Christopher R. Lowery, aka The PowerShell Bear (poshcodebear.com; Twitter: @poshcodebear)
It is free for all to use, and free to distribute with attribution to the original author.
Get-FileTimeStamp, which Find-PCBCrypto relies upon, is written by and copyright of PowerShell MVP Boe Prox; without his fine work, this would not have been possible.
.PARAMETER Path
A list of folder paths to scan.  Both local paths (C:\folder\path) and UNC paths (\\server\share) are supported.
.PARAMETER InfectedUser 
Optional argument to only return files owned by a particular user.
Note: Wildcards are supported; otherwise, specify in format "DOMAIN\user".
.PARAMETER InfectionDate
Optional argument to specify a known date of infection; by default, it will scan against the current date.
InfectionDate must be in format mm/dd/yyyy, without trailing 0's (for example, 5/1/2014).
Note: if used with FullScan, InfectionDate will be ignored.
.PARAMETER DriveLetter
Optional argument to specify an available drive letter to use; by default, it will find and use a random available drive letter.
This must be one letter, between "D" and "Z", and not already be in use.
Note: this is used to reduce the number of characters in a path to a network resource to help avoid an issue with the 260 character path limit.
It is only used when the target is a UNC path in the \\server\share format; it is not used when the target is a local path.
.PARAMETER NoCompare
Switch to turn off date comparison; when selected, it will return all files with MFT timestamp on InfectionDate owned by user specified in InfectedUser.
Note: this switch only works when an InfectedUser is specified; if none is specified, this switch will be ignored and normal comparison will occur.
.PARAMETER FullScan
Switch to compare all files regardless of MFT change time.
.EXAMPLE
Find-PCBCrypto -Path "\\server\possibly infected share"
.LINK
http://www.poshcodebear.com
.LINK
Get-FileTimeStamp
#>
    [CmdletBinding()]
    param(        
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$True)]
        [Alias('Folder')]
        [string[]]$Path,
         
        [Alias('UserName')]
        [string]$InfectedUser,
 
        [Alias('Date')]
        [string]$InfectionDate,
 
        [ValidateLength(1,1)]
        [string]$DriveLetter,
 
        [switch]$NoCompare,
 
        [switch]$FullScan
    )
    BEGIN {
        # Parameter and environment sanity checking
        $TestPrereq = Get-Command -Name Get-FileTimeStamp -ErrorAction SilentlyContinue
        if (!$TestPrereq) { 
            Write-Warning -Message 'Get-FileTimeStamp must be loaded to run this. If you need Get-FileTimeStamp, it can be downloaded from:'
            Write-Warning -Message 'http://gallery.technet.microsoft.com/scriptcenter/Get-MFT-Timestamp-of-a-file-9227f399'
            Write-Error -Message 'Get-FileTimeStamp is required and not loaded!' `
                        -Category ResourceUnavailable `
                        -CategoryActivity 'Function run without prereq Get-FileTimeStamp loaded' `
                        -CategoryReason 'Get-FileTimeStamp is required to capture data' `
                        -RecommendedAction 'Load Get-FileTimeStamp'
            Break
        }
        if ($NoCompare -and !$InfectedUser) {
            Write-Warning -Message 'Using the NoCompare switch without InfectedUser is not supported and will have no effect.'
        }
 
        # Variable setup
        $StartTime = Get-Date
 
        if ($InfectionDate) {
            $regex = "^1?\d/[123]?\d/[12][90]\d{2}"
            if ($InfectionDate -notmatch $regex) {
                Write-Error -Message "$InfectionDate is not a valid date field.  Make sure to use the format mm/dd/yyyy, without leading 0's." `
                            -Category InvalidArgument `
                            -CategoryActivity 'Incorrect date field specified' `
                            -CategoryReason 'Comparison will fail to function if date is not in the proper format' `
                            -RecommendedAction 'Specify a date field in the correct format'
                Break
            }
            $Date = $InfectionDate
        }
        else {
            # Default to "Today"
            $TempDate = ("$(Get-Date)").Split()[0]
            $Date = "$(($TempDate.Split('/')[0]).Trim('0') + '/' + ($TempDate.Split('/')[1]).Trim('0') + '/' + $TempDate.Split('/')[2])"
        }
 
        # Drive letter setup
        $drives = Get-PSDrive -Name ? | Select-Object -ExpandProperty Name
        $letters = 68..90 | ForEach-Object -Process { [char]$_ } # Enumerates all letters after 'C'
        if ($DriveLetter) {
            if ($drives -contains $DriveLetter) {
                Write-Error -Message "$DriveLetter is already in use; select a different letter" `
                            -Category ResourceUnavailable `
                            -CategoryActivity 'DriveLetter specified that was already in use' `
                            -CategoryReason 'Specified DriveLetter cannot be mapped' `
                            -TargetObject $DriveLetter `
                            -RecommendedAction 'Specify a DriveLetter that is not already in use'
                Break
            }
            if ($letters -notcontains $DriveLetter) {
                Write-Error -Message "$DriveLetter is not a valid drive selection; you must chose an available drive letter above `"C`"" `
                            -Category InvalidArgument `
                            -CategoryActivity 'Invalid DriveLetter specified' `
                            -CategoryReason 'Unable to map DriveLetters not in the specified range' `
                            -TargetObject $DriveLetter `
                            -RecommendedAction 'Specify a DriveLetter over "C"'
                Break
            }
        }
        else {            
            foreach ($drive in $drives) {
                $letters = $letters | Where-Object -FilterScript { $_ -ne $drive }
            }
            $DriveLetter = Get-Random -InputObject $letters
            Write-Verbose -Message "DriveLetter not selected; automatically selected `"$DriveLetter`""
        }
         
        # Bad character array initialization (for future deep scanning)
        $badchars = @()
 
        $badchars += 1..32 | foreach {[char]$_}
        $badchars += 161..500 | foreach {[char]$_}
 
        Write-Verbose -Message "Process started at $StartTime"
    }
    PROCESS {       
         
        foreach ($folder in $Path) {
            if ($folder -like "\\*\*" -and $Host.Version.Major -ge 3) {
                # Note: Using this method does not work properly in PSv2
                # Retry to allow multiple attempts if first drive letter doesn't work
                $Retry = 3
                if ($letters -eq $null) {
                    # Drive letter manually set; no retry, fail if it doesn't mount
                    $Retry = -1
                }
                Write-Verbose -Message "Connecting $DriveLetter to $folder..."
                 
                do {
                    try {
                        New-PSDrive -Name $DriveLetter -PSProvider FileSystem -Root $folder -Persist -ErrorAction Stop | Out-Null
                        $FolderPath = $DriveLetter + ":\"
                        $RemoveDrive = $True
                    }
                    catch {
                        Write-Verbose -Message "Connecting $DriveLetter to $folder failed.  $Retry attempts remaining."
                        if ($Retry -gt 0 -and $letters.count -gt 1) {
                            $letters = $letters | Where-Object -Filter {$_ -ne $DriveLetter}
                            $DriveLetter = Get-Random -InputObject $letters
                            Write-Verbose -Message "Retrying with $DriveLetter..."
                            $Retry--
                        }
                        elseif ($Retry -eq -1) {
                            Write-Error -Message "There was an error mapping $folder to $DriveLetter; this operation will not be retried" `
                                        -Category ConnectionError `
                                        -CategoryActivity 'Error connecting specified folder to specified drive letter' `
                                        -CategoryReason 'Unable to map DriveLetter' `
                                        -TargetObject $DriveLetter `
                                        -RecommendedAction 'Specify a different DriveLetter, or leave DriveLetter blank'
                            Break
                        }
                        elseif ($letters.count -eq 0) {
                            Write-Warning -Message "Connecting $folder to a drive letter failed, and ran out of letters to try.  Continuing without mapping..."
                            $FolderPath = $folder
                        }
                        else {
                            Write-Warning -Message "Connecting $folder to a drive letter failed.  Continuing without mapping..."
                            $FolderPath = $folder
                        }
                    }
                }
                while ($FolderPath -eq $null)
            }
            else { $FolderPath = $folder }
 
            Get-ChildItem -Path $FolderPath -Recurse | Where-Object -FilterScript {$_.Attributes -notlike "*Directory*"} | Select-Object -ExpandProperty FullName | ForEach-Object -Process {
                $TimeStamps = Get-FileTimeStamp -File $_ 
                $Acl = Get-ACL -Path $_
                if ($InfectedUser) {
                    if ($Acl.Owner -notlike "$InfectedUser") { $DropFile = $True }
                    if ($NoCompare) { $SkipComp = $True }
                }
                 
                if ($TimeStamps -ne $null) {
                    $ChangeDate = $TimeStamps.ChangeTime.ToString().Split()[0]
                     
                    # Strip out seconds to reduce false positives
                    $CompMFTChange = ("$($TimeStamps.ChangeTime)").split(':')[0..1] -join ':'
                    $CompWrite = ("$($TimeStamps.LastWriteTime)").split(':')[0..1] -join ':'
                    $CompCreate = ("$($TimeStamps.CreationTime)").split(':')[0..1] -join ':'
 
                    #############################################################
                    #    Plain english translation of complex IF block:
                    #    if it matches the InfectedUser, AND is either ( a match on comparison OR is not to be compared )
                    #############################################################
                    if (($DropFile -ne $True) -and
                        (("$ChangeDate" -eq "$Date") -or ($FullScan)) -and
                        (($SkipComp) -or
                        (($CompMFTChange -ne $CompWrite) -and
                        ($CompMFTChange -ne $CompCreate)))) {
                             
                            if ($RemoveDrive) {
                                $FullPath = $folder + $TimeStamps.FullName.Split(':')[1]
                            }
                            else {
                                $FullPath = $TimeStamps.FullName
                            }
                            $props = @{'FullName' = $TimeStamps.FullName.Split('\')[-1];
                                       'FullPath' = $FullPath;
                                       'CreationTime' = $TimeStamps.CreationTime;
                                       'ModifiedDate' = $TimeStamps.LastWriteTime;
                                       'MFTChangeTime' = $TimeStamps.ChangeTime;
                                       'Owner' = $Acl.Owner}
 
                            $obj = New-Object -TypeName PSObject -Property $props
                            $obj.PSObject.TypeNames.Insert(0,'PoshCodeBear.Crypto.FileSecurityInfo')
                            Write-Output -InputObject $obj
                    }
                }
            }
            if ($RemoveDrive) {
                Remove-PSDrive -Name $DriveLetter
                Write-Verbose -Message "$DriveLetter disconnected from $folder"
            }
        }
    }
    END {
        $EndTime = Get-Date
        $TotalTime = (("$($EndTime - $StartTime)").Split('.')[0])
 
        Write-Verbose -Message "Process ended at $EndTime"
        Write-Verbose -Message "Total time was $TotalTime"
    }
}
