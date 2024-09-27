# Install IIS
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Get VM Name and Local IP Address
$vmName = $env:COMPUTERNAME
#$localIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet").IPAddress

# Create Java content
$javaContent = @"
// server.js
const express = require('express');
const sql = require('mssql');
const app = express();
const port = 3000;

// Database configuration
const config = {
    user: 'your_username',
    password: 'your_password',
    server: 'your_server',
    database: 'AdventureWorks'
};

// Connect to the database
sql.connect(config, err => {
    if (err) console.log(err);
    else console.log('Connected to the database');
});

// Endpoint to get data
app.get('/api/products', async (req, res) => {
    try {
        const result = await sql.query`SELECT TOP 10 * FROM Production.Product`;
        res.json(result.recordset);
    } catch (err) {
        res.status(500).send(err.message);
    }
});

app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
});

"@
# Create HTML content
$htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AdventureWorks Products</title>
</head>
<body>
    <h1>AdventureWorks Products</h1>
    <table border="1">
        <thead>
            <tr>
                <th>ProductID</th>
                <th>Name</th>
                <th>ProductNumber</th>
                <th>Color</th>
                <th>StandardCost</th>
                <th>ListPrice</th>
            </tr>
        </thead>
        <tbody id="productTableBody">
        </tbody>
    </table>

    <script>
        async function fetchProducts() {
            try {
                const response = await fetch('/api/products');
                const products = await response.json();
                const tableBody = document.getElementById('productTableBody');

                products.forEach(product => {
                    const row = document.createElement('tr');
                    row.innerHTML = `
                        <td>${product.ProductID}</td>
                        <td>${product.Name}</td>
                        <td>${product.ProductNumber}</td>
                        <td>${product.Color}</td>
                        <td>${product.StandardCost}</td>
                        <td>${product.ListPrice}</td>
                    `;
                    tableBody.appendChild(row);
                });
            } catch (error) {
                console.error('Error fetching products:', error);
            }
        }

        fetchProducts();
    </script>
</body>
</html>
"@

# Define the path to the Java content
$javaPath = "C:\inetpub\wwwroot\server.js"

# Define the path to the default IIS site
$defaultSitePath = "C:\inetpub\wwwroot\index.html"

# Write the Java content to the default IIS site
Set-Content -Path $javaPath -Value $javaContent

# Write the HTML content to the default site
Set-Content -Path $defaultSitePath -Value $htmlContent

# Install dependencies
npm init -y
npm install express mssql

# Update Database Credentials
$serverJsPath = $javaPath
$content = Get-Content $serverJsPath
$content = $content -replace "your_server_name", "new_server_name"
$content = $content -replace "your_database_name", "new_database_name"
$content = $content -replace "your_username", "new_username"
$content = $content -replace "your_password", "new_password"
Set-Content $serverJsPath -Value $content

# Run the server
node $serverJsPath

# Adjust CORS Settings
$serverJsPath = $javaPath
$content = Get-Content $serverJsPath
$corsCode = @"
const cors = require('cors');
app.use(cors());
"@
$content = $content -replace "app.use\(express.json\(\)\);", "app.use(express.json());`n$corsCode"
Set-Content $serverJsPath -Value $content


# Restart IIS to apply changes
Restart-Service -Name 'W3SVC'