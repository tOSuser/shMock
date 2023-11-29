#!/bin/bash
#: jenkinsjob test
#:
#: File : jenkinsjob.test.sh
#
#
# Copyright (c) 2023 Nexttop (nexttop.se)
#---------------------------------------
## Import libraries
TESTORIGINALSCRIPT_PATH=$( dirname $(realpath "$0") )
SCRIPT_PATH=$( dirname "$0")
SCRIPT_NAME=jenkinsjob

[ -f $TESTORIGINALSCRIPT_PATH/${SCRIPT_NAME}.sh ] &&
	. $TESTORIGINALSCRIPT_PATH/${SCRIPT_NAME}.sh
[ -f $TESTORIGINALSCRIPT_PATH/${SCRIPT_NAME}.overloader.shinc ] &&
	. $TESTORIGINALSCRIPT_PATH/${SCRIPT_NAME}.overloader.shinc
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
function TEST_JENKINSJOB_REPORTFOUND ()
{
	isFileExist_return="0"
	JenkinsJob -jenkinsjob -patchnumber 11 -patchrevision 12223 -changenumber 734223748 \
		-project testproject -workspace $TESTORIGINALSCRIPT_PATH/testdata
	checkrunnerExitCode=$?

	ExpectCall 'grep' 0
	[ $? -ne 0 ] &&
		return 1
	ExpectCall 'ssh' 0
		[ $? -ne 0 ] &&
			return 1
	ExpectCall 'isFileExist' 1
		[ $? -ne 0 ] &&
			return 1
	ExpectCall 'isDirExist' 0
		[ $? -ne 0 ] &&
			return 1
	[ $checkrunnerExitCode -ne 0 ] &&
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
function TEST_JENKINSJOB_REPORTNOTFOUND ()
{
	isFileExist_return="1"
	JenkinsJob -jenkinsjob -patchnumber 11 -patchrevision 12223 -changenumber 734223748 \
		-project testproject -workspace $TESTORIGINALSCRIPT_PATH/testdata
	checkrunnerExitCode=$?

	ExpectCall 'grep' 0
	[ $? -ne 0 ] &&
		return 1
	ExpectCall 'ssh' 0
		[ $? -ne 0 ] &&
			return 1
	ExpectCall 'isFileExist' 1
		[ $? -ne 0 ] &&
			return 1
	ExpectCall 'isDirExist' 0
		[ $? -ne 0 ] &&
			return 1
	[ $checkrunnerExitCode -eq 0 ] &&
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
TEST_CASES=( 'TEST_JENKINSJOB_REPORTFOUND' \
	'TEST_JENKINSJOB_REPORTNOTFOUND' \
	'TEST_JENKINSJOB' )

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

	unset TESTWORK_TEMPORARYFOLDER
	bash -c "rm -r \"$TESTWORK_DIR\""
done
$(testTeardown)

[ $exitCode -ne 0 ] &&
	exit 1

exit 0
