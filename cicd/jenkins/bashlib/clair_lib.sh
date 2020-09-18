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
# -------------------------------------------------------------------------

function scan_clair () {
   CLAIR_HM="/var/jenkins_home/clair"
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
   $CLAIR_HM/clair-scanner --clair=http://$CLAIR_IP:6060 --ip=$ETH0_IP -t 'High' -r "$CLAIR_HM/clair_report.json" $ORG/$REPO:$BRANCH-$VERSION > $CLAIR_HM/tableoutput.txt > /dev/null
   sed -r "s/\x1B\[(([0-9]+)(;[0-9]+)*)?[m,K,H,f,J]//g" $CLAIR_HM/tableoutput.txt > $CLAIR_HM/clean_tableoutput.txt
   #cat $CLAIR_HM/clean_tableoutput.txt
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

   lines_to_remove=9
   num_lines=$(awk '/Medium/ { exit }
        { print }
        END{ print NR }' $PROJ_DIR/clair_report.json | \
                         tee $PROJ_DIR/clair_report_edited.json | \
                         wc -l)

   head -n $( expr $num_lines - $lines_to_remove )   \
                $PROJ_DIR/clair_report_edited.json > \
                $PROJ_DIR/clair_report_final.json

   cat >> $PROJ_DIR/clair_report_final.json \
          $CLAIR_DIR/template_json_ending.txt

   cat $PROJ_DIR/clair_report_final.json | \
                              json2table > \
                              $PROJ_DIR/clair_html_file.html

   sed -i 's|>\(https.*\)\(CVE-.*[0-9]\)<|><a href="\1\2" target="_blank">\2<|g'\
                              $PROJ_DIR/clair_html_file.html

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
