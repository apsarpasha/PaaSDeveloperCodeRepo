## Customer specific data
$storageaccountname = "ajtstsa"
$sastoken = "?sv=2018-03-28&ss=b&srt=sco&sp=rwdlac&se=2019-04-30T22:33:54Z&st=2019-04-29T14:33:54Z&spr=https,http&sig=yXWcUTBsLPp%2B8ab6IRLzgwQJsfsBp3h3yk4WKiD4%2Fig%3D"
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

    Write-Host "`r`nIssuing a delete blob.`r`n" -ForegroundColor Yellow
    $resp = Invoke-WebRequest -Method Delete -Uri $bloburi -Headers $ShortRequestHeaders 
    $resp
}