#!/usr/bin/env bash
set -euo pipefail

NUGETTOKEN=""
DOCKER_IMAGE=""

while (( "$#" )); do
    case $1 in
        --nugettoken)
            shift && NUGETTOKEN="${1}"
            ;;
        --docker)
            shift && DOCKER_IMAGE="${1}"
            ;;
    esac

    shift || break
done

if [ ! -z "${NUGETTOKEN}" ]; then
    dotnet nuget update source "wayke-gh" --store-password-in-clear-text --configfile NuGet.Config -u "ourbjorn" -p "${NUGETTOKEN}"
fi

if [ ! -z ${NUGETTOKEN} ]; then
    git config --global url."https://${NUGETTOKEN}@github.com".insteadOf "https://github.com"
fi

SBOMFILE="sbom.csv"

GOPRIVATE=github.com/wayke-se/* go mod download
GOPRIVATE=github.com/wayke-se/* go install github.com/wayke-se/sbom-xpend@master

dotnet restore

dotnet tool install --global dotnet-project-licenses
dotnet-project-licenses --include-transitive -i . -j
cat licenses.json | sbom-xpend dotnetpl --append-to "${SBOMFILE}"

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
