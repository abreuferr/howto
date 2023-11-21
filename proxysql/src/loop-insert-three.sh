#!/bin/bash
while true; do mysql -u superuser-test -h 192.168.122.23 -P 6033 -e 'INSERT INTO senhasegura.proxysqlTest (proxysqlTest_string) VALUES ("string")' -pcapivarasuicida; sleep 1; done
