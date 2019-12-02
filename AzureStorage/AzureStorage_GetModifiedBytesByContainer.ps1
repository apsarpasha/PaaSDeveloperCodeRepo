###
## Get blob bytes added per container between specific window start and window end
##https://gist.github.com/ajith-k
## NOTE: 1) Be careful when trying to equate this to Ingress and Egress because the same blob could have been overwritten multiple times
##       and blobs could have been deleted and so may no longer be available to be accounted.
##       2) This script will issue ListBlob operations against the storage account and will add to the overall transaction count
##       for the storage account. The overall transactions generated may be insignificant but please be aware of this.
##
## DISCLAIMER : This is a sample and is provided as is with no warranties express or implied.
##

[CmdletBinding(DefaultParametersetName="SharedKey")]
param(

  [Parameter(Mandatory=$true, HelpMessage="Storage Account Name")] 
  [String] $storage_account_name,

  [Parameter(Mandatory=$true, HelpMessage="Any one of the two shared access keys", ParameterSetName="SharedKey", Position=1)] 
  [String] $storage_shared_key,
  
  [Parameter(Mandatory=$true, HelpMessage="SAS Token : the GET parameters only starting with the ?", ParameterSetName="SASToken", Position=1)] 
  [String] $storage_sas_token,

  [Parameter(Mandatory=$true, HelpMessage="Data modification time window start")] 
  [DateTimeOffset] $start,

  [Parameter(Mandatory=$true, HelpMessage="Data modification time window end")] 
  [DateTimeOffset] $end
  
)
$container_sizes = @{}

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
    
    if ($containers -ne $null)
    {
        $container_continuation_token = $containers[$containers.Count - 1].ContinuationToken

        for ([int] $c = 0; $c -lt $containers.Count; $c++)
        {
            $container = $containers[$c].Name

            Write-Verbose "Processing container : $container"

            $container_usage = 0
        
            $blob_continuation_token = $null
        
            do {
            
                $blobs = Get-AzureStorageBlob -Context $Ctx -Container $container -MaxCount 5000 -ContinuationToken $blob_continuation_token
            
                if ($blobs -ne $null)
                {
                    $blob_continuation_token = $blobs[$blobs.Count - 1].ContinuationToken

                    for ([int] $b = 0; $b -lt $blobs.Count; $b++)
                    {
                        if ($blobs[$b].LastModified.CompareTo($start) -gt 0 -and $blobs[$b].LastModified.CompareTo($end)) {
                            $container_usage += $blobs[$b].Length
                        }
                    }

                       If ($blob_continuation_token -ne $null)
                       {
                           Write-Verbose "Blob listing continuation token = {0}".Replace("{0}",$blob_continuation_token.NextMarker)
                       }
                }
            } while ($blob_continuation_token -ne $null)

            Write-Verbose "Calculated size of $container = $container_usage"

            $container_sizes.Add($container, $container_usage)
        }
   }
 
   If ($container_continuation_token -ne $null)
   {
        Write-Verbose "Container listing continuation token = {0}".Replace("{0}",$container_continuation_token.NextMarker)
   }
 
} while ($container_continuation_token -ne $null)

$container_sizes | Format-Table -AutoSize 