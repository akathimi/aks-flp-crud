#!/bin/bash
# Lab scenario 3
function lab_scenario_3 () {
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
    az aks get-credentials -g $RESOURCE_GROUP -n $CLUSTER_NAME --overwrite-existing &>/dev/null

cat <<EOF | kubectl apply -f &>/dev/null -
kind: Deployment
apiVersion: apps/v1
metadata:
  name: mypod
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mypod
  template:
    metadata:
      labels:
        app: mypod
    spec:
      containers:
      - name: mypod
        image: nginx:latest
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 250m
            memory: 256Mi
---
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: mypod-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: mypod
EOF

    CLUSTER_URI="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query id -o tsv)"
    UPGRADE_VERSION="$(az aks get-upgrades -g $RESOURCE_GROUP -n $CLUSTER_NAME --output table | grep $RESOURCE_GROUP | awk '{print $4}' | tr -d ',')"
    while true; do for s in / - \\ \|; do printf "\r$s"; sleep 1; done; done &
    az aks upgrade -g $RESOURCE_GROUP -n $CLUSTER_NAME --kubernetes-version $UPGRADE_VERSION --yes &>/dev/null
    kill $!; trap 'kill $!' SIGTERM
    echo -e "\n\n********************************************************"
    echo -e "\n--> Issue description: \nCluster upgrade failed\n"
    echo -e "\nCluster uri == ${CLUSTER_URI}\n"
}

function lab_scenario_3_validation () {
    CLUSTER_NAME=aks-crud-ex${LAB_SCENARIO}-${USER_ALIAS}
    RESOURCE_GROUP=aks-crud-ex${LAB_SCENARIO}-rg-${USER_ALIAS}
    
    LAB_TAG="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query tags -o yaml 2>/dev/null | grep aks-crud-lab | cut -d ' ' -f2 | tr -d "'")"
    echo -e "\n+++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo -e "--> Running validation for Lab scenario $LAB_SCENARIO\n"
    if [ -z $LAB_TAG ]
    then
        echo -e "\n--> Error: Cluster $CLUSTER_NAME in resource group $RESOURCE_GROUP was not created with this tool for lab $LAB_SCENARIO and cannot be validated...\n"
        exit 6
    elif [ $LAB_TAG -eq $LAB_SCENARIO ]
    then
        CLUSTER_STATUS="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query provisioningState -o tsv)"
        if [ "$CLUSTER_STATUS" == 'Succeeded' ]
        then
            echo -e "\n\n========================================================"
            echo -e "\nThe Cluster $CLUSTER_NAME looks good now\n"
        else
            echo -e "\nScenario $LAB_SCENARIO is still FAILED\n"
        fi
    else
        echo -e "\n--> Error: Cluster $CLUSTER_NAME in resource group $RESOURCE_GROUP was not created with this tool for lab $LAB_SCENARIO and cannot be validated...\n"
        exit 6
    fi
}

