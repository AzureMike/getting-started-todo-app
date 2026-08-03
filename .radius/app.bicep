extension radius

param environment string

@secure()
param mysqlPassword string

@secure()
param registryUsername string

@secure()
param registryPassword string

resource todoApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'todo-app'
  properties: {
    environment: environment
  }
}

resource registryCreds 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'radius-ghcr-registry-creds'
  properties: {
    environment: environment
    application: todoApp.id
    data: {
      username: {
        value: registryUsername
      }
      password: {
        value: registryPassword
      }
    }
  }
}

resource mysqlDb 'Radius.Data/mySqlDatabases@2025-08-01-preview' = {
  name: 'todomysql${uniqueString(environment)}'
  properties: {
    environment: environment
    application: todoApp.id
    version: '8.0'
    database: 'todos'
    username: 'myadmin'
    password: mysqlPassword
  }
}

resource backendImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'todo-app-backend-image'
  properties: {
    environment: environment
    application: todoApp.id
    tag: '3d8d55accd3c130c9258df30674c6a180ee0d3f6'
    build: {
      source: 'git::https://github.com/AzureMike/getting-started-todo-app.git?ref=3d8d55accd3c130c9258df30674c6a180ee0d3f6'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource backendContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'todo-app-backend'
  properties: {
    environment: environment
    application: todoApp.id
    containers: {
      backend: {
        image: backendImage.properties.imageReference
        ports: {
          web: {
            containerPort: 3000
          }
        }
        env: {
          MYSQL_HOST: {
            value: mysqlDb.properties.host
          }
          MYSQL_USER: {
            value: 'myadmin'
          }
          MYSQL_PASSWORD: {
            value: mysqlPassword
          }
          MYSQL_DB: {
            value: 'todos'
          }
          MYSQL_SSL: {
            value: 'true'
          }
        }
      }
    }
    connections: {
      mysqldb: {
        source: mysqlDb.id
        disableDefaultEnvVars: true
      }
    }
  }
}
