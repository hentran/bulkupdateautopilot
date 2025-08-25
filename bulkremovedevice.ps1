#region install autopilot module
$nuget = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction Ignore
if(-not($nuget))
{
    Install-PackageProvider -Name NuGet -Confirm:$false -Force
    Write-Host "Installed NuGet"
}
else
{
    Write-Host "NuGet already installed"
}

$module = Get-Module -ListAvailable -Name WindowsAutopilotIntune -ErrorAction Ignore
if(-not($module))
{
    Install-Module -Name WindowsAutopilotIntune -Confirm:$false -Force
    Write-Host "Installed WindowsAutopilotIntune"
}
else
{
    Write-Host "WindowsAutopilotIntune already installed"
}
#endregion

#region connect to Microsoft Graph
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All"
$me = Get-MgUserMe
Write-Host "Connected Microsoft Graph with account: $($me.UserPrincipalName)"
#endregion

#region get list of serial numbers from CSV file
$csvPath = Join-Path -Path (Get-Location) -ChildPath "remove-serials.csv"

#region checking the CSV file
if (-not (Test-Path -Path $csvPath)) {
    Write-Host "Can not find the CSV file at $csvPath" -ForegroundColor Red
    exit
}

$serialNumbers = Import-Csv -Path $csvPath | Select-Object -ExpandProperty SerialNumber
$totalDevices = $serialNumbers.Count
Write-Host "Founded $totalDevices serial in CSV file"
#endregion

#region Remove the device on Autopilot
$successCount = 0
$failedCount = 0

foreach ($serial in $serialNumbers) {
    try {
        Write-Host "Processing: $serial..."
        
        # Find device by serial
        $device = Get-AutopilotDevice -serial $serial -ErrorAction Stop
        
        if ($device) {
            # Remove device
            Remove-AutopilotDevice -id $device.id -ErrorAction Stop
            Write-Host "REMOVED: $serial (ID: $($device.id))" -ForegroundColor Green
            $successCount++
        }
        else {
            Write-Host "NOT FOUND: $serial" -ForegroundColor Yellow
            $failedCount++
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-Host "ERROR with $serial`: $errorMsg" -ForegroundColor Red
        $failedCount++
    }
}
#endregion

#region Result
Write-Host "`nRESULT:" -ForegroundColor Cyan
Write-Host "--------------------------------" -ForegroundColor Cyan
Write-Host "Total: $totalDevices" -ForegroundColor Cyan
Write-Host "Success: $successCount" -ForegroundColor Green
Write-Host "Failed: $failedCount" -ForegroundColor Red
Write-Host "--------------------------------" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    Write-Host "Check the log to know the details of the error." -ForegroundColor Yellow
}
#endregion