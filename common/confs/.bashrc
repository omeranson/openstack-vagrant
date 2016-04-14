# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
set -o vi

if [ -r /usr/share/git-core/contrib/completion/git-prompt.sh ]; then
    source /usr/share/git-core/contrib/completion/git-prompt.sh
    export PS1='[\u@\h \W$(declare -F __git_ps1 &>/dev/null && __git_ps1 " (%s)")]\$ '
fi

# Taken from:
# http://stackoverflow.com/questions/370047/what-is-the-most-elegant-way-to-remove-a-path-from-the-path-variable-in-bash
path_append ()  { path_remove $1; export PATH="$PATH:$1"; }
path_prepend () { path_remove $1; export PATH="$1:$PATH"; }
path_remove ()  { export PATH=`echo -n $PATH | awk -v RS=: -v ORS=: '$0 != "'$1'"' | sed 's/:$//'`; }

path_prepend /usr/bin
path_prepend /usr/sbin
path_prepend $HOME/bin

