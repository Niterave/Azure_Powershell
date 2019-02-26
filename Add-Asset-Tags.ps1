<#PSScriptInfo 
 
.VERSION 1.0 
 
.AUTHOR Matt Richardson, Cloud Solutions Architect, matt.richardson@moxieusa.com 
 
.COMPANYNAME Moxie
 
.TAGS Azure, Tag, Management, Azure-Tag-Management
 
.STASHURL https://stash.moxieinteractive.com/projects/MOXHOST/repos/azure.scripts/
 
.RELEASENOTES 
  December 18, 2018 
  Intial Release - You will receive the following error if there is more than one asset with the same name in your
  subscription:
  "Cannot convert 'System.Object[]' to the type 'System.Collections.Hashtable' required by parameter 'Tag'.
  I do not plan on doing error checking/correcting for this script as it is a rare occurrence.
#>

<# 
.SYNOPSIS 
  Add a Tag to Azure assets based on an existing tag. 
  
  Use of "-Force" provides the ability to launch this script without prompting, if all required parameters are provided. 
  User of "-Verbose" provides feedback to the user and useful information if troubleshooting a failed tag assignment.
   
.DESCRIPTION 
  This script takes input from a user for Tag Name and Tag Value, searches on those parameters, and returns a list of 
  assets meeting the criteria.  It then prompts the user for a new Tag Name and Tag Value to ADD to the asset.
 
.PARAMETER TagName
    Default value of the existing Tag Name you would like to add a new Tag and Value to. 
  
.PARAMETER TagNameInput
    Tag name user inputs to override the default value of 'JobCode'

.PARAMETER NewTagName
    Default value of the new Tag Name you would like to add a new Tag and Value to. 

.PARAMETER NewTagNameInput
    Tag name user inputs to override the default value of 'InvoiceCategory'

.PARAMETER TagValue
    Specify the value of the existing Tag you would like to add a new Tag and Value to.

.PARAMETER NewTagValue
    New Tag value the user would like to add to the Azure asset
     
.PARAMETER SubscriptionId 
    The subscriptionID of the Azure Subscription that contains the resources you want to update/configure 
 
.PARAMETER Assets 
    The list of assets returned that match the Tag Name and Tag Value entered by the user for the Subscription they
    connected to. Since this value is used in multiple Functions, it is denoted as $script.Assets meaning it is available
    outside of the function for other functions to use.
     
.PARAMETER TryAgain
    User input to retry the 'GetTagVariables' Function
      
.PARAMETER ConfirmAssets
    User input to confirm the displayed Assets list is accurate and they would like to proceed with adding the new tags

.PARAMETER BeginAgain
    User input to start the operation over for additional tagging

.PARAMETER Force 
    Use Force to run silently [providing all parameters needed for silent mode - see get-help <scriptfile> -examples] 
 
.PARAMETER 
    Use DisableLogsMetrics to remove logs and metrics for a resource 
 
 Azure authentication function and subscription selection section originally written by jbritt@microsoft.com:
 https://www.powershellgallery.com/packages/Enable-AzureRMDiagnosticsEventHubs/1.0/Content/Enable-AzureRMDiagnosticsEventHubs.ps1

 #>

###############
#             #
#  FUNCTIONS  #
#             #
###############

#This function adds an index number to the array the command pulls for the Subscription login.
#Written by jbritt@microsoft.com
function Add-IndexNumberToArray (
    [Parameter(Mandatory=$True)]
    [array]$array
    )
{
    for($i=0; $i -lt $array.Count; $i++) 
    { 
        Add-Member -InputObject $array[$i] -Name "#" -Value ($i+1) -MemberType NoteProperty 
    }
    $array
}

#This function gathers the varilables needed to find the Azure assets you'd like to change the Tag on.
#Written by Matt Richardson
Function GetTagVariables 
    {

    #Set Default Value for TagName and TryAgain
    $script:TagName = "JobCode"
    $TryAgain = "Y"

    #Get Tag Name and Tag Value input from user for *existing* tag they'd like to search on.
    if (($script:TagNameInput = Read-Host -Prompt "What Tag NAME would you like to search for? (Press Enter for default $script:TagName)") -eq '') {$script:TagName} else {$script:TagName = $script:TagNameInput}
    $script:TagValue = Read-Host -Prompt "What Tag VALUE would you like to search for?"
    
    #Clear variable
    $script:Assets = $null
    
    #Get list of Assets that meet the user criteria entered above
    $script:Assets = Get-AzureRmResource -Tag @{ "$script:TagName"="$script:TagValue"}

    #Check for empty/no results.  If empty, give user option to start over.
    if ($script:Assets -eq $Null) 
       {
       Write-Warning -Message "No results were found for the Tag $script:TagName with a value of $script:TagValue."
       if (($TryAgainInput = Read-Host -Prompt "Would you like to try again? (Press Enter for default $TryAgain)") -eq '') {$TryAgain} else {$TryAgain = $TryAgainInput}
       
       if ($TryAgain -ne "Y")
        {
        exit
        }
       elseif ($TryAgain -eq "Y")
        {
        GetTagVariables
        }
       }

    #If there are results, give user feedback (and time to read the message), then display the list of found assets
    elseif ($script:Assets -ne $Null)
       {
       Write-Host "Please wait while I search for the assets with a tag of $script:TagName with a value of $script:TagValue." -ForegroundColor Cyan
       Start-Sleep -seconds 2
       echo $script:Assets | ft
       }
    }

#This function adds the new Tag and New Tag Value to the filtered Azure assets.
#Written by Matt Richardson
Function ChangeAssets 
{
  #Set Default Value for Tag Name input
  $NewTagName = "InvoiceCategory"
   
  #Prompt user for Tag Name and Tag Value input.
  if (($NewTagNameInput = Read-Host -Prompt "Please enter new Tag Name. (Press enter for default $NewTagName)") -eq '') {$NewTagName} else {$NewTagName = $NewTagNameInput}
  $NewTagValue = Read-Host -Prompt "Please enter new Tag Value i.e. client-billable or client-nb"
  
  #Assign Tag Name and Tag Value to discovered assets. 
  Foreach ($Asset in $script:Assets)
   {
   $Tag = Get-AzureRmResource -Name $Asset.Name -ResourceGroupName $Asset.ResourceGroupName
   $Tag.Tags.Add("$NewTagName", "$NewTagValue")
   Set-AzureRMResource -Tag $Tag.Tags -ResourceId $Asset.ResourceId -Force -EV AssetErr -EA Continue -Verbose
   }

   #Error checking.  Report success or error with error output.  So far while I'm using this, the errors just display on the 
   #screen.
   if ($AssetErr -eq $null)
    {
   Write-Host "All assets processed." -Verbose
    }

   elseif ($AssetErr -ne $null)
    {
    Write-Host "There was an error processing your request.  $AssetErr" -Verbose
    }
 }

###############
#             #
#   Script    #
#             #
###############
#This section pulls all Existing Subscriptions and allows you to choose one to log into if you haven't already.
#Written by jbritt@microsoft.com
Write-Host "Authenticating to Azure..." -ForegroundColor Cyan
try
{
    $AzureLogin = Get-AzureRmSubscription
}
catch
{
    $null = Login-AzureRmAccount
    $AzureLogin = Get-AzureRmSubscription
}

# Authenticate to Azure if not already authenticated 
# Ensure this is the subscription where your Azure Resources are you want to Tag
If($AzureLogin -and !($SubscriptionID))
{
    [array]$SubscriptionArray = Add-IndexNumberToArray (Get-AzureRmSubscription) 
    [int]$SelectedSub = 0

    # use the current subscription if there is only one subscription available
    if ($SubscriptionArray.Count -eq 1) 
    {
        $SelectedSub = 1
    }
    
    # Get SubscriptionID if one isn't provided
    while($SelectedSub -gt $SubscriptionArray.Count -or $SelectedSub -lt 1)
    {
        Write-host "Please select a subscription from the list below"
        $SubscriptionArray | select "#", Id, Name | ft
        try
        {
            $SelectedSub = Read-Host "Please enter a selection from 1 to $($SubscriptionArray.count)"
        }
        catch
        {
            Write-Warning -Message 'Invalid option, please try again.'
        }
    }
    if($($SubscriptionArray[$SelectedSub - 1].Name))
    {
        $SubscriptionName = $($SubscriptionArray[$SelectedSub - 1].Name)
    }
    elseif($($SubscriptionArray[$SelectedSub - 1].SubscriptionName))
    {
        $SubscriptionName = $($SubscriptionArray[$SelectedSub - 1].SubscriptionName)
    }
    write-verbose "You Selected Azure Subscription: $SubscriptionName"
    
    if($($SubscriptionArray[$SelectedSub - 1].SubscriptionID))
    {
        [guid]$SubscriptionID = $($SubscriptionArray[$SelectedSub - 1].SubscriptionID)
    }
    if($($SubscriptionArray[$SelectedSub - 1].ID))
    {
        [guid]$SubscriptionID = $($SubscriptionArray[$SelectedSub - 1].ID)
    }
}
Write-Host "Selecting Azure Subscription: $($SubscriptionID.Guid) ..." -ForegroundColor Cyan
$Null = Select-AzureRmSubscription -SubscriptionId $SubscriptionID.Guid

#This section chains the functions together to get the work done and gives the user the option to proceed, cancel, or start over.
#Written by Matt Richardson
do {
   GetTagVariables
   $ConfirmAssets = Read-Host -Prompt "Would you like to proceed with the Tag change? (Y/N) (Press Enter for default N)"
   
  If ($ConfirmAssets -ne "Y") 
   {
   Write-Host "Bye!" 
   exit
   }

elseif ($ConfirmAssets -eq "Y")
   { ChangeAssets }
   
   $BeginAgain = Read-Host "Would you like to search for another Tag and Value? (Y,N) (Press Enter for default Y)"
   }
while ($BeginAgain -ne "N")

Write-Host "Bye!"