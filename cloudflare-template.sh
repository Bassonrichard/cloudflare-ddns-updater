#!/bin/bash
## change to "bin/sh" when necessary

auth_email=""                                                               # The email used to login 'https://dash.cloudflare.com'
auth_method="global"                                                        # Set to "global" for Global API Key or "token" for Scoped API Token
auth_key=""                                                                 # Your API Token or Global API Key
zone_identifier=""                                                          # Can be found in the "Overview" tab of your domain
record_name=""                                                              # Which record you want to be synced
ttl="3600"                                                                  # Set the DNS TTL (seconds)
proxy="false"                                                               # Set the proxy to true or false

###########################################
## Set variables
###########################################

if [[ $auth_email == "" ]]; then
  # Set auth email to env variable if you set in script
  auth_email=$AUTH_EMAIL

  echo "Config: Set auth_email."
fi

if [[ $auth_key == "" ]]; then
  # Set auth key to env variable if you set in script
  auth_key=$AUTH_KEY

  echo "Config: Set auth_key."
fi

if [[ $zone_identifier == "" ]]; then
  # Set zone_identifier to env variable if you set in script
  zone_identifier=$ZONE_IDENTIFIER

  echo "Config: Set zone_identifier."
fi


if [[ $record_name == "" ]]; then
  # Set record name to env variable if you set in script
  record_name=$RECORD_NAME

  echo "Config: Set record_name."
fi

###########################################
## Check if we have a public IP
###########################################
ipv4_regex='([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])'
ip=$(curl -s -4 https://cloudflare.com/cdn-cgi/trace | grep -E '^ip'); ret=$?
if [[ ! $ret == 0 ]]; then # In the case that cloudflare failed to return an ip.
    # Attempt to get the ip from other websites.
    ip=$(curl -s https://api.ipify.org || curl -s https://ipv4.icanhazip.com)
else
    # Extract just the ip from the ip line from cloudflare.
    ip=$(echo $ip | sed -E "s/^ip=($ipv4_regex)$/\1/")
fi

# Use regex to check for proper IPv4 format.
if [[ ! $ip =~ ^$ipv4_regex$ ]]; then
    echo "DDNS Updater: Failed to find a valid IP."
    exit 2
fi

###########################################
## Check and set the proper auth header
###########################################
if [[ "${auth_method}" == "global" ]]; then
  auth_header="X-Auth-Key:"
else
  auth_header="Authorization: Bearer"
fi

###########################################
## Seek for the A record
###########################################

echo "DDNS Updater: Check Initiated"
record=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?type=A&name=$record_name" \
                      -H "X-Auth-Email: $auth_email" \
                      -H "$auth_header $auth_key" \
                      -H "Content-Type: application/json")

###########################################
## Check if the domain has an A record
###########################################
if [[ $record == *"\"count\":0"* ]]; then
  echo "DDNS Updater: Record does not exist, perhaps create one first? (${ip} for ${record_name})"
  exit 1
fi

###########################################
## Get existing IP
###########################################
old_ip=$(echo "$record" | sed -E 's/.*"content":"(([0-9]{1,3}\.){3}[0-9]{1,3})".*/\1/')
# Compare if they're the same
if [[ $ip == $old_ip ]]; then
  echo "DDNS Updater: IP ($ip) for ${record_name} has not changed."
  exit 0
fi

###########################################
## Set the record identifier from result
###########################################
record_identifier=$(echo "$record" | sed -E 's/.*"id":"(\w+)".*/\1/')

###########################################
## Change the IP@Cloudflare using the API
###########################################
update=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
                     -H "X-Auth-Email: $auth_email" \
                     -H "$auth_header $auth_key" \
                     -H "Content-Type: application/json" \
                     --data "{\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$ip\",\"ttl\":\"$ttl\",\"proxied\":${proxy}}")
