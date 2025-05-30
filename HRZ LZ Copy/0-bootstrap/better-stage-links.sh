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

FILES="\
  providers/0-bootstrap-providers.tf \
  0-bootstrap.auto.tfvars"

if [ "$#" -ne 1 ]; then
    echo "No configuration specified"
    exit 1
fi

REPOSITORY=${1}
CMD="ln -s ../$REPOSITORY/"

# Construct the command
COMMANDS="rm -rf .terraform"
for f in $FILES; do
  COMMANDS+="; rm -rf $(basename $f)"
done

for f in $FILES; do
  COMMANDS+="; $CMD$f ./"
done

# Execute the commands
# echo "$COMMANDS"
eval "$COMMANDS"
