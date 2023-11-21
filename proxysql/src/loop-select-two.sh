#!/bin/bash
while true; do mysql -u superuser-test -h 192.168.122.22 -P 6033 -e 'SELECT @@hostname' -pcapivarasuicida; sleep 1; done
