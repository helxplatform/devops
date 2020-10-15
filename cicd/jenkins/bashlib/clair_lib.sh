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
   echo "Invoking clair-scanner on $ORG/$REPO:$BRANCH-$VER"
   $CLAIR_HM/clair-scanner --clair=http://$CLAIR_IP:6060 --ip=$ETH0_IP -t 'High' -r \
      "$XFM_DIR/clair_report.json" "$ORG/$REPO:$BRANCH-$VER" > "$XFM_DIR/table.txt"

   # Remove control chars
   grep -o "[[:print:][:space:]]*" "$XFM_DIR/table.txt" > \
                                   "$XFM_DIR/clean_table.txt"
   rm -f "$XFM_DIR/table.txt"
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
# $5 - Vulnerability threshold. All vulnerabilities at or below this threshold
#        will be removed from the report.
# Example call: postprocess_clair_output "heliumdatastage" "appstore" "develop" "v0.0.13" Medium
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
   THRESHOLD=$5

   JENKINS_HM="/var/jenkins_home"
   CLAIR_HM="$JENKINS_HM/clair"
   CLAIR_XFM="$CLAIR_HM/xfm"
   FN="$REPO-$BRANCH-$VER"
   XFM_DIR="$CLAIR_XFM/$FN"
   CLAIR_RPT="$CLAIR_HM/reports"
   RPT_DIR="$CLAIR_RPT/$FN"

   echo "FN=$FN"
   echo "XFM_DIR=$XFM_DIR"
   echo "image=$ORG/$REPO:$BRANCH-$VER"

   lines_to_remove=9
   num_lines=$(awk "              \
   /unapproved/,/]/  { next }     \
   /$THRESHOLD/      { exit }     \
                     { print }    \
   END               { print NR }" "$XFM_DIR/clair_report.json" | \
                               tee "$XFM_DIR/clair_report_edited.json" | \
                               wc -l)

   head -n $( expr $num_lines - $lines_to_remove )  \
                "$XFM_DIR/clair_report_edited.json" > \
                "$XFM_DIR/clair_report_final.json"

   # Add back sane JSON ending to file.
   cat >> "$XFM_DIR/clair_report_final.json" \
          "$CLAIR_HM/template_json_ending.txt"

   cat "$XFM_DIR/clair_report_final.json" | \
                              json2table > \
                              "$XFM_DIR/clair_table.html"

   # Convert bare link to an href with CVE as target:
   sed -i 's|>\(https.*\)\(CVE-.*[0-9]\)<|><a href="\1\2" target="_blank">\2<|g' \
                              "$XFM_DIR/clair_table.html"

   # >>---> INSERT NEW HTML BODY HERE

   if [ ! -d "$RPT_DIR" ]; then
      mkdir "$RPT_DIR"
   fi
   cp $XFM_DIR/clair_table.html $RPT_DIR/vuln_table_$REPO_$BRANCH_$VER.html

   # Add link to new vuln file into index.html file:
   x="$CLAIR_RPT/index.html"
   RPT_DIR="$CLAIR_RPT/$REPO_$BRANCH_$VER"

   # >>---> ADD LINK HERE

   # Clean up
   cd "$XFM_DIR/.."
   tar -czvf "$FN.tar.gz" "$FN/"
   mv "$FN.tar.gz" "$FN/"
   cd "$FN/"
   rm -f clair_* clean* vuln*
}
