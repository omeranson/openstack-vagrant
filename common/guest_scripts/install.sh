#!/bin/bash

# These commands are separate. If one installation fails, we want to keep going
# and not fail the others.
dnf upgrade -y dnf
dnf install -y git
dnf install -y tmux
dnf install -y tigervnc
dnf install -y libnghttp2
dnf upgrade -y libnghttp2
dnf install -y python-pip
dnf upgrade -y vim-minimal
dnf install -y vim
dnf install -y xauth
dnf install -y tigervnc

dnf group install -y "C Development Tools and Libraries"
dnf install -y kernel-devel-`uname -r`

pip install --upgrade pip
pip install tox
pip install python-subunit

useradd -m -U -G wheel stack

echo "stack ALL=NOPASSWD: ALL" > /etc/sudoers.d/stack-nopasswd

