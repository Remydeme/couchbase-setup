DIR=$(pwd)

cd ~ || (printf "\033\0;31mUnable to open root folder : please make sure you run this script with admin right.\033[0m\nrun : sudo sh install.sh\n" && exit)

printf "\033[0;36mInstalling couchbase-setup...\033[0m\n"
printf "Copying files...\n"

mkdir ~/bin
cd ~/bin || (printf "\033[0;31mCouldn't move to bin folder. Exiting installer...\033[0m\n" && exit)

git clone https://github.com/a-novel/couchbase-setup couchbase-setup

cd "$DIR" || exit