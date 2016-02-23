#**********************************************************************************
#* Name: 	backup_sqldump.sh                                                     *
#* Author: 	Tom Carrio                                                            *
#* Function:    modular callscript for export_mysql tool                          *
#* Last Modif.:	02/23/2016                                                        *
#**********************************************************************************

#/bin/bash

DB_SCRIPTS="/dbs/migrate"
PROG_NAME="export_mysql.sh"
PROG_CALL="export_mysql"
LOGS="$DB_SCRIPTS/log"
BIN_EXPORT_MYSQL="/usr/bin/export_mysql"
DATE_STAMP=`date +"%Y-%m-%d"`
BACK_DIR="/dbs/backups/2016"
MIG_SRV="127.0.0.1" #filler
RSA_KEY="/.ssh/4096_bit_rsa"


if [ ! -f `which export_mysql` ]; then
	if [ -f $BIN_EXPORT_MYSQL ]; then
		if [ ! -x $BIN_EXPORT_MYSQL ]; then
			chmod +x $BIN_EXPORT_MYSQL
			PROG_CALL=$BIN_EXPORT_MYSQL
		fi
	else
		if [ ! -f $DB_SCRIPTS/$PROG_CALL ]; then
			ln -s $DB_SCRIPTS/$PROG_NAME $DB_SCRIPTS/$PROG_CALL
		fi
		chmod +x $DB_SCRIPTS/$PROG_CALL
		PROG_CALL=$DB_SCRIPTS/$PROG_CALL
	fi
fi

if [ ! -d $LOGS ]; then
	mkdir -p $LOGS
	mkdir -p $DB_SCRIPTS/backups
fi

# run export script
$PROG_CALL -l $LOGS/$DATE_STAMP_dump.log 

TARBALL=$BACK_DIR/$DATE_STAMP/backup.tar

tar cf - $BACK_DIR/$DATE_STAMP/* | ssh -i $RSA_KEY `whoami`@$MIG_SRV "dd of=$TARBALL; tar xf $TARBALL"

if [ -f $DB_SCRIPTS/$PROG_CALL ]; then
	rm $DB_SCRIPTS/$PROG_CALL
fi