# Some defaults:
if [ -r $HOME/.openstack-vagrant.conf ]; then
    source $HOME/.openstack-vagrant.conf
fi

VAGRANT_BOX_DEFAULT="fedora/23-cloud-base"
LIBVIRT_SERVER_DEFAULT="localhost"
VAGRANT_MEMORY_DEFAULT=8192
VAGRANT_CPUS_DEFAULT=1

STORAGE_POOL_DEFAULT="default"

VAGRANT_BOX=${VAGRANT_BOX:-$VAGRANT_BOX_DEFAULT}
LIBVIRT_SERVER=${LIBVIRT_SERVER:-$LIBVIRT_SERVER_DEFAULT}
LOCAL_CONF=${LOCAL_CONF:-"local.conf"}
VAGRANT_MEMORY=${VAGRANT_MEMORY:-$VAGRANT_MEMORY_DEFAULT}
VAGRANT_CPUS=${VAGRANT_CPUS:-$VAGRANT_CPUS_DEFAULT}
INSTALL_SCRIPT=${INSTALL_SCRIPT:-"install.sh"}
BASE=${BASE:-~/vagrant/instances}
STORAGE_POOL=${STORAGE_POOL:-$STORAGE_POOL_DEFAULT}
DISK_SIZE=${DISK_SIZE:-""}

function help {
    echo "USAGE: $0 [options]
Where [option]s may be:
    -b <box type>       The base box to use for the node (default: $VAGRANT_BOX_DEFAULT)
    -d <disk size>      The maximum allocated disk size (default: image default)
    -g <storage pool>   Allocate storage from this libvirt storage pool (default: $STORAGE_POOL_DEFAULT)
    -i <install-script> The install script to use (default: install.sh)
    -l <local.conf>     The name of the local.conf file on which to run stack.sh
    -m <memory>         The amount of allocated memory, in MB (default $VAGRANT_MEMORY_DEFAULT)
    -s <servername>     The name of the virtual machine server (default: $LIBVIRT_SERVER_DEFAULT)
    -v <vcpus>          The number of virtual CPUS allocated (default: $VAGRANT_CPUS_DEFAULT)
    -h                  This help message"
}

while getopts "b:d:g:i:l:m:s:v:h" OPTION ; do
    case $OPTION in
        b ) VAGRANT_BOX=$OPTARG ;;
        d ) DISK_SIZE=$OPTARG ;;
        g ) STORAGE_POOL=$OPTARG ;;
        i ) INSTALL_SCRIPT=$OPTARG ;;
        l ) LOCAL_CONF=$OPTARG ;;
        m ) VAGRANT_MEMORY=$OPTARG ;;
        s ) LIBVIRT_SERVER=$OPTARG ;;
        v ) VAGRANT_CPUS=$OPTARG ;;
        h ) help ; exit 0 ;;
    esac
done

# Verification
REGEX="^$VAGRANT_BOX\>"
vagrant box list | grep -q $REGEX
if [ $? -ne 0 ]; then
    echo >&2 "Cannot find vagrant box $VAGRANT_BOX. The following are available:"
    vagrant box list >&2
    exit 1
fi

if [ ! -r "$LOCAL_CONF" ]; then
    echo >&2 "Cannot find access local.conf file $LOCAL_CONF"
    exit 1
fi

if [ ! -x "$HOME/vagrant/common/guest_scripts/$INSTALL_SCRIPT" ]; then
    echo >&2 "Cannot find install script $INSTALL_SCRIPT, or it is not executable"
    exit 1
fi

RAND=`mktemp -u XXXXXX`

STORAGE_POOL_CONFIG=""
if [[ "$STORAGE_POOL" != "" ]]; then
    STORAGE_POOL_CONFIG="libvirt.storage_pool_name = \"$STORAGE_POOL\""
fi

DISK_SIZE_CONFIG=""
if [[ "$DISK_SIZE" != "" ]]; then
    DISK_SIZE_CONFIG="libvirt.machine_virtual_size=\"$DISK_SIZE\""
fi
#LVM_CREATE_VOLUME_TRIGGER=""
#LVM_DESTROY_VOLUME_TRIGGER=""
#if [ "$VAGRANT_LIBVIRT_SERVER" != "localhost" ]; then
#    LVM_USE_VOLUME="libvirt.storage_pool_name = \"$LVM_VOLUME_GROUP\""
#    VOLUME_NAME="stack-$RAND"
#    VOLUME_PATH="/dev/$LVM_VOLUME_GROUP/$VOLUME_NAME"
#    LVM_USE_VOLUME="
#    libvirt.storage :file do |storage|
#        storage.type = "raw"
#        storage.allow_existing = true
#        storage.path = "$VOLUME_NAME"
#        storage.bus = 'scsi'
#        storage.device = 'sda'
#    end
    
#    LVM_CREATE_VOLUME_TRIGGER="
#  config.trigger.before :up do
#    run \"ssh root@$VAGRANT_LIBVIRT_SERVER lvcreate -T -L $LVM_DISK_SIZE -n $VOLUME_NAME $LVM_VOLUME_GROUP && ln -s $VOLUME_PATH /var/lib/libvirt/images/$VOLUME_NAME\"
#  end
#"
#    LVM_DESTROY_VOLUME_TRIGGER="
#  config.trigger.after :destroy do
#    run \"ssh root@$VAGRANT_LIBVIRT_SERVER lvremove -f $VOLUME_PATH\"
#  end
#"
#fi

# Create!

VAGRANT_FOLDER="$BASE/stack-$RAND"
mkdir -p $VAGRANT_FOLDER
cat >> $VAGRANT_FOLDER/Vagrantfile << EOF
# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "$VAGRANT_BOX"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  #config.vm.network "public_network"

  config.vm.hostname = "stack-$RAND"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"
  config.vm.synced_folder '~/vagrant/common', '/vagrant_common', type: "rsync"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  config.vm.provider :libvirt do |libvirt|
    libvirt.host = "$LIBVIRT_SERVER"
    libvirt.connect_via_ssh = true
    libvirt.username = "root"
    libvirt.memory = $VAGRANT_MEMORY
    libvirt.cpus = $VAGRANT_CPUS
    $STORAGE_POOL_CONFIG
    $DISK_SIZE_CONFIG
  end

  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
 
  config.vm.provision "shell", inline: "/vagrant_common/guest_scripts/$INSTALL_SCRIPT"

  config.vm.provision "shell" do |s|
    s.inline = "sudo -u stack /vagrant_common/guest_scripts/devstack.sh"
    s.args = "/vagrant/local.conf"
  end
end
EOF

cp "$LOCAL_CONF" "$VAGRANT_FOLDER/local.conf"

pushd $VAGRANT_FOLDER
vagrant up
popd
echo $VAGRANT_FOLDER
