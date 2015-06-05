# Ansible Supervisioning

## Installation

You don't have to follow the installation steps. The instructions below are just for reference.

We have a setup to provision the user VMs via Ansible.
There is a configured machine on AWS, with the IP of `54.172.97.80`.

Export `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
Copy `ansible.cfg`, `hosts` and `ec2.ini` files into /etc/ansible/.
Copy `ssh_config` into ~/.ssh/config.

## Usage

SSH into the machine:

```sh
koding$ ssh ubuntu@54.172.97.80 -i machine.pem
```

Then you should be able to run arbitrary commands on the desired machine.

### Examples

* Check if `klient` is running on each server:

```sh
$ ansible us-east-1 -m service -a "name=klient state=started" -o -s
```

* Check a specific user's machines. You should put a `tags_koding-user_` prefix to the username.

```sh
$ ansible tags_koding-user_devrim -m ping -o
```

* Check klient.log for debugging purposes.

```sh
$ ansible tags_koding-user_devrim -m shell -a "tail -n 20 /var/log/upstart/klient.log" -s
```
