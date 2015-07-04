#!/bin/bash

##
#  dns-deploy-utilities
#  Deployment script
#
#  Author: Valérian Saliou https://valeriansaliou.name/
##

# Go to updir
ABSPATH=$(cd "$(dirname "$0")"; pwd)
BASE_DIR="$ABSPATH/../"

# Proceed deployment
echo "Deploying..."

cd "$BASE_DIR"

# Cleanup
if [[ -d "$BASE_DIR/tmp/zones" ]]; then
  rm -r "$BASE_DIR/tmp/zones"
fi

# Check for configuration errors
echo "Checking configuration..."

named-checkconf
rc=$?

if [[ $rc = 0 ]]; then
  echo "Configuration test passed."

  # Sign zones (DNSSEC)
  sign_rc=0
  echo "Signing zones..."

  mkdir "$BASE_DIR/tmp/zones"

  for cur_domain_dir in ./conf/zones/*/
  do
    cur_domain=$(basename "$cur_domain_dir")

    echo "Validating zone: $cur_domain..."

    named-checkzone "$cur_domain" "$BASE_DIR/conf/zones/$cur_domain/db"
    cur_check_rc=$?

    if [[ $cur_check_rc = 0 ]]; then
      echo "Validated zone: $cur_domain"
      echo "Signing zone: $cur_domain..."

      if [[ ! -d "$BASE_DIR/tmp/zones/$cur_domain" ]]; then
        mkdir "$BASE_DIR/tmp/zones/$cur_domain"
      fi

      cd "$BASE_DIR/tmp/zones/$cur_domain"

      SALT=$(head -c 1000 /dev/random | sha1sum | cut -b 1-16)

      dnssec-signzone -3 "$SALT" -A -N INCREMENT -o "$cur_domain" -f db.signed -K "$BASE_DIR/keys/$cur_domain/" "$BASE_DIR/conf/zones/$cur_domain/db"
      cur_sign_rc=$?

      if [[ $cur_sign_rc = 0 ]]; then
        echo "Signed zone: $cur_domain"
      else
        echo "Could not sign zone: $cur_domain"
        sign_rc=1
      fi
    else
      echo "Could not validate zone: $cur_domain"
      sign_rc=1
    fi
  done

  cd "$BASE_DIR"

  if [[ $sign_rc = 0 ]]; then
    echo "Done signing zones."

    # Merge temporary zones to final zones
    if [[ -d "$BASE_DIR/build/zones" ]]; then
      rm -r "$BASE_DIR/build/zones"
    fi

    mv "$BASE_DIR/tmp/zones" "$BASE_DIR/build/"

    # Reload BIND
    service bind9 reload

    echo "BIND server reloaded, zones updated."
    rc=0
  else
    echo "Could not sign some zones."
    echo "BIND server not reloaded."
    rc=1
  fi

  echo "Done."
else
  echo "Configuration test failed."
  echo "Aborted."
fi

exit $rc
