#
# Cookbook Name:: drupal
# Recipe:: app
#
# Glenn Pratt
#
# Based off application::php
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

app = node.run_state[:current_app]

include_recipe "php"

###
# You really most likely don't want to run this recipe from here - let the
# default application recipe work it's mojo for you.
###

node.default['apps'][app['id']][node.chef_environment]['run_migrations'] = false

# the PHP projects have no standard local settings file name..or path in the project
local_settings_full_path = app['local_settings_file'] || 'LocalSettings.php'
local_settings_file_name = local_settings_full_path.split(/[\\\/]/).last

drupal_verson = app['drupal_version'] || '7'

## First, install any application specific packages
if app['packages']
  app['packages'].each do |pkg,ver|
    package pkg do
      action :install
      version ver if ver && ver.length > 0
    end
  end
end

## Next, install any application specific gems
if app['pears']
  app['pears'].each do |pear,ver|
    php_pear pear do
      action :install
      version ver if ver && ver.length > 0
    end
  end
end

directory app['deploy_to'] do
  owner app['owner']
  group app['group']
  mode '0755'
  recursive true
end

directory "#{app['deploy_to']}/shared" do
  owner app['owner']
  group app['group']
  mode '0755'
  recursive true
end

directory "#{app['deploy_to']}/shared/public_files" do
  owner node[:apache][:user]
  group node[:apache][:group]
  mode '0755'
  recursive true
end

directory "#{app['deploy_to']}/shared/private_files" do
  owner node[:apache][:user]
  group node[:apache][:group]
  mode '0755'
  recursive true
end

if app.has_key?("deploy_key")
  file "#{app['deploy_to']}/id_deploy" do
    owner app['owner']
    group app['group']
    mode '0600'
    content app["deploy_key"]
  end

  template "#{app['deploy_to']}/deploy-ssh-wrapper" do
    source "deploy-ssh-wrapper.erb"
    cookbook 'application'
    owner app['owner']
    group app['group']
    mode "0755"
    variables app.to_hash
  end
end

if app["database_master_role"]
  dbm = nil
  # If we are the database master
  if node.run_list.roles.include?(app["database_master_role"][0])
    dbm = node
  else
  # Find the database master
    results = search(:node, "role:#{app["database_master_role"][0]} AND chef_environment:#{node.chef_environment}", nil, 0, 1)
    rows = results[0]
    if rows.length == 1
      dbm = rows[0]
    end
  end

  # Assuming we have one...
  if dbm
    template "#{app['deploy_to']}/shared/#{local_settings_file_name}" do
      source "settings.php.#{drupal_verson}.erb"
#      cookbook app["id"]
      owner app["owner"]
      group app["group"]
      mode "644"
      variables(
        :path => "#{app['deploy_to']}/current",
        :host => dbm['fqdn'],
        :database => app['databases'][node.chef_environment],
        :app => app
      )
    end
  else
    error = "No node with role #{app['database_master_role'][0]}, #{local_settings_file_name} not rendered!"
    Chef::Log.error(error)
    raise error
  end
end

## Then, deploy
deploy_revision app['id'] do
  revision app['revision'][node.chef_environment]
  repository app['repository']
  enable_submodules true
  user app['owner']
  group app['group']
  deploy_to app['deploy_to']
  action app['force'][node.chef_environment] ? :force_deploy : :deploy
  ssh_wrapper "#{app['deploy_to']}/deploy-ssh-wrapper" if app['deploy_key']
  shallow_clone true
  purge_before_symlink([])
  create_dirs_before_symlink([])
  symlinks "public_files" => (app['web_root']) ? "#{app['web_root']}/sites/default/files" : "sites/default/files"
  symlink_before_migrate({
    local_settings_file_name => local_settings_full_path,
    "#{app['deploy_to']}/shared/public_files" => local_settings_full_path
  })
  # TODO drush updatedb
  migrate true
  migration_command 'ls'
  before_migrate do
    # TODO bash is supposed to be synchronous and execute isn't.
    # Is that right, what are the implications of async here?
    if app.has_key?("drush_make_file")
      execute "drush_make" do
        user "root"
        cwd release_path
        environment ({'GIT_SSH' => "#{app['deploy_to']}/deploy-ssh-wrapper"}) if app['deploy_key']
        command "drush make #{app['drush_make_file']} #{app['web_root']}"
      end
    end
    # TODO create_dirs_before_symlink doesn't work here...
    if app.has_key?("dirs")
      app['dirs'].each do |path|
        directory "#{release_path}/#{path}" do
          owner app['owner']
          group app['group']
          mode '0755'
          recursive true
        end
      end
    end
  end
  before_restart do
    # Fix up file directory ownership - PHP *should* own the files directories.
    # TODO - This is hard coded to apache cookbook.
    directory "#{app['deploy_to']}/shared/public_files" do
      owner node[:apache][:user]
      group node[:apache][:group]
      mode '0755'
    end

    directory "#{app['deploy_to']}/shared/private_files" do
      owner node[:apache][:user]
      group node[:apache][:group]
      mode '0755'
    end
  end
end

# Sometimes repos are built above web root.
if app['web_root']
  path = ::File.join(app['deploy_to'], "current", app['web_root'])
else
  path = ::File.join(app['deploy_to'], "current")
end

# Enable cron via Drush
cron "drush-cron-#{app['id']}" do
  minute "*/5"
  command "/usr/bin/drush --root=#{path} cron"
end
