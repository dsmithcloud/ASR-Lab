# Install IIS
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Define the HTML content
$htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Web Server Details</title>
    <link rel="stylesheet" href="index.css">
</head>
<body>
<BR><BR><BR><DIV STYLE="background-color: #000000; color: #FFFFFF;" >ServerName<BR>Location<BR></DIV>
</body>
</html>
"@

$cssContent = @"
body{
/* single image */
background-image: linear-gradient(black, white);
background-image: url("asrdemo.png");
}
"@

# Define the path to the default IIS site
$defaultSitePath = "C:\inetpub\wwwroot"

# Write the HTML, CSS, background image, and powershell script content to the default site
Set-Content -Path "${defaultSitePath}\index.html" -Value $htmlContent
Set-content -path "${defaultSitePath}\index.css" -Value $cssContent
Invoke-WebRequest -Uri "https://github.com/dsmithcloud/ASR-Lab/raw/main/MODULES/asrdemo.png" -OutFile "${defaultSitePath}\asrdemo.png"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/dsmithcloud/ASR-Lab/refs/heads/main/MODULES/update-htmlcontent.ps1" -OutFile "${defaultSitePath}\update-htmlcontent.ps1"

& "${defaultSitePath}\update-htmlcontent.ps1"

# Define the action to run the script
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -File `"$defaultSitePath\update-htmlcontent.ps1`""

# Define the trigger to start at system startup and repeat every minute indefinitely
$trigger = New-ScheduledTaskTrigger -AtStartup

# Define the principal with highest privileges
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Create the scheduled task and change the repetition
Register-ScheduledTask -TaskName "MyScriptTask" -Action $action -Trigger $trigger -Principal $principal
schtasks /Change /TN "MyScriptTask" /RI 1 /DU 9999

