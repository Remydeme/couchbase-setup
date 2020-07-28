#!/bin/sh

alias="alias couchbase-jc='sh ~/bin/couchbase-jc/setup-couchbase.sh'"
exportPath="PATH=\"~/bin:$PATH\""

printf "\033[0;36mInstalling couchbase-jc...\033[0m\n"

printf "Installing dependencies..."

installer=""

if ! command -v apt-get > /dev/null; then
  installer="sudo apt-get install"
elif ! command -v dnf > /dev/null; then
  installer="sudo dnf install"
elif ! command -v zypper > /dev/null; then
  installer="sudo zypper install"
elif ! command -v pacman > /dev/null; then
  installer="sudo pacman -S"
elif ! command -v brew > /dev/null; then
  installer="brew install"
elif ! command -v port > /dev/null; then
  installer="port install"
fi
  printf "\r\033[K"

if ! required_cmd="$(type "jq")" || [ -z "$required_cmd" ]; then
  if [ -n "$installer" ]; then
    eval "${installer} jq"
  else
    printf "\033[0;31mCouldn't find any available installer. Install jq on your own, from https://stedolan.github.io/jq/download/\033[0m\n"
  fi
fi

printf "\033[0;32mSuccessfully installed dependencies.\033[0m\n"

printf "Copying files..."

(rm -rf ~/bin/couchbase-jc && mkdir -p ~/bin/couchbase-jc >/dev/null 2>&1) ||
  (printf "\r\033[K\033[0;31mCouldn't move to bin folder. Exiting installer...\033[0m\n" && exit)

curl https://raw.githubusercontent.com/a-novel/couchbase-setup/master/meta.json --output ~/bin/couchbase-jc/meta.json >/dev/null 2>&1
curl https://raw.githubusercontent.com/a-novel/couchbase-setup/master/setup-couchbase.sh --output ~/bin/couchbase-jc/setup-couchbase.sh >/dev/null 2>&1
chmod +x ~/bin/couchbase-jcsetup-couchbase.sh >/dev/null 2>&1

if ! [ -e ~/.bash_profile ]; then
  touch ~/.bash_profile
fi

if ! [ -e ~/.zshrc ]; then
  touch ~/.zshrc
fi

# Remove obsolete lines.
curl https://raw.githubusercontent.com/a-novel/couchbase-setup/master/old.sh -L -O >/dev/null 2>&1 && sh old.sh > old.txt
rm old.sh

grep -Ffvx old.txt ~/.bash_profile > tmp && mv tmp ~/.bash_profile
grep -Ffvx old.txt ~/.zshrc > tmp && mv tmp ~/.zshrc
rm old.txt

if ! grep -Fxq "$exportPath" ~/.bash_profile; then
  echo "$exportPath" >>~/.bash_profile
fi

if ! grep -Fxq "$exportPath" ~/.zshrc; then
  echo "$exportPath" >>~/.zshrc
fi

if ! grep -Fxq "$alias" ~/.bash_profile; then
  echo "$alias" >>~/.bash_profile
fi

if ! grep -Fxq "$alias" ~/.zshrc; then
  echo "$alias" >>~/.zshrc
fi

printf "\r\033[K\033[0;32mSetup complete !\033[0m\nYou can now use couchbase-jc in your local terminal.\n"
