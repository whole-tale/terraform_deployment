#!/bin/python
import argparse
import json
import requests

#
# Simple CLI to create/update DNS A record in GoDaddy
#

parser = argparse.ArgumentParser()

parser.add_argument("-k", "--key", required=True, help="Godaddy API key")
parser.add_argument("-s", "--secret", required=True, help="Godaddy API secret")
parser.add_argument("-d", "--domain", required=True, help="Domain name")
parser.add_argument("-a", "--address", required=True, help="DNS A record ip address value")

args = parser.parse_args()

domain = args.domain

# Use the domain argument to determine the wildcard address
if domain == 'wholetale.org':
    wildcard = "*"
else:
    wildcard = "*.%s" % (domain.replace(".wholetale.org", ""))

domain = "wholetale.org"

# Uses the records and A record enpoints
baseUrl = "https://api.godaddy.com/v1"
recordsUrl = "%s/domains/%s/records" % (baseUrl, domain)
recordUrl = "%s/A/%s" % (recordsUrl, wildcard)

# Authentication requires GoDaddy API key and secret
authHeader = "sso-key %s:%s" % (args.key, args.secret)

# DNS A record
wildcard_record = [{
    'data': args.address,
    'name': wildcard,
    'ttl': 600,
    'type': 'A'
}]

try:

    # Get the record for this name
    r = requests.get(recordUrl, headers={'Authorization': authHeader})

    # Endpoint should return 200 whether record exists or not
    if r.status_code == requests.codes.ok:

        body = r.json()

        if not body:
            #  If body is empty, no existing A record exists so created it using the PATCH method
            print("No record found for %s, creating" % wildcard)

            r = requests.patch(recordsUrl, json=wildcard_record, headers={'Authorization': authHeader, 'accept': 'application/json'})
            if r.status_code == requests.codes.ok:
                print("Record successfully created")
            else:
                print("Error: Failed to create record: %s" % r.status_code)

        else:
            #  If body is not empty, confirm that it differs from the specified information and update if needed
            if body == wildcard_record:
                print("Record found, but configuration unchanged")
            else:
                print("Record found for %s, updating" % wildcard)
                r = requests.put(recordUrl, json=wildcard_record, headers={'Authorization': authHeader, 'accept': 'application/json'})

                if r.status_code == requests.codes.ok:
                    print("Record successfully updated")
                else:
                    print("Error: Failed to create: %s" % r.status_code)

        # Get the final record and con  firm it matches what was supplied
        r = requests.get(recordUrl, headers={'Authorization': authHeader})

        print(json.dumps(r.json(), indent=4, sort_keys=True))

    else:
        r.raise_for_status()

except requests.exceptions.RequestException as e:
    print(e)
