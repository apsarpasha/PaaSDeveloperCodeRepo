###
## DISCLAIMER : This is a sample and is provided as is with no warranties express or implied.
##https://gist.github.com/ajith-k
## Instructions :-
##     1.Launch cloudshell and set the subscription context using 
##         Set-AzContext -SubscriptionID <yoursubscription>
##     2.Click "Raw" on this github gist and copy everything after the line "##StartCopy"
##     3.Execute this script in the cloud shell to register the routine.
##     4.Execute it as Get-CoolBlobs -RGName MyResourceGroup -Name MyStorageAccount
###

##StartCopy
function Get-CoolBlobs
{
 param(
  [Parameter(Mandatory=$true, HelpMessage="Resource Group Name")]
  [String] $RGName,
  [Parameter(Mandatory=$true, HelpMessage="Storage Account Name")]
  [String] $Name
 )
 
 $Ctx = (Get-AzStorageAccount -ResourceGroupName $RGName -Name $Name).Context
 $container_continuation_token = $null
 do {
  $containers = Get-AzStorageContainer -Context $Ctx -MaxCount 5000 -ContinuationToken $container_continuation_token
  $container_continuation_token = $null;
  If ($containers -ne $null)
  {
   $container_continuation_token = $containers[$containers.Count - 1].ContinuationToken
   for ([int] $c = 0; $c -lt $containers.Count; $c++)
   {
    $container = $containers[$c].Name
    Write-Verbose "Processing container : $container"
    $total_usage = 0
    $blob_continuation_token = $null
    do {
     $blobs = Get-AzStorageBlob -Context $Ctx -Container $container -MaxCount 5000 -IncludeDeleted -ContinuationToken $blob_continuation_token
     $blob_continuation_token = $null;
     if ($blobs -ne $null)
     {
      $blob_continuation_token = $blobs[$blobs.Count - 1].ContinuationToken
      for ([int] $b = 0; $b -lt $blobs.Count; $b++)
      {
       if ($blobs[$b].ICloudBlob.Properties.StandardBlobTier -eq "Cool")
       {
        $total_usage += $blobs[$b].Length
        Write-Host $blobs[$b].ICloudBlob.Uri.AbsolutePath
       }
      }
      If ($blob_continuation_token -ne $null)
      {
       Write-Verbose "Blob listing continuation token = {0}".Replace("{0}",$blob_continuation_token.NextMarker)
      }
     }
    }while ($blob_continuation_token -ne $null)
    if ($total_usage -gt 0)
    {
     Write-Host "Found cool blobs in container $container. Total Size = $total_usage "
    }
   }
  }
  If ($container_continuation_token -ne $null)
  {
   Write-Verbose "Container listing continuation token = {0}".Replace("{0}",$container_continuation_token.NextMarker)
  }
 } while ($container_continuation_token -ne $null)
}
