###
## DISCLAIMER : This is a sample and is provided as is with no warranties express or implied.

## This Script will list down all the cool blobs along with the total size of the blobs

## Instruction 
     #1. Run the script on PowerShell window
	 #2. Provide the Storage account Name 
	 #3. Provide your Storage Account Key 
	 
	 #Reference : https://gist.github.com/ajith-k/bf73ecd203bfdf1869a5e6d1f56ef99c
###

[CmdletBinding(DefaultParametersetName="SharedKey")]
param(

  [Parameter(Mandatory=$true, HelpMessage="Storage Account Name")] 
  [String] $storage_account_name,

  [Parameter(Mandatory=$true, HelpMessage="Any one of the two shared access keys", ParameterSetName="SharedKey", Position=1)] 
  [String] $storage_shared_key,
  
  [Parameter(Mandatory=$true, HelpMessage="SAS Token : the GET parameters", ParameterSetName="SASToken", Position=1)] 
  [String] $storage_sas_token
  
)

#If ($true)
If ($PsCmdlet.ParameterSetName -eq "SharedKey")
{
  $Ctx = New-AzureStorageContext -StorageAccountName $storage_account_name -StorageAccountKey $storage_shared_key
}
Else
{
  $Ctx = New-AzureStorageContext -StorageAccountName $storage_account_name -SasToken $storage_sas_token
}
　
$container_continuation_token = $null

do {

  $containers = Get-AzureStorageContainer -Context $Ctx -MaxCount 5000 -ContinuationToken $container_continuation_token
        
  $container_continuation_token = $null;
        
  if ($containers -ne $null)
  {
    $container_continuation_token = $containers[$containers.Count - 1].ContinuationToken

    for ([int] $c = 0; $c -lt $containers.Count; $c++)
    {
      $container = $containers[$c].Name

      Write-Verbose "Processing container : $container"

      $total_usage = 0
                
      $blob_continuation_token = $null
                
      do {
                        
        $blobs = Get-AzureStorageBlob -Context $Ctx -Container $container -MaxCount 5000 -IncludeDeleted -ContinuationToken $blob_continuation_token

        $blob_continuation_token = $null;

        if ($blobs -ne $null)
        {
          $blob_continuation_token = $blobs[$blobs.Count - 1].ContinuationToken

          for ([int] $b = 0; $b -lt $blobs.Count; $b++)
          {
            if ($blobs[$b].IsDeleted)
            {
              $soft_delete_count++
              $soft_delete_usage += $blobs[$b].Length
            }
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
      } while ($blob_continuation_token -ne $null)

      Write-Host "Calculated size cool blobs in $container = $total_usage "
                        
    }
  }
 
  If ($container_continuation_token -ne $null)
  {
    Write-Verbose "Container listing continuation token = {0}".Replace("{0}",$container_continuation_token.NextMarker)
  }

} while ($container_continuation_token -ne $null)

