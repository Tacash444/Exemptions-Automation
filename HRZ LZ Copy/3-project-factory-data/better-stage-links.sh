#!/bin/bash
# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. 
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.



if [ "$#" -ne 2 ]; then
    echo "${0} <configuration> <subunit>"
    exit 1
fi

REPOSITORY=${1:hrz-configs}
SUBUNIT=${2}
CMD="ln -s ../$REPOSITORY/"

FILES=(
  tfvars/0-globals.auto.tfvars.json
  tfvars/0-bootstrap.auto.tfvars.json
  tfvars/1-resman.auto.tfvars.json
  tfvars/2-security.auto.tfvars.json
  tfvars/2-shared-projects.auto.tfvars.json
)

NET_FILES=(
  tfvars/2-networking-research.auto.tfvars.json
)

PF_FILES=(
  providers/3-pf-${SUBUNIT}-dat-providers.tf
  3-pf-${SUBUNIT}-dat.auto.tfvars
)

# Construct the command string
COMMANDS="rm -rf .terraform"
for f in "${FILES[@]}" ; do
  COMMANDS+="; unlink $(basename "$f")"
done

# other configs
for f in "${FILES[@]}" ; do
  COMMANDS+="; $CMD$f ./"
done

# net files
for file in $(find . -type l -name "2-networking*"); do
    COMMANDS+="; unlink $(basename "$file")"
done

for f in "${NET_FILES[@]}" ; do
  COMMANDS+="; $CMD$f ./"
done

# pf files
for file in $(find . -type l -name "3-pf*"); do
    COMMANDS+="; unlink $(basename "$file")"
done

for f in "${PF_FILES[@]}" ; do
  COMMANDS+="; $CMD$f ./"
done

# Execute the commands
# echo "$COMMANDS"
eval "$COMMANDS"
