# Log in to Azure.  This is only needed if you're using local powershell. This is not needed if you're
# simply pasting this script into the Azure Portal Cloud Shell console, which is recommended.
# Login-AzureRmAccount

#Define Variables. surround with quotes even if there are no spaces.
$SubscriptionName = "<Name of the Subscription>"
$ResourceGroup = "<Resource Group that the NSG is in>"
$nsgName = "<Applicable NSG assigned to appropriate network tier>"

# This is the Source IP address or subnet.  $SouceIPName is what the name will be.  Usually both values are the
# same, however if your destination is any, you have to use an IP of an asterisk (*) and name it "any".  The IP 
# can also be a range, or a subnet.  i.e. 172.25.165.10-172.25.165.15 or 172.25.165.0/24.  For multiple comma 
# separated IPs, you will have to add those via the portal web interface after the rule has been created.
$LocalIP = "<Source IP>/32"
$LocalIPName = "<Friendly Name for above IP>"

# This is the Destination IP address or subnet.  $DestinationIPName is what the name will be.  Usually both values are the
# same, however if your destination is any, you have to use an IP of an asterisk (*) and name it "any".
$RemoteIP = "<Destination IP>/32"
$RemoteIPName = "<Friendly Name for above IP>"

# Port Number and port name.  Usually both values are the same, however if your Remote is any, you have to use
# a port of an asterisk (*) and name it "any".
# Additional File Sharing Port: 445
$Port = "<Applicable Port Number>"
$PortName = "<Applicable port name, i.e. SSH, SFTP, RDP, LDAP, etc. If multiple ports, a meaningful name i.e. MAIL or FileShare>"

# Protocol and protocol name.  Usually both values are the same, however if your Remote is any, you have to use
# an protocol of an asterisk (*) and name it "any".
$Protocol = "<tcp> <udp> or <*>"
$ProtocolName = "<tcp> <udp> or <any>"

#Inbound and outbound rule numbers.  Making the numbers the same is encouraged. This rule MUST be a higher
#priority than the default Re:Sources rule that blocks all Virtual Network traffic.  i.e. the rules that 
#are named like deny-virtualnetwork-any-inbound-tcp-all-virtualnetwork.  Typically these rules are numbers
#4047-4050.
$InboundPriority = "<Inbound Priority/Rule Number>"
$OutboundPriority = "<Outbound Priority/Rule Number>"

#Description used in both rules that will be created.
$Description = "<Text discription of the rule.>"

#########################################################################################################
#
# DO NOT EDIT ANTYHING BELOW - ALL VARIABLES HAVE BEEN DEFINED
#
#########################################################################################################

# Connect to Subscription
Select-AzureRmSubscription -SubscriptionName $SubscriptionName

#Define NSG
$nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Name $nsgName

# Use this template to add the desired rule(s). This example also shows how you can chain multiple rules together.
# NSG rule naming standard is:
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

# Apply the Rule
Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $nsg
