FROM golang:alpine
WORKDIR /github/workspace

RUN apk update && \
    apk add --no-cache \
        alpine-sdk \
        bash \
        git \
        curl

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
