#!/bin/bash

##
#  dns-deploy-utilities
#  Cron script
#
#  Author: Valérian Saliou https://valeriansaliou.name/
##

# Go to updir
ABSPATH=$(cd "$(dirname "$0")"; pwd)

# Proceed deployment
echo "Running crons..."

cd "$ABSPATH"

# Since dnssec-signzone outputs regular text to >stderr, we need to redirect it later on $rc code check
# Otherwise, cron will populate the dead.letter file w/ false positive >stderr content
output_str=$(./deploy.sh 2>&1)
rc=$?

if [[ $rc = 0 ]]; then
  >&1 echo "$output_str"

  echo "Crons successful."
else
  >&2 echo "$output_str"

  echo "Crons failed."
  rc=1
fi

echo "Done."

exit $rc
