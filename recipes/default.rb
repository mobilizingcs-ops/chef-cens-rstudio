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
    'suppressPackageStartupMessages(library(MobilizeSimple, warn.conflicts=FALSE, quietly=TRUE))',
    'suppressPackageStartupMessages(library(ggplot2, warn.conflicts=FALSE, quietly=TRUE))'
  ]
end

cran_pkgs = %w(raster dismo tm RColorBrewer rgdal sp wordcloud stringr plyr dplyr mosaic latticeExtra grid rpart rpart.plot curl)

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
