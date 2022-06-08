#!/bin/bash
# Lab scenario 1
function lab_scenario_1 () {
    CLUSTER_NAME=aks-crud-ex${LAB_SCENARIO}-${USER_ALIAS}
    RESOURCE_GROUP=aks-crud-ex${LAB_SCENARIO}-rg-${USER_ALIAS}
    check_resourcegroup_cluster $RESOURCE_GROUP $CLUSTER_NAME

    echo -e "\n--> Deploying cluster for lab${LAB_SCENARIO}...\n"

    az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --location $LOCATION \
    --node-count 3 \
    --node-vm-size Standard_DC2s_v2 \
    --tag aks-crud-lab=${LAB_SCENARIO} \
    --generate-ssh-keys \
    --yes \
    -o table

    validate_cluster_exists $RESOURCE_GROUP $CLUSTER_NAME

    echo -e "\n\n--> Please wait while we are preparing the environment for you to troubleshoot...\n"
    az aks get-credentials -g $RESOURCE_GROUP -n $CLUSTER_NAME --overwrite-existing &>/dev/null
    while true; do for s in / - \\ \|; do printf "\r$s"; sleep 1; done; done &
    az aks scale -g $RESOURCE_GROUP -n $CLUSTER_NAME --node-count 6 &>/dev/null
    kill $!; trap 'kill $!' SIGTERM
    CLUSTER_URI="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query id -o tsv)"
    echo -e "\n\n************************************************************************\n"
    echo -e "\n--> Issue description: \n AKS cluster scale operation failed\n"
    echo -e "Cluster uri == ${CLUSTER_URI}\n"
}

function lab_scenario_1_validation () {
    CLUSTER_NAME=aks-crud-ex${LAB_SCENARIO}-${USER_ALIAS}
    RESOURCE_GROUP=aks-crud-ex${LAB_SCENARIO}-rg-${USER_ALIAS}
    LAB_TAG="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query tags -o yaml 2>/dev/null | grep aks-crud-lab | cut -d ' ' -f2 | tr -d "'")"
    echo -e "\n+++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo -e "--> Running validation for Lab scenario $LAB_SCENARIO\n"
    if [ -z $LAB_TAG ]
    then
        echo -e "\n--> Error: Cluster $CLUSTER_NAME in resource group $RESOURCE_GROUP was not created with this tool for lab $LAB_SCENARIO and cannot be validated...\n"
        exit 6
    elif [ $LAB_TAG -eq $LAB_SCENARIO ]
    then
        az aks get-credentials -g $RESOURCE_GROUP -n $CLUSTER_NAME --overwrite-existing &>/dev/null
        CLUSTER_RESOURCE_GROUP=$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query nodeResourceGroup -o tsv)
        NUMBER_OF_NODES="$(kubectl get no | grep ^aks | grep Ready | wc -l)"
        if [ "$NUMBER_OF_NODES" == "6" ]
        then
            echo -e "\n\n========================================================"
            echo -e "\nThe cluster $CLUSTER_NAME scale action looks good now\n"
        else
            echo -e "\nScenario $LAB_SCENARIO is still FAILED\n"
        fi
    else
        echo -e "\n--> Error: Cluster $CLUSTER_NAME in resource group $RESOURCE_GROUP was not created with this tool for lab $LAB_SCENARIO and cannot be validated...\n"
        exit 6
    fi
}
