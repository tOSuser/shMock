# shMock - A simple test framework for shell scripts such as bash

## License
license AGPL-3.0 This code and the package of **shMock** are free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License, version 3, as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License, version 3, along with this program. If not, see http://www.gnu.org/licenses/

## A short background
I use to recode times sepent for stories/cards when I work on a project by using time tracker tools.
It helps to analyze jobs and improving ways of workings for next steps and future projects.

During a test automation job to automate E2E tests/ and improving a continuous testing flow I realized
that the time spent to fix shell scripts bugs and issues (in this case, scripts were mostly coded in
bash and groovy) is more than 40% of the total recoded times.

Scripts usually are not so complicated. The main idea of using a script is to package a bunch of commands
that are run together to get a certain output.
In the case of scripts for automation flows such as CI flow, CD or CT flow, most challenges are
values used by scripts (typically output from a command used as arguments for other commands).
Moreover most initial values and parameters are generated by hosts (such as Jenkins, gerrit...) that scripts run under. Accesses and permissions can also make it a little bit more complicated, for example when a script is run by Jenkins that the Jenkins itself is run under Tomcat.

Anyways a WOW optimization was started and the first idea was to use a real test framework for scripts to reduce the number of issues after being implemented in the main flow.

## What shMock is
**shMock** is a practical framework to develop tests for shell scripts such as sh/bash/groovy.
The framework contains several principals and also a set of pre-coded libraries to write and running tests.
**shMock** is developed on a private repository and **its GitHub fork is only updated for major changes and hotfixes**.

# An overview of shMock
If you are familiar with GMock and other standard test frameworks, you have already know how to use **shMock**!
**shMock** is based on a very simple idea to mock and stubbing shell commands and user's functions used within a shell script to have control on a bunch of shell script lines that are planed to work together.
The libraries provided by **shMock** help to automate script development steps, especially CI/DI scripts. Using **shMock** as the test framework helps to develop shell scripts faster and more structured.

# Why test for shell scripts
Both on development processe flows and system automations, specially Linux-based embedded systems, scripts play a big role. Any small changes to the environment/host or the script itself can lead to a failure. Tests help ensure that a script still works as expected after applying changes.

# Quick start

## An overview
Using **shMock** framework itself is not complicated.
A simple test usually coded on a sperated file (but it can also be part of the main file).

A **shMock** test file contains three parts
1. Header - Initializing global variables and importing required files and libraries
2. Tests
3. Test environment initializer and runner


```bash
#!/bin/bash
#: An shMOck test file template
#---------------------------------------
## Initializing global variables and importing libraries
#---------------------------------------
TESTORIGINALSCRIPT_PATH=$( dirname $(realpath "$0") )
SCRIPT_PATH=$( dirname "$0")
SCRIPT_NAME=myscript

. $TESTORIGINALSCRIPT_PATH/test.mock.shinc

#---------------------------------------
## Tests
#---------------------------------------
#@TEST
function TEST_TEMPLATE ()
{
    return 0
}

#---------------------------------------
## Initializing environment and running tests
#---------------------------------------
function testSetup()
{
    return 0
}

function testTeardown()
{
    return 0
}

# Main - run tests
#---------------------------------------
testGroup=""
#testGroup=WORKING
TEST_CASES=( $(grep -P -i -A1 "^#@TEST\s*$testGroup" $0 | grep '^\s*function' | cut -d' ' -f2) )

exitCode=0
$(testSetup)
for testCase in "${TEST_CASES[@]}"
do
    TESTWORK_DIR=$(bash -c "mktemp -d")
    export TESTWORK_TEMPORARYFOLDER=$TESTWORK_DIR

    echo -e "\n$testCase"

    echo "[RUN]"
    exitCode=1
    $testCase
    exitCode=$?
    [ $exitCode -ne 0 ] &&
        echo "[FAILED]" &&
        exitCode=1 &&
        break

    echo "[PASSED]"

    RESETMOCKS
    unset TESTWORK_TEMPORARYFOLDER
    bash -c "rm -r \"$TESTWORK_DIR\""
done
$(testTeardown)

[ $exitCode -ne 0 ] &&
    exit 1

exit 0
```

* The above template can have more or less sections depending on how a script is coded.

## Writing a simple test 
Let's start with a simple script and two simple tests for the scripts. 

The script below, is a simple script that is called by ocserv (a vpn server) when a client is connected or discconnecte.
The script logs client connections to an sqlite db.
It uses several variables that are passed throgh env definations and can be not called from a terminal directlly. It is developed to be called by ocserv.
> * When a client is connected, the script addsa new row to the database with some fields such as `connectid`, `username` passed by ocserv
> * When a client is disconnected, the script looks on `/var/log/syslog` to collect more information about the client and then updated the row created for the connection with additional information such as `totalrx` and `totaltx`

* `ocservlogscript` - The script uses some external applications such as `grep`, `sqlite3` and `mail`. It has no function, starts from the first line and exits with code 0.

```bash
#!/bin/bash

# Script to call when a client connects and obtains an IP.
# The following parameters are passed on the environment.
# REASON, USERNAME, GROUPNAME, HOSTNAME (the hostname selected by client),
# DEVICE, IP_REAL (the real IP of the client), IP_REAL_LOCAL (the local
# interface IP the client connected), IP_LOCAL (the local IP
# in the P-t-P connection), IP_REMOTE (the VPN IP of the client),
# IPV6_LOCAL (the IPv6 local address if there are both IPv4 and IPv6
# assigned), IPV6_REMOTE (the IPv6 remote address), IPV6_PREFIX, and
# ID (a unique numeric ID); REASON may be "connect" or "disconnect".
# In addition the following variables OCSERV_ROUTES (the applied routes for this
# client), OCSERV_NO_ROUTES, OCSERV_DNS (the DNS servers for this client),
# will contain a space separated list of routes or DNS servers. A version
# of these variables with the 4 or 6 suffix will contain only the IPv4 or
# IPv6 values.

# The disconnect script will receive the additional values: STATS_BYTES_IN,
# STATS_BYTES_OUT, STATS_DURATION that contain a 64-bit counter of the bytes
# output from the tun device, and the duration of the session in seconds.

USAGELOGDB_PATH=/opt/ocservlog.db

# email setting
emailSendingFlag=0
adminMail="admin@mailserver"
myHostName=$(hostname)
systemLogfile=/var/log/syslog

if [ $REASON = "disconnect" ]; then
    dtlsline=$(grep -i -e "ocserv\[${ID}\].*DTLS ciphersuite" $systemLogfile)
    dtlsvalue="${dtlsline##* }"

    regexinoutstr="in: [0-9]*.*out: [0-9]*"
    statsline=$(grep --text -i -e "ocserv\[${ID}\].*sent periodic stats.*" "$systemLogfile" | grep -o --text -i -e "$regexinoutstr")
    totalrx=${statsline//*in: /}
    totalrx=${totalrx//, out: */}
    totaltx=${statsline//*, out: /}
fi

[ $REASON = 'connect' ] &&
    sqlite3 $USAGELOGDB_PATH "INSERT INTO usagelog (connectid,username,userip,userlocalip,localip,vpnip,devicename,connectat,status) VALUES (\"$ID\",\"$USERNAME\",\"$IP_REAL\",\"$IP_REMOTE\",\"$IP_LOCAL\",\"$IP_REAL_LOCAL\",\"$DEVICE\",\"$(date +%s)\",1);"

[ $REASON = "disconnect" ] &&
    sqlite3 "$USAGELOGDB_PATH" "UPDATE usagelog SET dtls=\"$dtlsvalue\",rx=\"$totalrx\",tx=\"$totaltx\",status="0",disconnectat=\"$(date +%s)\" WHERE connectid=\"$ID\""

[ "${emailSendingFlag}" = 1 ] &&
    echo "${USERNAME}: ${HOSTNAME}, ${REASON}, ${IP}: ${IP_REAL}, ${IP_LOCAL}: ${IP_REAL_LOCAL}, ${IP_REMOTE}, ${ID}, ${DEVICE}, ${dtlsvalue}, ${totalrx}, ${totaltx}"  | mail -s "$myHostName - ${USERNAME} ${REASON}" "${adminMail}"

exit 0
```

 * `ocservlogscript.test` - We write two tests for the script above, one for connection and one for disconnection. Lets starts with two empty tests


```bash
#!/bin/bash
#: ocservlogscript tests
#---------------------------------------
## Initializing global variables and importing libraries
#---------------------------------------
TESTORIGINALSCRIPT_PATH=$( dirname $(realpath "$0") )
SCRIPT_PATH=$( dirname "$0")
SCRIPT_NAME=ocservlogscript

. $TESTORIGINALSCRIPT_PATH/test.mock.shinc

#---------------------------------------
## Tests
#---------------------------------------
#@TEST
function TEST_OCSERVLOGSCRIPT_CONNECT ()
{
    return 0
}

#@TEST
function TEST_OCSERVLOGSCRIPT_DISCONNECT ()
{
    return 0
}

#---------------------------------------
## Initializing environment and running tests
#---------------------------------------
function testSetup()
{
    return 0
}

function testTeardown()
{
    return 0
}

# Main - run tests
#---------------------------------------
testGroup=""
#testGroup=WORKING
TEST_CASES=( $(grep -P -i -A1 "^#@TEST\s*$testGroup" $0 | grep '^\s*function' | cut -d' ' -f2) )

exitCode=0
$(testSetup)
for testCase in "${TEST_CASES[@]}"
do
    TESTWORK_DIR=$(bash -c "mktemp -d")
    export TESTWORK_TEMPORARYFOLDER=$TESTWORK_DIR

    echo -e "\n$testCase"

    echo "[RUN]"
    exitCode=1
    $testCase
    exitCode=$?
    [ $exitCode -ne 0 ] &&
        echo "[FAILED]" &&
        exitCode=1 &&
        break

    echo "[PASSED]"

    RESETMOCKS
    unset TESTWORK_TEMPORARYFOLDER
    bash -c "rm -r \"$TESTWORK_DIR\""
done
$(testTeardown)

[ $exitCode -ne 0 ] &&
    exit 1

exit 0
```

As the test code above, `ocservlogscript.test` looks for `test.mock.shinc` (shMOck library).
It means to run tests it needs to find a copy of `test.mock.shinc` alongside the test file. 
If `test.mock.shinc` is stored somewhere else, `ocservlogscript.test` should be updated with the correct path for `test.mock.shinc`

Now the test above can be run. The both empty tests `TEST_OCSERVLOGSCRIPT_CONNECT` and `TEST_OCSERVLOGSCRIPT_DISCONNECT` are passed (they are testsing nothing for now).

* `TEST_OCSERVLOGSCRIPT_CONNECT` (The first edition) - The test below mocks 3 command used by `ocservlogscript` and then initialize environment variables to simulate a `connect` call. 
> * The command `ADDMOCK grep` takes controll over `grep` calls and logs them (number of calls, passed argumants and outpts). Using `ADDMOCK grep` without extra parameters does not chagne the functionality of `gerp`. It works as a stub, logs the call and then run the original command at the end.
> * `ExpectCalls grep:0 sqlite3:1 mail:0` checks number of calls for `grep`, `sqlite3` and `mail` For example in the case of a `connect` we expect only 1 `sqlite3` call.
 
```bash
function TEST_OCSERVLOGSCRIPT_CONNECT ()
{
    ADDMOCK grep
    ADDMOCK sqlite3
    ADDMOCK mail

    REASON=connect
    ID='id'
    USERNAME='USERNAME'
    IP_REAL='IP_REAL'
    IP_REMOTE='IP_REMOTE'
    IP_LOCAL='IP_LOCAL'
    IP_REAL_LOCAL='IP_REAL_LOCAL'
    DEVICE='DEVICE'    
    ./ocservlogscript
    exitCode=$?
    [ $exitCode -ne 0 ] &&
        return 1

    ExpectCalls grep:0 sqlite3:1 mail:0
    [ $? -ne 0 ] &&
        return 1

    return 0

}
```

* `TEST_OCSERVLOGSCRIPT_CONNECT` (The second edition) - As explained for the test above using `ADDMOCK sqlite3` without addtional parameters create a stub. It means **shMock** logs `sqlite3` calls but the original command will be also run. In the other words the test above tries to write to a sqlite db which is not a good idea for a test case.
> * To avoid running orginal commands it needs define return codes and outputs for mocked commands.
> * `ADDMOCK sqlite3 $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})` defines return codes and outputs for `sqlite3`.
> * The first argumant after `ADDMOCK sqlite3` refers to return codes (`$(mockCreateParamList {0,})`). It means **shMock** will set the return code to 0 for all `sqlite3`
> * The second argumant after `ADDMOCK sqlite3` refers to outputs (`$$(mockCreateParamList {'-',})`). It means **shMock** will print nothing for all `sqlite3`

```bash
function TEST_OCSERVLOGSCRIPT_CONNECT ()
{
    ADDMOCK grep
    ADDMOCK sqlite3 $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    ADDMOCK mail

    REASON=connect
    ID='id'
    USERNAME='USERNAME'
    IP_REAL='IP_REAL'
    IP_REMOTE='IP_REMOTE'
    IP_LOCAL='IP_LOCAL'
    IP_REAL_LOCAL='IP_REAL_LOCAL'
    DEVICE='DEVICE'    
    ./ocservlogscript
    exitCode=$?
    [ $exitCode -ne 0 ] &&
        return 1

    ExpectCalls grep:0 sqlite3:1 mail:0
    [ $? -ne 0 ] &&
        return 1

    return 0

}
```

### Some real case examples
https://github.com/tOSuser/whMan/blob/main/whmanager/tests/whman.block.test.sh
https://github.com/tOSuser/whMan/blob/main/whmanager/tests/whman.unit.test.sh

## Jenkinsjob - A very simple example
This example shows how to test a script that is developed to use with in a groovy script.
The groovy script used by this example is only one line that calls a bash script and it is not considered by this example.

* `jenkinsjob.sh` - The main script
* `jenkinsjobshelper.shinc` - provide some helper functions used by `jenkinsjob.sh`
* `jenkinsjob.test.sh` - `jenkinsjob.sh` tests

need-to-be-updated
