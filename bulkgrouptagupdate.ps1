# install autopilot module
$nuget = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction Ignore
if(-not($nuget))
{
    Install-PackageProvider -Name NuGet -confirm:$false -Force
    Write-Host "Installed NuGet"
}
else
{
    Write-Host "NuGet already installed"
}

$module = Get-Module -ListAvailable -Name WindowsAutopilotIntune -ErrorAction Ignore
if(-not($module))
{
    Install-Module -Name WindowsAutopilotIntune -confirm:$false -Force
    Write-Host "Installed WindowsAutopilotIntune"
}
else
{
    Write-Host "WindowsAutopilotIntune already installed"
}


# connect to microsoft graph
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All"

$me = Get-MgUserMe
Write-Host "Connected Microsoft Graph with account: $($me.UserPrincipalName)"

# You can change the group tag of autopilot devices using either a list of serial numbers or using an old group tag as a target

# OPTION 1: Change group tag using a list of serial numbers

# get list of serial numbers from CSV file
$csvPath = Join-Path -Path (Get-Location) -ChildPath "grouptag-serials.csv"
$serialNumbers = Import-Csv -Path $csvPath | Select-Object -ExpandProperty SerialNumber

# for each serial number, get entra device object id
foreach ($serialNumber in $serialNumbers) {
    try 
    {
        $id = (Get-AutopilotDevice -serial $serialNumber).id
        Set-AutopilotDevice -id $id -GroupTag "EN-VN-H"
        Write-Host "Changed group tag for device with serial number $serialNumber"        
    }
    catch 
    {
        $message = $_.Exception.Message
        Write-Host "Failed to change group tag for device with serial number $($serialNumber): $message"
    }

}

# OPTION 2: Change group tag using an old group tag as a target
$oldGroupTag = "OldGroupTag"

# get list of devices with the old group tag
$devices = Get-AutopilotDevice -GroupTag $oldGroupTag
foreach($device in $devices)
{
    try 
    {
        Set-AutopilotDevice -id $device.id -GroupTag "EN-VN-H"
        Write-Host "Changed group tag for device with serial number $($device.serialNumber)"        
    }
    catch 
    {
        $message = $_.Exception.Message
        Write-Host "Failed to change group tag for device with serial number $($device.serialNumber): $message"
    }
}