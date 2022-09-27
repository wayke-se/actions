#!/usr/bin/env bash
set -euo pipefail

COLRED='\033[0;31m'
COLGREEN='\033[0;32m'
COLYELLOW='\033[0;33m'
COLDEFAULT='\033[0m'

DOCKER_IMAGE=""

while (( "$#" )); do
    case $1 in
        --docker)
            shift && DOCKER_IMAGE="${1}"
            ;;
    esac

    shift || break
done

if [ ! -z ${DOCKER_IMAGE} ]; then
    BINDIR="$(pwd)/bin"
    EXEC="grype"

    mkdir -p "${BINDIR}"
    if ! which ${EXEC} > /dev/null; then
        curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b ${BINDIR}
        EXEC="${BINDIR}/grype"
    fi

    ${EXEC} -f Medium --add-cpes-if-none ${DOCKER_IMAGE}
    if [ $? -ne 0 ]; then
        printf "\n${COLRED}[Failure]${COLDEFAULT} ${COLYELLOW}grype${COLDEFAULT} found vulnerabilities.\n"
        exit 1
    fi
fi

printf "\n${COLGREEN}[Success] ${COLDEFAULT}No vulnerabilities found!\n"
