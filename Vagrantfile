require 'yaml'

def escape(s)
    "\"" + s.gsub("\\", "\\\\").gsub("\"", "\\\"") + "\""
end

directory = YAML.load_file("directory.conf.yml")

username = "root"

Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"
  config.vm.synced_folder '~/vagrant/common', '/vagrant_common', type: "rsync"

  directory['machines'].each do |machine|
    config.vm.define machine['name'] do |config|
      config.vm.hostname = machine['name']
      config.vm.box = machine['box']
      config.vm.provider :libvirt do |libvirt|
        libvirt.host = machine['hypervisor']['name']
        libvirt.connect_via_ssh = true
        libvirt.username = machine['hypervisor']['username']
        libvirt.memory = machine['memory']
        libvirt.cpus = machine['vcpus']
      end
      config.vm.provision "ansible" do |ansible|
        ansible.playbook = "devstack.yml"
        ansible.raw_arguments = "-vvv"
        ansible.host_vars = {machine['name'] => {"ansible_ssh_common_args": escape("-o ProxyCommand=\"ssh '#{machine['name']}' -l '#{machine['hypervisor']['username']}' -i '/#{ENV['HOME']}/.ssh/id_rsa' nc %h %p\"")}}
        ansible.extra_vars = {
          local_conf_file: machine['local_conf_file']
        }
      end
    end
  end
end
