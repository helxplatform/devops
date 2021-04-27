set -ex

# CONSTANTS
PREBUILD=0
BUILD=1
UNIT_TEST=2
UDF=3

PROJECT=$1
JENKINS_HOME="/var/jenkins_home"
WKSPC="$JENKINS_HOME/workspace/$PROJECT"
JOBS="$JENKINS_HOME/jobs/$PROJECT"


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

   echo "${FUNCNAME[0]}"
   echo "${FUNCNAME[0]}: Checking pre-requisites for build . . ."
   bash_ver=$(bash --version | head -1 | cut -d ' ' -f4)
   arr_bash_ver=(${bash_ver//./ })

   if [ ${arr_bash_ver[0]} -le $ver_major -a \
        ${arr_bash_ver[1]} -le $ver_minor ]; then
      echo "Insufficient bash version for build: [$bash_ver]"
      return 1
   fi

   echo "Bash version is $bash_ver. Everything's cool."
   return 0
}


# --- INIT_BUILD ---
function init_build ()
{
   local -r req_prebuild=$1
   local -r req_build=$2
   local -r req_test=$3
   local -r req_udf=$4
   local -n func_arr=${5}

   echo "${FUNCNAME[0]} $req_prebuild $req_build $req_test $req_udf ${func_arr[@]}"
   echo "${FUNCNAME[0]}: Initializing build . . ."
   echo "${FUNCNAME[0]}: Setting up functions array . . ."
   request_arr=($req_prebuild $req_build $req_test $req_udf)
   for index in {0..3}; do
      if [ ${request_arr[$index]} != "default" ]; then
         unset func_arr[$index]
         func_arr[$index]=${request_arr[$index]}
      fi
   done

   echo "${FUNCNAME[0]}: Fetching version library . . ."
   VERSION_LIB_URL="https://raw.githubusercontent.com/helxplatform/devops/master/cicd/jenkins/bashlib/version_lib.sh"
   curl $VERSION_LIB_URL > version_lib.sh
   . ./version_lib.sh

   echo "${FUNCNAME[0]}: Fetching clair library . . ."
   CLAIR_LIB_URL="https://raw.githubusercontent.com/helxplatform/devops/master/cicd/jenkins/bashlib/clair_lib.sh"
   curl $CLAIR_LIB_URL > clair_lib.sh
   . ./clair_lib.sh

   # Fetch custom prebuild function lib here if there are ever any custom prebuild functions

   echo "${FUNCNAME[0]}: Fetching custom build function lib . . ."
   CUSTOM_BUILD_LIB_URL="https://raw.githubusercontent.com/helxplatform/devops/master/cicd/jenkins/bashlib/custom_build_lib.sh"
   curl $CUSTOM_BUILD_LIB_URL > custom_build_lib.sh
   . ./custom_build_lib.sh

   echo "${FUNCNAME[0]}: Fetching custom test function lib . . ."
   CUSTOM_TEST_LIB_URL="https://raw.githubusercontent.com/helxplatform/devops/master/cicd/jenkins/bashlib/custom_test_lib.sh"
   curl $CUSTOM_TEST_LIB_URL > custom_test_lib.sh
   . ./custom_test_lib.sh
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

   if [ ! -e $version_file ]; then
      mkdir $JOBS/version
      mkdir $JOBS/version/$branch
      echo "0.0.0" > $JOBS/version/$branch/ver
   fi

   incr_version $version_file
   rc=$?
   case $rc in
        0) ;;
        255) echo "${FUNCNAME[0]}: Failed to increment version. Exiting."; exit $rc;;
        *) echo "${FUNCNAME[0]}: Unknown error"; exit $rc;;
   esac

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

   echo "${FUNCNAME[0]} $org $repo $branch $build_args $tag1 $tag2 $app1_path $docker_path $docker_fn"
   echo "${FUNCNAME[0]}: Building app . . ."
   if [ "$build_args" ==  "null" ]; then unset build_args; fi
   if [ "$docker_fn" == "null" ]; then docker_fn="Dockerfile"; fi
   if [ "$app1_path" != "." ]; then cd $app1_path; fi

   docker build --no-cache $build_args -t $org/$repo:$tag1 -t $org/$repo:$tag2 -f $docker_path/$docker_fn $docker_path
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
   local -r app_home=${11}
   local -r repo2_app_home=${12}
   local -r cmd_path=${13}
   shift 13
   local cmd_args=$1
   local -r datafile=$2

   echo -n "${FUNCNAME[0]} $org $repo1 $repo2 $repo1_url $repo2_url $repo1_req_path $repo2_req_path "
   echo "$branch $ver $tag1 $repo2_app_home $cmd_path $cmd_args $datafile"
   echo "${FUNCNAME[0]}: Executing unit tests . . ."
   if [ $cmd_path != "null" ]; then
      pwd
      ls -l
      /usr/bin/python3 -m venv venv && \
      source venv/bin/activate && \
      # upgrade pip independently to prevent potential version errors i.e.
      # If you are using an outdated pip version, it is possible a prebuilt wheel is available for this package but
      # pip is not able to install from it.
      pip install --upgrade pip && \
      pip install --no-cache-dir -r $repo1_req_path

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
      elif [ "$cmd_args" == "null"  ]; then
         unset full_cmd_args
      else
         full_cmd_args="$cmd_args"
      fi
      echo "${FUNCNAME[0]}: Invoking test with cmd_path [$cmd_path] and cmd_args [$full_cmd_args]"
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

   echo "${FUNCNAME[0]}: $org $repo $tag1 $tag2"
   echo "${FUNCNAME[0]}: Pushing image to DockerHub . . ."
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

   echo "${FUNCNAME[0]}: $org $repo $tag"
   echo "Scanning image for security issues . . ."
   scan_clair "$org" "$repo" "$tag"  || true
   if [ $? -ne 0 ]
   then
      echo "${FUNCNAME[0]}: Skipping clair postprocessing."
      return 1
   else
      echo "${FUNCNAME[0]}: postprocessing clair output"
      postprocess_clair_output "$org" "$repo" "$branch" "$ver" "$tag" "Medium" || true
   fi
}


# --- CLEANUP ---
function cleanup ()
{
   local org=$1
   local repo=$2

   echo "${FUNCNAME[0]} $org $repo"
   echo "${FUNCNAME[0]}: Cleaning up docker images . . ."
   docker images -a | grep "$org/$repo" | awk '{print $3}' | xargs docker rmi -f || true
}


# --- GENERIC ---
function udf ()
{
   local -r org=$1
   local -r repo=$2
   local -r repo_url=$3
   local -r branch=$4
   local -r ver=$5
   local -r tag=$6
   local -r cmd_path=$7
   local -r cmd_args=$8

   echo -n "${FUNCNAME[0]} $org $repo $repo_url"
   echo "$branch $ver $tag $cmd_path $cmd_args"
   echo "${FUNCNAME[0]}: Executing user defined function. . ."

   if [ ! -z "$cmd_path" -a "$cmd_path" != "null" ]; then
      echo "${FUNCNAME[0]}: Invoking user defined function [$cmd_path] with args [$cmd_args]"
      $cmd_path "$cmd_args"
   else
      true
   fi
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
   local -r DOCKER_DF_FN=3
   local -r DOCKER_PRI_D_DIR=4
   local -r DOCKER_SEC_D_DIR=5
   local -r DOCKER_BUILD_ARGS=6

   local -r TEST_CMD_PATH=0
   local -r TEST_CMD_ARGS=1
   local -r TEST_DATAFILE=2

   local -r GENERIC_UDF_PATH=0

   local -r CLAIR_CMD_ARGS=0  # For future use
   local -r CLAIR_THRESHOLD=1 # ""
   local -r CLAIR_WHITELIST=2 # ""

   echo "${FUNCNAME[0]} starting."

   # Read YAML into arrays for processing
   echo "${FUNCNAME[0]}: Reading yaml file . . ."
   local code_array=(`yq read -X $project.yaml 'code.*'`)
   local docker_array=(`yq read -X $project.yaml 'docker.*'`)
   local test_array=(`yq read -X $project.yaml 'test.*'`)
   local udf_array=(`yq read -X $project.yaml 'udf.*'`)

   # yaml constants
   local -r ORG=${docker_array[$DOCKER_ORG]}
   local -r REPO1=${docker_array[$DOCKER_PRI_REPO]}
   local -r REPO2=${docker_array[$DOCKER_SEC_REPO]}
   local -r BRANCH=${code_array[$CODE_BRANCH]}

   local -r REPO1_URL=${code_array[$CODE_PRI_URL]}
   local -r REPO2_URL=${code_array[$CODE_SEC_URL]}
   local -r APP_HOME=${code_array[$CODE_PRI_APP_PATH]}

   local -r REQ_PREBUILD_FUNC=${code_array[$CODE_PREBUILD]}
   local -r REQ_BUILD_FUNC=${code_array[$CODE_BUILD]}
   local -r REQ_TEST_FUNC=${code_array[$CODE_TEST]}
   local -r REQ_UDF_FUNC=$(yq read "$project.yaml" "--defaultValue"  "default" 'code.udf')

   local -r REPO1_REQ_PATH=${code_array[$CODE_PRI_REQ_PATH]}
   local -r REPO2_REQ_PATH=${code_array[$CODE_SEC_REQ_PATH]}

   local -r DOCKER_FN=${docker_array[$DOCKER_DF_FN]}
   local -r DOCKER_DIR1=${docker_array[$DOCKER_PRI_D_DIR]}
   local -r DOCKER_DIR2=${docker_array[$DOCKER_SEC_D_DIR]}
   local -r BUILD_ARGS=$(yq read "$project.yaml" 'docker.build_args')

   local -r CMD_PATH=${test_array[$TEST_CMD_PATH]}
   local -r CMD_ARGS=$(yq read "$project.yaml" 'test.cmd_args')
   local -r DATAFILE=$(yq read "$project.yaml" 'test.datafile')

   local -r UDF_CMD_PATH=${udf_array[$GENERIC_UDF_PATH]}
   local -r UDF_CMD_ARGS=$(yq read "$project.yaml" 'udf.cmd_args')

   # Derived constants from yaml + givens
   local -r WS="$WKSPC/${docker_array[$DOCKER_PRI_REPO]}"
   local -r REPO2_APPDIR=${docker_array[$DOCKER_PRI_REPO]}
   local -r REPO2_APP_HOME="$WS/$REPO2_APPDIR"
   local -r VERSION_FILE="$JOBS/version/$BRANCH/ver"

   echo "${FUNCNAME[0]}: Invoking check_prereqs"
   check_prereqs
   if [ $? -ne 0 ]
   then
     echo "${FUNCNAME[0]}: check_prereqs failed, Exiting build." >&2
     exit 1
   fi

   # Init function array to the default build/test functions.
   func_array=(prebuild build unit_test udf)

   # The init function checks the app's yaml to see if it requires a custom
   #   function for any of the above three functions. If so, it updates
   #   func_array with the name of the custom function.
   # The resulting function set is then invoked from the array below.
   # This provides a _very_ weak form of polymorphism akin to function
   #   pointers in C which reduces the amount of "hooking" that has to occur
   #   in the default functions and hopefully increases maintainability.
   # For simplicity, the custom functions must use the same parameter list as
   #   the default functions.
   echo "${FUNCNAME[0]}: Requested build/test functions: $REQ_PREBUILD_FUNC, $REQ_BUILD_FUNC, $REQ_TEST_FUNC, $REQ_UDF_FUNC"
   echo "${FUNCNAME[0]}: Invoking init_build $REQ_PREBUILD_FUNC $REQ_BUILD_FUNC $REQ_TEST_FUNC $REQ_UDF_FUNC func_array"
   init_build $REQ_PREBUILD_FUNC $REQ_BUILD_FUNC $REQ_TEST_FUNC $REQ_UDF_FUNC func_array
   echo "Post-init_build function array: ${func_array[@]}"

   # Invoke prebuild:
   echo "${FUNCNAME[0]}: Invoking ${func_array[$PREBUILD]} $ORG $REPO1 $BRANCH $VERSION_FILE $BUILD_ARGS"
   local build_info=$(${func_array[$PREBUILD]} $ORG $REPO1 $BRANCH $VERSION_FILE $BUILD_ARGS)
   rc=$?
   case $rc in
      0) ;;
      255) echo "${FUNCNAME[0]}: prebuild failed, Exiting."; exit 2;;
      *) echo "${FUNCNAME[0]}: Unknown error, Exiting."; exit 3;;
   esac

   # Process array of returned vars for tags and version:
   local build_array=(${build_info//:/ })
   local -r TAG1=${build_array[0]}
   local -r TAG2=${build_array[1]}
   local -r VER=${build_array[2]}

   # Invoke build:
   echo "${FUNCNAME[0]}: Invoking ${func_array[$BUILD]} $ORG $REPO1 $BRANCH [$BUILD_ARGS] $TAG1 $TAG2 $APP_HOME $DOCKER_DIR1 $DOCKER_FN"
   ${func_array[$BUILD]} $ORG $REPO1 $BRANCH "$BUILD_ARGS" $TAG1 $TAG2 $APP_HOME $DOCKER_DIR1 $DOCKER_FN
   if [ $? -ne 0 ]
   then
     echo "build_app: Build failed, skipping tests and not pushing to Dockerhub. Exiting." >&2
     exit 4
   fi

   # Invoke unit tests:
   echo -n "${FUNCNAME[0]}: Invoking ${func_array[$UNIT_TEST]} $ORG $REPO1 $REPO2 $REPO1_URL $REPO2_URL "
   echo "$REPO1_REQ_PATH $REPO2_REQ_PATH $BRANCH $VER $TAG1 $APP_HOME $REPO2_APP_HOME $CMD_PATH $CMD_ARGS $DATAFILE"
   ${func_array[$UNIT_TEST]} $ORG $REPO1 $REPO2 $REPO1_URL $REPO2_URL $REPO1_REQ_PATH \
                $REPO2_REQ_PATH $BRANCH $VER $TAG1 $APP_HOME $REPO2_APP_HOME $CMD_PATH "$CMD_ARGS" $DATAFILE
   if [ $? -ne 0 ]
   then
      echo "${FUNCNAME[0]}: Unit tests failed, not pushing to DockerHub. Exiting." >&2
      exit 5
   fi

   # Invoke generic command:
   echo -n "${FUNCNAME[0]}: Invoking ${func_array[$UDF]} $ORG $REPO1 $REPO1_URL $BRANCH $VER $TAG1 $UDF_CMD_PATH $UDF_CMD_ARGS"
   ${func_array[$UDF]} "$ORG" "$REPO1" "$REPO1_URL" "$BRANCH" "$VER" "$TAG1" "$UDF_CMD_PATH" "$UDF_CMD_ARGS"
   if [ $? -ne 0 ]
   then
      echo "${FUNCNAME[0]}: User defined function failed, not pushing to DockerHub. Exiting." >&2
      exit 6
   fi

   # Push to DockerHub
   echo "${FUNCNAME[0]}: Invoking push $ORG $REPO1 $TAG1 $TAG2"
   push $ORG $REPO1 $TAG1 $TAG2

   # Do clair scanning
   echo "${FUNCNAME[0]}: Invoking security_scan $ORG $REPO1 $TAG1"
   security_scan $ORG $REPO1 $BRANCH $VER $TAG1

   # Clean up build artifacts
   echo "${FUNCNAME[0]}: Invoking cleanup $ORG $REPO1"
   cleanup $ORG $REPO1

   echo "${FUNCNAME[0]}: Done."
}

build_app $PROJECT
