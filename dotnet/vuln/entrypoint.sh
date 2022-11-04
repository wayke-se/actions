#!/usr/bin/env bash
set -euo pipefail

COLRED='\033[0;31m'
COLGREEN='\033[0;32m'
COLYELLOW='\033[0;33m'
COLDEFAULT='\033[0m'

NUGETTOKEN=""

while (( "$#" )); do
    case $1 in
        --nugettoken)
            shift && NUGETTOKEN="${1}"
            ;;
    esac

    shift || break
done

if [ ! -z "${NUGETTOKEN}" ]; then
    dotnet nuget update source "wayke-gh" --store-password-in-clear-text --configfile NuGet.Config -u "ourbjorn" -p "${NUGETTOKEN}"
fi
dotnet restore

echo "==> Running vulnerability scanner..."
RESULT=$(dotnet list package --vulnerable --include-transitive)
if test $(echo "${RESULT}" | grep -cm 1 "following vulnerable packages") -ne 0; then
    echo "${RESULT}"
    printf "\n${COLRED}[Failure]${COLDEFAULT} ${COLYELLOW}dotnet${COLDEFAULT} found vulnerabilities.\n"
    exit 1
fi

printf "\n${COLGREEN}[Success]${COLDEFAULT} No vulnerabilities found!\n"
