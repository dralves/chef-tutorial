current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "dralves"
client_key               "#{current_dir}/dralves.pem"
validation_client_name   "pictonio-validator"
validation_key           "#{current_dir}/pictonio-validator.pem"
chef_server_url          "https://api.opscode.com/organizations/pictonio"
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
cookbook_path            ["#{current_dir}/../cookbooks"]
