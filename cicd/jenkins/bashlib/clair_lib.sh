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

   echo "DIFFS"
   diff $CLAIR_RPT/index.html $CLAIR_RPT/$tmpf

   echo "mv ing $CLAIR_RPT/$tmpf to $CLAIR_RPT/index.html"
   mv $CLAIR_RPT/$tmpf $CLAIR_RPT/index.html

   # Clean up
   #cd "$XFM_DIR/.."
   #tar -czvf "$FN.tar.gz" "$FN/"
   #mv "$FN.tar.gz" "$FN/"
   #cd "$FN/"
   #rm -f clair_* clean* vuln*
}

