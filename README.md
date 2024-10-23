# Readme

```bash
export RESOURCE_GROUP="test-scaler-rg"
export LOCATION="East US"

az group create -n $RESOURCE_GROUP -l $LOCATION

az deployment group create -g $RESOURCE_GROUP \
    --query 'properties.outputs.*.value' \
    --template-file deploy.bicep
```
