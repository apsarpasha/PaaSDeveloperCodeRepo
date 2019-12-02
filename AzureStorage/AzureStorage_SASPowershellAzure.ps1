## Customer specific data
## Invoking REST API using PowerShell 
$storageaccountname = "apsardemo4"
$sastoken = "?sv=2019-02-02&ss=bfqt&srt=sco&sp=rwdlacup&se=2019-11-13T18:26:23Z&st=2019-11-12T10:26:23Z&spr=https&sig=zms9xaUqwiApiTGa7lBpxwqTpKBPEq78Vo6PBvJdBsA%3D"
$container = "sasaccesstest"
$blobname = "mytestblob.txt"

## Construct required variables"
$containeruri="https://$storageaccountname.blob.core.windows.net/$container$sastoken&restype=container"
$bloburi="https://$storageaccountname.blob.core.windows.net/$container/$blobname$sastoken"
$blobdata = "Test blob data"
$date = (Get-Date).ToUniversalTime().ToString("o")

$ShortRequestHeaders = @{
    "Date"=$date
}

$RequestHeaders = @{
    "Date"=$date
    "Content-Length"=$blobdata.length
    "Content-Type"="application/text"
    "x-ms-blob-type"="BlockBlob"
}

# create container
try {
    $resp = Invoke-WebRequest -Method Put -Uri $containeruri -Headers $ShortRequestHeaders 
    $resp
} catch
{
  ## for now we will ignore failures (most likely caused by container already exists.
}

# create blob
$resp = Invoke-WebRequest -Method Put -Uri $bloburi -Headers $RequestHeaders -Body $blobdata
$resp

#if successful get blob and then delete it.
if ($resp.StatusCode -eq 201)
{
    Write-Host "`r`nCreate blob successful. We will now retrieve the blob.`r`n" -ForegroundColor Yellow
    $resp = (Invoke-WebRequest -Method Get -Uri $bloburi).RawContent ##-Headers $RequestHeaders -Body $blobdata
    $resp

#    Write-Host "`r`nIssuing a delete blob.`r`n" -ForegroundColor Yellow
 #   $resp = Invoke-WebRequest -Method Delete -Uri $bloburi -Headers $ShortRequestHeaders 
    $resp
}