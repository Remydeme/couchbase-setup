#!/bin/sh


alias="alias couchbase-jc='sh ~/bin/couchbase-jc/setup-couchbase.sh'"
exportPath='export PATH="~/bin:$PATH"'

printf "\033[0;36mInstalling couchbase-jc...\033[0m\n"

printf "Installing dependencies..."

installer=""

commands[0]="apt-get"
commands[1]="dnf"
commands[2]="zypper"
commands[3]="pacman"
commands[4]="brew"

for com in "${commands[@]}"
do
    command -v "${com}"
    if [ $? -eq 0 ]
    then
        installer="${com} install"
        break
    fi
done

printf "\r\033[K"

command -v "jq"
if [ $? -eq 1 ] ; then
  if [ -n "${installer}" ]; then
    eval "${installer} jq"
  else
    printf "\033[0;31mCouldn't find any available installer. Install jq on your own, from https://stedolan.github.io/jq/download/\033[0m\n"
    exit 1
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
grep -v "^PATH" ~/.bash_profile >tmp.txt && mv tmp.txt ~/.bash_profile
grep -v "^export PATH=\"~/bin" ~/.bash_profile >tmp.txt && mv tmp.txt ~/.bash_profile
grep -v "^PATH" ~/.zshrc >tmp.txt && mv tmp.txt ~/.zshrc
grep -v "^export PATH=\"~/bin" ~/.zshrc >tmp.txt && mv tmp.txt ~/.zshrc

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
