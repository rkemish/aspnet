# ASP.NET Application - Architecture

## Overview

This is an ASP.NET Core MVC web application built on **.NET 10**. It follows the standard Model-View-Controller pattern, is containerised with Docker, and ships via a CI/CD pipeline on GitHub Actions to **GitHub Container Registry (ghcr.io)**.

## Technology Stack

| Layer | Technology |
|---|---|
| Framework | ASP.NET Core MVC (.NET 10) |
| Frontend | Razor Views, Bootstrap 5, jQuery |
| Testing | xUnit, Microsoft.AspNetCore.Mvc.Testing, Coverlet |
| Containerisation | Docker (multi-stage build) |
| CI/CD | GitHub Actions |
| Container Registry | GitHub Container Registry (ghcr.io) |
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
├── Program.cs                    # Application entry point and pipeline config
├── Dockerfile                    # Multi-stage container build
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

## CI/CD Pipeline

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

### Pipeline Jobs

| Job | Trigger | Purpose |
|---|---|---|
| **build-test** | Push & PR | Restore, build, run xUnit tests, upload code coverage |
| **docker** | Push to main (after build-test passes) | Build Docker image and push to `ghcr.io` |
| **security-analysis** | Push to main | Run Microsoft Security DevOps scanning |

### Container Image Tags

Each push to `main` publishes to `ghcr.io` with two tags:

| Tag | Example | Purpose |
|---|---|---|
| `sha-<hash>` | `sha-f4e93e8` | Pin deployments to a specific commit |
| `latest` | `latest` | Always points to the most recent build |

```bash
# Pull the latest image
docker pull ghcr.io/rkemish/aspnet:latest
```

## Testing Strategy

| Type | Project | Framework | Coverage |
|---|---|---|---|
| **Unit Tests** | `aspnet.Tests` | xUnit | Controller actions, model behaviour |
| **Integration Tests** | `aspnet.Tests` | xUnit + `WebApplicationFactory` | HTTP endpoint responses, routing |

Tests run automatically in CI with code coverage collection via Coverlet.
