# Vagrant script generator for Openstack

This project contains a simple script (*devstack.sh*), which generates a
Vagrantfile, and runs it. Within the generated VM, some base packages are
installed, and then devstack is run.

## Instructions

1. Clone the project.
2. Set up a libvirt server
3. Verify the defaults are to your likings
4. (Optional) Install an SSH public key in common/keys/id_rsa.pub
5. Create a local.conf file (Or use some of the examples in common/local.confs)
6. Run the script

Once the VM is set up, the vagrant folder will be printed (it will be in the
*instances* folder.) To enter the VM, cd into that folder, and run: *vagrant
ssh -p -- -l stack*. Other SSH options may follow if desired.

## Options

Run *./devstack -h* For options.

## Customisation

Once the VM is set up, the script *common/guest_scripts/install.sh* is executed
with root permissions. If you want additional packages installed, that is the
place.

Once install.sh is done, *common/guest_scripts/devstack.sh* is run, which
starts a tmux session, and calls stack.sh. This script is run as user *stack*.

