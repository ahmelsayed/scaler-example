FROM mcr.microsoft.com/dotnet/sdk:8.0 AS runtime-image

COPY . /src
RUN cd src && \
    dotnet publish *.csproj --output /output

FROM mcr.microsoft.com/dotnet/aspnet:8.0

COPY --from=runtime-image ["/output", "/output"]

CMD ["dotnet", "/output/ExternalScalerSample.dll"]
