#**********************************************************************************
#* Name: 	export_mysql.sh                                                         *
#* Author: 	Tom Carrio                                                            *
#* Function:    export mysql database data to a flatfile                          *
#* Last Modif.:	02/22/2016                                                        *
#**********************************************************************************

set +e # turn off errexit

SCRIPT="export_mysql"
UN="USERNAME"
PW="PASSWORD"
BACK_DIR="/dbservices/backup_data/2016_migration"
MYSQLDUMP="/usr/local/mysql/bin/mysqldump"
VERBOSE=""
LOGGER=""

while test $# -gt 0; do
        case "$1" in
                -h|--help)
                        printf "%s - %s\n\n" $SCRIPT "export SQL dump of all databases and tables"
                        printf "%s [options]\n\n" $SCRIPT
                        printf "%s" "options:\n"
                        printf "%25s %25s" "-h, --help" "show brief help"                        
                        printf "%25s %25s" "-v, --verbose" "show verbose output"
                        printf "%25s %25s" "-l, --log=FILE" "specify a file to store log in"
                        printf "%25s %25s" "-u, --user=NAME" "specify the user to access mysql"
                        printf "%25s %25s" "-p, --password=PASSWORD" "specify the password to access mysql"
                        printf "%25s %25s" "-e, --execute=PROGRAM" "specify the path to mysqldump"
                        exit 0
                        ;;
                -v|--verbose)
                        VERBOSE="2>&1"
                        shift
                        ;;
                --action*)
                        PROCESS=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -u)
                        shift
                        if test $# -gt 0; then
                                UN=$1
                        else
                                echo "No username was specified"
                                exit 1
                        fi
                        shift
                        ;;
                --user*)
						UN=`echo $1 | sed -e 's/^[^=]*=//g'`
						shift
						;;
				-p)
                        shift
                        if test $# -gt 0; then
                                PW=$1
                        else
                                printf "%s" "Please enter the password: "
                                stty -echo
                                read PW
                                stty echo
                                printf "\n"
                                if [[ -z $PW ]]; then
									echo "No password was entered"
									exit 1
								fi
                        fi
                        shift
                        ;;
                --password*)
						PW=`echo $1 | sed -e 's/^[^=]*=//g'`
						if [[ -z $PW ]]; then
							echo "No password was entered"
							exit 1
						fi
						shift
						;;
				-e)
						shift
						if test $# -gt 0; then
							MYSQLDUMP=$1
						else
							echo "No executable was specified"
							exit 1
						fi
						shift
						;;
				--execute*)
						MYSQLDUMP=`echo $1 | sed -e 's/^[^=]*=//g'`
						if [[ -z $MYSQLDUMP ]]; then
							echo "No executable was specified"
							exit 1
						fi
						shift
						;;
                --output-dir*)
                        OUTPUT=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                *)
                        break
                        ;;
        esac
done

if [ ! -d  $BACK_DIR ]; then
	mkdir -p $BACK_DIR
fi

if [ ! -f  $MYSQLDUMP ]; then
	MYSQLDUMP=`which mysql`
fi

mysql --user=$UN --password=$PW < /dbservices/migration/show_dbs.sql | sed '1d' | while read DB_NAME
do
	if $MYSQLDUMP --user=$UN --password=$PW $DB_NAME > $BACK_DIR/$DB_NAME.sql; then
		mysql --user=$UN --password=$PW $DB_NAME < /dbservices/migration/show_tables.sql | sed '1d' | while read TABLE
		do
			$MYSQLDUMP --user=$UN --password=$PW $DB_NAME $TABLE > $BACK_DIR/$DB_NAME.$TABLE.sql
		done
	else
		printf "Error occurred during database %s. " $DB_NAME
		if [[ -z "$TABLE" ]]; then
			printf "Last table in use was %s." $TABLE
		fi
		printf "\n" 
		continue
	fi
done
