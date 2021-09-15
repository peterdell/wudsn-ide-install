#!/bin/bash
#
#

#
#
#
error(){
  echo ERROR: See messages above.
  exit /b 1
}

#
#
#
download(){
  FILE=$1
  URL=$2
  FOLDER=$3
  TARGET_FOLDER=$4
  TARGET=$TARGET_FOLDER/$FOLDER
  MODE=$5

  if [ ! -f $FILE ]; then
    echo Downloading $FILE from $URL.
    curl -L $URL --output $FILE
  else
    echo File $FILE is present.
  fi

  if [ -d $TARGET ]; then
    echo Removing target folder $TARGET.
    rm -rf $TARGET
  fi
  mkdir -p $TARGET_FOLDER

  if [[ $FILE == *.zip ]] || [[ $FILE == *.tar.gz ]]; then
    echo Unpacking $FILE to $TARGET_FOLDER.
    tar -xf $FILE -C $TARGET_FOLDER
  fi
}

#
#
#
download_repo(){
  REPO=$1
  BRANCH=main
  REPO_BRANCH=$REPO-$BRANCH
  REPO_FILE=$REPO_BRANCH.zip
  REPO_URL=https://github.com/peterdell/$REPO/archive/refs/heads/$BRANCH.zip
  REPO_TARGET_FOLDER=$2
  echo Download repo $REPO to $REPO_TARGET_FOLDER.
  download $REPO_FILE $REPO_URL $REPO_BRANCH $INSTALL_FOLDER IGNORE

  echo Copying files to $REPO_TARGET_FOLDER.
  if [ ! -d $REPO_TARGET_FOLDER ]; then
    mkdir -p $REPO_TARGET_FOLDER
  fi
  cp -p -R $REPO_BRANCH/* $REPO_TARGET_FOLDER
  rm -rf $REPO_BRANCH
}

#set -v
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
WUDSN_FOLDER=$SCRIPT_DIR
INSTALL_FOLDER=$WUDSN_FOLDER/Install
TOOLS_FOLDER=$WUDSN_FOLDER/Tools
WORKSPACE_FOLDER=$WUDSN_FOLDER/Workspace
TOOLS_FILE=wudsn-ide-tools-main.zip
TOOLS_URL=https://github.com/peterdell/wudsn-ide-tools/archive/refs/heads/main.zip
DOWNLOADS_URL=https://www.wudsn.com/productions/java/ide/downloads

ECLIPSE_FILE=eclipse-platform-4.20-macosx-cocoa-x86_64.dmg
ECLIPSE_URL=$DOWNLOADS_URL/$ECLIPSE_FILE
ECLIPSE_FOLDER=$WUDSN_FOLDER/Tools/IDE/Eclipse
ECLIPSE_MOUNT_FOLDER=/Volumes/Eclipse
ECLIPSE_RUNTIME_FOLDER=$ECLIPSE_FOLDER/eclipse
ECLIPSE_APP_NAME=Eclipse.app
ECLIPSE_APP_FOLDER=$ECLIPSE_RUNTIME_FOLDER/$ECLIPSE_APP_NAME

JRE_FILE=openjdk-16.0.2_osx-x64_bin.tar.gz
JRE_URL=$DOWNLOADS_URL/$JRE_FILE
JRE_FOLDER_NAME=jdk-16.0.2.jdk
JRE_JVM_FOLDER=/Library/Java/JavaVirtualMachines
JRE_TARGET_FOLDER=$JRE_JVM_FOLDER/$JRE_FOLDER_NAME

echo Press RETURN to install WUDSN IDE in $WUDSN_FOLDER
read

mkdir -p $INSTALL_FOLDER
pushd $INSTALL_FOLDER
download_repo wudsn-ide-tools $TOOLS_FOLDER
download $ECLIPSE_FILE $ECLIPSE_URL eclipse $ECLIPSE_FOLDER FAIL
hdiutil mount $ECLIPSE_FILE -quiet
rsync -az $ECLIPSE_MOUNT_FOLDER/$ECLIPSE_APP_NAME $ECLIPSE_RUNTIME_FOLDER
hdiutil detach $ECLIPSE_MOUNT_FOLDER -force -quiet

# Check for JDK
if [ ! -d $JRE_TARGET_FOLDER ]; then
  download $JRE_FILE $JRE_URL $JRE_FOLDER_NAME $INSTALL_FOLDER FAIL
  echo Enter your password to install Java version $JRE_FOLDER_NAME in $JRE_TARGET_FOLDER.
  sudo mv $JRE_FOLDER_NAME $JRE_JVM_FOLDER
else
  echo Java version $JRE_FOLDER_NAME is already installed in $JRE_TARGET_FOLDER.
fi

echo Installing WUDSN IDE feature.
# See http://help.eclipse.org/latest/index.jsp?topic=/org.eclipse.platform.doc.isv/guide/p2_director.html
#$ECLIPSE_RUNTIME_FOLDER/eclipsec.exe -nosplash -application org.eclipse.equinox.p2.director -repository https://www.wudsn.com/update -installIU com.wudsn.ide.feature.feature.group -destination $ECLIPSE_RUNTIME_FOLDER
download_repo wudsn-ide-workspace $WORKSPACE_FOLDER

echo Installing WUDSN defaults for workspace $WORKSPACE_FOLDER.
SETTINGS_FOLDER=$ECLIPSE_APP_FOLDER/Contents/Eclipse/configuration/.settings
PREFS=$SETTINGS_FOLDER/org.eclipse.ui.ide.prefs
if [ ! -d $SETTINGS_FOLDER ]; then
  mkdir -p $SETTINGS_FOLDER
fi

RECENT_WORKSPACES=$WORKSPACE_FOLDER
echo MAX_RECENT_WORKSPACES=10>$PREFS
echo RECENT_WORKSPACES=$RECENT_WORKSPACES>>$PREFS
echo RECENT_WORKSPACES_PROTOCOL=3>>$PREFS
echo SHOW_RECENT_WORKSPACES=false>>$PREFS
echo SHOW_WORKSPACE_SELECTION_DIALOG=false>>$PREFS
echo eclipse.preferences.version=1>>$PREFS

popd
echo Starting WUDSN IDE.
open $ECLIPSE_APP_FOLDER

