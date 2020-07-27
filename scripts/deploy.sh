#!/usr/bin/env bash

set -e

project_file=$1
project_name=$(basename $project_file .csproj)

package_version=$(cat $project_file | grep -oP '<PackageVersion>(.*)<\/PackageVersion>' | sed "s/<PackageVersion>\|<\/PackageVersion>//g")
status_code=$(curl -s -o /dev/null -w "%{http_code}" https://$GITHUB_ACTOR:$GITHUB_TOKEN@nuget.pkg.github.com/$GITHUB_ACTOR/${project_name,,}/$package_version.json)

echo $package_version
echo $status_code

if [ $status_code = 200 ]; then
    echo "skip..."
else
    echo "publish..."
    dotnet pack $project_file --configuration Release --output "${PWD}"
    NUGET_CONFIG=`cat nuget.config`
    NUGET_CONFIG="${NUGET_CONFIG//GITHUB_TOKEN/$GITHUB_TOKEN}"
    NUGET_CONFIG="${NUGET_CONFIG//GITHUB_ACTOR/$GITHUB_ACTOR}"
    echo $NUGET_CONFIG > nuget.config
    dotnet nuget push *.nupkg -s GitHubPackageRegistry
fi