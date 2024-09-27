# Install IIS
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Define the HTML content
$htmlContent = @"
<!DOCTYPE html>
<html>

<head>
    <title>VM Info</title>
    <style>
        body {
            background-image: url('asrdemo.png');
            background-size: cover;
            color: white;
            text-shadow: 2px 2px 4px #000000;
        }

        h1,
        p {
            background-color: rgba(0, 0, 0, 0.5);
            padding: 10px;
            border-radius: 5px;
        }
    </style>
    <script>
        function displayDateTime() {
            var now = new Date();
            document.getElementById("dateTime").innerHTML = now;
        }

        function fetchVmInfo() {
            const xhr = new XMLHttpRequest();
            xhr.open('GET', 'http://169.254.169.254/metadata/instance/compute?api-version=2021-02-01', true);
            xhr.setRequestHeader('Metadata', 'true');
            xhr.onreadystatechange = function () {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    const response = JSON.parse(xhr.responseText);
                    document.getElementById("vmName").innerHTML = response.name;
                    document.getElementById("vmRegion").innerHTML = response.location;
                }
            };
            xhr.send();
        }

        window.onload = function () {
            fetchVmInfo();
            displayDateTime();
        };
    </script>
</head>

<body>
    <h1>VM Information</h1>
    <p>VM Name: <span id="vmName"></span></p>
    <p>Azure Region: <span id="vmRegion"></span></p>
    <p>Current Date and Time: <span id="dateTime"></span></p>
</body>

</html>
"@

# Define the path to the default IIS site
$defaultSitePath = "C:\inetpub\wwwroot\index.html"

# Write the HTML content to the default site
Set-Content -Path $defaultSitePath -Value $htmlContent
Invoke-WebRequest -Uri "https://github.com/dsmithcloud/ASR-Lab/raw/main/MODULES/asrdemo.png" -OutFile "${defaultSitePath}\asrdemo.png"

# Restart IIS to apply changes
Restart-Service -Name 'W3SVC'