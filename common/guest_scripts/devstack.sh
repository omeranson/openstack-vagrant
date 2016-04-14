#!/bin/bash

cd /home/stack
mkdir -p .ssh
if [ ! -f ~/.ssh/authorized_keys ]; then
    cat /vagrant_common/keys/id_rsa.pub >> ~/.ssh/authorized_keys
fi
find /vagrant_common/confs/ -type f -exec cp {} ~/ \;

if [ ! -d "devstack" ]; then
    git clone https://github.com/openstack-dev/devstack
else
    pushd devstack
    git pull
    popd
fi

cp /vagrant/local.conf devstack/local.conf
tmux start-server
tmux new-session -d -s stack -n stack
tmux send-keys -t stack:stack "cd devstack" C-m
tmux send-keys -t stack:stack "./stack.sh" C-m

ip addr

