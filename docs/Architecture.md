# ASP.NET Application - Architecture

## Overview

This is an ASP.NET Core MVC web application built on **.NET 10**. It follows the standard Model-View-Controller pattern, is containerised with Docker, and deploys to **Azure App Service** via a blue-green deployment strategy with infrastructure managed by **Bicep**.

## Technology Stack

| Layer | Technology |
|---|---|
| Framework | ASP.NET Core MVC (.NET 10) |
| Frontend | Razor Views, Bootstrap 5, jQuery |
| Testing | xUnit, Microsoft.AspNetCore.Mvc.Testing, Coverlet |
| Containerisation | Docker (multi-stage build) |
| CI/CD | Azure DevOps Pipelines, GitHub Actions |
| Container Registry | Azure Container Registry, GitHub Container Registry |
| Infrastructure as Code | Bicep |
| Hosting | Azure App Service (Linux Containers) |
| Deployment Strategy | Blue-green (deployment slots) |
| Security Scanning | Microsoft Security DevOps |

## Application Architecture

::: mermaid
graph TB
    subgraph Client
        Browser[Browser]
    end

    subgraph "ASP.NET Core MVC"
        MW[Middleware Pipeline]
        Router[Routing]
        HC[HomeController]
        Views[Razor Views]
        Models[Models]
        Static[Static Assets<br/>wwwroot]
    end

    Browser -->|HTTP Request| MW
    MW --> Router
    Router --> HC
    HC --> Models
    HC --> Views
    Views -->|HTML Response| Browser
    Browser -->|CSS / JS| Static
:::

## MVC Component Map

::: mermaid
graph LR
    subgraph Controllers
        HC[HomeController]
    end

    subgraph Actions
        HC --> Index["Index()"]
        HC --> Privacy["Privacy()"]
        HC --> Error["Error()"]
    end

    subgraph Views
        Index --> VI["Views/Home/Index.cshtml"]
        Privacy --> VP["Views/Home/Privacy.cshtml"]
        Error --> VE["Views/Shared/Error.cshtml"]
    end

    subgraph Shared
        VI --> Layout["_Layout.cshtml"]
        VP --> Layout
        VE --> Layout
    end

    subgraph Models
        Error --> EVM["ErrorViewModel"]
    end
:::

## Middleware Pipeline

The request pipeline is configured in `Program.cs` and executes in the following order:

::: mermaid
graph LR
    A[Request] --> B[Exception Handler<br/>prod only]
    B --> C[HSTS]
    C --> D[HTTPS Redirect]
    D --> E[Static Files]
    E --> F[Routing]
    F --> G[Authorization]
    G --> H[Controller<br/>Endpoint]
    H --> I[Response]
:::

## Project Structure

```
aspnet/
├── Controllers/
│   └── HomeController.cs        # Main controller with Index, Privacy, Error actions
├── Models/
│   └── ErrorViewModel.cs        # Error page view model
├── Views/
│   ├── Home/
│   │   ├── Index.cshtml          # Home page
│   │   └── Privacy.cshtml        # Privacy page
│   └── Shared/
│       ├── _Layout.cshtml        # Main layout template (Bootstrap 5)
│       ├── _ValidationScriptsPartial.cshtml
│       └── Error.cshtml          # Error page
├── wwwroot/                      # Static assets (CSS, JS, libraries)
├── aspnet.Tests/                 # Unit and integration test project
│   ├── Controllers/
│   │   └── HomeControllerTests.cs
│   ├── Models/
│   │   └── ErrorViewModelTests.cs
│   └── IntegrationTests.cs
├── infra/
│   ├── main.bicep                # Azure infrastructure (ACR, App Service, slots)
│   └── main.bicepparam           # Bicep parameter values
├── Program.cs                    # Application entry point and pipeline config
├── Dockerfile                    # Multi-stage container build
├── azure-pipelines.yml           # Azure DevOps CI pipeline (build, test, Docker push)
├── azure-pipelines-release.yml   # Azure DevOps release pipeline (deploy, approve, swap)
├── appsettings.json              # Application configuration
└── aspnet.csproj                 # Project file (.NET 10)
```

## Docker Build

The application uses a multi-stage Docker build to keep the final image small.

::: mermaid
graph LR
    subgraph "Stage 1 – Build"
        SDK["dotnet/sdk:10.0"]
        Restore["dotnet restore"]
        Publish["dotnet publish -c Release"]
        SDK --> Restore --> Publish
    end

    subgraph "Stage 2 – Runtime"
        RT["dotnet/aspnet:10.0"]
        App["aspnet.dll"]
        RT --> App
    end

    Publish -->|COPY /app/publish| App
:::

| Image | Purpose | Approximate Size |
|---|---|---|
| `mcr.microsoft.com/dotnet/sdk:10.0` | Build & publish | ~900 MB |
| `mcr.microsoft.com/dotnet/aspnet:10.0` | Runtime only | ~220 MB |

### Build and Run Locally

```bash
# Build the image
docker build -t aspnet-app .

# Run on port 5278
docker run -d -p 5278:8080 --name aspnet-app aspnet-app
```

The container listens on port **8080** internally (ASP.NET Core default in containers).

## Azure Infrastructure (Bicep)

The infrastructure is defined as code using Bicep templates in `infra/`.

::: mermaid
graph TB
    subgraph "Azure Resource Group"
        ACR["Azure Container Registry<br/>(Basic SKU)"]
        ASP["App Service Plan<br/>(Linux, Standard S1)"]
        WA["Web App<br/>(Linux Container)"]
        SLOT["Staging Slot"]
        ASP --> WA
        ASP --> SLOT
        ACR -->|Pull image| WA
        ACR -->|Pull image| SLOT
    end
:::

### Resources Provisioned

| Resource | Type | Purpose |
|---|---|---|
| **Azure Container Registry** | `Microsoft.ContainerRegistry/registries` | Stores Docker images |
| **App Service Plan** | `Microsoft.Web/serverfarms` | Linux plan (S1+ required for slots) |
| **Web App** | `Microsoft.Web/sites` | Production container host |
| **Staging Slot** | `Microsoft.Web/sites/slots` | Blue-green deployment target |

### Bicep Parameters

| Parameter | Default | Description |
|---|---|---|
| `appName` | `aspnet-app` | Base name for all resources |
| `acrName` | `aspnetappcr` | Container registry name |
| `appServicePlanSku` | `S1` | Plan SKU (must support slots) |
| `containerImageTag` | `latest` | Image tag to deploy |
| `location` | Resource group location | Azure region |

## CI/CD Pipelines

### GitHub Actions (CI)

::: mermaid
graph LR
    subgraph "Trigger"
        Push["Push to main"]
        PR["Pull Request"]
    end

    subgraph "build-test"
        Restore["Restore"]
        Build["Build"]
        Test["Test + Coverage"]
    end

    subgraph "docker"
        Login["GHCR Login"]
        DBuild["Docker Build"]
        DPush["Push Image"]
    end

    subgraph "security-analysis"
        MSDO["Microsoft Security<br/>DevOps"]
    end

    Push --> Restore
    PR --> Restore
    Restore --> Build --> Test
    Test -->|main only| Login --> DBuild --> DPush
    Push -->|main only| MSDO
:::

### Azure DevOps CI Pipeline (`azure-pipelines.yml`)

Triggered on every push to `main`. Builds, tests, and pushes the Docker image to ACR.

::: mermaid
graph LR
    subgraph "Trigger"
        Push["Push to main"]
        PR["Pull Request"]
    end

    subgraph "BuildTest"
        Restore["Restore"]
        Build["Build"]
        Test["Test + Coverage"]
        SEC["Security Analysis"]
    end

    subgraph "DockerBuildPush"
        Login["ACR Login"]
        DBuild["Docker Build"]
        DPush["Push Image"]
    end

    Push --> Restore
    PR --> Restore
    Restore --> Build --> Test
    Test -->|main only| SEC
    Test -->|main only| Login --> DBuild --> DPush
:::

### Azure DevOps Release Pipeline (`azure-pipelines-release.yml`)

Automatically triggered by a successful CI pipeline run on `main`. Provisions infrastructure, deploys to staging, and swaps to production after manual approval.

::: mermaid
graph LR
    subgraph "Trigger"
        CI["CI Pipeline<br/>completed ✓"]
    end

    subgraph "Infrastructure"
        BICEP["Deploy Bicep<br/>Templates"]
    end

    subgraph "DeployStaging (Blue)"
        STAGING["Deploy to<br/>Staging Slot"]
        HEALTH1["Health Check"]
    end

    subgraph "Approval Gate"
        APPROVE["Manual<br/>Approval"]
    end

    subgraph "SwapToProduction (Green)"
        SWAP["Swap Slots<br/>Staging → Production"]
        HEALTH2["Health Check"]
    end

    CI --> BICEP --> STAGING --> HEALTH1
    HEALTH1 --> APPROVE --> SWAP --> HEALTH2
:::

### CI Pipeline Stages

| Stage | File | Condition | Description |
|---|---|---|---|
| **BuildTest** | `azure-pipelines.yml` | Always | Restore, build, run tests, publish coverage, security scan |
| **DockerBuildPush** | `azure-pipelines.yml` | Main only, after BuildTest | Build Docker image and push to ACR |

### Release Pipeline Stages

| Stage | File | Environment | Description |
|---|---|---|---|
| **Infrastructure** | `azure-pipelines-release.yml` | — | Deploy Bicep templates (ACR, App Service, slot) |
| **DeployStaging** | `azure-pipelines-release.yml` | `staging` | Deploy new container image to staging slot, run health check |
| **SwapToProduction** | `azure-pipelines-release.yml` | `production` | Manual approval gate, swap staging → production, verify health |

### Pipeline Trigger Chain

::: mermaid
sequenceDiagram
    participant Dev as Developer
    participant CI as CI Pipeline
    participant CD as Release Pipeline
    participant Staging as Staging Slot (Blue)
    participant Prod as Production (Green)
    participant Approver as Approver

    Dev->>CI: Push to main
    CI->>CI: Build & Test
    CI->>CI: Build Docker image → ACR
    CI-->>CD: Trigger (pipeline resource)
    CD->>CD: Provision infrastructure (Bicep)
    CD->>Staging: Deploy new image
    CD->>Staging: Health check (up to 5 min)
    CD->>Approver: Request manual approval
    Approver->>CD: Approve
    CD->>Prod: Swap slots (Staging ↔ Production)
    CD->>Prod: Health check
    Note over Staging,Prod: Rollback: swap slots again
:::

### Variable Group: `deployment-details`

The pipeline reads deployment configuration from the `deployment-details` variable group in Azure DevOps. Create this under **Pipelines → Library**.

| Variable | Example | Description |
|---|---|---|
| `azureSubscription` | `my-azure-connection` | Azure DevOps service connection name |
| `resourceGroupName` | `rg-aspnet-app` | Target resource group |
| `webAppName` | `aspnet-app` | Azure Web App name |
| `acrName` | `aspnetappcr` | Azure Container Registry name |
| `acrServiceConnection` | `my-acr-connection` | Docker registry service connection |
| `location` | `uksouth` | Azure region |

### Environment Approval Setup

To enable the manual approval gate, configure the `production` environment in Azure DevOps:

1. Navigate to **Pipelines → Environments**
2. Create an environment named `production`
3. Click **Approvals and checks** → **Add check** → **Approvals**
4. Add the required approvers

The `staging` environment does not require approval — it deploys automatically.

## Container Image Tags

Each build publishes to ACR with two tags:

| Tag | Example | Purpose |
|---|---|---|
| `$(Build.BuildId)` | `456` | Pin to a specific pipeline run |
| `latest` | `latest` | Always points to the most recent build |

## Testing Strategy

| Type | Project | Framework | Coverage |
|---|---|---|---|
| **Unit Tests** | `aspnet.Tests` | xUnit | Controller actions, model behaviour |
| **Integration Tests** | `aspnet.Tests` | xUnit + `WebApplicationFactory` | HTTP endpoint responses, routing |

Tests run automatically in CI with code coverage collection via Coverlet.
