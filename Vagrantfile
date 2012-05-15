Vagrant::Config.run do |config|
  config.vm.box = "base"

  config.vm.customize do |vm|
    vm.memory_size = 1024
  end

  config.vm.network("33.33.33.10")
  config.vm.share_folder("v-root", "/vagrant", ".")
end
