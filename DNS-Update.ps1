# Update DNS Record for domain after public IP change

param (
    [switch]$ipcheck
);

# Config-File
$configPath = "$PSScriptRoot\Config\config.json"

if (-not (Test-Path $configPath)) {
    Write-Error "Config-Datei missing"
    exit 1
}

$Config = Get-Content $configPath -Raw | ConvertFrom-Json

# Get Public IP of host if -ipcheck is set
if ($ipcheck) {
    try {
        $PublicIP = Invoke-RestMethod -Uri "https://api.ipify.org?format=json" -ErrorAction Stop
        $Config.NewIP = $PublicIP.ip
    }
    catch {
        Write-Error "Could not retrieve Public IP."
        exit 4
    }
}

# Insert ZONE_ID
$Config.Records_URI = $Config.Records_URI -replace '{ZONE_ID}', $Config.ZONE_ID
$Config.Update_URI = $Config.Update_URI -replace '{ZONE_ID}', $Config.ZONE_ID

# Create Secure Token
$Secure_Token = $(ConvertTo-SecureString $Config.API_Token -AsPlainText)

# Get ID of record to update
$DNS_Records = Invoke-RestMethod -Uri $Config.Records_URI -Authentication Bearer -Token $Secure_Token

if ($DNS_Records) {
    $Record = $DNS_Records.result | Where-Object { $_.type -eq $Config.Record_Type -and $_.name -eq $Config.Domain_Name }
    if ($Record) {
        $Record_ID = $Record | Select-Object -ExpandProperty id

        # Check for changes
        $changes =
        $Record.name -ne $Config.Domain_Name -or
        $Record.ttl -ne $Config.Record_TTL -or
        $Record.type -ne $Config.Record_Type -or
        $Record.comment -ne $Config.Record_Comment -or
        $Record.content -ne $Config.NewIP -or
        $Record.proxied -ne $Config.Record_Proxied

        # Stop script if no changes detected
        if (-not $changes) {
            Write-Host "No changes detected. Exiting."
            exit 0
        }
        
        # Insert Record_ID
        $Update_URI = $Config.Update_URI -replace '{Record_ID}', $Record_ID

        # Create body for PATCH request
        $body = @{
            name    = $Config.Domain_Name
            ttl     = $Config.Record_TTL
            type    = $Config.Record_Type
            comment = $Config.Record_Comment
            content = $Config.NewIP
            proxied = $Config.Record_Proxied
        } | ConvertTo-Json -Depth 3

        $Update_Result = Invoke-WebRequest -Uri $Update_URI -Authentication Bearer -Token $Secure_Token -Method Patch -ContentType 'application/json' -Body $body
        Write-Host $Update_Result
    }
    else {
        Write-Error "No matching $Config.Record_Type Record found."
        exit 3
    }
}
else {
    Write-Error "No Records fetched."
    exit 2
}