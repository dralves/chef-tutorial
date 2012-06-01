#
# Cookbook Name:: drupal
# Recipe:: app_mod_php_apache2
#
# Glenn Pratt
#
# Based off application::mod_php_apache2
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

# TODO - This is only needed if you have an lb.
#node.default['apache']['listen_ports'] = [ "8080" ]


# TODO - Need PHP > 5.3.3 for PHP-FPM

include_recipe "nginx::ppa"
include_recipe "php::fpm"
include_recipe "nginx"

# TODO Review wildcard alias, that could get messy.
server_aliases = [ "#{app['id']}.*" ]

# TODO - Make this generic 'cloud'.
if node.has_key?("ec2")
  server_aliases << node.ec2.public_hostname
end

# Sometimes repos are built above web root.
if app['web_root']
  path = ::File.join(app['deploy_to'], "current", app['web_root'])
else
  path = ::File.join(app['deploy_to'], "current")
end

nginx_app app['id'] do
  docroot path
  template 'app_nginx.conf.erb'
  server_name "#{app['id']}.#{node['domain']}"
  server_aliases server_aliases
  log_dir node['nginx']['log_dir']
  port '8080'
end

if ::File.exists?(::File.join(app['deploy_to'], "current"))
  d = resources(:deploy_revision => app['id'])
  d.restart_command do
    service "nginx" do action :restart; end
  end
end

nginx_site "default" do
  enable false
end