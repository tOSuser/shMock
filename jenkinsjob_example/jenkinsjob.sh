#!/bin/bash
#: jenkinsjob to use within Jenkins Pipline
#:
#: File : jenkinsjob.sh
#
#
# Copyright (c) 2022 Nexttop (nexttop.se)
#---------------------------------------
#
# Environment variables passd by Gerrit trigger:
#   GERRIT_EVENT_TYPE
#   GERRIT_EVENT_HASH
#   GERRIT_CHANGE_WIP_STATE
#   GERRIT_CHANGE_PRIVATE_STATE
#   GERRIT_BRANCH
#   GERRIT_TOPIC
#   GERRIT_CHANGE_NUMBER
#   GERRIT_CHANGE_ID
#   GERRIT_PATCHSET_NUMBER
#   GERRIT_PATCHSET_REVISION
#   GERRIT_REFSPEC
#   GERRIT_PROJECT
#   GERRIT_CHANGE_SUBJECT
#   GERRIT_CHANGE_COMMIT_MESSAGE
#   GERRIT_CHANGE_URL (link)
#   GERRIT_CHANGE_OWNER
#   GERRIT_CHANGE_OWNER_NAME
#   GERRIT_CHANGE_OWNER_EMAIL
#   GERRIT_PATCHSET_UPLOADER
#   GERRIT_PATCHSET_UPLOADER_NAME
#   GERRIT_PATCHSET_UPLOADER_EMAIL
#   GERRIT_NAME
#   GERRIT_HOST
#   GERRIT_PORT
#   GERRIT_SCHEME
#   GERRIT_VERSION
#
# Environment variables passd by Jenkins:
#   JENKINS_URL
#   PWD
#   WORKSPACE
#   RUN_DISPLAY_URL
#   RUN_CHANGES_DISPLAY_URL
#   RUN_TESTS_DISPLAY_URL
#   NODE_NAME
#   JOB_BASE_NAME
#   JOB_URL
#   BUILD_ID
#   BUILD_NUMBER
#   BUILD_URL
#
# Local variables:
#
#---------------------------------------
ORIGINALSCRIPT_PATH=$( dirname $(realpath "$0") )
SCRIPT_PATH=$( dirname "$0")

TEMPEXTRACTION_DIR=''
TEMPEXTRACTION_FULLPATH=$TEMPEXTRACTION_DIR
TESTRESULTREPORT_FILE='testsresultreport'
failstopmode=1
generalFailure=0

## Import libraries
[ -f $ORIGINALSCRIPT_PATH/jenkinsjobshelper.shinc ] &&
    . $ORIGINALSCRIPT_PATH/jenkinsjobshelper.shinc

function JenkinsJob () #@ USAGE JenkinsJob param1 param2 ...
{
    ## Initialize values
    nextitem=$(lookForArgument "-verbose" "$@")
    verbosemode=$?
    nextitem=$(lookForArgument "-keep" "$@")
    keeptempfiles=$?
    nextitem=$(lookForArgument "-jenkinsjob" "$@")
    jenkinsjobmode=$?
    nextitem=$(lookForArgument "-rawmode" "$@")
    rawmode=$?
    nextitem=$(lookForArgument "-debug" "$@")
    debugmode=$?
    nextitem=$(lookForArgument "-info" "$@")
    infomode=$?
    nextitem=$(lookForArgument "-failstop" "$@")
    failstopmode=$?
    nextitem=$(lookForArgument "-color" "$@")
    colormode=$?
    if [ $jenkinsjobmode -eq 0 ] || [ $rawmode -eq 0 ]; then
        colormode=1
    fi

    patchsetNumber=$GERRIT_PATCHSET_NUMBER
    nextitem=$(lookForArgument "-patchnumber" "$@")
    manualPatchNumberMode=$?
    [ $manualPatchNumberMode -eq 0 ] &&
        patchsetNumber=$nextitem

    patchsetRevision=$GERRIT_PATCHSET_REVISION
    nextitem=$(lookForArgument "-patchrevision" "$@")
    manualPatchRevisionMode=$?
    [ $manualPatchRevisionMode -eq 0 ] &&
        patchsetRevision=$nextitem

    patchsetChangeNumber=$GERRIT_CHANGE_NUMBER
    nextitem=$(lookForArgument "-changenumber" "$@")
    manualChangeNumberMode=$?
    [ $manualChangeNumberMode -eq 0 ] &&
        patchsetChangeNumber=$nextitem

    projectName=$GERRIT_PROJECT
    nextitem=$(lookForArgument "-project" "$@")
    manualProjectMode=$?
    [ $manualProjectMode -eq 0 ] &&
        projectName=$nextitem

    workspacePath=$WORKSPACE
    nextitem=$(lookForArgument "-workspace" "$@")
    manualWorkspaceMode=$?
    [ $manualWorkspaceMode -eq 0 ] &&
        workspacePath=$nextitem

    currentHome=$HOME
    nextitem=$(lookForArgument "-home" "$@")
    manualHomeMode=$?
    [ $manualHomeMode -eq 0 ] &&
        currentHome=$nextitem

    #---------------------------------------
    # Add your job codes here
    #---------------------------------------
    # An example just to can run tests
    isFileExist $TESTRESULTREPORT_FILE
    if [ $? -ne 0 ]; then
        echo -e "WARRNING: No report was created."
        return 1
    fi
    #---------------------------------------

    return 0
}

#---------------------------------------
# Main
nextitem=$(lookForArgument "--main" "$@")
[ $? -eq 0 ] &&
    JenkinsJob "$@" &&
    exit $?