targetScope = 'resourceGroup'
param location string = resourceGroup().location

resource appEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'aca-env'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'azure-monitor'
    }
    workloadProfiles: [
      {
        name: 'consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

resource scaler 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'scaler'
  location: location
  properties: {
    environmentId: appEnv.id
    workloadProfileName: 'consumption'
    configuration: {
      ingress: {
        external: false
        targetPort: 5000
        transport: 'http2'
        allowInsecure: true
      }
    }
    template: {
      containers: [
        {
          name: 'earthquake-scaler'
          image: 'docker.io/ahmelsayed/scaler:latest'
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

resource app 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'webapp'
  location: location
  properties: {
    environmentId: appEnv.id
    workloadProfileName: 'consumption'
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'http'
      }
    }
    template: {
      containers: [
        {
          name: 'sample'
          image: 'mcr.microsoft.com/dotnet/samples:aspnetapp'
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 5
        rules: [
          {
            name: 'earthquake-scaler'
            custom: {
              type: 'external'
              metadata: {
                scalerAddress: '${scaler.properties.configuration.ingress.fqdn}:80'
                longitude: '-122.335167'
                latitude: '47.608013'
              }
            }
          }
        ]
      }
    }
  }
}

output appUrl string = 'https://${app.properties.configuration.ingress.fqdn}'
output appId string = app.id
output latestCreatedRevision string = app.properties.latestRevisionName
output latestCreatedRevisionId string = '${app.id}/revisions/${app.properties.latestRevisionName}'
output latestReadyRevision string = app.properties.latestReadyRevisionName
output latestReadyRevisionId string = '${app.id}/revisions/${app.properties.latestReadyRevisionName}'
output azAppLogs string = 'az containerapp logs show -n ${app.name} -g ${resourceGroup().name} --revision ${app.properties.latestRevisionName} --follow --tail 30'
output azAppExec string = 'az containerapp exec -n ${app.name} -g ${resourceGroup().name} --revision ${app.properties.latestRevisionName} --command /bin/bash'
output azShowRevision string = 'az containerapp revision show -n ${app.name} -g ${resourceGroup().name} --revision ${app.properties.latestRevisionName}'

output scalerUrl string = 'https://${scaler.properties.configuration.ingress.fqdn}'
output scalerId string = app.id
output scalerLatestCreatedRevision string = scaler.properties.latestRevisionName
output scalerLatestCreatedRevisionId string = '${scaler.id}/revisions/${scaler.properties.latestRevisionName}'
output scalerLatestReadyRevision string = scaler.properties.latestReadyRevisionName
output scalerLatestReadyRevisionId string = '${scaler.id}/revisions/${scaler.properties.latestReadyRevisionName}'
output azScalerAppLogs string = 'az containerapp logs show -n ${scaler.name} -g ${resourceGroup().name} --revision ${scaler.properties.latestRevisionName} --follow --tail 30'
output azScalerAppExec string = 'az containerapp exec -n ${scaler.name} -g ${resourceGroup().name} --revision ${scaler.properties.latestRevisionName} --command /bin/bash'
output azScalerShowRevision string = 'az containerapp revision show -n ${scaler.name} -g ${resourceGroup().name} --revision ${scaler.properties.latestRevisionName}'
