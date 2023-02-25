#!/bin/bash

source_code_dir=/var/www
backup_dir=/root/backup
file_names=`ls $source_code_dir`
date=`date -I`

echo "--- START BACKING UP SOURCE CODE ---"
for entry in $file_names
do
	echo "Compressing $source_code_dir/$entry.tar.gz"
	echo "......"
	tar -zcf $backup_dir/sources/$entry-$date.tar.gz $source_code_dir/$entry
done

echo "--- FINISHED BACKUP SOURCE CODE ---"

DB_USER=""
DB_PASS=""
DB_HOST="127.0.0.1"
db_names=`mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -e 'show databases;'`
echo "--- START BACKING UP DATABASES ---"
for db in $db_names
do
	result=$(mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -s -N -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='$db'")

	if
	[ -z "$result" ] ||
	[ $result == "performance_schema" ] ||
	[ $result == "mysql" ] ||
	[ $result == "information_schema" ];
	then
		echo 'Ignoring'
	else
		echo 'Backing up database: ' $result
		mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASS $db | gzip > $backup_dir/databases/$db-$date.sql.gz
	fi
done

echo "--- FINISHED BACKUP DATABASES ---"

echo "--- DELETE OLD FILES ---"
find $backup_dir -maxdepth 2 -type f -mtime +3 -exec rm -vf {} \;

echo "-- FINISHED DELETE OLD FILES ---"