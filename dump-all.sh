#**********************************************************************************
#* Name: 	export_mysql.sh                                                         *
#* Author: 	Tom Carrio                                                            *
#* Function:    export mysql database data to a flatfile                          *
#* Last Modif.:	02/23/2016                                                        *
#**********************************************************************************

#/bin/bash

set +e # turn off errexit

SCRIPT="export_mysql"
DATE_STAMP="`date +"%Y-%m-%d"`"
DIR="/dbservices/migration"
DBS="Show databases;"
TABLES="Show tables;"

while [ $# -gt 0 ]; do
  case "$1" in
      -h|--help)
        printf "%-s - %-s\n\n" $SCRIPT "export SQL dump of all databases and tables"
        printf "%-s [options]\n\n" $SCRIPT
        printf "%-s\n" "options:"
        printf "%-10s %-30s\n" "-h" "show brief help"
        printf "%-10s %-30s\n" "-v" "show verbose output"
        printf "%-10s %-30s\n" "-l" "specify a file to store log output"
        printf "%-10s %-30s\n" "-u" "specify the user to access mysql"
        printf "%-10s %-30s\n" "-p" "specify the password to access mysql"
        printf "%-10s %-30s\n" "-e" "specify the path to mysql tools directory"
        printf "%-10s %-30s\n" "-o" "specify the output directory (default: pwd)"
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
    			MYSQLDIR=$1
    		else
    			printf "%s\n" "No executable was specified"
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
        printf "%s is not a valid option\n" "$1"
        exit 1
        ;;
  esac
done

if [ -z "$UN" ]; then
  UN="root"
fi

if [ -z "$PW" ]; then
  PW="password"
fi

if [ -z "$BACK_DIR" ]; then
  BACK_DIR="`pwd`/mysql_backup"
fi

if [ -n "$MYSQLDIR" ]; then
  MYSQLBIN=$MYSQLDIR/mysql
  MYSQLDUMP=$MYSQLDIR/mysqldump
  if [ ! -f $MYSQLBIN ] || [ ! -f $MYSQLDUMP ]; then
    printf "mysqldump was not found in PATH. Please specify"
    exit 1
  fi
else
  if [ "`which mysql | cut -d ' ' -f 1 `" = "no" ] || \
     [ "`which mysqldump | cut -d ' ' -f 1 `" = "no" ]; then
    printf "mysql tools were not found in PATH"
    exit 1
  else
    MYSQLBIN=`which mysql`
    MYSQLDUMP=`which mysqldump`
  fi
fi

if [ ! -d  $BACK_DIR ]; then
  mkdir -p $BACK_DIR
fi

if [ -z "$VERBOSE" ]; then
  exec 3>&1 4>&2
  trap 'exec 2>&4 1>&3' 0 1 2 3

  if [ -n "$LOGGER" ]; then
    if [ -f $LOGGER ]; then
      rm $LOGGER
    fi
    exec 1>$LOGGER 2>&1
    
  else
    exec 1>/dev/null 2>&1
  fi
fi

printf "Started at %s on %s\n" "`date +"%T"`" $DATE_STAMP
$MYSQLBIN --user=$UN --password=$PW -e "$DBS" -B -N | while read DB_NAME
do
  if [ ! -d $BACK_DIR ]; then
    mkdir -p $BACK_DIR
  fi
  if $MYSQLDUMP --user=$UN --password=$PW $DB_NAME > $BACK_DIR/$DB_NAME.sql; then
    printf "%s Successfully dumped database %s\n" "`date +"%T"`" $DB_NAME
    printf "%s Attempting table dump from database %s\n" "`date +"%T"`" $DB_NAME
    $MYSQLBIN --user=$UN --password=$PW $DB_NAME -e "$TABLES" -B -N | while read TABLE
    do
      TABLE_OUT=$BACK_DIR/$DB_NAME-Tables
      if [ ! -d $TABLE_OUT ]; then
        mkdir -p $TABLE_OUT
      fi
      if $MYSQLDUMP --user=$UN --password=$PW $DB_NAME $TABLE > $TABLE_OUT/$TABLE.sql; then
        continue
      else
        if [ -n "$TABLE" ]; then
          printf "%s Error occured in table %s.\n" "`date +"%T"`" $TABLE
        fi
      fi
    done
  fi
done
