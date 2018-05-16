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

# Rule Variables

# This is the Source IP address or subnet.  $SouceIPName is what the name will be.  Usually both values are the
# same, however if your destination is any, you have to use an IP of an asterisk (*) and name it "any".
$LocalIP = "172.25.165.69/32"
$LocalIPName = "Astral"

# This is the Destination IP address or subnet.  $DestinationIPName is what the name will be.  Usually both values are the
# same, however if your destination is any, you have to use an IP of an asterisk (*) and name it "any".
$RemoteIP = "167.89.115.53/32"
$RemoteIPName = "SendGrid"

# Port Number and port name.  Usually both values are the same, however if your Remote is any, you have to use 
# an port of an asterisk (*) and name it "any".
$Port = "587"
$PortName = "SMTP"

# Protocol and protocol name.  Usually both values are the same, however if your Remote is any, you have to use 
# an protocol of an asterisk (*) and name it "any".
$Protocol = "tcp"
$ProtocolName = "tcp"

#Inbound and outbound rule numbers.  Making the numbers the same is encouraged.
$InboundPriority = "1890"
$OutboundPriority = "1890"

#Description used in both rules that will be created.
$Description = "Astral to SendGrid."

# Connect to Subscription
Select-AzureRmSubscription -SubscriptionName $SubscriptionName

# Define NSG using variables provided above
$nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Name $nsgName

# Use this template to add the desired rule(s). This example also shows how you can chain multiple rules
# together.  Re:Sources NSG rule naming standard is:
# <agency identifier>-<access>-<source>-<source port>-<direction>-<protocol>-<destination port>-<destination>
# See example below
Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg `
-Name mox-allow-$RemoteIPName-any-inbound-$ProtocolName-$PortName-$LocalIPName `
-Description "$Description" `
-Access Allow `
-Protocol $Protocol `
-Direction Inbound `
-Priority $InboundPriority `
-SourceAddressPrefix $RemoteIP `
-SourcePortRange * `
-DestinationAddressPrefix $LocalIP `
-DestinationPortRange $Port

Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg `
Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg `
-Name mox-allow-$LocalIPName-any-outbound-$ProtocolName-$PortName-$RemoteIPName `
-Description "$Description" `
-Access Allow `
-Protocol $Protocol `
-Direction Outbound `
-Priority $OutboundPriority `
-SourceAddressPrefix $LocalIP `
-SourcePortRange * `
-DestinationAddressPrefix $RemoteIP `
-DestinationPortRange $Port

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