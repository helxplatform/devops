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
   CLAIR_HM="/var/jenkins_home/clair/"
   CLAIR_XFM="/var/jenkins_home/clair/xfm" # clair output transform dir
   ORG="$1"
   REPO="$2"
   BRANCH="$3"
   VERSION="$4"

   CLAIR_IP=$(docker network inspect bridge --format='{{(index .IPAM.Config 0).Gateway}}')
   echo "Clair IP = $CLAIR_IP"
   ETH0_IP=$(ip -4 addr show eth0 | grep 'inet' | cut -d' ' -f6 | cut -d'/' -f1)
   echo "ETHO IP = $ETH0_IP"
   echo "Running clair on $REPO . . ."
   docker pull $ORG/$REPO:$BRANCH-$VERSION

   if [ ! -d "$CLAIR_XFM" ]; then
      mkdir "$CLAIR_XFM"
   fi

   if [ ! -d "$CLAIR_XFM/$BRANCH-$VERSION" ]; then
      mkdir "$CLAIR_XFM/$BRANCH-$VERSION"
   fi

   $CLAIR_HM/clair-scanner --clair=http://$CLAIR_IP:6060 --ip=$ETH0_IP -t 'High' -r \
      "$CLAIR_XFM/$REPO-$BRANCH-$VERSION/clair_report.json" $ORG/$REPO:$BRANCH-$VERSION > \
      "$CLAIR_XFM/$REPO-$BRANCH-$VERSION/table.txt"

   # Remove control chars
   grep -o "[[:print:][:space:]]*" "$CLAIR_XFM/$REPO-$BRANCH-$VERSION/table.txt" > \
        "$CLAIR_XFM/$REPO-$BRANCH-$VERSION/table.txt"

   rm -f "$CLAIR_XFM/$REPO-$BRANCH-$VERSION/table.txt"

   echo "clair scan complete."
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
# Example call: postprocess-clair-output "heliumdatastage" "appstore" "develop" "v0.0.13"
# Result:
#    - Clair json output has Medium and below CVE's removed.
#    - All URL's are turned into HTML links.
#    - HTML Publisher server is set up for related build page.
#    - HTML table of CVE's is linked from related build page.
# -------------------------------------------------------------------------

function postprocess_clair_output() {

   ORG=$1
   REPO=$2
   BRANCH=$3
   VER=$4

   CLAIR_DIR=/var/jenkins_home/clair
   PROJ_DIR=$CLAIR_DIR/$REPO-$BRANCH-$VER
   WKSPC_DIR=/var/jenkins_home/workspace/
   LF_DIR="${CTEST:-$REPO}"
   WK_DIR=$WKSPC_DIR$LF_DIR

   # Print lines in awk until the first line that has a Medium threshold
   # That leaves 9 lines that need to be removed at the end.
   lines_to_remove=9
   num_lines=$(awk '/Medium/ { exit }
        { print }
        END{ print NR }' $PROJ_DIR/clair_report.json | \
                         tee $PROJ_DIR/clair_report_edited.json | \
                         wc -l)

   # Note for future development: change clair_report_final below to
   # clair_report_edited2.json
   head -n $( expr $num_lines - $lines_to_remove )   \
                $PROJ_DIR/clair_report_edited.json > \
                $PROJ_DIR/clair_report_final.json

   cat >> $PROJ_DIR/clair_report_final.json \
          $CLAIR_DIR/template_json_ending.txt

   # Note for future development: Call python program here to re-order
   # json list of vulnerability info prior to calling json2table. Also
   # use clair_report_edited2.json name when calling it, keep "final"
   # name here.
   cat $PROJ_DIR/clair_report_final.json | \
                              json2table > \
                              $PROJ_DIR/clair_html_file.html

   # Convert bare link to an href with CVE as target:
   # Future Dev:
   # Note: this href column should be moved to CVE column's place above
   # and its column deleted.
   # Note also, the redundant "Unapproved" CVE column should be removed too.
   sed -i 's|>\(https.*\)\(CVE-.*[0-9]\)<|><a href="\1\2" target="_blank">\2<|g'\
                              $PROJ_DIR/clair_html_file.html

   # Remove edited2 file here too.
   rm $PROJ_DIR/clair_report_edited.json

   cd $WK_DIR
   if [ ! -d "$WK__DIR/html" ]; then
      mkdir $WK_DIR/html
   fi

   cd html
   cp $CLAIR_DIR/template_index.html index.html
   sed -i "s/project/$REPO-$BRANCH-$VER/g" index.html
   sed -i "s/linter_url//g" index.html
   ln -f $PROJ_DIR/clair_html_file.html $REPO-$BRANCH-$VER-table.html
}
