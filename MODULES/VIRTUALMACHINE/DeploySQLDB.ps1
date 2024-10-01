param (
    [string] $adminUsername,
    [securestring] $adminPassword
)

# Set the credentials
$credential = New-Object System.Management.Automation.PSCredential($adminUsername, $adminPassword)

# Get the disk you attached
$disk = Get-Disk | Where-Object PartitionStyle -Eq 'RAW'

# Initialize the disk
Initialize-Disk -Number $disk.Number

# Create a new partition
$partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter

# Format the partition
Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel "DataDisk" -Confirm:$false

# Output the drive letter
$driveletter = "$($partition.DriveLetter):"

# Create DB folder on the new drive
$dataPath = New-Item -Path "${driveletter}\SQLData" -ItemType Directory

# Download the AdventureWorks database
$downloadPath = "C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup"
Invoke-WebRequest -Uri "https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksLT2019.bak" -OutFile "${downloadPath}\AdventureWorksLT2019.bak"

# Install and import the SQLSERVER PS Module
Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
Install-Module -Name SqlServer -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck | Import-Module

# Restore the AdventureWorks database
$databaseName = "AdventureWorksLT2019"
$dataFile = "${dataPath}\AdventureWorksLT2019_Data.mdf"
$logFile = "${dataPath}\AdventureWorksLT2019_Log.ldf"
$backupPath = "${downloadPath}\AdventureWorksLT2019.bak"
$restoreQuery = @"
RESTORE DATABASE [$databaseName]
FROM DISK = N'$backupPath'
WITH MOVE N'AdventureWorksLT2019_Data' TO N'$dataFile',
MOVE N'AdventureWorksLT2019_Log' TO N'$logFile',
NOUNLOAD, STATS = 10
"@

SqlServer\Invoke-Sqlcmd -ServerInstance . -Query $restoreQuery -TrustServerCertificate -Credential $credential