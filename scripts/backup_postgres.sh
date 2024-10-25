#!/usr/bin/env bash

time=$(date +"%Y%m%d-%H%M%S")

# set information
user="postgres"
backup="/root/backup_postgres/backup_${time}.dump"
log="/root/backup_postgres/backup_${time}.log"

# create database dump
pg_dumpall -U "$user" --verbose > "$backup" 2> "$log"
if [ $? -eq 0 ]; then
    echo "backup SUCCESS"
else
    echo "backup FAILED"
fi
