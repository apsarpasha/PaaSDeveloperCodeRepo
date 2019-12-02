# https://gist.github.com/ajith-k
[CmdletBinding()]
Param (
    [Parameter (Mandatory=$true, HelpMessage="Premium Storage Account resource URI")] 
    [String] $storageResourceId 
)


# Enable Verbose logs for debugging
$VerbosePreference = "Continue"

####
# Set the premium blob provisioned sizes per documentation : https://docs.microsoft.com/en-us/azure/virtual-machines/windows/premium-storage#premium-storage-disk-limits
##
$premium_blob_tiers = @{}
$premium_blob_tiers.Add("P4",32)
$premium_blob_tiers.Add("P6",64)
$premium_blob_tiers.Add("P10",128)
$premium_blob_tiers.Add("P15",256)
$premium_blob_tiers.Add("P20",512)
$premium_blob_tiers.Add("P30",1024)
$premium_blob_tiers.Add("P40",2048)
$premium_blob_tiers.Add("P50",4095)
$premium_blob_tiers.Add("P60",8192)
$premium_blob_tiers.Add("P70",16384)
$premium_blob_tiers.Add("P80",32767)

Write-Verbose "Got this Storage Resource Id : $storageResourceId" 

# Split up the resource ID segments
$resIdFields = $storageResourceId.Split("/")

# Detect Subscription ID, Resource Group Name and Storage Account name
$subId = $resIdFields[$resIdFields.IndexOf("subscriptions")+1]
$rg = $resIdFields[$resIdFields.IndexOf("resourceGroups")+1]
$storageAccount = $resIdFields[$resIdFields.IndexOf("storageAccounts")+1]

# Cant validate it for now just dump it as verbose info
Write-Verbose "Retrieved the following information :" 
Write-Verbose "  Subscription ID : $subId" 
Write-Verbose "  Resource Group  : $rg" 
Write-Verbose "  Storage Account : $storageAccount" 

# Ensure we have the right context
While ((Select-AzureRmSubscription -Subscription $subId -ErrorAction SilentlyContinue) -eq $null)
{
    Write-Verbose "Unable to set subscription $subId. Please login with the right credentials"
    Login-AzureRmAccount -Subscription $subId
}

# Check if we are a premium storage account
$sa = Get-AzureRmStorageAccount -ResourceGroupName $rg -Name $storageAccount
Write-Verbose ([String]::Format("Retrieved the storage account sku : {0}",$sa.Sku.Tier.ToString()))
If ($sa.Sku.Tier -ne "Premium")
{
    Write-Debug " Storage account is not premium. Exiting.."
    return;
}

# Get storage context from storage account object to enumerate entities.
$Ctx = $sa.Context 

# Data tracking variables.
$blob_tiers = @{}
$global:provisioned_size = 0
　
# Initialize continuation tokens for segmented access
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
            $blob_continuation_token = $null
            do {
                $blobs = Get-AzureStorageBlob -Context $Ctx -Container $container -MaxCount 5000 -ContinuationToken $blob_continuation_token
                if ($blobs -ne $null)
                {
                    $blob_continuation_token = $blobs[$blobs.Count - 1].ContinuationToken
                    for ([int] $b = 0; $b -lt $blobs.Count; $b++)
                    {
                        # Dont use snapshot for quota usage calculation for now. It has a separate quota.
                        if ($blobs[$b].ICloudBlob.IsSnapshot)
                        {
                            $snapName = $blobs[$b].ICloudBlob.SnapshotQualifiedUri.PathAndQuery.ToString()
                            Write-Verbose "Skipping snapshot : $snapName"
                        } else
                        {
                            $blobs[$b].ICloudBlob.FetchAttributes()
                            $blobsize = $premium_blob_tiers[$blobs[$b].ICloudBlob.Properties.PremiumPageBlobTier.ToString()]
                            if ($VerbosePreference -eq "Continue")
                            {
                                $blob_tiers.Add([String]::Format("{0} : {1}",$blobs[$b].ICloudBlob.StorageUri.PrimaryUri.PathAndQuery,$blobs[$b].ICloudBlob.Properties.PremiumPageBlobTier),$blobsize)
                            }
                            $Global:provisioned_size += $blobsize
                        }
                    }
                    If ($blob_continuation_token -ne $null)
                    {
                        Write-Verbose "Blob listing continuation token = {0}".Replace("{0}",$blob_continuation_token.NextMarker)
                    }
                } else {
                    # Should not happen but if we retrieved nothing with continuationtoken set, we must nullify continuation token
                    $blob_continuation_token = $null;
                }
            } while ($blob_continuation_token -ne $null)
        }
   }
   If ($container_continuation_token -ne $null)
   {
        Write-Verbose "Container listing continuation token = {0}".Replace("{0}",$container_continuation_token.NextMarker)
   }
} while ($container_continuation_token -ne $null)

if ($VerbosePreference -eq "Continue")
{
    $blob_tiers | Format-Table -AutoSize 
}

Write-Host "Storage capacity already provisioned : $global:provisioned_size GB" -ForegroundColor Yellow
Write-Host
Write-Host "All Done!" -ForegroundColor Yellow
