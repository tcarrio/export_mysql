### CLEAR OUT AND REFILL DATABASES

### DROP DATABASES
for filename in /dbs/migration/backups/yyyy-mm-dd/*.sql
	do dbname=$(echo $filename | cut -d '.' -f 1 | cut -d '/' -f 6 | grep -v "mysql")
		if [ -n "$dbname" ]; then
			echo "Dropping $dbname..."
			mysql -u root "-pDBPASSWORD" -e "drop database if exists $dbname;"
		fi
	done

### FILL DATABASES 

for filename in /dbs/migration/backups/yyyy-mm-dd/*.sql
	do dbname=$(echo $filename | cut -d '.' -f 1 | cut -d '/' -f 6)
		if [ -n "$filename" ]; then
			if (( $(stat -c%s Database.sql) > 161 )); then
				echo "FILLING DATABASE $dbname"
				mysql -u root "-pDBPASSWORD" -e "create database if not exists $dbname"
				mysql -u root "-pDBPASSWORD" $dbname  < $filename
			fi
		fi
	done