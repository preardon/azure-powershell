﻿# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------------


<#
.SYNOPSIS
Tests creating a new application
#>
function Test-AddApplication
{
    # Setup
    $applicationId = "test"
    $applicationVersion = "foo"
    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    try
    {
        $addAppPack = New-AzureRmBatchApplication -AccountName $context.AccountName -ApplicationId $applicationId -ResourceGroupName $context.ResourceGroupName
        $getapp = Get-AzureRmBatchApplication -AccountName $context.AccountName -ApplicationId $applicationId -ResourceGroupName $context.ResourceGroupName

        Assert-AreEqual $getapp.Id $addAppPack.Id
    }
    finally
    {
        Remove-AzureRmBatchApplication  -AccountName $context.AccountName -ApplicationId $applicationId -ResourceGroupName $context.ResourceGroupName
    }
}

<#
.SYNOPSIS
Tests uploading an application package.
#>
function Test-UploadApplicationPackage
{
    param([string]$filePath)

    # Setup
    $applicationId = "test"
    $applicationVersion = "foo"
    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    try
    {
        $addAppPack = New-AzureRmBatchApplicationPackage -ResourceGroupName $context.ResourceGroupName -AccountName $context.AccountName -ApplicationId $applicationId -ApplicationVersion $applicationVersion -FilePath $filePath -format "zip"
        $getapp = Get-AzureRmBatchApplicationPackage -ResourceGroupName $context.ResourceGroupName -AccountName $context.AccountName -ApplicationId $applicationId -ApplicationVersion $applicationVersion

        Assert-AreEqual $getapp.Id $addAppPack.Id
        Assert-AreEqual $getapp.Version $addAppPack.Version
    }
    finally
    {
        Remove-AzureRmBatchApplicationPackage -AccountName $context.AccountName -ApplicationId $applicationId -ResourceGroupName $context.ResourceGroupName -ApplicationVersion $applicationVersion
    }
}

<#
.SYNOPSIS
Tests can update an application settings
#>
function Test-UpdateApplicationPackage
{
    param([string]$filePath)

    # Setup
    $applicationId = "test"
    $applicationVersion = "foo"
    $newDisplayName = "application-display-name"
    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    try
    {
        $addAppPack = New-AzureRmBatchApplicationPackage -ResourceGroupName $context.ResourceGroupName -AccountName $context.AccountName -ApplicationId $applicationId -ApplicationVersion $applicationVersion -FilePath $filePath -format "zip"
        $beforeUpdateApp = Get-AzureRmBatchApplication -ResourceGroupName $context.ResourceGroupName -AccountName $context.AccountName -ApplicationId $applicationId

        Set-AzureRmBatchApplication -ResourceGroupName $context.ResourceGroupName -AccountName $context.AccountName -ApplicationId $applicationId -displayName $newDisplayName -defaultVersion $applicationVersion
        $afterUpdateApp = Get-AzureRmBatchApplication -ResourceGroupName $context.ResourceGroupName -AccountName $context.AccountName -ApplicationId $applicationId

        Assert-AreEqual $afterUpdateApp.DefaultVersion "foo"
        Assert-AreNotEqual $afterUpdateApp.DefaultVersion $beforeUpdateApp.DefaultVersion
        Assert-AreEqual $afterUpdateApp.AllowUpdates $true
    }
    finally
    {
        Remove-AzureRmBatchApplicationPackage -AccountName $context.AccountName -ApplicationId $applicationId -ResourceGroupName $context.ResourceGroupName -ApplicationVersion $applicationVersion
    }
}

<#
.SYNOPSIS
Tests create pool with an application package.
#>
function Test-CreatePoolWithApplicationPackage
{
    param([string] $poolId, [string]$filePath)

    # Setup
    $applicationId = "test"
    $applicationVersion = "foo"
    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    try
    {
        $addAppPack = New-AzureRmBatchApplicationPackage -ResourceGroupName $context.ResourceGroupName -AccountName $context.AccountName -ApplicationId $applicationId -ApplicationVersion $applicationVersion -FilePath $filePath -format "zip"

        $getapp = Get-AzureRmBatchApplicationPackage -ResourceGroupName $context.ResourceGroupName -AccountName $context.AccountName -ApplicationId $applicationId -ApplicationVersion $applicationVersion

        Assert-AreEqual $getapp.Id $addAppPack.Id
        Assert-AreEqual $getapp.Version $addAppPack.Version

        $apr1 = New-Object Microsoft.Azure.Commands.Batch.Models.PSApplicationPackageReference
        $apr1.ApplicationId = $applicationId
        $apr1.Version = $applicationVersion
        $apr = [Microsoft.Azure.Commands.Batch.Models.PSApplicationPackageReference[]]$apr1

        # Create a pool with application package reference
        $osFamily = "4"
        $targetOSVersion = "*"
        $paasConfiguration = New-Object Microsoft.Azure.Commands.Batch.Models.PSCloudServiceConfiguration -ArgumentList @($osFamily, $targetOSVersion)

        New-AzureBatchPool -Id $poolId -CloudServiceConfiguration $paasConfiguration -TargetDedicated 3 -VirtualMachineSize "small" -BatchContext $context -ApplicationPackageReferences $apr
    }
    finally
    {
        Remove-AzureRmBatchApplicationPackage -AccountName $context.AccountName -ApplicationId $applicationId -ResourceGroupName $context.ResourceGroupName -ApplicationVersion $applicationVersion
        Remove-AzureBatchPool -Id $poolId -Force -BatchContext $context
    }
}

<#
.SYNOPSIS
Tests update pool with an application package.
#>
function Test-UpdatePoolWithApplicationPackage
{
    param([string] $poolId, [string]$filePath)

    $applicationId = "test"
    $applicationVersion = "foo"
    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    try
    {
        $addAppPack = New-AzureRmBatchApplicationPackage -ResourceGroupName $context.ResourceGroupName -AccountName $context.AccountName -ApplicationId $applicationId -ApplicationVersion $applicationVersion -FilePath $filePath -format "zip"
        $getapp = Get-AzureRmBatchApplicationPackage -ResourceGroupName $context.ResourceGroupName -AccountName $context.AccountName -ApplicationId $applicationId -ApplicationVersion $applicationVersion

        Assert-AreEqual $getapp.Id $addAppPack.Id
        Assert-AreEqual $getapp.Version $addAppPack.Version

        $getPool = Get-AzureBatchPool -Id $poolId -BatchContext $context

        # update pool with application package references
        $apr1 = New-Object Microsoft.Azure.Commands.Batch.Models.PSApplicationPackageReference
        $apr1.ApplicationId = $applicationId
        $apr1.Version = $applicationVersion
        $apr = [Microsoft.Azure.Commands.Batch.Models.PSApplicationPackageReference[]]$apr1

        $getPool.ApplicationPackageReferences = $apr
        $getPool | Set-AzureBatchPool -BatchContext $context

        $getPoolWithAPR = get-AzureBatchPool -Id $poolId -BatchContext $context
        # pool has application package references
        Assert-AreNotEqual $getPoolWithAPR.ApplicationPackageReferences $null
    }
    finally
    {
        Remove-AzureRmBatchApplicationPackage -AccountName $context.AccountName -ApplicationId $applicationId -ResourceGroupName $context.ResourceGroupName -ApplicationVersion $applicationVersion
    }
}
