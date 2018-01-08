function Get-XKCDCalendarFact
{
    <#
    .SYNOPSIS
    Get a random calendar fact
    
    .DESCRIPTION
    Generates a random calendar fact for you to marvel at.
    Just a fun little thing I made based on https://xkcd.com/1930/
    
    .EXAMPLE
    PS> Get-XKCDCalendarFact
    Did you know that Shark Week happens earlier every year because of eccentricity of the moon? Apparently there's a proposal to fix it, but it might be unconstitutional.
    While it might seem like trivia, it triggered the 2003 Northeast Blackout.
    
    .NOTES
    All rights for XKCD belong to Randall Monroe; the comic this is based off of is licensed by Monroe under Creative Commons Attribution-NonCommercial 2.5 Generic
    CC BY-NC 2.5: https://creativecommons.org/licenses/by-nc/2.5/
    All rights to this PowerShell function that did not come from Randall Monroe's work belong to The PowerShell Bear (aka, Christopher R. Lowery)
    All parts of this work not covered by CC BY-NC 2.5 (i.e., those parts created by Monroe) are licensed under the MIT license
    MIT license: https://opensource.org/licenses/MIT
    #>
    
    $Seg1 = @(
        "the $(Get-Random 'Fall', 'Spring') Equinox",
        "the $(Get-Random 'Winter', 'Summer') $(Get-Random 'Solstice', 'Olympics')",
        "the $(Get-Random 'earliest', 'latest') $(Get-Random 'sunrise', 'sunset')",
        "Daylight $(Get-Random 'Saving', 'Savings') Time",
        "Leap $(Get-Random 'Day', 'Year')",
        'Easter',
        "the $(Get-Random 'Harvest', 'Super', 'Blood') Moon",
        'Toyota Truck Month',
        'Shark Week'
    )
    $Seg2 = @(
        "happens $(Get-Random 'earlier', 'later', 'at the wrong time') every year",
        "drifts out of sync with the $(Get-Random 'sun', 'moon', 'zodiac', "$(Get-Random 'Gregorian', 'Mayan', 'Lunar', 'iPhone') calendar", 'atomic clock in Colorado')",
        "might $(Get-Random 'not happen', 'happen twice') this year"
    )
    $Seg3 = @(
        "time zone legislation in $(Get-Random 'Indiana', 'Arizona', 'Russia')",
        'a decree by the Pope in the 1500s',
        "$(Get-Random 'precession', 'liberation', 'nutation', 'libation', 'eccentricity', 'obliquity') of the $(Get-Random 'moon', 'sun', 'Earth''s axis', 'equator', 'Prime Meridian', "$(Get-Random 'International Date', 'Mason-Dixon') Line")",
        "an arbitrary decision by $(Get-Random 'Benjamin Franklin', 'Isaac Newton', 'FDR')"
    )
    $Seg4 = @(
        'it causes a predictable increase in car accidents',
        "that's why we have leap seconds",
        'scientists are really worried',
        "it was even more extreme during the $(Get-Random 'Bronze Age', 'Ice Age', 'Cretaceous', '1990s')",
        "there's a proposal to fix it, but it $(Get-Random 'will never happen', 'actually makes things worse', 'is stalled in Congress', 'might be unconstitutional')",
        "it's getting worse and noone knows why"
    )
    $Seg5 = @(
        'causes huge headaches for software developers',
        'is taken advantage of by high-speed traders',
        'triggered the 2003 Northeast Blackout',
        'has to be corrected for by GPS satellites',
        'is now recognized as a major cause of World War I'
    )
    
    $CalFact = "Did you know that $(Get-Random $Seg1) $(Get-Random $Seg2) because of $(Get-Random $Seg3)? Apparently $(Get-Random $Seg4).`nWhile it might seem like trivia, it $(Get-Random $Seg5)."
    
    # I apologize in advance for any dead puppies...
    Write-Host $CalFact
}
