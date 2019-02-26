# Network Security Group (NSG) Rule(s) Add/Edit template
# Taken from https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-nsg-arm-ps
# Composed by Matt Richardson | Cloud Solutions Architect | Moxie | matt.richardson@moxieusa.com
# 
# Pre-requisites: An understanding of NSG Inbound/Outbound rules and how they work:
# https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-nsg
#
# As with all of my scripts, I try to write them so all the user of the script needs to do is fill in the
# variables and then run the script with no further edits needed.  Unfortunately in this case, each rule
# must be individually defined, so simply filling in the variables isn't enough.
