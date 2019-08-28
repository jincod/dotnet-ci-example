#!/usr/bin/env bash

set -e

project_file=$1
project_name=$(basename $project_file .csproj)

package_version=$(cat $project_file | grep -oP '<PackageVersion>(.*)<\/PackageVersion>' | sed "s/<PackageVersion>\|<\/PackageVersion>//g")
status_code=$(curl -s -o /dev/null -I -w "%{http_code}" https://nuget.pkg.github.com/jincod/${project_name,,}/$package_version.json)

if [ $status_code = 200 ]; then
    echo "skip..."
else
    echo "publish..."
    dotnet pack $project_file --configuration Release --output "${PWD}"
    NUGET_CONFIG=`cat nuget.config`
    NUGET_CONFIG="${NUGET_CONFIG//GITHUB_TOKEN/$GITHUB_TOKEN}"
    echo $NUGET_CONFIG > nuget.config
    cat nuget.config
    dotnet nuget push *.nupkg -s https://nuget.pkg.github.com/jincod/index.json
fi