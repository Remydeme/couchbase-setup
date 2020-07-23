#!/bin/sh

# Constants
tag=$(git describe --tags)

# ╭────────────────────────╮
# │ COUCHBASE SETUP vX.X.X │
# ╰────────────────────────╯
# I'm hardly working to setup Couchbase asap 😉 Please be patient, I'll inform you about every incoming steps UwU

printf "╭────────────────────────╮\n│\u001b[36m COUCHBASE SETUP %s\u001b[0m │\n╰────────────────────────╯\n" "$tag"
printf "I'm hardly working to setup Couchbase asap 😉 Please be patient, I'll inform you about every incoming steps UwU\n\n"

# → Looking for configuration file...
printf "→ \u001b[33mLooking for configuration file...\u001b[0m"

CONFIG_FILE=""

for ARGUMENT in "$@"; do
  KEY=$(echo $ARGUMENT | cut -f1 -d=)
  VALUE=$(echo $ARGUMENT | cut -f2 -d=)

  case "$KEY" in
    --config-file)  		CONFIG_FILE=${VALUE} ;;
    *) ;;
  esac
done

if [ -z $CONFIG_FILE ]; then
	printf "\r\033[K😾 \u001b[31mUgu, you didn't provide any config file ! Please pass a path to your config.json file with \033[0m--config-file=\"path/to/my/configFile.json\"\u001b[31m flag\033[0m\n"
	exit
fi