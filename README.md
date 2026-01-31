# Cloudflare DNS Update
Script for updating DNS Records in a Cloudflare Zone
Based on the config file, a record is selected an updated based on the content of the config file.

If the -ipcheck param is set, $NewIP will be set as the public IP of the host.

I created this script for updating an A Record after the regular public IP change of  a local site I maintain, because DDNS was not available. 

## Use
Install-Module -Name Send-MailKitMessage for mail notification

Clone the repository, rename the sample-config.json into config.json and fill in the information.
Reference for the used Cloudflare API: [LINK](https://developers.cloudflare.com/api/resources/dns/subresources/records/)
