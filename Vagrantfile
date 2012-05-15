user = ENV['OPSCODE_USER'] || ENV['USER']
base_box = ENV['VAGRANT_BOX'] || 'base'
 
Vagrant::Config.run do |config|
  config.vm.box = base_box
  config.vm.network("33.33.33.10")
  config.vm.provision :chef_client do |chef|
 
    # Set up some organization specific values based on environment variable above.
    chef.chef_server_url = "https://api.opscode.com/organizations/#{ENV['ORGNAME']}"
    chef.validation_key_path = ".chef/#{ENV['ORGNAME']}-validator.pem"
    chef.validation_client_name = "#{ENV['ORGNAME']}-validator"
 
    # Change the node/client name for the Chef Server
    chef.node_name = "#{user}-vagrant"
 
    # Put the client.rb in /etc/chef so chef-client can be run w/o specifying
    chef.provisioning_path = "/etc/chef"
 
    # logging
    chef.log_level = :info
 
    # adjust the run list to suit your testing needs
    chef.run_list = [
      "role[base]"
    ]
  end
end
