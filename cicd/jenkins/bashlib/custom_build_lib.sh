function cloudtopsdk_build ()
{
   local -r org=$1
   local -r repo=$2
   local -r branch=$3
   shift 3
   local build_args=$1
   local -r tag1=$2
   local -r tag2=$3
   local -r app_home=$4
   local docker_path=$5
   local docker_fn=$6

   echo "cloudtopsdk_build: $org $repo $branch $build_args $tag1 $tag2 $app_home $docker_path $docker_fn"
   echo "Building app . . ."

   python3 -m venv venv
   source venv/bin/activate
   pip install pyyaml

   cd $app_home
   pwd
   ls -l
   echo $build_args # for master, imagej.yml "latest", for develop, imagej.yml
   ../../CloudTopBuilder.py $build_args

   if [ ! -f "$docker_fn" ]
   then
      echo "Failed to create $DOCKER_FILE, skipping build."
      return 1
   fi

   docker build --no-cache -f ./$docker_fn -t $org/$repo:$tag1 -t $org/$repo:$tag2 .
}


function dug_client_build ()
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

   echo "PUBLIC_URL=/ui" > "$app1_path/.env"
   echo "Contents of env file: " `cat "$app1_path/.env"`

   docker build --no-cache $build_args -t $org/$repo:$tag1 -t $org/$repo:$tag2 -f $docker_path/$docker_fn $docker_path
}
