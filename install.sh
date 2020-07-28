DIR=$(pwd)

cd ~ || (printf "\033\0;31mUnable to open root folder : please make sure you run this script with admin right.\033[0m\nrun : sudo sh install.sh\n" && exit)

printf "\033[0;36mInstalling couchbase-jc...\033[0m\n"
printf "Copying files..."

mkdir ~/bin/couchbase-jc
cd ~/bin/couchbase-jc || (printf "\033[0;31mCouldn't move to bin folder. Exiting installer...\033[0m\n" && exit)

curl https://github.com/a-novel/couchbase-setup/blob/master/meta.json --output meta.json
curl https://github.com/a-novel/couchbase-setup/blob/master/setup-couchbase.sh --output setup-couchbase.sh

touch .bash_profile
echo "PATH=~/bin:$PATH" > ".bash_profile"
echo "alias couchbase-jc='couchbase-setup.sh'" >> ".bash_profile"

cd "$DIR" || exit
printf "\r\033[K\o3[0;33mSetup complete !\033[0m\nYou can now use couchbase-jc in your local terminal."