# -----------------------------------------------------------------------
# get_version
#
# Description: Retrieves the current version number for a build.
#
# Inputs: $VERSION_FILE: Full path to version file, a file that:
#           Contains a single version number in one of these formats:
#           [v]n
#           [v]n.n
#           [v]n.n.nn, where n is an integer from 0-9
#           may optionally be preceded by a single letter "v" to denote version
#
# Outputs: The version number from the version file.
#
# Returns: 0 on success
#          255 when $VERSION_FILE file is not found
# -----------------------------------------------------------------------
function get_version () {
    local -r version_file=$1
    if [ ! -f "$version_file" ]
    then
        echo "Version file $version_file does not exist."
        echo "Skipping build."
        echo "Please check for or re-create it."
        exit 255
    fi

    ver=$(< $version_file)
    echo "$ver"
}


# -----------------------------------------------------------------------
# incr_version
#
# Description: Increments a version number for a build.
#
# Inputs: $1: Full path to version file, a file that:
#           Contains a single version number in one of these formats:
#           [v]n
#           [v]n.n
#           [v]n.n.nn, where n is an integer from 0-9
#           may optionally be preceded by a single letter "v" to denote version
#
# Outputs: An incremented version number that rolls over when
#             it reaches its max value for the number of digit places
#             available.
#          Number is updated in version file.
#
# Returns: 0 on success
#          255 when $version_file is not found
# -----------------------------------------------------------------------
function incr_version () {

    local -r version_file=$1

    SUBMINOR_OVERFLOW=99
    MINOR_OVERFLOW=9

    oldver=$(get_version $version_file)
    rc=$?
    case $rc in
        0) ;;
        255) echo "Version file not found."; exit $rc;;
        *) echo "Unknown error";;
    esac
    read -r major minor subminor <<< $(echo $oldver | awk -F. '{print $1, $2, $3}')

    newsubminor=''
    if [ -n "${subminor}" ] && [ $subminor -lt $SUBMINOR_OVERFLOW ]
    then
        # increment normally
        newsubminor=$(($subminor + 1))
    else
        # we overflowed
        newsubminor=0
    fi

    newminor="$minor"
    if [ -n "${minor}" ]
    then
        if [ -z "${subminor}" ] ||
           [ -n "${subminor}" ] && [ $newsubminor -eq 0 ]
        then
            if [ $minor -lt $MINOR_OVERFLOW ]
            then
                # increment normally
                newminor=$(($minor + 1))
            else
                # we overflowed
                newminor=0
            fi
        fi
    fi

    newmajor="$major"
    if [ -z "${minor}" ] || [ $newminor -eq 0 -a ! $minor -eq 0 ]
    then
         newmajor=$(($major + 1))
    fi

    newver="$newmajor"
    if [ -n "${minor}" ]; then newver=$newver".$newminor"; fi
    if [ -n "${subminor}" ]; then newver=$newver".$newsubminor"; fi

    echo "$newver" > $version_file
}
