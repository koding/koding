if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo - exiting."
  exit
fi


FILE=`pwd`"/koding/README.markdown"

if [ -f $FILE ];
then
   echo "I can see $FILE - seems like you have the git repo."
else
  # echo "File $FILE does not exist."
  echo "What is your github username:"
  read githubUsername
  gitRepo="git@github.com:"$githubUsername"/koding.git"
  echo "So I'll pull from "$gitRepo" - correct?"
  read nothing
  git clone $gitRepo
  if [ -f $FILE ];
  then
     echo "I can see $FILE - seems like you have the git repo."
  fi

fi

echo "Do you think you have the koding git repo now?"
read gitWorked
if [ $gitWorked == "no" ]
  then echo "You probably should add your PublicKey to Github then try again. exiting..."
  exit
fi

sudo apt-get -y update
sudo apt-get install -y nodejs make nginx gcc mongodb-clients docker.io graphicsmagick 
sudo ln -sf "/usr/bin/docker.io" "/usr/local/bin/docker"
sudo sed -i '$acomplete -F _docker docker' /etc/bash_completion.d/docker.io

user=`whoami`
sudo chown $user:$user -R /usr/local
npm i coffee-script gulp stylus minimist -g

cd ./koding
npm i
git submodule update --recursive
./configure
./run install
sudo ./run buildservices
chmod +x ./run
echo "---------------------------------------------------------------------"
echo "INSTALL COMPLETE: TYPE ./run and see koding at http://yourdomain:8090"
echo "---------------------------------------------------------------------"
