#!/bin/bash

# Preparation of the folder
mkdir -p /bacula/mysql-backup
chown -R bacula:bacula /bacula
chmod -R 666 /bacula

# Backup
mysqldump -u root -pAAaa00--==  --all-databases > /bacula/mysql-backup/dump$(date +%Y-%m-%d_%H:%M).sql

chown -R bacula:bacula /bacula
chmod -R 666 /bacula
