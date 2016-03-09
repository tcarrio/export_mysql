# mysqldump-cli
Argument-driven bash script to perform fallback SQL dumps of all MySQL databases

# about
I began working on this script due to a failing SunOS 5 server, a system that is well over a decade old at this point. 

The program is written to run on Unix-based systems with Bash. It requires MySQL be installed on the local system with both the `mysql` and `mysqldump` commands available. If they are not in the PATH, the script allows a directory to be specified to use as the executable origin. The script takes a username and password for accessing the specified MySQL server and will generate a SQL dump of every database in the server, resolving to SQL dumps of every table if a database were to fail. 

It also supports complete logging of stdout to a file or verbose output, otherwise the process will run silent until complete. 

# compatibility
The script should be fully functional on the following systems:
* Solaris / SunOS
* GNU/Linux
* *BSD

# arguments
````
-h show brief help
-v show verbose output
-l specify a file to store log output
-u specify the user to access mysql
-p specify the password to access mysql
-e specify the path to mysql tools directory
-o specify the output directory (default: pwd)
````

# requirements
mysql (tested v4.0.16+)
* mysql
* mysqldump
bash (tested v2.03.0+)

# future functionality
My hopes are to implement a few conveniences for the system. My greatest hope would be to allow remote backup output. This could be done using a `user@host:/path/to/dir` syntax on the `-o` argument and automatically assume an SSH protocol for connection. 
