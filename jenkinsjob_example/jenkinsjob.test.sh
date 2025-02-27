#!/bin/bash
#: jenkinsjob test
#:
#: File : jenkinsjob.test.sh
#
#
# Nexttop 2023-2025 (nexttop.se)
# Maintenance nexttop -> hossein a.t. (osxx.com)
#---------------------------------------
## Import libraries
TESTORIGINALSCRIPT_PATH=$( dirname $(realpath "$0") )
SCRIPT_PATH=$( dirname "$0")
SCRIPT_NAME=jenkinsjob

[ -f $TESTORIGINALSCRIPT_PATH/${SCRIPT_NAME}.sh ] &&
	. $TESTORIGINALSCRIPT_PATH/${SCRIPT_NAME}.sh

[ -f $TESTORIGINALSCRIPT_PATH/${SCRIPT_NAME}.stubs.shinc ] &&
	. $TESTORIGINALSCRIPT_PATH/${SCRIPT_NAME}.stubs.shinc
testExpects="test.expect.shinc"
[ -f $TESTORIGINALSCRIPT_PATH/$testExpects ] &&
	. $TESTORIGINALSCRIPT_PATH/$testExpects

#*
#*  @description    Test setup
#*
#*  @param
#*
#*  @return			0 SUCCESS, > 0 FAILURE
#*
function testSetup()
{
	return 0
}

#*
#*  @description    Test teardown
#*
#*  @param
#*
#*  @return			0 SUCCESS, > 0 FAILURE
#*
function testTeardown()
{
	return 0
}

#*
#*  @description    Test jenkinsjob
#*  	Test jenkinsjob when :
#*  		- The report file is found
#*
#*  @param
#*
#*  @return			0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_JENKINSJOB_REPORTFOUND ()
{
    ADDMOCK grep
    ADDMOCK ssh
	ADDMOCK isFileExist $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
	ADDMOCK isDirExist $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})

	output=$(JenkinsJob -jenkinsjob -patchnumber 11 -patchrevision 12223 -changenumber 734223748 \
		-project testproject -workspace $TESTORIGINALSCRIPT_PATH/testdata)
    JenkinsJobExitCode=$?
    [ $JenkinsJobExitCode -ne 0 ] &&
        echo -e "---\n$output\n---\n" &&
        return 1

    ExpectCalls grep:0 ssh:0 isFileExist:1 isDirExist:0
    [ $? -ne 0 ] &&
        return 1

	return 0
}

#*
#*  @description    Test jenkinsjob
#*  	Test jenkinsjob when :
#*  		- The report file is not found
#*
#*  @param
#*
#*  @return			0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_JENKINSJOB_REPORTNOTFOUND ()
{
    ADDMOCK grep
    ADDMOCK ssh
	ADDMOCK isFileExist $(mockCreateParamList {1,}) $(mockCreateParamList {'-',})
	ADDMOCK isDirExist $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})

	isFileExist_return="1"
	output=$(JenkinsJob -jenkinsjob -patchnumber 11 -patchrevision 12223 -changenumber 734223748 \
		-project testproject -workspace $TESTORIGINALSCRIPT_PATH/testdata)
    [ $JenkinsJobExitCode -ne 0 ] &&
        echo -e "---\n$output\n---\n" &&
        return 1

    ExpectCalls grep:0 ssh:0 isFileExist:1 isDirExist:0
    [ $? -ne 0 ] &&
        return 1

	return 0
}

#*
#*  @description    Test jenkinsjob
#*
#*  @param
#*
#*  @return			0 SUCCESS, > 0 FAILURE
#*
function TEST_JENKINSJOB ()
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
