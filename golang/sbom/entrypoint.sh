#!/usr/bin/env bash
set -euo pipefail

GOPKGTOKEN=""
DOCKER_IMAGE=""

while (( "$#" )); do
    case $1 in
        --gopkgtoken)
            shift && GOPKGTOKEN="${1}"
            ;;
        --docker)
            shift && DOCKER_IMAGE="${1}"
            ;;
    esac

    shift || break
done

if [ ! -z ${GOPKGTOKEN} ]; then
    git config --global url."https://${GOPKGTOKEN}@github.com".insteadOf "https://github.com"
fi

SBOMFILE="sbom.csv"

GOPRIVATE=github.com/wayke-se/* go mod download
GOPRIVATE=github.com/wayke-se/* go install github.com/wayke-se/sbom-xpend@master
go install github.com/ourstudio-se/lct@master

go mod graph | lct gomod --json | sbom-xpend lct --append-to "${SBOMFILE}"

if [ ! -z ${DOCKER_IMAGE} ]; then
    BINDIR="$(pwd)/bin"
    EXEC="syft"

    mkdir -p "${BINDIR}"
    if ! which ${EXEC} > /dev/null; then
        curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b ${BINDIR}
        EXEC="${BINDIR}/syft"
    fi

    ${EXEC} --scope=all-layers ${DOCKER_IMAGE} -o json | sbom-xpend syft --append-to "${SBOMFILE}"
fi

REFNAME="${GITHUB_SHA}"
if [ "${GITHUB_REF_NAME}" = "master" ] || [ "${GITHUB_REF_NAME}" = "main" ]; then
    REFNAME="${GITHUB_REF_NAME}"
fi

curl \
    -F repository_name="$(echo ${GITHUB_REPOSITORY} | awk -F / '{print $2}')" \
    -F version_name="${REFNAME}" \
    -F updated_by="${GITHUB_ACTOR}" \
    -F sbom-xpend=@"${SBOMFILE}" \
    https://sbom-xpend.wayketech.se/api/x
