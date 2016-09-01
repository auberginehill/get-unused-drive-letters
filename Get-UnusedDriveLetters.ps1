<# 
.\Get-UnusedDriveLetters.ps1
#>

# Set the common parameters 
$timestamp = Get-Date -UFormat "%Y%m%d" 
$date = Get-Date -Format g
$time = (Get-Date -UFormat "%d. %m. %Y klo %H.%M")

$path = $env:temp

$name_list = $env:COMPUTERNAME
# $name_list = Get-Content 'C:\Temp\servers.txt'                                              # These can be computer names or IP addresses, one in each line
# If remote computers are specified, this script will use Windows Management Instrumentation (WMI) over Remote Procedure Calls (RPCs) 
$separator = '--------------------'
$empty_line = ""


# Function used to convert bytes to MB or GB or TB                                            # Credit: clayman2: "Disk Space"
function ConvertBytes { 
    param($size) 
    If ($size -lt 1MB) { 
        $drive_size = $size / 1KB 
        $drive_size = [Math]::Round($drive_size, 2) 
        [string]$drive_size + ' KB' 
    } ElseIf ($size -lt 1GB) { 
        $drive_size = $size / 1MB 
        $drive_size = [Math]::Round($drive_size, 2) 
        [string]$drive_size + ' MB' 
    } ElseIf ($size -lt 1TB) {  
        $drive_size = $size / 1GB 
        $drive_size = [Math]::Round($drive_size, 2) 
        [string]$drive_size + ' GB' 
    } Else { 
        $drive_size = $size / 1TB 
        $drive_size = [Math]::Round($drive_size, 2) 
        [string]$drive_size + ' TB' 
    } # else
} # function




# Function used to convert the Time Zone Offset from minutes to hours
function DayLight { 
    param($minutes) 
    If ($minutes -gt 0) { 
        $hours = ($minutes / 60) 
        [string]'+' + $hours + ' h' 
    } ElseIf ($minutes -lt 0) { 
        $hours = ($minutes / 60) 
        [string]$hours + ' h'     
    } ElseIf ($minutes -eq 0) { 
        [string]'0 h (GMT)' 
    } Else { 
        [string]'' 
    } # else
} # function




# Function used to calculate the UpTime of a computer
function UpTime {
    param ()

    $wmi_os = Get-WmiObject -class Win32_OperatingSystem -ComputerName $env:COMPUTERNAME 
    $up_time = ($wmi_os.ConvertToDateTime($wmi_os.LocalDateTime)) - ($wmi_os.ConvertToDateTime($wmi_os.LastBootUpTime))

    If ($up_time.Days -ge 2) {
        $uptime_result = [string]$up_time.Days + ' days ' + $up_time.Hours + ' h ' + $up_time.Minutes + ' min'
    } ElseIf ($up_time.Days -gt 0) {
        $uptime_result = [string]$up_time.Days + ' day ' + $up_time.Hours + ' h ' + $up_time.Minutes + ' min'
    } ElseIf ($up_time.Hours -gt 0) {
        $uptime_result = [string]$up_time.Hours + ' h ' + $up_time.Minutes + ' min'
    } ElseIf ($up_time.Minutes -gt 0) {
        $uptime_result = [string]$up_time.Minutes + ' min ' + $up_time.Seconds + ' sec'
    } ElseIf ($up_time.Seconds -gt 0) {
        $uptime_result = [string]$up_time.Seconds + ' sec'                                             
    } Else { 
        $uptime_result = [string]'' 
    } # else (if)

        If ($uptime_result.Contains("0 h")) {
            $uptime_result = $uptime_result.Replace("0 h","")
            } If ($uptime_result.Contains("0 min")) { 
                $uptime_result = $uptime_result.Replace("0 min","")
                } If ($uptime_result.Contains("0 sec")) { 
                $uptime_result = $uptime_result.Replace("0 sec","")
        } # if ($uptime_result: first)

$uptime_result

} # function




# Display a welcoming screen in console
$empty_line | Out-String
$title = 'Computer Info'
Write-Output $title 
$separator | Out-String




# Create a partition table with WMI
$obj_osinfo = @()
$obj_device = @()
$partition_table = @()
$obj_volumes = @()
$obj_used = @()




ForEach ($computer in $name_list) {

    # Retrieve basic os and computer related information and display it in console
    $bios = Get-WmiObject -class Win32_BIOS -ComputerName $computer 
    $compsys = Get-WmiObject -class Win32_ComputerSystem -ComputerName $computer 
    $compsysprod = Get-WMIObject -class Win32_ComputerSystemProduct -ComputerName $computer 
    $os = Get-WmiObject -class Win32_OperatingSystem -ComputerName $computer 
    $processor = Get-WMIObject -class Win32_Processor -ComputerName $computer 
    $timezone = Get-WmiObject -class Win32_TimeZone -ComputerName $computer 
   
   
            # CPU
            $CPUArchitecture_data = $processor.Name
            If ($CPUArchitecture_data.Contains("(TM)")) {
                $CPUArchitecture_data = $CPUArchitecture_data.Replace("(TM)","")
                } If ($CPUArchitecture_data.Contains("(R)")) { 
                        $CPUArchitecture_data = $CPUArchitecture_data.Replace("(R)","")
            } # if (CPUArchitecture_data)


            # Manufacturer
            $Manufacturer_data = $compsysprod.Vendor
            If ($Manufacturer_data.Contains("HP")) {
                $Manufacturer_data = $Manufacturer_data.Replace("HP","Hewlett-Packard")
            } # if 


            # Operating System                           
            $OperatingSystem_data = $os.Caption
            If ($OperatingSystem_data.Contains(",")) {
                $OperatingSystem_data = $OperatingSystem_data.Replace(",","")
                } If ($OperatingSystem_data.Contains("(R)")) { 
                        $OperatingSystem_data = $OperatingSystem_data.Replace("(R)","")
            } # if (OperatingSystem_data)

            # $osa = Get-WmiObject win32_operatingsystem | Select @{Name='InstallDate';Expression={$_.ConvertToDateTime($_.InstallDate)}}
            # $InstallDate_Local = $osa.InstallDate

                    $obj_osinfo += New-Object -TypeName PSCustomObject -Property @{ 
                        'Computer'              = $computer
                        'Manufacturer'          = $Manufacturer_data
                        'Computer Model'        = $compsys.Model
                        'System Type'           = $compsys.SystemType
                        'CPU'                   = $CPUArchitecture_data
                        'Operating System'      = $OperatingSystem_data
                        'Architecture'          = $os.OSArchitecture
                        'SP Version'            = $os.CSDVersion
                        'Build Number'          = $os.BuildNumber
                        'Memory'                = (ConvertBytes($compsys.TotalPhysicalMemory))        
                        'Processors'            = $processor.NumberOfLogicalProcessors
                        'Cores'                 = $processor.NumberOfCores
                        'Country Code'          = $os.CountryCode
                        'OS Install Date'       = ($os.ConvertToDateTime($os.InstallDate)).ToShortDateString()
                        'Last BootUp'           = (($os.ConvertToDateTime($os.LastBootUpTime)).ToShortDateString() + ' ' + ($os.ConvertToDateTime($os.LastBootUpTime)).ToShortTimeString())
                        'UpTime'                = (Uptime)
                        'Date'                  = $date
                        'Daylight Bias'         = ((DayLight($timezone.DaylightBias)) + ' (' + $timezone.DaylightName + ')')
                        'Time Offset (Current)' = (DayLight($timezone.Bias))
                        'Time Offset (Normal)'  = (DayLight($os.CurrentTimeZone))
                        'Time (Current)'        = (Get-Date).ToShortTimeString()
                        'Time (Normal)'         = (((Get-Date).AddMinutes($timezone.DaylightBias)).ToShortTimeString() + ' (' + $timezone.StandardName + ')') 
                        'Daylight In Effect'    = $compsys.DaylightInEffect
                     #  'Daylight In Effect'    = (Get-Date).IsDaylightSavingTime()
                        'Time Zone'             = $timezone.Description
                        'OS Version'            = $os.Version        
                        'BIOS Version'          = $bios.SMBIOSBIOSVersion  
                        'ID'                    = $compsysprod.IdentifyingNumber
                        'Serial Number (BIOS)'  = $bios.SerialNumber
                        'Serial Number (OS)'    = $os.SerialNumber
                        'UUID'                  = $compsysprod.UUID
                    } # New-Object
                $obj_osinfo.PSObject.TypeNames.Insert(0,"OSInfo")
                $obj_osinfo_selection = $obj_osinfo | Select-Object 'Computer','Manufacturer','Computer Model','System Type','CPU','Operating System','Architecture','SP Version','Build Number','Memory','Processors','Cores','Country Code','OS Install Date','Last BootUp','UpTime','Date','Daylight Bias','Time Offset (Current)','Time Offset (Normal)','Time (Current)','Time (Normal)','Daylight In Effect','Time Zone','OS Version','BIOS Version','Serial Number (BIOS)','Serial Number (OS)','UUID'
                Write-Output $obj_osinfo_selection
                $empty_line | Out-String
                $empty_line | Out-String


    # Retrieve information about optical drives
    $optical = Get-WmiObject win32_logicaldisk -filter 'DriveType=5'

            ForEach ($device in $optical) {    
                    Write-Verbose "Found CDROM drive on $computer"
                        $obj_device += New-Object -TypeName PSCustomObject -Property @{ 
                            'Computer'          = $device.SystemName
                            'Drive'             = $device.Name
                            'Media Type'        = $device.Description
                            'DriveType'         = $device.DriveType
                            'Path'              = $device.Path
                            'Source'            = $device.CreationClassName
                            'MediaType Code'    = $device.MediaType
                        } # New-Object
                    $obj_device.PSObject.TypeNames.Insert(0,"Optical")
            } # ForEach ($device)




    # Create the partition table

    $disks = Get-WmiObject -class Win32_DiskDrive -ComputerName $computer

    ForEach ($disk in $disks) {

            # $partitions = Get-WmiObject -class Win32_DiskPartition -ComputerName $computer 
            # $partitions = (Get-WmiObject -ComputerName $computer -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='\\.\PHYSICALDRIVE0'} WHERE ResultRole=Dependent") 
            $partitions = (Get-WmiObject -ComputerName $computer -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($disk.DeviceID)'} WHERE ResultRole=Dependent")
            
            ForEach ($partition in ($partitions)) {

                    # $drives = Get-WmiObject -class Win32_LogicalDisk -ComputerName $computer 
                    # $drives = Get-WmiObject -ComputerName $computer -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='Disk #0, Partition #1'} WHERE ResultRole=Dependent" 
                    $drives = (Get-WmiObject -ComputerName $computer -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} WHERE ResultRole=Dependent") 
                    
                    ForEach ($drive in ($drives)) {
                                                        
                            $free_percentage = If ($drive.Size -gt 0) { 
                                                    $relative_free = [Math]::Round((($drive.FreeSpace / $drive.Size) * 100 ), 1) 
                                                        [string]$relative_free + ' %'
                                                    } Else { 
                                                        [string]''
                                                    } # else (if) 

                            $used_percentage = If ($drive.Size -gt 0) { 
                                                    $relative_size = [Math]::Round(((($drive.Size - $drive.FreeSpace) / $drive.Size) * 100 ), 1) 
                                                        [string]$relative_size + ' %'
                                                    } Else { 
                                                        [string]''
                                                    } # else (if) 

                            $status = "" 
                                If ($used_percentage -eq 100) { 
                                    $status = "Full" 
                                } ElseIf ($used_percentage -ge 95) { 
                                    $status = "Very Low Space" 
                                } ElseIf ($used_percentage -ge 90) { 
                                    $status = "Low Space" 
                                } ElseIf ($used_percentage -ge 85) { 
                                    $status = "Medium Space"
                                } ElseIf ($used_percentage -gt 0) { 
                                    $status = "OK" 
                                } Else { 
                                    $status = ""
                                } # else (if)

                                $partition_table += New-Object -Type PSCustomObject -Property @{

                                    'Definition'              = $disk.Description
                                    'Disk'                    = $disk.DeviceID
                                    'Disk Capabilities'       = $disk.CapabilityDescriptions
                                    'Disk Status'             = $disk.Status
                                    'Interface'               = $disk.InterfaceType
                                    'Media Type'              = $disk.MediaType
                                    'Model'                   = $disk.Model
                                    'Serial Number (Disk)'    = $disk.SerialNumber


                                    'Boot Partition'          = $partition.BootPartition
                                    'Bootable'                = $partition.Bootable
                                    'Partition'               = $partition.DeviceID
                                    'Partition Type'          = $partition.Description
                                    'Primary Partition'       = $partition.PrimaryPartition  


                                    'Computer'                = $drive.SystemName
                                    'Compressed'              = $drive.Compressed
                                    'Description'             = $drive.Description
                                    'Drive'                   = $drive.DeviceID
                                    'File System'             = $drive.FileSystem
                                    'Free Space'              = ConvertBytes($drive.FreeSpace)
                                    'Free (%)'                = $free_percentage
                                    'Label'                   = $drive.VolumeName
                                    'Free Space Status'       = $status           
                                    'Total Size'              = ConvertBytes($drive.Size)
                                    'Used'                    = (ConvertBytes($drive.Size - $drive.FreeSpace))
                                    'Used (%)'                = $used_percentage
                                    'Serial Number (Volume)'  = $drive.VolumeSerialNumber

                                    } # New-Object
                                $partition_table.PSObject.TypeNames.Insert(0,"PartitionTable")
                    } # ForEach ($drive)
            } # ForEach ($partition)
    } # ForEach ($disk)



    
    # Retrieve additional disk information from volumes (Win32_Volume)
    
    $volumes = Get-WmiObject -class Win32_Volume -ComputerName $computer 

            ForEach ($volume in $volumes) {
                $obj_volumes += New-Object -TypeName PSCustomObject -Property @{
                        'Automount'             = $volume.Automount
                        'Block Size'            = $volume.BlockSize
                        'Boot Volume'           = $volume.BootVolume
                        'Compressed'            = $volume.Compressed
                        'Computer'              = $volume.SystemName
                        'DeviceID'              = $volume.DeviceID
                        'Drive'                 = $volume.DriveLetter
                        'DriveType'             = $volume.DriveType                
                        'File System'           = $volume.FileSystem
                        'Free Space'            = (ConvertBytes($volume.FreeSpace))                      
                        'Free (%)'              = $free_percentage = If ($volume.Capacity -gt 0) { 
                                                        $relative_free = [Math]::Round((($volume.FreeSpace / $volume.Capacity) * 100 ), 1) 
                                                            [string]$relative_free + ' %'
                                                        } Else { 
                                                            [string]''
                                                    } # else (if) 
                        'Indexing Enabled'      = $volume.IndexingEnabled
                        'Label'                 = $volume.Label
                        'PageFile Present'      = $volume.PageFilePresent
                        'Root'                  = $volume.Name
                        'Serial Number (Volume)' = $volume.DeviceID
                        'Source'                = $volume.__CLASS
                        'System Volume'         = $volume.SystemVolume
                        'Total Size'            = (ConvertBytes($volume.Capacity)) 
                        'Used'                  = (ConvertBytes($volume.Capacity - $volume.FreeSpace))
                        'Used (%)'              = $used_percentage = If ($volume.Capacity -gt 0) { 
                                                        $relative_size = [Math]::Round(((($volume.Capacity - $volume.FreeSpace) / $volume.Capacity) * 100 ), 1) 
                                                            [string]$relative_size + ' %'
                                                        } Else { 
                                                            [string]''
                                                    } # else (if)
                    } # New-Object
                $obj_volumes.PSObject.TypeNames.Insert(0,"Volume")
            } # ForEach ($volume}


    # Enumerate the used drive-letters
    
    # $pi = Get-PSDrive -PSProvider FileSystem
    $epsilon = [System.IO.DriveInfo]::getdrives() 

            Write-Verbose "Reading the .NET Framework object 'System.IO.DriveInfo' on $computer"  

            ForEach ($in_use in $epsilon) { 
                $obj_used += New-Object -TypeName PSCustomObject -Property @{
                        'Computer'      = $computer
                        'Drive'         = (($in_use.Name).Replace("\",""))
                        'File System'   = $in_use.DriveFormat
                        'Free Space'    = (ConvertBytes($in_use.AvailableFreeSpace))                   
                        'Free (%)'      = $free_percentage = If ($in_use.TotalSize -gt 0) { 
                                                $relative_free = [Math]::Round((($in_use.AvailableFreeSpace / $in_use.TotalSize) * 100 ), 1) 
                                                    [string]$relative_free + ' %'
                                                } Else { 
                                                    [string]''
                                                } # else (if) 
                        'Is Ready'      = $in_use.IsReady
                        'Label'         = $in_use.VolumeLabel
                        'Media Type'    = $in_use.DriveType
                        'Root'          = $in_use.RootDirectory
                        'Total Size'    = (ConvertBytes($in_use.TotalSize))
                        'Used'          = (ConvertBytes($in_use.TotalSize - $in_use.AvailableFreeSpace))
                        'Used (%)'      = $used_percentage = If ($in_use.TotalSize -gt 0) { 
                                                $relative_size = [Math]::Round(((($in_use.TotalSize - $in_use.AvailableFreeSpace) / $in_use.TotalSize) * 100 ), 1) 
                                                    [string]$relative_size + ' %'
                                                } Else { 
                                                    [string]''
                                                } # else (if) 
                    } # New-Object
                $obj_used.PSObject.TypeNames.Insert(0,"Used")
            } # ForEach ($in_use)   




    # Create an alphabetical list of possible drive letter names                                  # Credit: ps1 and Sylvain LESIRE
    $letters = 65..90 | ForEach-Object { ([char]$_) + ":" }


    # Enumerate the unused drive letters                                                          # Credit: ps1
    $unused = $letters | Where-Object { 
        (New-Object System.IO.DriveInfo($_)).DriveType -eq 'NoRootDirectory'
    } # Where
    $unused.PSObject.TypeNames.Insert(0,"Unused")

} # ForEach ($computer/first)




# Display the optical drives in console
$optical_selection = $obj_device | Select-Object Computer,Drive,'Media Type' 
$empty_line | Out-String
$optical_header = 'Optical Drives'
Write-Output $optical_header 
$separator | Out-String
$optical_selection | Format-Table -AutoSize | Out-String
$empty_line | Out-String
$empty_line | Out-String


# Display the partition table in console
$partition_table_selection = $partition_table | Sort Computer,Drive | Select-Object Computer,Drive,Label,'File System','Boot Partition',Interface,'Media Type','Partition Type',Partition,Used,'Used (%)','Free Space Status','Total Size','Free Space','Free (%)'
$partition_table_selection_screen = $partition_table | Sort Computer,Drive | Select-Object Computer,Drive,Label,Interface,'Media Type',Partition,'Used (%)','Total Size','Free Space','Free (%)'
$partition_table_header = 'Partition Table'
Write-Output $partition_table_header 
$separator | Out-String 
$partition_table_selection_screen | Format-Table -AutoSize | Out-String
$empty_line | Out-String
$empty_line | Out-String


# Display the used drive-letters in console
$used_selection = $obj_used | Sort Computer,Drive | Select-Object Computer,Drive,Label,'File System','Media Type','Is Ready',Used,'Used (%)','Total Size','Free Space','Free (%)',Root
$used_selection_screen = $obj_used | Sort Computer,Drive | Select-Object Computer,Drive,Label,'File System','Media Type',Used,'Used (%)','Total Size','Free Space','Free (%)'
$used_header = 'Drive Letters in Use'
Write-Output $used_header
$separator | Out-String
$used_selection_screen | Format-Table -AutoSize | Out-String
$empty_line | Out-String
$empty_line | Out-String


# Display the volumes in console
$volumes_selection = $obj_volumes | Sort Computer,Drive | Select-Object Computer,Drive,Label,'File System','System Volume','Boot Volume','Indexing Enabled','PageFile Present','Block Size','Compressed','Automount',Used,'Used (%)','Total Size','Free Space','Free (%)'
$volumes_selection_screen = $obj_volumes | Sort Computer,Drive | Select-Object Computer,Drive,Label,'File System','System Volume',Used,'Used (%)','Total Size','Free Space','Free (%)'
$volumes_header = 'Volumes'
Write-Output $volumes_header
$separator | Out-String
$volumes_selection_screen | Format-Table -AutoSize | Out-String
$empty_line | Out-String
$empty_line | Out-String


# Display the unused drives in console
$unused_header = 'Unused Drive Letters'
Write-Output $unused_header
$separator | Out-String
Write-Output $unused
$empty_line | Out-String


# Write the used_drive_letters to a CSV-file
$used_selection | Export-Csv -Path $path\used_drive_letters.csv -Delimiter ';' -NoTypeInformation -Encoding UTF8


# Write the unused_drive_letters to a txt-file (the small characters below are single quotes)
$txt_file_unused = New-Item -ItemType File -Path "$path\unused_drive_letters.txt" -Force 
$txt_file_unused
Add-Content $txt_file_unused -Value ('Generated: ' + $time + '
Computer: ' + $computer)
Add-Content $txt_file_unused -Value $empty_line
Add-Content $txt_file_unused -Value $empty_line
Add-Content $txt_file_unused -Value $unused_header 
Add-Content $txt_file_unused -Value $separator 
Add-Content $txt_file_unused -Value $unused


# Display the results in four pop-up windows
# $obj_osinfo_selection | Out-GridView
# $optical_selection | Out-GridView
$partition_table_selection | Out-GridView
$used_selection | Out-GridView
$volumes_selection | Out-GridView
$unused | Out-GridView




# [End of Line]


<#

   ____        _   _                 
  / __ \      | | (_)                
 | |  | |_ __ | |_ _  ___  _ __  ___ 
 | |  | | '_ \| __| |/ _ \| '_ \/ __|
 | |__| | |_) | |_| | (_) | | | \__ \
  \____/| .__/ \__|_|\___/|_| |_|___/
        | |                          
        |_|                          


# Write the used_drive_letters to a txt-file (in two steps)
$partition_table_selection | Format-Table -AutoSize | Out-File $path\used_drive_letters.txt -Width 9000
$partition_table_selection | Format-List | Out-File $path\used_drive_letters.txt -Append 


# Write the used_drive_letters to a HTML-file and open the HTML-file in browser
$partition_table_selection | Select-Object * | ConvertTo-Html | Out-File $path\used_drive_letters.html; & "$path\used_drive_letters.html"


# Open the used_drive_letters CSV-file         
Invoke-Item -Path $path\used_drive_letters.csv


# Open the unused_drive_letters txt-file         
Invoke-Item -Path $path\unused_drive_letters.txt


unused_drive_letters_$timestamp.txt                                                           # an alternative filename format
used_drive_letters_$timestamp.csv                                                             # an alternative filename format
$time = Get-Date -Format g                                                                    # a "general short" time-format (short date and short time) 



   _____                          
  / ____|                         
 | (___   ___  _   _ _ __ ___ ___ 
  \___ \ / _ \| | | | '__/ __/ _ \
  ____) | (_) | |_| | | | (_|  __/
 |_____/ \___/ \__,_|_|  \___\___|


http://powershell.com/cs/blogs/tips/archive/2009/01/15/enumerating-drive-letters.aspx         # ps1 and Sylvain LESIRE
http://powershell.com/cs/media/p/7476.aspx                                                    # clayman2: "Disk Space"



  _    _      _       
 | |  | |    | |      
 | |__| | ___| |_ __  
 |  __  |/ _ \ | '_ \ 
 | |  | |  __/ | |_) |
 |_|  |_|\___|_| .__/ 
               | |    
               |_|    
#>

<#

.SYNOPSIS
Retrieves the used and unused drive-letters from a computer.

.DESCRIPTION
Get-UnusedDriveLetters uses Windows Management Instrumentation (WMI) to retrieve basic 
computer information and .NET Framework to determine which drive-letters are unused 
by the system. This script is based on ps1's PowerShell Tip "Enumerating Drive Letters".
(http://powershell.com/cs/blogs/tips/archive/2009/01/15/enumerating-drive-letters.aspx).

.OUTPUTS
Displays general computer information, a list of optical drives, a partition table,  
volumes list and the used and unused drive letters in console. In addition to that... 


Four pop-up windows (Out-GridView):

        Name                                Description
        ----                                -----------
        $partition_table_selection          A partition table, which doesn't include 
                                            the optical drives 

        $used_selection	                    Lists all the used drive letters, but  
                                            doesn't include the boot sector

        $volumes_selection                  Lists all the used drive letters
                                            (including the boot sector)

        $unused                             A list of all unused drive letters


And also one txt-file and one CSV-file at $path

$env:temp\unused_drive_letters.txt          : txt-file                : unused_drive_letters.txt
$env:temp\used_drive_letters.csv            : CSV-file                : used_drive_letters.csv

.NOTES
Please note that the two files are created in a directory, which is specified with the 
$path variable (at line 10). The $env:temp variable points to the current temp folder. 
The default value of the $env:temp variable is C:\Users\<username>\AppData\Local\Temp
(i.e. each user account has their own separate temp folder at path %USERPROFILE%\AppData\Local\Temp). 
To see the current temp path, for instance a command

    [System.IO.Path]::GetTempPath()
    
may be used at the PowerShell prompt window [PS>]. To change the temp folder for instance 
to C:\Temp, please, for example, follow the instructions at 
http://www.eightforums.com/tutorials/23500-temporary-files-folder-change-location-windows.html 

    Homepage:           https://github.com/auberginehill/get-unused-drive-letters
    Version:            1.0

.EXAMPLE
./Get-UnusedDriveLetters
Run the script. Please notice to insert ./ or .\ before the script name.

.EXAMPLE
help ./Get-UnusedDriveLetters -Full
Display the help file.

.EXAMPLE
Set-ExecutionPolicy remotesigned
This command is altering the Windows PowerShell rights to enable script execution. Windows PowerShell 
has to be run with elevated rights (run as an administrator) to actually be able to change the script 
execution properties. The default value is "Set-ExecutionPolicy restricted". 


    Parameters:

    Restricted      Does not load configuration files or run scripts. Restricted is the default 
                    execution policy.

    AllSigned       Requires that all scripts and configuration files be signed by a trusted 
                    publisher, including scripts that you write on the local computer.

    RemoteSigned    Requires that all scripts and configuration files downloaded from the Internet 
                    be signed by a trusted publisher.

    Unrestricted    Loads all configuration files and runs all scripts. If you run an unsigned  
                    script that was downloaded from the Internet, you are prompted for permission  
                    before it runs.

    Bypass          Nothing is blocked and there are no warnings or prompts.

    Undefined       Removes the currently assigned execution policy from the current scope.  
                    This parameter will not remove an execution policy that is set in a Group 
                    Policy scope. 


For more information, 
type "help Set-ExecutionPolicy -Full" or visit https://technet.microsoft.com/en-us/library/hh849812.aspx.

.EXAMPLE
New-Item -ItemType File -Path C:\Temp\Get-UnusedDriveLetters.ps1
Creates an empty ps1-file to the C:\Temp directory. The New-Item cmdlet has an inherent -NoClobber mode  
built into it, so that the procedure will halt, if overwriting (replacing the contents) of an existing 
file is about to happen. Overwriting a file with the New-Item cmdlet requires using the Force. 
For more information, please type "help New-Item -Full".

.LINK
http://powershell.com/cs/blogs/tips/archive/2009/01/15/enumerating-drive-letters.aspx
http://powershell.com/cs/media/p/7476.aspx   
http://learningpcs.blogspot.com/2011/10/powershell-get-wmiobject-and.html
https://social.technet.microsoft.com/Forums/windowsserver/en-US/f82e6f0b-ab97-424b-8e91-508d710e03b1/how-to-link-the-output-from-win32diskdrive-and-win32volume?forum=winserverpowershell
https://technet.microsoft.com/en-us/library/ff730960.aspx
https://blogs.msdn.microsoft.com/dsadsi/2010/03/19/mapping-volumeid-to-disk-partition-using-the-deviceiocontrol-api/
https://technet.microsoft.com/en-us/library/ee692723.aspx

#>
