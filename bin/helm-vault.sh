#!/bin/bash

# stop on errors
set -eo pipefail

# execute and print
# set -x

function print_help() {
  echo "\
usage: $0
  -d|--debug        [ print commands ]
  -g|--get          Just get the values YAML file (do not run Helm command).
                    Specify path of file for input or directory that contains
                    the file (filename created from secret path).
  -h|--help         Print this help message.
  -p|--put          Specify a values YAML to insert into Vault (do not run
                    Helm command).  Specify path of file for input or directory
                    that contains the file (filename created from secret path).
  -r|--remove-cmd   Specify the remove file command to be used when deleting the
                    temporary values YAML.  Default value is 'rm'.  It is good
                    to specify a secure delete program if your file system is
                    not encrypted.
  -s|--secret-path  Specify vault secret path to get values YAML file from.
  --                Additional arguments for the Helm command go after this.
"
}

HELM_ARGS=""
DEBUG=false
# Get directory containing this script.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
VALUES_FIELD=values.yaml
REMOVE_CMD="rm"
GET_VALUES_YAML=false
PUT_VALUES_YAML=false
COMPARE_VALUES=false
PUT_VALUES_YAML_FILE=""
SECRET_PATH=""
YAMLS_DIR=""

if [[ $# = 0 ]]; then
  print_help
  exit 1
fi

while [[ $# > 0 ]]
  do
  key="$1"
  case $key in
      -d|--debug)
        set -x
        DEBUG=true
        ;;
      -h|--help)
        print_help
        exit 0
        ;;
      -c|--compare)
        COMPARE_VALUES=true
        GET_VALUES_YAML_FILE="$2"
        shift # past argument
        ;;

      -g|--get)
        GET_VALUES_YAML=true
        GET_VALUES_YAML_FILE="$2"
        shift # past argument
        ;;
      -p|--put)
        PUT_VALUES_YAML=true
        PUT_VALUES_YAML_FILE="$2"
        shift # past argument
        ;;
      -r|--remove-cmd)
        REMOVE_CMD="$2"
        shift # past argument
        ;;
      -s|--secret-path)
        SECRET_PATH="$2"
        shift # past argument
        ;;
      --)
        HELM_ARGS="${@:2}"
        let "REMAINING_ARGS=$#-1"
        shift $REMAINING_ARGS
        ;;
      *)
        # unknown option
        print_help
        exit 1
        ;;
  esac
  shift # past argument or value
done

if [ -z "$SECRET_PATH" ]; then
  echo "Vault path not specified."
  print_help
  exit 1
fi

SECRET_FILE_NAME=$( echo "$SECRET_PATH-values.yaml" | tr "/" "-" )

if $DEBUG
then
  echo "SCRIPT_DIR: $SCRIPT_DIR"
  echo "SECRET_PATH=$SECRET_PATH"
  echo "SECRET_FILE_NAME=$SECRET_FILE_NAME"
  echo "helm args: $HELM_ARGS"
  echo
fi

if $PUT_VALUES_YAML
then
  # Put values into Vault.
  if [ -z "$PUT_VALUES_YAML_FILE" ]
  then
    echo "Values YAML not specified as input."
    print_help
    exit 1
  else
    if [ -d "$PUT_VALUES_YAML_FILE" ]
    then
      PUT_VALUES_YAML_FILE=$PUT_VALUES_YAML_FILE/$SECRET_FILE_NAME
    fi
    vault kv put $SECRET_PATH $VALUES_FIELD=@$PUT_VALUES_YAML_FILE
  fi
else
  # Get values from Vault.
  VALUES_YAML=$( vault kv get -field=$VALUES_FIELD $SECRET_PATH )
  if [ -d "$GET_VALUES_YAML_FILE" ]
  then
    GET_VALUES_YAML_FILE=$GET_VALUES_YAML_FILE/$SECRET_FILE_NAME
  fi

  TEMP_FILE=$SCRIPT_DIR/$SECRET_FILE_NAME
  echo "$VALUES_YAML" > "$TEMP_FILE"

  if $GET_VALUES_YAML
  then
    mv "$TEMP_FILE" "$GET_VALUES_YAML_FILE"
    echo "** keeping values YAML: $GET_VALUES_YAML_FILE"
    echo "Not running helm command"
  elif $COMPARE_VALUES
  then
    echo "comparing file from Vault to $GET_VALUES_YAML_FILE"
    echo "< remote difference"
    echo "> local difference"
    echo
    diff "$TEMP_FILE" "$GET_VALUES_YAML_FILE"
  else
    if [ -z "$HELM_ARGS" ]; then
      echo "Helm arguments not specified."
      print_help
      exit 1
    fi
    # Run helm command with values pulled from Vault.
    helm --values=$TEMP_FILE $HELM_ARGS
    # Delete the temp file used for values pulled from Vault.
    $REMOVE_CMD $TEMP_FILE
  fi
fi

echo "## $0 done. ##"
