FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Restore dependencies as a separate layer for caching
COPY aspnet.csproj ./
RUN dotnet restore aspnet.csproj

# Copy everything else and publish
COPY . ./
RUN dotnet publish aspnet.csproj -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish .

EXPOSE 8080

ENTRYPOINT ["dotnet", "aspnet.dll"]
