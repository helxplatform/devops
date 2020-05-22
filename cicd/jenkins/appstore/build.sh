set -ex

echo "Branch: $BRANCH_NAME"
echo "Git commit: $GIT_COMMIT"
echo "Change ID: $CHANGE_ID"
echo "Change author: $CHANGE_AUTHOR"
echo "Change author display name: $CHANGE_AUTHOR_DISPLAY_NAME"
echo "Change author email: $CHANGE_AUTHOR_EMAIL"
echo "Build number: $BUILD_NUMBER"
echo "Build ID: $BUILD_ID"
echo "Job name: $JOB_NAME"
echo "Build tag: $BUILD_TAG"
echo "Node name: $NODE_NAME"
echo "Node labels: $NODE_LABELS"
echo "Workspace: $WORKSPACE"
echo "Jenkins URL: $JENKINS_URL"


WS="/var/lib/jenkins/jobs/appstore/jobs/appstore/workspace"
GITDIR="appstore"
APPDIR="appstore"
CLONE_HOME="$WS/$GITDIR"
APP_HOME="$CLONE_HOME/$APPDIR"

AJA_DIR="/var/lib/jenkins/jobs/appstore/jobs/appstore"
VERSION_FILE="$AJA_DIR/version/metadata/ver"

BUILD_BRANCH="metadata"
APPSTORE_URL="https://github.com/helxplatform/appstore.git"
TYCHO_URL="https://github.com/helxplatform/tycho.git"


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Version file functions: get_ver, incr_ver
#   --> TODO: Place these on the server as a separate script called 
#             version.sh so they can be used by separate builds from one 
#             place once I get sudo access. Update code to source them 
#             and use appropriately.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


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



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Initial version file setup: remove after 1 iteration!!!!
#   --> Needed because no sudo access.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#echo "CREATING VERSION FILE"
#mkdir "$AJA_DIR/version"
#mkdir "$AJA_DIR/version/metadata"
#cat <<EOF >$VERSION_FILE
#v0.0.7
#EOF
#echo "VERSION FILE CREATED"



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Clean the workspace:
#   --> Jenkins is leaving git artifacts causing build failure
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ls -ld $CLONE_HOME
if [ $? -eq 0 ]
then
  # Directory exists, remove it so git clone will work . . .
  echo "Removing existing appstore directory for git clone."
  rm -rf $CLONE_HOME
fi


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Set up the code:
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Clone the repo
git clone $APPSTORE_URL
sleep 10


# Checkout target branch
cd appstore
git checkout $BUILD_BRANCH


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Build the image:
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# We're building, so increment and get updated version
ov=`get_ver`
echo "OLD VERSION: $ov"
incr_ver
ver=`get_ver`
echo "NEW VERSION: $ver"

# Build the docker container.
cd appstore
docker build --no-cache -t heliumdatastage/appstore:metadata-$ver \
               -t heliumdatastage/appstore:metadata-latest .

if [ $? -ne 0 ]
then
  echo "Build failed, skipping tests and not pushing to Dockerhub." >&2
  exit 2
fi


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Execute unit tests:
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# virtualenv cmd didn't work so using this form . . .
/usr/bin/python3 -m venv venv && \
source venv/bin/activate && \
pip install -r requirements.txt --upgrade pip && \
if [ ! -d $APP_HOME/tycho ]; then git clone --branch $BUILD_BRANCH $TYCHO_URL ; fi && \
pip install -r ./tycho/requirements.txt && \
bin/appstore tests braini

if [ $? -ne 0 ]
then
  echo "Unit tests failed, not pushing to DockerHub." >&2
  exit 3
fi


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Push to DockerHub:
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
docker push heliumdatastage/appstore:metadata-$ver
docker push heliumdatastage/appstore:metadata-latest
