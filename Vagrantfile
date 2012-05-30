user = ENV['OPSCODE_USER'] || ENV['USER']
base_box = ENV['VAGRANT_BOX'] || 'base'
 
Vagrant::Config.run do |config|

  config.vm.box = base_box

  config.vm.network :hostonly, "33.33.33.10"

end
