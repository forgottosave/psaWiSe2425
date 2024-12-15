#!/usr/bin/env bash

time=$(date +"%Y%m%d")

# set information
host="localhost"
user="ronlyusr"
backup="/root/backup_postgres/backup_${time}.dump"
log="/root/backup_postgres/backup_${time}.log"

# create database dump
pg_dumpall -h "$host" -U "$user" --verbose > "$backup" 2> "$log"
if [ $? -eq 0 ]; then
    echo "backup SUCCESS"
else
    echo "backup FAILED"
fi
