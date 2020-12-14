# -------------------------------------------------------------------------
# start_clair
# Starts clair db and server
# Pre-requisites:
#    - None
# Parameters:
#    - N/A
# Example call: start_clair
# Result:
#    - Outputs:
#       1) clair db and clair server are running
#       2) /var/jenkins_home/clair/pid_lock has the container ids of server/db
#       3) logs of execution are in /var/jenkins_home/clair_startup_log.txt
# -------------------------------------------------------------------------
function start_clair ()
{
   #set -ex

   exec 3>&1 4>&2
   trap 'exec 2>&4 1>&3' 0 1 2 3 RETURN
   exec 1>>/var/jenkins_home/clair/clair_startup_log.txt 2>&1
   #exec 1>>/var/log/clair/clair_startup_log.txt 2>&1
   #exec 1>>./clair_startup_log.txt 2>&1

   DIVIDER="------------------------------------------------------------------------------------"
   echo $DIVIDER
   echo `date` "Starting new clair server and db."

   PID=/var/jenkins_home/clair/pid_lock
   FIVE_MIN_IN_HALF_SECS=600
   count=1
   while  [ test -f "$PID" && count <= FIVE_MIN_IN_HALF_SECS ]
   do
      if [ count -lt FIVE_MIN_IN_HALF_SECS  ]; then
         echo "Waiting on pid_lock"
         sleep .5
         ((count++))
      else
         echo "ERROR: Timed out waiting on $PID!"
         echo "Taking Corrective action: Stopping and removing existing clair server and db!"
      fi
   done

   clair_images=$(docker ps | grep clair | cut -d' ' -f1 | paste -d " "  - -)
   if [ -n "$clair_images" ]; then

      echo `date` "Stopping old containers."
      docker kill $clair_images || true

      echo `date` "Removing stopped containers."
      docker container rm $clair_images || true
   fi

   # Start most current version of clair-db
   echo `date` "Starting new clair db . . ."
   db_cont_id=$(docker run -d --name clair-db arminc/clair-db:latest | cut -c1-12)
   if [  $? -eq 0 ]; then
      echo `date` "New clair db started successfully."
      echo $db_cont_id > $PID
   else
      echo `date` "Failed to start new clair db."
      return 1
   fi

   # Start clair server
   echo `date` "Starting new clair server . . ."
   server_cont_id=$(docker run -p 6060:6060 --link clair-db:postgres -d --name clair \
       arminc/clair-local-scan:v2.1.0_1e2ed91d90973d68a9840e4f08798d045cf7c2d7 | cut -c1-12)
   if [  $? -eq 0 ]; then
      echo `date` "New clair server started successfully."
      echo $server_cont_id >> $PID
   else
      echo `date` "Failed to start new clair server."
      echo `date` "Deleting clair db."
      docker kill $db_cont_id || true
      docker container rm $db_cont_id || true
      rm -rf $PID
      return 2
   fi

   echo "Done."
   echo $DIVIDER
}


# -------------------------------------------------------------------------
# stop_clair
# Stops clair db and server
# Pre-requisites:
#    - None
# Parameters:
#    - N/A
# Example call: stop_clair
# Result:
#    - Outputs:
#       1) clair db and clair server containers are stopped and removed
#       2) /var/jenkins_home/clair/pid_lock is removed
#       3) logs of execution are in /var/jenkins_home/clair_startup_log.txt
# -------------------------------------------------------------------------
function stop_clair ()
{
   #set -ex

   exec 3>&1 4>&2
   trap 'exec 2>&4 1>&3' 0 1 2 3 RETURN
   exec 1>>/var/jenkins_home/clair/clair_startup_log.txt 2>&1
   #exec 1>>/var/log/clair/clair_startup_log.txt 2>&1
   #exec 1>>./clair_startup_log.txt 2>&1

   DIVIDER="------------------------------------------------------------------------------------"
   echo $DIVIDER
   echo `date` "Stopping clair server and db."

   PID=/var/jenkins_home/clair/pid_lock
   clair_images=$(docker ps | grep clair | cut -d' ' -f1 | paste -d " "  - -)
   if [ -n "$clair_images" ]; then

      echo `date` "Stopping old containers."
      docker kill $clair_images || true

      echo `date` "Removing stopped containers."
      docker container rm $clair_images || true
   fi

   rm -rf $PID

   echo "Done."
   echo $DIVIDER
}


# -------------------------------------------------------------------------
# scan_clair
# Security scans Docker images. Call from containerized Jenkins
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
#    - Outputs:
#       1) JSON table of security scan information
#       2) Text table of security scan information, free of control chars
# -------------------------------------------------------------------------
function scan_clair () {

   ORG="$1"
   REPO="$2"
   BRANCH="$3"
   VER="$4"

   CLAIR_HM="/var/jenkins_home/clair"
   CLAIR_XFM="$CLAIR_HM/xfm" # clair output transform dir
   FN="$REPO-$BRANCH-$VER"
   XFM_DIR="$CLAIR_XFM/$FN"

   echo "scan_clair"

   echo "FN=$FN"
   echo "XFM_DIR=$XFM_DIR"
   echo "image=$ORG/$REPO:$BRANCH-$VER"

   CLAIR_IP=$(docker network inspect bridge --format='{{(index .IPAM.Config 0).Gateway}}')
   echo "Clair IP = $CLAIR_IP"
   ETH0_IP=$(ip -4 addr show eth0 | grep 'inet' | cut -d' ' -f6 | cut -d'/' -f1)
   echo "ETHO IP = $ETH0_IP"
   echo "Running clair on $ORG/$REPO:$BRANCH-$VER . . ."
   docker pull "$ORG/$REPO:$BRANCH-$VER"

   if [ ! -d "$CLAIR_XFM" ]; then
      /bin/mkdir "$CLAIR_XFM"
   fi

   if [ ! -d "$XFM_DIR" ]; then
      echo "Creating $XFM_DIR"
      /bin/mkdir "$XFM_DIR"
   fi

   # start clair server and db here
   echo "Starting clair server and db . . ."
   start_clair
   if [ $? -ne 0 ]; then
      echo "WARNING: clair failed to start, unable to scan image."
      return 1
   fi

   echo "Invoking clair-scanner on $ORG/$REPO:$BRANCH-$VER"
   $CLAIR_HM/clair-scanner --clair=http://$CLAIR_IP:6060 --ip=$ETH0_IP -t 'High' -r \
      "$XFM_DIR/clair_report.json" "$ORG/$REPO:$BRANCH-$VER" > "$XFM_DIR/table.txt"

   # Stop clair server and db here
   echo "Stopping clair server and db  . . ."
   stop_clair

   # Remove control chars
   sed -r "s/\x1B\[(([0-9]+)(;[0-9]+)*)?[m,K,H,f,J]//g" $XFM_DIR/table.txt > \
                                                        $XFM_DIR/clean_table.txt
   rm -f "$XFM_DIR/table.txt"
   echo "clair scan complete."
   return 0
}


# -------------------------------------------------------------------------
# postprocess_clair_output  
# Cleans up clair json output including creating links from urls and creates
#    html table. Sets up an index.html and links to table from jenkins build
#    page.
# Pre-requisites:
#    - json2table is installed and reachable via path.
#    - Clair scan has run.
# Parameters:
# $1 - Organization or name of the DockerHub repo to scan
# $2 - DockerHub repo to scan
# $3 - Branch part of version tag of repo to scan, if any
#        or "" if none
# $4 - Version number including "v" if any of repo to be
#        scanned.
# $5 - Vulnerability threshold. All vulnerabilities at or below this threshold
#        will be removed from the report.
# Example call: postprocess_clair_output "heliumdatastage" "appstore" "develop" "v0.0.13" Medium
# Result:
#    - Data has been converted from JSON into readable HTML.
#    - Redundant CVE information has been removed from table and and columns 
#         consolidated into a single CVE link.
#    - Unapproved CVE info at top has been removed as redundant.
#    - Double lines have been removed from table styling (except for nested table)
#    - Source clair html files are organized by directory.
# -------------------------------------------------------------------------
function postprocess_clair_output() {

   ORG=$1
   REPO=$2
   BRANCH=$3
   VER=$4
   THRESHOLD=$5

   JENKINS_HM="/var/jenkins_home"
   CLAIR_HM="$JENKINS_HM/clair"
   CLAIR_XFM="$CLAIR_HM/xfm"
   FN="$REPO-$BRANCH-$VER"
   XFM_DIR="$CLAIR_XFM/$FN"
   CLAIR_RPT="$CLAIR_HM/reports"
   RPT_DIR="$CLAIR_RPT/$FN"

   echo "postprocess_clair_output"

   echo "FN=$FN"
   echo "XFM_DIR=$XFM_DIR"
   echo "image=$ORG/$REPO:$BRANCH-$VER"

   awk "/unapproved/,/]/ { next }       \ 
                         { print }" "$XFM_DIR/clair_report.json" > "$XFM_DIR/clair_report_edited.json" 

   cat "$CLAIR_HM/template_html_css_body_open.txt" > "$XFM_DIR/clair_table.html"
   cat "$XFM_DIR/clair_report_edited.json" | \
                               json2table >> \
                              "$XFM_DIR/clair_table.html"
   cat "$CLAIR_HM/template_html_body_close.txt" >> "$XFM_DIR/clair_table.html"


   # Convert bare link to an href with CVE as target:
   sed -i 's|>\(https.*\)\(CVE-.*[0-9]\)<|><a href="\1\2" target="_blank">\2<|g' \
                              "$XFM_DIR/clair_table.html"

   awk "/^<th>Vulnerability<\/th>/                { next }                             \
        /^<th>Link<\/th>/                         { print \"<th>Vulnerability</th>\" } \
        /^<th>Link<\/th>/                         { next }                             \
        /^<td>CVE-[0-9]+-[0-9]+<\/td>/            { next }                             \
                                                  { print }"                           \
                         "$XFM_DIR/clair_table.html" > "$XFM_DIR/clair_table_updated.html"

   if [ ! -d "$RPT_DIR" ]; then
      mkdir "$RPT_DIR"
   fi
   cp "$XFM_DIR/clair_table_updated.html" "$RPT_DIR/vuln_table_$REPO-$BRANCH-$VER.html"

   # Add link to new vuln file in index.html:
   if [ $REPO == "tranql-app"  -o \
        $REPO == "tranql-base" -o \
        $REPO == "helx-hail"   -o \
        $REPO == "conda-layer" -o \
        $REPO == "jdk-layer" ]; then
      PAD="        "
   else
      PAD="    "
   fi

   repl="$PAD<li><a href=\"\/$REPO-develop-$ver\/vuln_table_$REPO-develop-$ver.html\" target=\"_blank\">Develop branch $ver vulnerabilities<\/a><\/li>"
   rnd_str=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 5 | xargs)
   tmpf=index_$rnd_str.html

   echo "tmpfile is $tmpf"

   echo "sed\'ing $CLAIR_RPT/index.html into $CLAIR_RPT/$tmpf"
   sed -e "/^.*$REPO-develop-VER.*$/p" \
       -e "s|^.*$REPO-develop-VER.*$|$repl|" $CLAIR_RPT/index.html > $CLAIR_RPT/$tmpf

   echo "mv ing $CLAIR_RPT/$tmpf to $CLAIR_RPT/index.html"
   mv $CLAIR_RPT/$tmpf $CLAIR_RPT/index.html

   # Clean up
   #cd "$XFM_DIR/.."
   #tar -czvf "$FN.tar.gz" "$FN/"
   #mv "$FN.tar.gz" "$FN/"
   #cd "$FN/"
   #rm -f clair_* clean* vuln*
   echo "Postprocessing clair output complete."
}


# -------------------------------------------------------------------------
# scan_clair_v2
# Security scans Docker images. Call from containerized Jenkins
# Pre-requisites:
#    - A clair server and clair db are running on the same Docker network
#    - clair-scanner exists on Jenkins server at specified location
# Parameters:
# $1 - Organization or name of the DockerHub repo to scan
# $2 - DockerHub repo to scan
# $3 - TAG docker tag
# Example call: scan-clair "heliumdatastage" "appstore-master" "1.0.13"
# Result: 
#    - Outputs:
#       1) JSON table of security scan information
#       2) Text table of security scan information, free of control chars
# -------------------------------------------------------------------------
function scan_clair_v2 () {

   ORG="$1"
   REPO="$2"
   TAG="$3"

   CLAIR_HM="/var/jenkins_home/clair"
   CLAIR_XFM="$CLAIR_HM/xfm" # clair output transform dir
   FN="$REPO-$TAG"
   XFM_DIR="$CLAIR_XFM/$FN"


   echo "scan_clair_v2""

   echo "FN=$FN"
   echo "XFM_DIR=$XFM_DIR"
   echo "image=$ORG/$REPO:$TAG"

   CLAIR_IP=$(docker network inspect bridge --format='{{(index .IPAM.Config 0).Gateway}}')
   echo "Clair IP = $CLAIR_IP"
   ETH0_IP=$(ip -4 addr show eth0 | grep 'inet' | cut -d' ' -f6 | cut -d'/' -f1)
   echo "ETHO IP = $ETH0_IP"
   echo "Running clair on $ORG/$REPO:$TAG . . ."
   docker pull "$ORG/$REPO:$TAG"

   if [ ! -d "$CLAIR_XFM" ]; then
      /bin/mkdir "$CLAIR_XFM"
   fi

   if [ ! -d "$XFM_DIR" ]; then
      echo "Creating $XFM_DIR"
      /bin/mkdir "$XFM_DIR"
   fi

   # start clair server and db here
   echo "Starting clair server and db . . ."
   start_clair
   if [ $? -ne 0 ]; then
      echo "WARNING: clair failed to start, unable to scan image."
      return 1
   fi

   echo "Invoking clair-scanner on $ORG/$REPO:$TAG"
   $CLAIR_HM/clair-scanner --clair=http://$CLAIR_IP:6060 --ip=$ETH0_IP -t 'High' -r \
      "$XFM_DIR/clair_report.json" "$ORG/$REPO:$TAG" > "$XFM_DIR/table.txt"

   # Stop clair server and db here
   echo "Stopping clair server and db  . . ."
   stop_clair

   # Remove control chars
   sed -r "s/\x1B\[(([0-9]+)(;[0-9]+)*)?[m,K,H,f,J]//g" $XFM_DIR/table.txt > \
                                                        $XFM_DIR/clean_table.txt
   rm -f "$XFM_DIR/table.txt"
   echo "clair scan complete."
   return 0
}


