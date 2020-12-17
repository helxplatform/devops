function cloudtopsdk-build ()
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

   echo "cloudtop-imagej-build: $org $repo $branch $build_args $tag1 $tag2 $app1_path $docker_path $docker_fn"
   echo "Building app . . ."

   python3 -m venv venv
   source venv/bin/activate
   pip install pyyaml

   cd $app1_path
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