#!/bin/bash
#
# Copyright (c) 2020 Reficio (TM) - Reestablish your software! All Rights Reserved.
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e
set -o pipefail

# Trap not-normal exit signals: 1/HUP, 2/INT, 3/QUIT, 15/TERM
trap catch_sig 1 2 3 15
# Trap errors (simple commands exiting with a non-zero status)
trap 'catch_err ${LINENO}' ERR

function clean_exit {
  echo "Exiting - version state may be inconsistent!"
  exit $1
}

function catch_err() {
  local PARENT_LINENO="$1"
  local MESSAGE="$2"
  local CODE="${3:-1}"
  if [[ -n "$MESSAGE" ]] ; then
    echo "Error on or near line ${PARENT_LINENO}: ${MESSAGE}; exiting with status ${CODE}"
  else
    echo "Error on or near line ${PARENT_LINENO}; exiting with status ${CODE}"
  fi
  clean_exit "${CODE}"
}

function catch_sig() {
    local exit_status=$?
    clean_exit $exit_status
}

if [ $# -ne 3 ]; then
  echo "Usage: release.sh <current_version> <release_version> <new_version>"
  exit 1
fi

current_version=$1
release_version=$2
new_version=$3

find . \( -name "pom.xml" -or -name "README.md" \) -not -path "*/src/it/*" -not -path "*/target/*" -not -path "*svn*" -not -path "*git*" -exec sed -i "" "s#<version>$current_version</version>#<version>$release_version</version>#g" {} \;
find . \( -name "pom.xml" -or -name "README.md" \) -not -path "*/src/it/*" -not -path "*/target/*" -not -path "*svn*" -not -path "*git*" -exec sed -i "" "s#projects.reficio.org/p2-maven-plugin/$current_version#projects.reficio.org/p2-maven-plugin/$release_version#g" {} \;
git commit -a -m "$release_version release"
git tag -a v$release_version -a -m "$release_version release"

find . \( -name "pom.xml" -or -name "README.md" \) -not -path "*/src/it/*" -not -path "*/target/*" -not -path "*svn*" -not -path "*git*" -exec sed -i "" "s#<version>$release_version</version>#<version>$new_version</version>#g" {} \;
find . \( -name "pom.xml" -or -name "README.md" \) -not -path "*/src/it/*" -not -path "*/target/*" -not -path "*svn*" -not -path "*git*" -exec sed -i "" "s#projects.reficio.org/p2-maven-plugin/$release_version#projects.reficio.org/p2-maven-plugin/$new_version#g" {} \;
git commit -a -m "Preparing $new_version iteration"

git push
git push origin v$release_version
