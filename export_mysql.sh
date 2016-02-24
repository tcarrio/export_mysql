#**********************************************************************************
#* Name: 	export_mysql.sh                                                         *
#* Author: 	Tom Carrio                                                            *
#* Function:    export mysql database data to a flatfile                          *
#* Last Modif.:	02/23/2016                                                        *
#**********************************************************************************

#/bin/bash

set +e # turn off errexit

SCRIPT="export_mysql"

while [ $# -gt 0 ]; do
  case "$1" in
      -h|--help)
        printf "%-s - %-s\n\n" $SCRIPT "export SQL dump of all databases and tables"
        printf "%-s [options]\n\n" $SCRIPT
        printf "%-s\n" "options:"
        printf "%-10s %-30s\n" "-h" "show brief help"
        printf "%-10s %-30s\n" "-v" "show verbose output"
        printf "%-10s %-30s\n" "-l" "specify a file to store log in"
        printf "%-10s %-30s\n" "-u" "specify the user to access mysql"
        printf "%-10s %-30s\n" "-p" "specify the password to access mysql"
        printf "%-10s %-30s\n" "-e" "specify the path to mysqldump"
        printf "%-10s %-30s\n" "-o" "specify the output directory"
        printf "\n%10s %-30s\n" "" "log will override verbose if both flagged"
        exit 0
        ;;
      -v)
        VERBOSE="Y"
        shift
        ;;
      -l)
        shift
        if [ -n "$1" ]; then
          LOGGER=$1
          VERBOSE=""
        fi
        shift
        ;;
      -u)
        shift
        if [ -n "$1" ]; then 
          UN=$1
        else
          printf "%s\n" "No username was specified"
          exit 1
        fi
        shift
        ;;
      -p)
        shift
        if [ -n "$1" ]; then
          PW=$1
        fi
        shift
        ;;
    	-e)
    		shift
    		if [ -n "$1" ]; then 
    			MYSQLDUMP=$1
    		else
    			printf "%s" "No executable was specified"
    			exit 1
    		fi
    		shift
    		;;
      -o)
        shift
        if [ -n "$1" ]; then
          BACK_DIR=$1
        fi
        shift
        ;;
      
      *)
        break
        ;;
  esac
done

if [ -z "`which mysqldump`" ] && [ -z $MYSQLDUMP ]; then
  printf "mysqldump was not found in PATH. Please specify "
fi

if [ -z "$UN" ]; then
  UN="root" #filler
fi

if [ -z "$PW" ]; then
  PW="" #filler
fi

if [ -z "$BACK_DIR" ]; then
  BACK_DIR="/dbs/backups/2016"
fi

if [ -z "$MYSQLDUMP" ]; then
  if [ -f "/usr/local/mysql/bin/mysqldump" ]; then
     MYSQLDUMP="/usr/local/mysql/bin/mysqldump"
  else
    MYSQLDUMP="`which mysqldump`"
    if [ -z $MYSQLDUMP ]; then
      printf "mysqldump was not found in PATH or at a given location."
      exit 1
    fi
  fi
fi

if [ ! -d  $BACK_DIR ]; then
  mkdir -p $BACK_DIR
fi

if [ ! -f  $MYSQLDUMP ]; then
  MYSQLDUMP=`which mysqldump`
fi

if [ -z "$VERBOSE" ]; then
  exec 3>&1 4>&2
  trap 'exec 2>&4 1>&3' 0 1 2 3

  if [ -n "$LOGGER" ]; then
    exec 1>$LOGGER 2>&1
    
  else
    exec 1>/dev/null 2>&1
  fi
fi

TIME_STAMP="`date +"%T"` "
DATE_STAMP="`date +"%Y-%m-%d"`"
DIR="/dbs/migrate"
SHOW_DBS=$DIR/sql_tools/show_dbs.sql
SHOW_TABLES=$DIR/sql_tools/show_tables.sql

### Start of sqldump execution

printf "Started at %s on %s\n" $TIME_STAMP $DATE_STAMP
mysql --user=$UN --password=$PW < $SHOW_DBS | sed '1d' | while read DB_NAME
do
  if [ ! -d $BACK_DIR/$DATE_STAMP ]; then
    mkdir -p $BACK_DIR/$DATE_STAMP
  fi
  if $MYSQLDUMP --user=$UN --password=$PW $DB_NAME > $BACK_DIR/$DATE_STAMP/$DB_NAME.sql; then
    printf "%sSuccessfully dumped database %s\n" $TIME_STAMP $DB_NAME
  	continue
  else
  	printf "%sError occurred during database %s.\n" $TIME_STAMP $DB_NAME
    printf "%sAttempting dump of child tables\n" $TIME_STAMP
    mysql --user=$UN --password=$PW $DB_NAME < $SHOW_TABLES | sed '1d' | while read TABLE
    do
      if $MYSQLDUMP --user=$UN --password=$PW $DB_NAME $TABLE > $BACK_DIR/$DATE_STAMP/$DB_NAME.$TABLE.sql; then
        continue
      else
        if [ -z "$TABLE" ]; then
          printf "%sError occured in table %s.\n" $TIME_STAMP $TABLE
        fi
      fi
    done
  fi
done
