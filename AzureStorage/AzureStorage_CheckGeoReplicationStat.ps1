# https://gist.github.com/ajith-k
function PrintServiceStats 
{
    Param(
      [Parameter (Mandatory=$True,Position=1)] [string] $storageAccountName,
      [Parameter (Mandatory=$True,Position=2)] [string] $accountSASToken,
      [Parameter (Mandatory=$True,Position=3)] [string] $service
    )
    $accountSASParam = $accountSASToken.Replace("?","")
    $statsURI = "https://$storageAccountName-secondary.$service.core.windows.net/?restype=service&comp=stats&$accountSASParam"
    $resp = Invoke-WebRequest -Method Get -Uri $statsURI 

    #strip leading unprintables
    $resp = $resp.Content.Remove(0,$resp.Content.IndexOf('<'))

    #Show Replication stats
    Write-Host "Replication stats for $storageAccountName $service service : "
    ([Xml]$resp).StorageServiceStats.GeoReplication | ft

}

#Get the storage context information
$storageAccount = "<MyAccountName>"
$sharedkey = "<MyAccountKey>"

# Build a SAS Token for easy authentication with secondary.
$ctx = New-AzureStorageContext -StorageAccountName $storageAccount -StorageAccountKey $sharedKey
$acctSAS = (New-AzureStorageAccountSASToken -Context $ctx -Service @("Blob","Table","Queue") -ResourceType Service -Permission "rl" -ExpiryTime ((Get-Date).AddHours(1)).ToUniversalTime())

# Print all three service stats.
PrintServiceStats $storageAccount $acctSAS "blob"
PrintServiceStats $storageAccount $acctSAS "queue"
PrintServiceStats $storageAccount $acctSAS "table"
