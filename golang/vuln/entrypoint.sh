#!/usr/bin/env bash
set -euo pipefail

COLRED='\033[0;31m'
COLGREEN='\033[0;32m'
COLYELLOW='\033[0;33m'
COLDEFAULT='\033[0m'

GOPKGTOKEN=""
GOVULNCHECK_VERSION="latest"
SONATYPE_NANCY_VERSION="1.0.39"

while (( "$#" )); do
    case $1 in
        --gopkgtoken)
            shift && GOPKGTOKEN="${1}"
            ;;
        --govulncheck)
            shift && GOVULNCHECK_VERSION="${1}"
            ;;
        --nancy)
            shift && SONATYPE_NANCY_VERSION="${1}"
            ;;
    esac

    shift || break
done

if [ ! -z ${GOPKGTOKEN} ]; then
    git config --global url."https://${GOPKGTOKEN}@github.com".insteadOf "https://github.com"
fi

GOPRIVATE=github.com/wayke-se/* go mod download

echo "==> Installing/updating govulncheck@${GOVULNCHECK_VERSION}..."
go install golang.org/x/vuln/cmd/govulncheck@${GOVULNCHECK_VERSION}

echo "==> Running 'govulncheck'..."
if ! govulncheck ./...; then
    printf "\n${COLRED}[Failure]${COLDEFAULT} ${COLYELLOW}govulncheck${COLDEFAULT} found vulnerabilities.\n"
    exit 1
fi

if ! which nancy > /dev/null; then
    echo "==> Installing nancy@v${SONATYPE_NANCY_VERSION}..."
    curl -L https://github.com/sonatype-nexus-community/nancy/releases/download/v${SONATYPE_NANCY_VERSION}/nancy-v${SONATYPE_NANCY_VERSION}-linux-amd64 -o $(go env GOPATH)/bin/nancy
    chmod +x $(go env GOPATH)/bin/nancy
fi

if [[ $(nancy --version) != *"${SONATYPE_NANCY_VERSION}"* ]]; then
    echo "==> Updating to nancy@v${SONATYPE_NANCY_VERSION}..."
    curl -L https://github.com/sonatype-nexus-community/nancy/releases/download/v${SONATYPE_NANCY_VERSION}/nancy-v${SONATYPE_NANCY_VERSION}-linux-amd64 -o $(go env GOPATH)/bin/nancy
    chmod +x $(go env GOPATH)/bin/nancy
fi

echo "==> Running 'nancy'..."
if ! go list -m all | nancy sleuth; then
    printf "\n${COLRED}[Failure]${COLDEFAULT} ${COLYELLOW}nancy${COLDEFAULT} found vulnerabilities.\n"
    exit 1
fi

printf "\n${COLGREEN}[Success] ${COLDEFAULT}No vulnerabilities found!\n"
