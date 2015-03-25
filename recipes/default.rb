# vim: set ft=ruby
# Cookbook Name:: drupal_s3fs_proxy
# Recipe:: default
#
# Copyright (C) 2015 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'apache2::mod_proxy'
include_recipe 'apache2::mod_proxy_http'

node[:deploy].each do |app_name, deploy|

  app_domain = deploy[:domains].first
  if deploy[:application_type] != 'php' and node[:appcfg][app_domain][:s3fs].nil?
    Chef::Log.debug("Skipping s3fs_proxy configuration, app #{app_domain} does not seem to use s3fs")
    next
  end


  domain_conf = node[:appcfg][app_domain]
  if !domain_conf.nil? and !domain_conf[:s3fs].nil?
    if domain_conf[:s3fs][:cdn_domain_name] and !domain_conf[:s3fs][:cdn_domain_name].nil?
      s3fs_res_name = domain_conf[:s3fs][:cdn_domain_name]
    else
      s3fs_res_name = "#{domain_conf[:s3fs][:s3_bucket_name]}.s3.amazonaws.com"
    end
  end

  directory "#{node[:apache][:dir]}/sites-available/#{app_name}.conf.d" do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end

  template "#{node[:apache][:dir]}/sites-available/#{app_name}.conf.d/local_s3fs_proxy.conf" do
    source 's3fs_proxy.conf'
    mode '0644'
    variables :s3fs_res_name => s3fs_res_name
    notifies :reload, 'service[apache2]', :immediately
    only_if {s3fs_res_name}
  end
    
end
