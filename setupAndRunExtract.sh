#!/bin/bash
set -e
# inspecting the container to find the mounts
docker ps
containerid=`docker ps|grep  k8s_step-build-push-step|awk '{print $1}'`
echo Container ID: ${containerid}
dockerinspect=`docker inspect ${containerid}`
# checking the mounts to extract the workspace mount
notdone=true
found=false
idx=0
while [ "$notdone" = true ]; do
  echo $idx
  dest=`echo ${dockerinspect}|jq --argjson index $idx '.[] | .Mounts[$index].Destination '`
  echo Destination: $dest
  if [ "$dest" = "\"/workspace\"" ] ; then
     source=`echo ${dockerinspect}|jq --argjson index $idx '.[] | .Mounts[$index].Source '`
     found=true
     notdone=false
  elif [ "$dest" == null ]; then
     notdone=false
  fi
  idx=$[$idx+1]
  
done
if [ ! "$found" = true ] ; then
  echo Could not find a workspace mount - something is wrong
  exit 1
else
  echo Source mount is ${source}
# Removing the quotes
  source="${source%\"}"
  source="${source#\"}"
fi
# Appending git-source - assumes this is called with an env var set
  postfix=$gitsource
  source=$source/$postfix
export APPSODY_MOUNT_PROJECT=${source}
echo APPSODY_MOUNT_PROJECT=${APPSODY_MOUNT_PROJECT}
# Create the /extracted sub-dir
mkdir /workspace/extracted
# Run appsody extract -v from the source directory
cd /workspace/$postfix
ls -latr
appsody extract -v
# Copy the extracted contents to /workspace/extracted
cp -rf /builder/home/.appsody/extract/$appname/* /builder/home/.appsody/extract/$appname/.[!.]* /workspace/extracted/
ls -latr /workspace/extracted


echo "Done!"
