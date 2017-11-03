#!/bin/bash
set -ex

if [ -z "$GITHUB_USER" ]; then
  echo "Env var GITHUB_USER not defined and needed to git push the new version."
  exit -1
fi

if [ -z "$GITHUB_TOKEN" ]; then
  echo "Env var GITHUB_TOKEN not defined and needed to git push the new version."
  exit -1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
MAJOR=`grep "%global major_version" $DIR/tomcat.spec |sed 's/.* //g' `
MINOR=`grep "%global minor_version" $DIR/tomcat.spec |sed 's/.* //g' `
RELEASE=`grep "Release:" $DIR/tomcat.spec |sed 's/Release: *\([0-9]*\).*/\1/g'`

echo "Scrap tomcat website and fetch the version"
MICRO=`curl -s http://www.apache.org/dist/tomcat/tomcat-$MAJOR/ |grep -e "<a href=\"v[0-9]\.$MINOR" |sed "s#.*v$MAJOR\.$MINOR\.\([0-9]*\).*#\1#g" |head -n 1`
VERSION="$MAJOR.$MINOR.$MICRO"

echo "Update specfile with new version $VERSION"
sed -i "s/%global micro_version .*/%global micro_version $MICRO/g" $DIR/tomcat.spec

echo "Check if version $VERSION is already commited"
curl -s -f --user "$GITHUB_USER:$GITHUB_TOKEN" https://api.github.com/repos/$TRAVIS_REPO_SLUG/branches |grep name | grep "v$VERSION" && exit 0
git diff --exit-code && exit 0

echo "Download new sources"
rm -f *.tar.gz
docker build -t rpmbuilder .release/
docker run -w /mnt -it -v `pwd`:/mnt rpmbuilder spectool -g *.spec
md5sum *.tar.gz > sources
git add -A

echo "Create branch v$VERSION"
git checkout -b "v$VERSION"
git commit -am "Update to $VERSION"

echo "Commit changelog"
docker run -w /mnt -it -v `pwd`:/mnt rpmbuilder tito tag --accept-auto-changelog --keep-version

echo "Push branch v$VERSION"
NAME=`git remote -v |sed 's#.*/##'|sed 's/ .*//g'|sed 's/\.git//g'|head -n1` 
git remote set-url origin "https://$GITHUB_USER:$GITHUB_TOKEN@github.com/$TRAVIS_REPO_SLUG.git"
git push --set-upstream origin "v$VERSION"

echo "Create new Merge Request"
curl -s -f --user "$GITHUB_USER:$GITHUB_TOKEN" --request POST --data "{ \"title\": \"New version $VERSION\", \"body\": \"A new release is available $VERSION\n\nOnce merged don't forget to create the tag \`tomcat-$VERSION-$RELEASE\`\", \"head\": \"v$VERSION\", \"base\": \"$TRAVIS_BRANCH\" }" https://api.github.com/repos/$TRAVIS_REPO_SLUG/pulls
