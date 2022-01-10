#!/usr/bin/env python3

import os
import sys
import base64
import urllib.parse
import urllib.request

def mydns_register_validation(MYDNS_ID, MYDNS_PW, cmd, certbot_domain, certbot_validation):
	url = "https://www.mydns.jp/directedit.html"
	headers = {
		"Content-Type": "application/x-www-form-urlencoded",
		"Authorization": "Basic " + base64.b64encode((MYDNS_ID + ":" + MYDNS_PW).encode()).decode("utf-8")
	}

	data = {
		"EDIT_CMD": cmd,
		"CERTBOT_DOMAIN": certbot_domain,
		"CERTBOT_VALIDATION": certbot_validation
	}
	request = urllib.request.Request(url, headers=headers, data=urllib.parse.urlencode(data).encode(), method="POST")

	try:
		urllib.request.urlopen(request)
	except urllib.error.HTTPError as e:
		print(e.code)
		print(e.read())

def main():
	if len(sys.argv) < 2 or sys.argv[1] not in ("REGIST", "DELETE"):
		raise Exception("No or wrong command is specified, expected: REGIST or DELETE.")
	cmd = sys.argv[1].upper()

	if len(sys.argv) == 4:
		MYDNS_ID = sys.argv[2]
		MYDNS_PW = sys.argv[3]
	elif len(sys.argv) == 2:
		if "MYDNS_ID" not in os.environ or "MYDNS_PW" not in os.environ:
			raise Exception("MyDns credentials (MYDNS_ID and MYDNS_PW) are not set in environment variables!")
		MYDNS_ID = os.environ.get("MYDNS_ID")
		MYDNS_PW = os.environ.get("MYDNS_PW")
	else:
		raise Exception("Insufficient or redundant number of arguments?")

	certbot_domain = os.environ.get("CERTBOT_DOMAIN")
	certbot_validation = os.environ.get("CERTBOT_VALIDATION")
	mydns_register_validation(MYDNS_ID, MYDNS_PW, cmd, certbot_domain, certbot_validation)


if __name__ == "__main__":
	main()
