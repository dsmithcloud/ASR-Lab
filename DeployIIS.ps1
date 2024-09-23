# Install IIS
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Get VM Name and Local IP Address
$vmName = $env:COMPUTERNAME
#$localIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet").IPAddress

# Create HTML content
$htmlContent = @"
<html>
<head>
    <title>Welcome to IIS on $vmName</title>
</head>
<body>
    <h1>Welcome to IIS on $vmName</h1>
</body>
</html>
"@

# Define the path to the default IIS site
$defaultSitePath = "C:\inetpub\wwwroot\index.html"

# Write the HTML content to the default site
Set-Content -Path $defaultSitePath -Value $htmlContent

# Restart IIS to apply changes
Restart-Service -Name 'W3SVC'