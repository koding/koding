Deploying using ansible.

---- 

do:
echo "export ANSIBLE_CONFIG=YOUR_PATH_TO_THIS_FOLDER/ansible.cfg" >> ~/.bash_profile
echo "export RAX_CREDS_FILE=YOUR_PATH_TO_THIS_FOLDER/rax_creds_file" >> ~/.bash_profile

source ~/.bash_profile



you should install pip and pyrax for this to work.

sudo easy_install pip
sudo pip install pyrax
sudo pip install --upgrade distribute

you gotta run this ./auth.py

then try,

ansible localhost -m rax -a "name=awx flavor=4 image=ubuntu-1204-lts-precise-pangolin wait=yes" -c local

if it works, pyrax works. continue.







