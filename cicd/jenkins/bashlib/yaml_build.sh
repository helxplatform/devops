set -ex

# CONSTANTS
PREBUILD=0
BUILD=1
UNIT_TEST=2

# --- GET_TAGS ---
# parameters:
#   - $1 branch - branch being built
#   - $2 ver - version of app being built
# returns:
#   - echoes tag for docker build and push cmds appropriate for branch/cluster
#       - for master branch, version only, ex: 1.0.0
#       - for other branches, branch-v<version>, ex: develop-v0.0.1
#
function get_tags ()
{
   local branch=$1
   local ver=$2

   if [ $branch == "master" ]; then
      tags="$ver:latest"
   else
      tags="$branch-$ver:$branch-latest"
   fi
   echo $tags
}

# --- CHECK_PREREQS ---
function check_prereqs ()
{
   local -r ver_major=4
   local -r ver_minor=3

   echo "check_prereqs"
   bash_ver=$(bash --version | head -1 | cut -d ' ' -f4)
   arr_bash_ver=(${bash_ver//./ })

   if [ ${arr_bash_ver[0]} -le $ver_major -a \
        ${arr_bash_ver[1]} -le $ver_minor ]; then
      echo "Insufficient bash version for build: [$bash_ver]"
      exit 1
   else
      echo "Bash version is $bash_ver. Everything is cool."
   fi
}


# --- INIT_BUILD ---
function init_build ()
{
   echo "Initializing build . . ."

   local -r req_prebuild=$1
   local -r req_build=$2
   local -r req_test=$3
   local -n func_arr=${4}

   echo "init_build: $req_prebuild $req_build $req_test ${func_arr[@]}"
   echo "Setting up functions array . . ."
   request_arr=($req_prebuild $req_build $req_test)
   for index in {0..2}; do
      if [ ${request_arr[$index]} != "default" ]; then
         unset func_arr[$index]
         func_arr[$index]=${request_arr[$index]}
      fi
   done

   echo "Fetching version library . . ."
   VERSION_LIB_URL="https://raw.githubusercontent.com/helxplatform/devops/master/cicd/jenkins/bashlib/version_lib.sh"
   curl $VERSION_LIB_URL > version_lib.sh
   . ./version_lib.sh

   echo "Fetching curl library . . ."
   CURL_LIB_URL="https://raw.githubusercontent.com/helxplatform/devops/master/cicd/jenkins/bashlib/clair_lib.sh"
   curl $CURL_LIB_URL > clair_lib.sh
   . ./clair_lib.sh
}


# --- PREBUILD ---
# Handle tasks which must be done prior to the build, such as
#   - getting version number
#   - programatically creating dockerfile (if necessary)
#   - return tags for docker use
# parameters:
#   - $1 org - org of repo to build, if creating Dockerfile
#   - $2 repo - repo to build, if creating Dockerfile
#   - $3 branch - branch to build, if creating Dockerfile
#   - $4 version_file - path to file with current version of app
#   - $5 build_args - additional aguments to docker command, if needed
# returns:
#   - String containing colon separated values for
#      - docker tag 1
#      - docker tag 2
#      - build version
#   - Dockerfile may be created by some versions of this function
function prebuild ()
{
   local -r org=$1
   local -r repo=$2
   local -r branch=$3
   local -r version_file=$4
   local -r build_args=$5

 #  echo "prebuild: $org $repo $branch $version_file $build_args"
   incr_version $version_file
   local ver=$(get_version $version_file)
   echo "$ver" >&2
   local tags=$(get_tags $branch $ver)
   local tag_array=(${tags//:/ })
   local tag1=${tag_array[0]}
   local tag2=${tag_array[1]}

   echo "$tag1:$tag2:$ver"
}


# --- BUILD ---
function build ()
{
   local -r org=$1
   local -r repo=$2
   local -r branch=$3
   shift 3
   local build_args=$1
   local -r tag1=$2
   local -r tag2=$3
   local -r app1_path=$4
   local docker_path=$5
   local docker_fn=$6

   echo "build: $org $repo $branch $build_args $tag1 $tag2 $app1_path $docker_path $docker_fn"
   echo "Building app . . ."

   if [ "$build_args" ==  "null" ]; then unset build_args; fi
   if [ "$docker_fn" == "null" ]; then docker_fn="Dockerfile"; fi
   if [ "$docker_path" == "." ]; then docker_path="./"; fi 
   if [ "$app1_path" != "." ]; then cd $app1_path; fi

   docker build -f $docker_fn --no-cache $build_args -t $org/$repo:$tag1 -t $org/$repo:$tag2 $docker_path
}


# --- UNIT_TEST ---
function unit_test ()
{
   local -r org=$1
   local -r repo1=$2
   local -r repo2=$3
   local -r repo1_url=$4
   local -r repo2_url=$5
   local -r repo1_req_path=$6
   local -r repo2_req_path=$7
   local -r branch=$8
   local -r ver=$9
   local -r tag1=${10}
   local -r repo2_app_home=${11}
   local -r cmd_path=${12}
   shift 12
   local cmd_args=$1
   local -r datafile=$2

   echo -n "unit_test: $org $repo1 $repo2 $repo1_url $repo2_url $repo1_req_path $repo2_req_path "
   echo "$branch $ver $tag1 $repo2_app_home $cmd_path $cmd_args $datafile"
   echo "Executing unit tests . . ."
   if [ $cmd_path != "null" ]; then
      pwd
      ls -l
      /usr/bin/python3 -m venv venv && \
      source venv/bin/activate && \
      pip install --no-cache-dir -r $repo1_req_path --upgrade pip

      # Handle case of supplemental repo needed for testing
      if [ -n "$repo2" ] && \
         [ "$repo2" != "null" ] && \
         [ -n "$repo2_url" ] && \
         [ -n "$repo2_req_path" ] && \
         [ -n "$repo2_app_home" ]; then
         if [ ! -d $repo2_app_home/$repo2 ]; then git clone --branch $branch $repo2_url ; fi && \
            pip install -r $repo2_req_path
      fi

      if [[ "$cmd_args" =~ .*TAG1.* ]]; then
         full_cmd_args=`echo $cmd_args | sed -e "s/\TAG1/$tag1/g"`
      else
         full_cmd_args="$cmd_args"
      fi
      echo "Invoking test with cmd_path [$cmd_path] and cmd_args [$full_cmd_args]"
      $cmd_path $full_cmd_args
   else
      true
   fi
}


# --- PUSH ---
function push ()
{

   local -r org=$1
   local -r repo=$2
   local -r tag1=$3
   local -r tag2=$4

   echo "push: $org $repo $tag1 $tag2"
   echo "Pushing image to DockerHub . . ."
   docker push $org/$repo:$tag1
   docker push $org/$repo:$tag2
}


# --- SECURITY_SCAN ---
function security_scan ()
{
   local org=$1
   local repo=$2
   local branch=$3
   local ver=$4
   local tag=$5

   echo "security_scan: $org $repo $tag"
   echo "Scanning image for security issues . . ."
   scan_clair_v2 "$org" "$repo" "$tag"  || true
   if [ $? -ne 0 ]
   then
      echo "Skipping clair postprocessing."
      return 1
   else
      echo "postprocessing clair output" 
      postprocess_clair_output_v2 "$org" "$repo" "$branch" "$ver" "$tag" "Medium" || true
   fi
}


# --- CLEANUP --- 
function cleanup ()
{
   local org=$1
   local repo=$2

   echo "cleanup: $org $repo"
   docker images -a | grep "$org/$repo" | awk '{print $3}' | xargs docker rmi -f || true
}

# --- BUILD_APP --- 
function build_app ()
{

   local -r project=$1

   # Array index constants
   local -r CODE_PRI_URL=0
   local -r CODE_SEC_URL=1
   local -r CODE_PRI_APP_PATH=2
   local -r CODE_PRI_REQ_PATH=3
   local -r CODE_SEC_REQ_PATH=4
   local -r CODE_BRANCH=5
   local -r CODE_PREBUILD=6
   local -r CODE_BUILD=7
   local -r CODE_TEST=8

   local -r DOCKER_ORG=0
   local -r DOCKER_PRI_REPO=1
   local -r DOCKER_SEC_REPO=2
   local -r DOCKER_BUILD_ARGS=3
   local -r DOCKER_DF_FN=4
   local -r DOCKER_PRI_D_DIR=5
   local -r DOCKER_SEC_D_DIR=6

   local -r TEST_CMD_PATH=0
   local -r TEST_CMD_ARGS=1
   local -r TEST_DATAFILE=2

   local -r CLAIR_CMD_ARGS=0  # For future use
   local -r CLAIR_THRESHOLD=1 # ""
   local -r CLAIR_WHITELIST=2 # ""

   echo "build_app starting."

   # Read YAML into arrays for processing 
   echo "Reading yaml file . . ."
   local code_array=(`yq read -X $project.yaml 'code.*'`)
   local docker_array=(`yq read -X $project.yaml 'docker.*'`)
   local test_array=(`yq read -X $project.yaml 'test.*'`)

   # yaml constants
   local -r ORG=${docker_array[$DOCKER_ORG]}
   local -r REPO1=${docker_array[$DOCKER_PRI_REPO]}
   local -r REPO2=${docker_array[$DOCKER_SEC_REPO]}
   local -r BRANCH=${code_array[$CODE_BRANCH]}
   echo "ORG:[$ORG] REPO1:[$REPO1] REPO2:[$REPO2] BRANCH:[$BRANCH]"

   local -r REPO1_URL=${code_array[$CODE_PRI_URL]}
   local -r REPO2_URL=${code_array[$CODE_SEC_URL]}
   local -r APP1_PATH=${code_array[$CODE_PRI_APP_PATH]}
   echo "REPO1_URL:[$REPO1_URL] REPO2_URL:[$REPO2_URL] APP1_PATH:[$APP1_PATH]"

   local -r REQ_PREBUILD_FUNC=${code_array[$CODE_PREBUILD]}
   local -r REQ_BUILD_FUNC=${code_array[$CODE_BUILD]}
   local -r REQ_TEST_FUNC=${code_array[$CODE_TEST]}
   echo "REQ_PREBUILD_FUNC:[$REQ_PREBUILD_FUNC] REQ_BUILD_FUNC:[$REQ_BUILD_FUNC] REQ_TEST_FUNC:[$REQ_TEST_FUNC]"

   local -r REPO1_REQ_PATH=${code_array[$CODE_PRI_REQ_PATH]}
   local -r REPO2_REQ_PATH=${code_array[$CODE_SEC_REQ_PATH]}
   echo "REPO1_REQ_PATH:[$REPO1_REQ_PATH] REPO2_REQ_PATH:[$REPO2_REQ_PATH]"

   local -r DOCKER_FN=${docker_array[$DOCKER_DF_FN]}
   local -r DOCKER_DIR1=${docker_array[$DOCKER_PRI_D_DIR]}
   local -r DOCKER_DIR2=${docker_array[$DOCKER_SEC_D_DIR]}
   local -r BUILD_ARGS=${docker_array[$DOCKER_BUILD_ARGS]}
   echo "DOCKER_FN:[$DOCKER_FN] DOCKER_DIR1:[$DOCKER_DIR1] DOCKER_DIR2:[$DOCKER_DIR2] BUILD_ARGS:[$BUILD_ARGS]"

   local -r CMD_PATH=${test_array[$TEST_CMD_PATH]}
   #local -r CMD_ARGS=${test_array[$TEST_CMD_ARGS]}
   local -r CMD_ARGS=$(yq read "$project.yaml" 'test.cmd_args')
   local -r DATAFILE=$(yq read "$project.yaml" 'test.datafile')
   echo "CMD_PATH:[$CMD_PATH] CMD_ARGS:[$CMD_ARGS] DATAFILE:[$DATAFILE]"

   # Fundamental given constant
   local -r JENKINS_HOME="/var/jenkins_home"

   # Derived constants from yaml + givens
   local -r WS="$JENKINS_HOME/workspace/$project/${docker_array[$DOCKER_PRI_REPO]}"
   local -r REPO2_APPDIR=${docker_array[$DOCKER_PRI_REPO]}
   local -r REPO2_APP_HOME="$WS/$REPO2_APPDIR"
   local -r VERSION_FILE="$JENKINS_HOME/jobs/$project/version/$BRANCH/ver"
   echo "WS:[$WS] REPO2_APPDIR:[$REPO2_APPDIR] REPO2_APP_HOME:[$REPO2_APP_HOME] VERSION_FILE:[$VERSION_FILE]"

   echo "Invoking check_prereqs"
   check_prereqs

   # Init function array to the default build/test functions.
   func_array=(prebuild build unit_test)

   # The init function checks the app's yaml to see if it requires a custom
   #   function for any of these three functions. If so, it updates 
   #   func_array with the name of the custom function. 
   # The resulting function set is then invoked from the array below.
   # This provides a _very_ weak form of polymorphism akin to function 
   #   pointers in C which reduces he amount of "hooking" that has to occur
   #   in the default functions and hopefully increases maintainability.
   # Note: The custom functions must use the same parameter list as 
   #   the default functions.
   echo "Requested build/test functions: $REQ_PREBUILD_FUNC, $REQ_BUILD_FUNC, $REQ_TEST_FUNC"
   echo "Invoking init_build $REQ_PREBUILD_FUNC $REQ_BUILD_FUNC $REQ_TEST_FUNC func_array"
   init_build $REQ_PREBUILD_FUNC $REQ_BUILD_FUNC $REQ_TEST_FUNC func_array
   echo "Post-init_build function array: ${func_array}[@]"

   # Invoke prebuild:
   echo "Invoking ${func_array[$PREBUILD]} $ORG $REPO1 $BRANCH $VERSION_FILE $BUILD_ARGS"
   local build_info=$(${func_array[$PREBUILD]} $ORG $REPO1 $BRANCH $VERSION_FILE $BUILD_ARGS)

   # Process array of returned vars for tags and version:
   local build_array=(${build_info//:/ })
   local -r TAG1=${build_array[0]}
   local -r TAG2=${build_array[1]}
   local -r VER=${build_array[2]}

   # Invoke build:
   echo "Invoking ${func_array[$BUILD]} $ORG $REPO1 $BRANCH $BUILD_ARGS $TAG1 $TAG2 $APP1_PATH $DOCKER_DIR1 $DOCKER_FN"
   ${func_array[$BUILD]} $ORG $REPO1 $BRANCH $BUILD_ARGS $TAG1 $TAG2 $APP1_PATH $DOCKER_DIR1 $DOCKER_FN
   if [ $? -ne 0 ]
   then
     echo "Build failed, skipping tests and not pushing to Dockerhub." >&2
     exit 2
   fi

   # Invoke unit tests:
   echo -n "Invoking ${func_array[$UNIT_TEST]} $ORG $REPO1 $REPO2 $REPO1_URL $REPO2_URL "
   echo "$REPO1_REQ_PATH $REPO2_REQ_PATH $BRANCH $VER $TAG1 $REPO2_APP_HOME $CMD_PATH $CMD_ARGS $DATAFILE"
   ${func_array[$UNIT_TEST]} $ORG $REPO1 $REPO2 $REPO1_URL $REPO2_URL $REPO1_REQ_PATH \
                $REPO2_REQ_PATH $BRANCH $VER $TAG1 $REPO2_APP_HOME $CMD_PATH "$CMD_ARGS" $DATAFILE
   if [ $? -ne 0 ]
   then
      echo "Unit tests failed, not pushing to DockerHub." >&2
      exit 3
   fi

   # Push to DockerHub
   echo "Invoking push $ORG $REPO1 $TAG1 $TAG2"
   push $ORG $REPO1 $TAG1 $TAG2

   # Do clair scanning
   echo "Invoking security_scan $ORG $REPO1 $TAG1"
   security_scan $ORG $REPO1 $BRANCH $VER $TAG1

   # Clean up build artifacts
   echo "Invoking cleanup $ORG $REPO1"
   cleanup $ORG $REPO1

   echo "Done."
}

build_project=$1
build_app $build_project
