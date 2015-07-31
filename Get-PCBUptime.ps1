function Get-PCBUptime {
<#
.SYNOPSIS
A simple tool for checking how long a system on the network has been running since last boot.
.DESCRIPTION
Get-PCBUptime is a quick WMI-based tool for determinging a remote system's uptime.  It is useful for verifying
what a user says when asked if they've rebooted their machine recently.

Get-PCBUptime is written by and copyright of Christopher R. Lowery, aka The PowerShell Bear (poshcodebear.com; Twitter: @poshcodebear)
It is free for all to use, and free to distribute with attribution to the original author.
.PARAMETER ComputerName
The name of the computer to check; if left blank, it defaults to "localhost".
.EXAMPLE
Get-PCBUptime -ComputerName system
.LINK
http://www.poshcodebear.com
#>
    [CmdletBinding()]
    param(        
        [Parameter(ValueFromPipeline=$True)]
        [Alias('Host')]
        [string[]]$ComputerName = 'localhost'
    )
    BEGIN {
        $PSVersion = (Get-Host).Version.Major
    }

    PROCESS {
        foreach ($computer in $ComputerName) {
            try {
                $timestring = (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computer -ErrorAction Stop | `
                               Select-Object -ExpandProperty LastBootupTime).split('.')[0]

                # The date-time string isn't in a useful format; need to convert it:
                $year = $timestring[0..3] -join ''
                $month = $timestring[4..5] -join ''
                $day = $timestring[6..7] -join ''
                $hour = $timestring[8..9] -join ''
                $minute = $timestring[10..11] -join ''
                $time = "$year/$month/$day $hour`:$minute"

                # Convert the new date-time string into a date-time object, then compare:
                $boottime = Get-Date -Date $time
                $LongTimeSinceBoot = (Get-Date) - $boottime
                $TimeSinceBoot = "$($LongTimeSinceBoot.Days):$($LongTimeSinceBoot.Hours):$($LongTimeSinceBoot.Minutes)"
            }
            catch {
                # If the system couldn't be queried, set up output
                $boottime = 'Unknown'
                $TimeSinceBoot = 'System Unreachable'
                Write-Warning -Message "Unable to reach $computer`:"
                Write-Warning -Message $_.Exception.Message
            }

            if ($PSVersion -gt 2) {
                # Use the nice, ordered list in v3 and newer
                $props = [ordered]@{'ComputerName' = $computer;
                                    'LastBootupTime' = $boottime;
                                    'TimeSinceLastBoot(Day:Hour:Min)' = $TimeSinceBoot}
            }
            else {
                # In v2, you get the order the system feels like using
                $props = @{'ComputerName' = $computer;
                           'LastBootupTime' = $boottime;
                           'TimeSinceLastBoot' = $TimeSinceBoot}
            }

            $obj = New-Object -TypeName PSObject -Property $props
            $obj.PSObject.TypeNames.Insert(0,'PoshCodeBear.System.UpTime')
            Write-Output -InputObject $obj
        }
    }

    END {}
}
