[CmdletBinding()]
param()

$ComputerName = $env:COMPUTERNAME

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Windows Server Health Check" -ForegroundColor Cyan
Write-Host " Server: $ComputerName" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n[1] Operating System" -ForegroundColor Yellow

Get-CimInstance Win32_OperatingSystem |
    Select-Object Caption,
                  Version,
                  BuildNumber,
                  LastBootUpTime

Write-Host "`n[2] Computer System" -ForegroundColor Yellow

Get-CimInstance Win32_ComputerSystem |
    Select-Object Manufacturer,
                  Model,
                  TotalPhysicalMemory

Write-Host "`n[3] Disk Space" -ForegroundColor Yellow

Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID,
        @{Name="SizeGB";Expression={[math]::Round($_.Size / 1GB,2)}},
        @{Name="FreeGB";Expression={[math]::Round($_.FreeSpace / 1GB,2)}},
        @{Name="FreePercent";Expression={
            if ($_.Size) {
                [math]::Round(($_.FreeSpace / $_.Size) * 100,2)
            }
        }}

Write-Host "`n[4] Important Services" -ForegroundColor Yellow

Get-Service |
    Where-Object {
        $_.Status -eq "Stopped" -and
        $_.StartType -eq "Automatic"
    } |
    Select-Object Name, DisplayName, Status, StartType

Write-Host "`n[5] Recent System Errors" -ForegroundColor Yellow

Get-WinEvent -FilterHashtable @{
    LogName   = "System"
    Level     = 2
    StartTime = (Get-Date).AddHours(-24)
} -ErrorAction SilentlyContinue |
    Select-Object -First 10 TimeCreated,
        ProviderName,
        Id,
        LevelDisplayName,
        Message

Write-Host "`nHealth check completed." -ForegroundColor Green