
##The following sample is used to fetch the capacity of the Azure Storage Account within the Azure Subscription.

## Note that the shared method relies on the metrics being enable for the Azure Storage Account.



Connect-AzureRmAccount



$storageAccountName = Get-AzureRMStorageAccount | select StorageAccountName, ResourceGroupName



Write-Host -ForegroundColor Black -BackgroundColor Cyan "Fetching all the Storage Accounts under the above subscription and its corressponding resource group"



foreach($name in $storageAccountName){



$key = Get-AzureRmStorageAccountKey -ResourceGroupName $name.ResourceGroupName -AccountName $name.StorageAccountName



$ctx = New-AzureStorageContext -StorageAccountName $name.StorageAccountName -StorageAccountKey $key[0].Value.ToString()



$table = Get-AzureStorageTable -Name "`$MetricsCapacityBlob" -Context $ctx



$query = New-Object Microsoft.WindowsAzure.Storage.Table.TableQuery

$datefrom = (Get-Date).ToUniversalTime().AddDays(-2).ToString("yyyyMMddT0000")



$query.FilterString = "PartitionKey ge '$datefrom'"



$entities = $table.CloudTable.ExecuteQuery($query)



Write-Host -ForegroundColor Black -BackgroundColor Cyan "Storage Account Name:: $name.StorageAccountName"

$entities  | Format-Table PartitionKey, RowKey, @{ Label = "Capacity"; Expression={$_.Properties["Capacity"].Int64Value}}, @{ Label = "ContainerCount"; Expression={$_.Properties["ContainerCount"].Int64Value}}, @{ Label = "ObjectCount"; Expression={$_.Properties["ObjectCount"].Int64Value}} 







}