# Azure Connect

This event is focused on showcasing how Azure can be used in a microservices-oriented project leveraging DevOps culture.

## Architecture

The application used for this event is a heavily modified and recreated version of the original [My Driving application](https://github.com/Azure-Samples/MyDriving).

The team environment consists of the following:

* App Service Plan (or Azure Kubernetes Service cluster) which has five applications deployed:

  * POI (Trip Points of Interest) - CRUD API written in .Net Core 2 for points of interest on trips
  * Trips - CRUD open API written in golang 1.11 for trips connected to the client application
  * UserProfile - CRUD open API written in Node.JS for the users of the client application
    > Note:PATCH/POST operations not functional
  * User-Java - API written in Java with POST and PATCH routes plus swagger docs routes for the users of the client application.
  * Trip Viewer - the frontend leveraging the 4 aforeamentioned APIs

## Getting Started

To understand each of the components above in more detail, please visit the readme files inside the root folder of each corresponding part of the application.

## Deploy the application

To create the necessary resources to see the application in action on Azure, please run the bash script in the folder **/deploy/deploy-application.azcli** which will create the following indicative resources:


| Azure resource           | Pricing tier/SKU       | Purpose                                 | Registered Resource Providers |
| ------------------------ | ---------------------- | --------------------------------------- | ----------------------------- |
| Azure Container Registry | Standard               | Private container registry              | Microsoft.ContainerRegistry   |
| Azure SQL Database       | Standard S2: 50 DTUs  | mydrivingDB                             | Microsoft.Sql                 |
| Azure Key Vault          | Standard               | Key vault for database secrets          | Microsoft.KeyVault            |
| App Service Plan         | Standard P2v3          | App Service Plan for all Azure Web Apps | NA                            |
| Application Insights         | -          | Application Performance Monitoring | NA                            |
| Azure Container Instance | 1 CPU core/1.5 GiB RAM | Simulator                               | Microsoft.ContainerInstance   |

### Prerequisites

It is useful but not required to have a basic knowledge of the following topics:

* Kubernetes / App Service
* GitHub or Azure DevOps
