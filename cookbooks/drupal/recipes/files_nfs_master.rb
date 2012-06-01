#
# Author:: Seth Chisamore <schisamo@opscode.com>
# Cookbook Name:: mediawiki
# Recipe:: db_bootstrap
#
# Copyright 2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

app = data_bag_item("apps", "drupal")

if node.run_list.roles.include?(app["files_master_role"][0])
  dbm = node
else
  dbm = search(:node, "role:#{app["files_master_role"][0]} AND chef_environment:#{node.chef_environment}").first
end

# Shared files directory.
# NOTE - This directory is to be shared via NFS, etc.  Client nodes attach to it
# via NFS, etc.
directory ::File.join(app['deploy_to'], "files") do
  owner app['owner']
  group app['group']
  mode '0644'  # No execute
  recursive true
end

#db = app['databases'][node.chef_environment]

#cookbook_file "#{Chef::Config[:file_cache_path]}/schema.sql" do
#  source "schema.sql"
#  mode 0755
#  owner "root"
#  group "root"
#end

# TODO Symlink empty or default settings file from shared dir.

execute "drush_site-install" do
  cwd "#{::File.join(app['deploy_to'], 'shared')}"
  command "drush -u #{db['username']} -p#{db['password']} -h #{dbm['fqdn']} #{db['database']} < #{::File.join(app['deploy_to'], "current")}"
  action :run
  notifies :create, "ruby_block[remove_drupal_db_bootstrap]", :immediately
end

ruby_block "remove_drupal_db_bootstrap" do
  block do
    Chef::Log.info("Database Bootstrap completed, removing the destructive recipe[drupal::db_bootstrap]")
    node.run_list.remove("recipe[drupal::db_bootstrap]") if node.run_list.include?("recipe[drupal::db_bootstrap]")
  end
  action :nothing
end