# -------------------------------------------------------------------------
# scan-clair
# Security scans Docker images. Meant to be called from containerized Jenkins
# Pre-requisites:
#    - A clair server and clair db are running on the same Docker network
#    - clair-scanner exists on Jenkins server at specified location
# Parameters:
# $1 - Organization or name of the DockerHub repo to scan
# $2 - DockerHub repo to scan
# $3 - Branch part of version tag of repo to scan, if any
#        or "" if none
# $4 - Version number including "v" if any of repo to be
#        scanned.
# Example call: scan-clair "heliumdatastage" "appstore" "develop" "v0.0.13"
# Result: 
#    - Outputs clean table of security scan information in $CLAIR_HM/clean_tableoutput.txt
#    - Displays clean output table in Jenkins build log.
# -------------------------------------------------------------------------

function scan_clair () {
   ORG="$1"
   REPO="$2"
   BRANCH="$3"
   VERSION="$4"
   CLAIR_PROG="/usr/bin/clair-scanner"
   CLAIR_HM="/var/jenkins_home/clair"

   if [ $BRANCH ] then
      OUTPUT_DIR=$CLAIR_HM/$REPO-$VERSION
      IMAGE="$ORG/$REPO:$VERSION"
   else
      OUTPUT_DIR=$CLAIR_HM/$REPO-$BRANCH-$VERSION
      IMAGE="$ORG/$REPO:$BRANCH-$VERSION"
   fi

   CLAIR_IP=$(docker network inspect bridge --format='{{(index .IPAM.Config 0).Gateway}}')
   echo "Clair IP = $CLAIR_IP"
   ETH0_IP=$(ip -4 addr show eth0 | grep 'inet' | cut -d' ' -f6 | cut -d'/' -f1)
   echo "ETHO IP = $ETH0_IP"

   echo "Running clair on $REPO . . ."
   echo "OUTPUT_DIR=[$OUTPUT_DIR]"
   echo "IMAGE=[$IMAGE]"   
   docker pull $IMAGE
   mkdir $OUTPUT_DIR
   $CLAIR_PROG --clair=http://$CLAIR_IP:6060 --ip=$ETH0_IP -t 'High' -r "$OUTPUT_DIR/clair_report.json" $IMAGE | tee $OUTPUT_DIR/tableoutput.txt
   sed -r "s/\x1B\[(([0-9]+)(;[0-9]+)*)?[m,K,H,f,J]//g" $OUTPUT_DIR/tableoutput.txt > $OUTPUT_DIR/clean_tableoutput.txt
}

# NOTE: Use of these functions requires the creation of a global var
# in the calling script called VERSION_FILE, which is the path to a 
# file containing a version number of the form vn.n.n or optionally 
# vn.n.nn, where n is a number from 0-9.

# -----------------------------------------------------------------------
# get_ver
#
# Description: Retrieves the current version number for a build.
#
# Inputs: $VERSION_FILE: A file that: 
#           Contains a single version number in one of these formats:
#           n
#           n.n
#           n.n.nn, where n is an integer from 0-9
#
# Outputs: ver, a one to three place version number 
#
# Returns: 0 on success
#          255 when $VERSION_FILE file is not found
#
# Notes: $VERSION_FILE requires a newline.
# -----------------------------------------------------------------------
function get_ver () {
    if [ ! -f "$VERSION_FILE" ]
    then
        echo "Version file $VERSION_FILE does not exist."
        echo "Skipping build."
        echo "Please check for or re-create it."
        return 255
    fi

    ver=$(< $VERSION_FILE)
    echo "$ver"
    return 0
}


# -----------------------------------------------------------------------
# incr_ver
#
# Description: Increments a version number for a build.
#
# Inputs: $VERSION_FILE: A file that:
#           Contains a single version number in one of these formats:
#           n
#           n.n
#           n.n.nn, where n is an integer from 0-9
#
# Outputs: newver, an incremented version number that rolls over when 
#             it reaches its max value for the number of digit places 
#             available.
#          Updated $VERSION_FILE  with the new version number
#
# Returns: 0 on success
#          255 when $VERSION_FILE is not found
#
# Notes: $VERSION_FILE requires a newline since this script uses awk.
# -----------------------------------------------------------------------
function incr_ver () {
    SUBMINOR_OVERFLOW=99
    MINOR_OVERFLOW=9

    oldver=$(get_ver)
    rc=$?
    case $rc in
        0) ;;
        255) echo "Version file not found."; exit $rc;;
        *) echo "Unknown error";;
    esac 
    echo "Old version: [$oldver]."
    read -r major minor subminor <<< $(echo $oldver | awk -F. '{print $1, $2, $3}')

    newsubminor=''
    if [ -n "${subminor}" ] && [ $subminor -lt $SUBMINOR_OVERFLOW ]
    then
        # increment normally
        newsubminor=$(($subminor + 1))
    else
        # we overflowed
        newsubminor=0
    fi

    newminor="$minor"
    if [ -n "${minor}" ]
    then
        if [ -z "${subminor}" ] ||
           [ -n "${subminor}" ] && [ $newsubminor -eq 0 ]
        then
            if [ $minor -lt $MINOR_OVERFLOW ]
            then
                # increment normally
                newminor=$(($minor + 1))
            else
                # we overflowed
                newminor=0
            fi
        fi
    fi

    newmajor="$major"
    if [ -z "${minor}" ] || [ $newminor -eq 0 -a ! $minor -eq 0 ]
    then
         newmajor=$(($major + 1))        
    fi

    newver="$newmajor"
    if [ -n "${minor}" ]; then newver=$newver".$newminor"; fi
    if [ -n "${subminor}" ]; then newver=$newver".$newsubminor"; fi

    echo "New version: [$newver]."
    echo "$newver"
    echo "$newver" > $VERSION_FILE
    return 0
}
