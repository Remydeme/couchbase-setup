#!/bin/sh

DIR="$(cd "$(dirname "$0")" && pwd)"

# Parse command-line arguments.
for ARGUMENT in "$@"; do
  KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
  VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)

  case "$KEY" in
  --commit) Commit=${VALUE} ;;
  --version) Version=${VALUE} ;;
  *) ;;
  esac
done

if [ -z "$Commit" ]; then
  printf "\033[0;31mMissing commit message !\033[0m\n"
  exit
fi

if [ -z "$Version" ]; then
  printf "\033[0;31mMissing commit version !\033[0m\n"
  exit
fi

echo "{\"version\": \"${Version}\"}" > "${DIR}/meta.json"

git add .
git commit -m "$Commit"
git push

git tag "$Version"
git push --tags