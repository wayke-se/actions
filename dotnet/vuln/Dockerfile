FROM mcr.microsoft.com/dotnet/sdk:6.0-alpine
WORKDIR /github/workspace

RUN apk update && \
    apk add --no-cache \
        alpine-sdk \
        bash

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
