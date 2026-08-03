extension radius

param environment string

@secure()
param mysqlPassword string

resource todoApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'todo-app'
  properties: {
    environment: environment
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
    tag: '55680777bc46c59d3fe0ab9ff7e79ee947d0c757'
    build: {
      source: 'git::https://github.com/AzureMike/getting-started-todo-app.git?ref=55680777bc46c59d3fe0ab9ff7e79ee947d0c757'
      platforms: [
        'linux/amd64'
      ]
    }
  }
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
