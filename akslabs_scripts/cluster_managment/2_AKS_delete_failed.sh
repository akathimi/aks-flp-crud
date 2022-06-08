#!/bin/bash
# Lab scenario 2
function lab_scenario_2 () {
    CLUSTER_NAME=aks-crud-ex${LAB_SCENARIO}-${USER_ALIAS}
    RESOURCE_GROUP=aks-crud-ex${LAB_SCENARIO}-rg-${USER_ALIAS}
    check_resourcegroup_cluster $RESOURCE_GROUP $CLUSTER_NAME

    echo -e "\n--> Deploying cluster for lab${LAB_SCENARIO}...\n"
    az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --location $LOCATION \
    --node-count 1 \
    --generate-ssh-keys \
    --tag aks-crud-lab=${LAB_SCENARIO} \
	--yes \
    -o table

    validate_cluster_exists $RESOURCE_GROUP $CLUSTER_NAME
    
    echo -e "\n\n--> Please wait while we are preparing the environment for you to troubleshoot...\n"
    MC_RESOURCE_GROUP=$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query nodeResourceGroup -o tsv)
    CLUSTER_URI="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query id -o tsv)"
    VNET_NAME="$(az network vnet list -g $MC_RESOURCE_GROUP --query "[0].name" --output tsv)"
    SUBNET_URI="$(az network vnet subnet list -g $MC_RESOURCE_GROUP --vnet-name $VNET_NAME --query "[0].id" --output tsv)"
    az network nic create --name test-nic -g $RESOURCE_GROUP --subnet $SUBNET_URI -o none
    az aks delete -g $RESOURCE_GROUP -n $CLUSTER_NAME --yes --no-wait

    echo -e "\n\n********************************************************"
    echo -e "\n--> Issue description: \n AKS cluster stuck in deleting status, need help to delete the cluster\n"
    echo -e "Cluster uri == ${CLUSTER_URI}\n"
}

function lab_scenario_2_validation () {
    CLUSTER_NAME=aks-crud-ex${LAB_SCENARIO}-${USER_ALIAS}
    RESOURCE_GROUP=aks-crud-ex${LAB_SCENARIO}-rg-${USER_ALIAS}
    echo -e "\n+++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo -e "--> Running validation for Lab scenario $LAB_SCENARIO\n"
    CLUSTER_EXIST=$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME &>/dev/null; echo $?)
    if [ $CLUSTER_EXIST -eq 0 ]
    then
        echo -e "\nScenario $LAB_SCENARIO is still FAILED\n"
    else
        echo -e "\nScenario $LAB_SCENARIO looks good, cluster $CLUSTER_NAME has been removed\n"
    fi
}
