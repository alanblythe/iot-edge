#!/bin/sh

openssl x509 -in $1 -fingerprint -noout | cut -d= -f2 | sed -e 's/://g'