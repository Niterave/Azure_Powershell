# Network Security Group (NSG) Rule(s) Add/Edit template
# Taken from https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-nsg-arm-ps
# Composed by Matt Richardson | Manager of Cloud Services | Moxie | matt.richardson@moxieusa.com
# 
# Pre-requisites: An understanding of NSG Inbound/Outbound rules and how they work:
# https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-nsg
#
# As with all of my scripts, I try to write them so all the user of the script needs to do is fill in the
# variables and then run the script with no further edits needed.  Unfortunately in this case, each rule
# must be individually defined, so simply filling in the variables isn't enough.

# Log in to Azure.  This is only needed if you're using local powershell. This is not needed if you're
# simply pasting this script into the Azure Portal Cloud Shell console, which is recommended.
Login-AzureRmAccount

#Define Variables. Variables must be surrounded with quotes.
$SubscriptionName = "Subscription Name Here"
$ResourceGroup = "Resource Group Name Here"
$nsgName = "NSG Name Here"

# Connect to Subscription
Select-AzureRmSubscription -SubscriptionName $SubscriptionName

# Define NSG using variables provided above
$nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Name $nsgName

# Use this template to add the desired rule(s). This example also shows how you can chain multiple rules
# together.  Re:Sources NSG rule naming standard is:
# <agency identifier>-<access>-<source>-<source port>-<direction>-<protocol>-<destination port>-<destination>
# See example below
Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg `
-Name mox-allow-209.208.245.115-any-inbound-any-22-172.25.164.5 `
-Description "Allow Moxie SFTP inbound to Server A" `
-Access Allow `
-Protocol Tcp `
-Direction Inbound `
-Priority 3360 `
-SourceAddressPrefix 209.208.245.115/32 ` # This can also be an * for 'any'
-SourcePortRange * ` 
-DestinationAddressPrefix 172.25.164.5/32 ` # This can also be an * for 'any'
-DestinationPortRange 22

Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg `
-Name mox-allow-209.208.245.115-any-inbound-any-22-172.25.164.4 `
-Description "Allow Moxie SFTP inbound to Server B" `
-Access Allow `
-Protocol Tcp `
-Direction Inbound `
-Priority 3370 `
-SourceAddressPrefix 209.208.245.115/32 `
-SourcePortRange * `
-DestinationAddressPrefix 172.25.164.4/32 `
-DestinationPortRange 22

#Use this template to edit an existing rule.  Very handy since you can't edit some fields in the portal.
#Set-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg `
#-Name mox-allow-172.25.164.4-any-outbound-any-22-209.208.245.115 `
#-Description "Allow SFTP outbound" `
#-Access Allow `
#-Protocol Tcp `
#-Direction Outbound `
#-Priority 3370 `
#-SourceAddressPrefix 172.25.164.4/32 `
#-SourcePortRange * `
#-DestinationAddressPrefix 209.208.245.115 `
#-DestinationPortRange 22

# Apply the Rule
Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $nsg