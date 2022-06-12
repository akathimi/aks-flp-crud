#!/bin/bash

# script name: aks-flp-crud.sh
# Version v0.0.5 20211112
# Set of tools to deploy AKS troubleshooting labs

# "-l|--lab" Lab scenario to deploy
# "-r|--region" region to deploy the resources
# "-u|--user" User alias to add on the lab name
# "-h|--help" help info
# "--version" print version

# read the options
TEMP=$(getopt -o g:n:l:r:u:hv --long resource-group:,name:,lab:,region:,user:,help,validate,version -n 'aks-flp-crud.sh' -- "$@")
eval set -- "$TEMP"

# set an initial value for the flags
RESOURCE_GROUP=""
CLUSTER_NAME=""
LAB_SCENARIO=""
USER_ALIAS=""
LOCATION="westeurope"
VALIDATE=0
HELP=0
VERSION=0
labs=""
labs_count=${#labs[@]}

while true; do
    case "$1" in
    -h | --help)
        HELP=1
        shift
        ;;
    -g | --resource-group) case "$2" in
        "") shift 2 ;;
        *)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        esac ;;
    -n | --name) case "$2" in
        "") shift 2 ;;
        *)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        esac ;;
    -l | --lab) case "$2" in
        "") shift 2 ;;
        *)
            LAB_SCENARIO="$2"
            shift 2
            ;;
        esac ;;
    -r | --region) case "$2" in
        "") shift 2 ;;
        *)
            LOCATION="$2"
            shift 2
            ;;
        esac ;;
    -u | --user) case "$2" in
        "") shift 2 ;;
        *)
            USER_ALIAS="$2"
            shift 2
            ;;
        esac ;;
    -v | --validate)
        VALIDATE=1
        shift
        ;;
    --version)
        VERSION=1
        shift
        ;;
    --)
        shift
        break
        ;;
    *)
        echo -e "Error: invalid argument\n"
        exit 3
        ;;
    esac
done

# Variable definition
# SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
# SCRIPT_NAME="$(echo $0 | sed 's|\.\/||g')"
SCRIPT_VERSION="Version v0.0.5 20211112"

# Funtion definitions

# az login check
function az_login_check() {
    if $(az account list 2>&1 | grep -q 'az login'); then
        echo -e "\n--> Warning: You have to login first with the 'az login' command before you can run this lab tool\n"
        az login -o table
    fi
}

# check resource group and cluster
function check_resourcegroup_cluster() {
    # RESOURCE_GROUP="$1"
    # CLUSTER_NAME="$2"

    RG_EXIST=$(
        az group show -g "$RESOURCE_GROUP" &>/dev/null
        echo $?
    )
    if [ "$RG_EXIST" -ne 0 ]; then
        echo -e "\n--> Creating resource group ${RESOURCE_GROUP}...\n"
        az group create --name "$RESOURCE_GROUP" --location "$LOCATION" -o table &>/dev/null
    else
        echo -e "\nResource group $RESOURCE_GROUP already exists...\n"
    fi

    CLUSTER_EXIST=$(
        az aks show -g "$RESOURCE_GROUP" -n "$CLUSTER_NAME" &>/dev/null
        echo $?
    )
    if [ "$CLUSTER_EXIST" -eq 0 ]; then
        echo -e "\n--> Cluster $CLUSTER_NAME already exists...\n"
        echo -e "Please remove that one before you can proceed with the lab.\n"
        exit 5
    fi
}

# validate cluster exists
function validate_cluster_exists() {
    RESOURCE_GROUP="$1"
    CLUSTER_NAME="$2"

    CLUSTER_EXIST=$(
        az aks show -g "$RESOURCE_GROUP" -n "$CLUSTER_NAME" &>/dev/null
        echo $?
    )
    if [ "$CLUSTER_EXIST" -ne 0 ]; then
        echo -e "\n--> ERROR: Failed to create cluster $CLUSTER_NAME in resource group $RESOURCE_GROUP ...\n"
        exit 5
    fi
}

# Usage text
function print_usage_text() {
    NAME_EXEC="$0"
    lab_names=()
    for lab in "${labs[@]}"; do
        name=$(echo "$lab" | sed 's/_/./' | sed 's/_/ /g')
        lab_names+=("${name::-3}") #removes .sh
    done

    echo -e "$NAME_EXEC usage: $NAME_EXEC -l <LAB#> -u <USER_ALIAS> [-v|--validate] [-r|--region] [-h|--help] [--version]\n"
    echo -e "\nHere is the list of current labs available:\n*************************************************************************************"
    printf '*\t%s\n' "${lab_names[@]}"
    echo -e "*************************************************************************************\n"
}

#if -h | --help option is selected usage will be displayed
if [ $HELP -eq 1 ]; then
    print_usage_text
    echo -e '"-l|--lab" Lab scenario to deploy (3 possible options)
"-r|--region" region to create the resources
"--version" print version of aks-flp-crud
"-h|--help" help info\n'
    exit 0
fi

if [ $VERSION -eq 1 ]; then
    echo -e "$SCRIPT_VERSION\n"
    exit 0
fi

if [ -z "$LAB_SCENARIO" ]; then
    echo -e "\n--> Error: Lab scenario value must be provided. \n"
    print_usage_text
    exit 9
fi

if [ -z "$USER_ALIAS" ]; then
    echo -e "Error: User alias value must be provided. \n"
    print_usage_text
    exit 10
fi

# lab scenario has a valid option
if ! (("$LAB_SCENARIO" > 0 && "$LAB_SCENARIO" <= "$labs_count")); then
    echo -e "\n--> Error: invalid value for lab scenario '-l $LAB_SCENARIO'\nIt must be value from 1 to $labs_count\n"
    exit 11
fi

# main
echo -e "\n--> AKS Troubleshooting sessions
********************************************

This tool will use your default subscription to deploy the lab environments.
Verifing if you are authenticated already...\n"

# Verify az cli has been authenticated
az_login_check

# Verify az cli has been authenticated
az_login_check

if [ $VALIDATE -eq 0 ]; then
    check_resourcegroup_cluster
    lab_scenario_"$LAB_SCENARIO"

elif [ $VALIDATE -eq 1 ]; then
    lab_scenario_"$LAB_SCENARIO"_validation
else
    echo -e "\n--> Error: no valid option provided\n"
    exit 12
fi
exit 0
