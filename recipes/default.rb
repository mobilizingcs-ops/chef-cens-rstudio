#
# Cookbook Name:: cens-rstudio
# Recipe:: default
#
# Author: Steve Nolen <technolengy@gmail.com>
#
# Copyright (c) 2014.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# require chef-vault
chef_gem 'chef-vault'
require 'chef-vault'

# install/enable nginx
node.set['nginx']['default_site_enabled'] = false
node.set['nginx']['install_method'] = 'package'
include_recipe 'nginx::repo'
include_recipe 'nginx'

# install R and required packages?
r 'default' do
  enable_cran_repo 'cran.stat.ucla.edu'
  site_profile [
    'local({r <- getOption("repos"); r["CRAN"] <- "http://cran.stat.ucla.edu/"; options(repos = r)})',
    'suppressPackageStartupMessages(library(mobilizr, warn.conflicts=FALSE, quietly=TRUE))'
   ]
end

cran_pkgs = %w(dplyr stats curl mosaic rstudioapi rmarkdown bitops evaluate htmltools knitr yaml log4r leaflet network)

# manage installation of our dependencies. should no-op since we have no interest in upgrading currently.
cran_pkgs.each do |pkg|
  cran pkg do
    repo 'http://cran.stat.ucla.edu'
    action [:install]
  end
end

# SSL
item = ChefVault::Item.load('ssl', 'mobilizingcs.org')
file '/etc/ssl/certs/mobilizingcs.org.crt' do
  owner 'root'
  group 'root'
  mode '0777'
  content item['cert']
  notifies :reload, 'service[nginx]', :delayed
end
file '/etc/ssl/private/mobilizingcs.org.key' do
  owner 'root'
  group 'root'
  mode '0600'
  content item['key']
  notifies :reload, 'service[nginx]', :delayed
end

# install rstudio server pro
directory '/root/rstudio_deb_pkgs'
rstudio_server_pro_version = '0.99.446'
rstudio_server_pro_checksum = '25a1dfc4c1d999b6106c9b1e587c97c0'
package 'gdebi-core'
remote_file 'download rstudio deb' do
  path "/root/rstudio_deb_pkgs/rstudio-server-pro-#{rstudio_server_pro_version}-amd64.deb"
  source "http://download2.rstudio.org/rstudio-server-pro-#{rstudio_server_pro_version}-amd64.deb"
  checksum rstudio_server_pro_checksum
  notifies :run, 'execute[install rstudio deb]', :immediately
end
execute 'install rstudio deb' do
  command "gdebi --non-interactive /root/rstudio_deb_pkgs/rstudio-server-pro-#{rstudio_server_pro_version}-amd64.deb"
  action :nothing
end

# activate? rstudio server pro
licenses = ChefVault::Item.load('rstudio', 'license')
license = licenses[node['fqdn']]
execute 'activate rstudio server pro' do
  command "rstudio-server license-manager activate #{license}; rstudio-server restart"
  not_if 'rstudio-server license-manager status | grep "Status: Activated"'
end

# RStudio server pro conf files
template '/etc/rstudio/rsession.conf' do
  source 'rsession.conf.erb'
  mode '0755'
end
template '/etc/rstudio/rserver.conf' do
  source 'rserver.conf.erb'
  mode '0755'
end

# nginx conf
template '/etc/nginx/sites-available/rstudio' do
  source 'rstudio-nginx.conf.erb'
  mode '0755'
  action :create
  notifies :reload, 'service[nginx]', :delayed
end
nginx_site 'rstudio' do
  action :enable
end

# raster hack
directory '/tmp/R_raster_tmp' do
  owner 'root'
  group 'root'
  mode '0777'
  action :create
end
