function dug_test ()
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


   cd $app_home
   bin/dug dev init && \
   bin/dug stack up -d
   bin/dug pytests
   bin/dug stack down
}

function restartr_test()
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

   bin/restartr api
   bin/restartr tests add $datafile 2
   bin/restartr tests query $datafile 2

}
