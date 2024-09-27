# Install IIS
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Define the HTML content
$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
  <title>VM Info</title>
  <script>
    function displayDateTime() {
      var now = new Date();
      document.getElementById("dateTime").innerHTML = now;
    }

    function fetchVmName() {
      // Placeholder for VM name fetching logic
      return "MyVirtualMachine";
    }
    
    window.onload = function() {
      document.getElementById("vmName").innerHTML = fetchVmName();
      displayDateTime();
    };
  </script>
</head>
<body>
  <h1>VM Information</h1>
  <p>VM Name: <span id="vmName"></span></p>
  <p>Current Date and Time: <span id="dateTime"></span></p>
</body>
</html>
"@

# Define the path to the default IIS site
$defaultSitePath = "C:\inetpub\wwwroot\index.html"

# Write the HTML content to the default site
Set-Content -Path $defaultSitePath -Value $htmlContent

# Restart IIS to apply changes
Restart-Service -Name 'W3SVC'